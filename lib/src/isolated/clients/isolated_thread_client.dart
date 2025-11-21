import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_service_client_witt_entity.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_services_client_manager.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_client_background.dart';
import 'package:maxi_thread/src/isolated/isolate_stream_manager.dart';
import 'package:maxi_thread/src/isolated/isolate_thread_instance.dart';
import 'package:maxi_thread/src/isolated/logic/obtain_thread_identifier.dart';
import 'package:maxi_thread/src/isolated/logic/search_point_on_thread_server.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_message.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';
import 'package:maxi_thread/src/isolated/remote/isolate_thread_remote_object.dart';

class IsolatedThreadClient implements ThreadInstance, IsolatedThread, IsolateThreadInstance {
  final _connections = <IsolatedThreadConnection>[];
  final _contentionsIDS = <int, IsolatedThreadConnection>{};

  IsolateThreadRemoteObject? _threadRemoteObject;
  IsolateStreamManager? _streamManager;

  final Map<dynamic, dynamic> zoneValues = {};

  @override
  final int identifier;

  @override
  late final IsolatedThreadConnection server;

  @override
  late ThreadServiceManager services;

  @override
  ThreadRemoteObjectManager get remoteObjects {
    _threadRemoteObject ??= IsolateThreadRemoteObject();
    return _threadRemoteObject!;
  }

  @override
  IsolateStreamManager get streamManager {
    _streamManager ??= IsolateStreamManager(parent: this);
    return _streamManager!;
  }

  IsolatedThreadClient({required SendPort serverPort, required this.identifier}) {
    final serverInstance = IsolatedThreadConnection(
      instance: this,
      channel: IsolatorChannelEndPoint(sendPoint: serverPort),
      zoneValues: zoneValues,
    );
    server = serverInstance;
    _connections.add(serverInstance);

    services = IsolatedServicesClientManager(invocator: this, serverConnection: server);
  }

  void changeToEntityThread<T>(T item) {
    if (services is IsolatedServiceClientWittEntity) {
      throw ArgumentError('[IsolatedThreadClient] This thread has already been defined as an entity (${(services as IsolatedServiceClientWittEntity).serviceType})!');
    }
    services = IsolatedServiceClientWittEntity<T>(entity: item, services: services);
    zoneValues[ThreadInvocator.entitySymbol] = item;
  }

  @override
  ThreadInvocator get background => IsolatedThreadClientBackground(server: server);

  Future<Result<IsolatedThreadConnection>> connectPoint({required SendPort point}) async {
    final instance = IsolatedThreadConnection(
      instance: this,
      channel: IsolatorChannelEndPoint(sendPoint: point),
      zoneValues: zoneValues,
    );

    final idContent = await const ObtainThreadIdentifier().inThread(instance);
    if (idContent.itsFailure) return idContent.cast();

    _connections.add(instance);
    _contentionsIDS[idContent.content] = instance;

    instance.onDispose.whenComplete(() => _connections.remove(instance));

    return ResultValue(content: instance);
  }

  @override
  Future<Result<ThreadInvocator>> createThread({required String name}) async {
    final point = await server.executeResult(parameters: InvocationParameters.only(name), function: _createThreadInServer);
    if (point.itsFailure) return point.cast();
    return connectPoint(point: point.content);
  }

  static Future<Result<SendPort>> _createThreadInServer(InvocationParameters para) async {
    final name = para.firts<String>();

    final serverInstance = ThreadInstance.getIsolatedInstance();
    if (serverInstance.itsFailure) return serverInstance.cast();

    final threadResult = await serverInstance.content.createThread(name: name);
    if (threadResult.itsFailure) return threadResult.cast();

    final itsIsolatedThread = threadResult.cast<IsolatedThread>();
    if (itsIsolatedThread.itsFailure) return itsIsolatedThread.cast();

    return await itsIsolatedThread.content.getNewSendPortFromThread();
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() async {
    final point = IsolatorChannelInitiationPoint();
    final newConnection = IsolatedThreadConnection(instance: this, channel: point, zoneValues: zoneValues);

    _connections.add(newConnection);

    newConnection.onDispose.whenComplete(() => _connections.remove(newConnection));

    separateExecution(
      function: () async {
        await point
            .waitInitialization(timeout: const Duration(seconds: 5))
            .onCorrectFuture((_) async {
              final idResult = await ObtainThreadIdentifier().inThread(newConnection);
              if (idResult.itsFailure) return idResult.cast();

              _contentionsIDS[idResult.content] = newConnection;
              return voidResult;
            })
            .catchNegativeFuture((error) => log('[IsolatedThreadClient -> getNewSendPortFromThread] Could not obtain new send port: $error'));
        return voidResult;
      },
    );

    return ResultValue(content: point.output);
  }

  @override
  Future<Result<void>> closeThread() async {
    _reservedCloseThread();
    return voidResult;
  }

  Future<void> _reservedCloseThread() async {
    await Future.delayed(Duration.zero);
    for (final item in _connections) {
      final closedResult = item.channel.send(const IsolatedThreadMessage(type: IsolatedThreadMessageType.closed, identifier: 0, content: null));
      if (closedResult.itsFailure) {
        log('[IsolatedThreadClient -> closeThread] ${closedResult.error}!');
      }
    }

    server.dispose();

    Future.delayed(Duration(milliseconds: 20)).whenComplete(() {
      Isolate.exit();
    });
  }

  @override
  Future<Result<ThreadInvocator>> getInvocatorByID({required int identifier}) async {
    if (identifier == this.identifier) {
      return asResultValue();
    } else if (identifier == 0) {
      return server.asResultValue();
    }

    final connectionObtained = _contentionsIDS[identifier];
    if (connectionObtained != null) {
      return connectionObtained.asResultValue();
    }

    return await SearchPointOnThreadServer(identifier: identifier).inThread(server).onCorrectFuture((x) => connectPoint(point: x));
  }
}

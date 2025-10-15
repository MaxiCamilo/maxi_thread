import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_entity_connection.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_message.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';

class IsolatedThreadClient implements ThreadInstance, IsolatedThread {
  final _connections = <IsolatedThreadConnection>[];

  final _services = <IsolatedThreadEntityConnection>[];

  @override
  late final IsolatedThreadConnection server;

  @override
  T? getEntityThread<T>() => ThreadEntity.getEntity<T>();

  IsolatedThreadClient(SendPort serverPort) {
    final serverInstance = IsolatedThreadConnection(channel: IsolatorChannelEndPoint(sendPoint: serverPort));
    server = serverInstance;
    _connections.add(serverInstance);
  }

  @override
  // TODO: implement background
  ThreadInvocator get background => throw UnimplementedError();

  @override
  Future<Result<ThreadInvocator>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    final point = await server.executeResult(parameters: InvocationParameters.list([item, skipIfAlreadyMounted, name]), function: _createServiceThreadInServer<T>);
    if (point.itsFailure) return point.cast();
    final instance = IsolatedThreadConnection(channel: IsolatorChannelEndPoint(sendPoint: point.content));

    _connections.add(instance);
    instance.onDispose.whenComplete(() => _connections.remove(instance));

    return ResultValue(content: instance);
  }

  static Future<Result<SendPort>> _createServiceThreadInServer<T extends Object>(InvocationParameters para) async {
    final item = para.firts<T>();
    final skipIfAlreadyMounted = para.second<bool>();
    final name = para.third<String?>();

    final threadResult = await ThreadSingleton.createServiceThread(item: item, skipIfAlreadyMounted: skipIfAlreadyMounted, name: name);
    if (threadResult.itsFailure) return threadResult.cast();

    return await (threadResult as IsolatedThread).getNewSendPortFromThread();
  }

  @override
  Future<Result<ThreadInvocator>> createThread({required String name}) async {
    final point = await server.executeResult(parameters: InvocationParameters.only(name), function: _createThreadInServer);
    if (point.itsFailure) return point.cast();
    final instance = IsolatedThreadConnection(channel: IsolatorChannelEndPoint(sendPoint: point.content));

    _connections.add(instance);
    instance.onDispose.whenComplete(() => _connections.remove(instance));

    return ResultValue(content: instance);
  }

  static Future<Result<SendPort>> _createThreadInServer(InvocationParameters para) async {
    final name = para.firts<String>();
    final threadResult = await ThreadSingleton.createThread(name: name);
    if (threadResult.itsFailure) return threadResult.cast();

    return await (threadResult as IsolatedThread).getNewSendPortFromThread();
  }

  @override
  ThreadInvocator service<T extends Object>() {
    final instance = _services.selectType<IsolatedThreadEntityConnection<T>>();
    if (instance != null) {
      return instance;
    }

    final newInstance = IsolatedThreadEntityConnection<T>(serverConnection: server);
    _services.add(newInstance);
    newInstance.onDispose.whenComplete(() => _services.remove(newInstance));

    return newInstance;
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() async {
    final point = IsolatorChannelInitiationPoint();
    final newConnection = IsolatedThreadConnection(channel: point);
    _connections.add(newConnection);

    newConnection.onDispose.whenComplete(() => _connections.remove(newConnection));
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

    for (final item in _services) {
      item.dispose();
    }

    server.dispose();

    Future.delayed(Duration(milliseconds: 20)).whenComplete(() {
      Isolate.exit();
    });
  }
}

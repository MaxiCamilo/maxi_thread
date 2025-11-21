import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/main_thread_instance.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_created.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';
import 'package:maxi_thread/src/isolated/isolate_stream_manager.dart';
import 'package:maxi_thread/src/isolated/isolate_thread_instance.dart';
import 'package:maxi_thread/src/isolated/logic/define_app_manager_in_isolator.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolated/remote/isolate_thread_remote_object.dart';
import 'package:maxi_thread/src/isolated/server/isolate_thread_background_manager.dart';
import 'package:maxi_thread/src/isolated/server/isolated_services_server_manager.dart';

class IsolatedThreadServer implements ThreadInstance, IsolatedThread, IsolateThreadInstance {
  final _childs = <IsolatedThreadCreated>[];
  final Map<dynamic, dynamic> zoneValues;

  IsolateThreadBackgroundManager? _backgroundManager;
  IsolateThreadRemoteObject? _threadRemoteObject;
  IsolateStreamManager? _streamManager;

  @override
  ThreadInvocator get server => const MainThreadInstance();

  @override
  ThreadInvocator get background {
    _backgroundManager ??= IsolateThreadBackgroundManager(server: this);
    return _backgroundManager!;
  }

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

  @override
  int get identifier => 0;

  @override
  late final IsolatedServicesServerManager services;

  IsolatedThreadServer({this.zoneValues = const {}}) {
    services = IsolatedServicesServerManager(invocator: this);
  }

  @override
  Future<Result<IsolatedThreadConnection>> createThread({required String name}) async {
    if (!ApplicationManager.itsWasDefined) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'You must first define the application manager'),
      );
    }

    final point = IsolatorChannelInitiationPoint();
    final id = _childs.length + 1;
    final isolate = await Isolate.spawn(_prepareThread, (point.output, id), debugName: name, errorsAreFatal: false);
    if (!await point.waitConfirmation()) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The isolator did not return his channel'),
      );
    }

    final connection = IsolatedThreadConnection(channel: point, instance: this, zoneValues: zoneValues);
    final instance = IsolatedThreadCreated(identifier: id, isolate: isolate, communicator: connection);
    _childs.add(instance);

    connection.onDispose.whenComplete(() => _childs.remove(instance));

    final appManagerClone = ApplicationManager.singleton.cloneToIsolate();
    if (appManagerClone.itsFailure) return appManagerClone.cast();

    final defineAppManagerResult = await DefineAppManagerInIsolator(appManager: appManagerClone.content).inThread(connection);
    if (defineAppManagerResult.itsFailure) {
      return defineAppManagerResult.cast();
    }

    return ResultValue(content: connection);
  }

  static Future<void> _prepareThread((SendPort, int) content) async {
    try {
      ThreadSingleton.changeInstance(IsolatedThreadClient(serverPort: content.$1, identifier: content.$2));
    } catch (ex) {
      log(ex.toString());
      Future.delayed(const Duration(milliseconds: 20)).whenComplete(() {
        Isolate.exit();
      });
    }
  }

  @override
  Future<Result<void>> closeThread() async {
    for (final item in _childs.toList()) {
      item.isolate.kill(priority: Isolate.immediate);
      item.communicator.dispose();
    }

    _childs.clear();

    _backgroundManager?.dispose();
    _backgroundManager = null;

    return voidResult;
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() async {
    return NegativeResult.controller(
      code: ErrorCode.implementationFailure,
      message: FixedOration(message: '[IsolatedThreadServer] This is a thread Server!'),
    );
  }

  @override
  Future<Result<IsolatedThreadConnection>> getInvocatorByID({required int identifier}) async {
    if (identifier == 0) {
      return asResultValue();
    }

    final exists = _childs.selectItem((x) => x.identifier == identifier);
    if (exists == null) {
      return NegativeResult.controller(
        code: ErrorCode.nonExistent,
        message: FixedOration(message: 'A thread with identifier %1 does not exist'),
      );
    } else {
      return exists.communicator.asResultValue();
    }
  }
}

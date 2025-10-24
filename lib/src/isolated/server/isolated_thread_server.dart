import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/main_thread_instance.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel_initiation_point.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_created.dart';
import 'package:maxi_thread/src/isolated/connections/isolated_thread_connection.dart';
import 'package:maxi_thread/src/isolated/logic/define_app_manager_in_isolator.dart';
import 'package:maxi_thread/src/isolated/logic/prepare_service.dart';
import 'package:maxi_thread/src/isolated/clients/isolated_thread_client.dart';
import 'package:maxi_thread/src/isolated/server/isolate_thread_background_manager.dart';

class IsolatedThreadServer implements ThreadInstance, IsolatedThread {
  final _childs = <IsolatedThreadCreated>[];
  final _services = <Type, ThreadInvocator>{};
  final _subClients = <IsolatedThreadConnection>[];

  IsolateThreadBackgroundManager? _backgroundManager;

  @override
  ThreadInvocator get server => const MainThreadInstance();

  @override
  ThreadInvocator get background {
    _backgroundManager ??= IsolateThreadBackgroundManager(server: this);
    return _backgroundManager!;
  }

  @override
  T? getEntityThread<T>() => null;

  @override
  Future<Result<ThreadInvocator>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) async {
    final actualInstance = _services[T];
    if (actualInstance != null) {
      if (skipIfAlreadyMounted) {
        return ResultValue(content: actualInstance);
      } else {
        return NegativeResult.controller(
          code: ErrorCode.implementationFailure,
          message: FlexibleOration(message: 'Service %1 has already been mounted', textParts: [T]),
        );
      }
    }

    if (name == null && item is ThreadService) {
      name = item.serviceName;
    } else {
      name ??= T.toString();
    }
    final threadResult = await createThread(name: name);
    if (threadResult.itsFailure) return threadResult.cast();

    final initResult = await PrepareService(service: service).inThread(threadResult.content);
    if (initResult.itsCorrect) {
      _services[T] = threadResult.content;
      threadResult.content.onDispose.whenComplete(() => _services.remove(T));
      return ResultValue(content: threadResult.content);
    } else {
      threadResult.content.closeThread();
      return initResult.cast();
    }
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
    final isolate = await Isolate.spawn(_prepareThread, point.output, debugName: name, errorsAreFatal: false);
    if (!await point.waitConfirmation()) {
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The isolator did not return his channel'),
      );
    }

    final connection = IsolatedThreadConnection(channel: point);
    final instance = IsolatedThreadCreated(isolate: isolate, communicator: connection);
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

  static Future<void> _prepareThread(SendPort point) async {
    try {
      ThreadSingleton.changeInstance(IsolatedThreadClient(point));
    } catch (ex) {
      log(ex.toString());
      Future.delayed(const Duration(milliseconds: 20)).whenComplete(() {
        Isolate.exit();
      });
    }
  }

  @override
  ThreadInvocator service<T extends Object>() {
    final item = _services[T];
    if (item == null) {
      throw NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FlexibleOration(message: 'Service %1 has not been mounted yet', textParts: [T]),
      );
    } else {
      return item;
    }
  }

  @override
  Future<Result<void>> closeThread() async {
    for (final item in _childs.toList()) {
      item.isolate.kill(priority: Isolate.immediate);
      item.communicator.dispose();
    }

    _subClients.lambda((x) => x.dispose());

    _subClients.clear();
    _childs.clear();
    _services.clear();

    _backgroundManager?.dispose();
    _backgroundManager = null;

    return voidResult;
  }

  @override
  Future<Result<SendPort>> getNewSendPortFromThread() async {
    log('[IsolatedThreadServer] This is a thread Server!');

    final point = IsolatorChannelInitiationPoint();
    final connection = IsolatedThreadConnection(channel: point);

    _subClients.add(connection);
    connection.onDispose.whenComplete(() => _subClients.remove(connection));

    return ResultValue(content: point.output);
  }
}

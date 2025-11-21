import 'dart:async';
import 'dart:io';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:rxdart/rxdart.dart';

class IsolateThreadBackgroundManager with DisposableMixin implements ThreadInvocator {
  final ThreadInstance server;

  late final int limit;

  final _semaphore = Semaphore();
  final _threadList = <ThreadInvocator>[];

  final _freeThreadList = <ThreadInvocator>[];
  final _busyTreadList = <ThreadInvocator>[];

  Completer? _finishWaiter;

  IsolateThreadBackgroundManager({required this.server}) {
    limit = Platform.numberOfProcessors;
  }

  Future<Result<ThreadInvocator>> _getThread() {
    return _semaphore.execute(() async {
      if (itWasDiscarded) {
        return CancelationResult();
      }

      if (_busyTreadList.length >= limit) {
        _finishWaiter = Completer();
        await _finishWaiter!.future;
        _finishWaiter = null;
        if (itWasDiscarded) {
          return CancelationResult();
        }
      }

      if (_freeThreadList.isNotEmpty) {
        final thread = _freeThreadList.removeLast();
        _busyTreadList.add(thread);
        return ResultValue(content: thread);
      } else {
        final newThread = await server.createThread(name: 'Background number ${_threadList.length + 1}');
        if (newThread.itsFailure) return newThread.cast();

        _threadList.add(newThread.content);
        _busyTreadList.add(newThread.content);
        return newThread;
      }
    });
  }

  @override
  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) async {
    final threadResult = await _getThread();
    if (threadResult.itsFailure) return threadResult.cast();
    final thread = threadResult.content;

    try {
      if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
        return CancelationResult();
      } else {
        return thread.execute<T>(function: function, parameters: parameters);
      }
    } finally {
      _busyTreadList.remove(thread);
      _freeThreadList.add(thread);

      _finishWaiter?.complete();
      _finishWaiter = null;
    }
  }

  @override
  Future<Result<T>> executeFunctionality<T>({required Functionality<T> functionality}) async {
    final threadResult = await _getThread();
    if (threadResult.itsFailure) return threadResult.cast();
    final thread = threadResult.content;

    try {
      if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
        return CancelationResult();
      } else {
        return thread.executeFunctionality<T>(functionality: functionality);
      }
    } finally {
      _busyTreadList.remove(thread);
      _freeThreadList.add(thread);

      _finishWaiter?.complete();
      _finishWaiter = null;
    }
  }

  @override
  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) async {
    final threadResult = await _getThread();
    if (threadResult.itsFailure) return threadResult.cast();
    final thread = threadResult.content;

    try {
      if (LifeCoordinator.tryGetZoneHeart?.itWasDiscarded == true) {
        return CancelationResult();
      } else {
        return thread.executeResult<T>(function: function, parameters: parameters);
      }
    } finally {
      _busyTreadList.remove(thread);
      _freeThreadList.add(thread);

      _finishWaiter?.complete();
      _finishWaiter = null;
    }
  }

  @override
  void performObjectDiscard() {
    if (_finishWaiter != null && !_finishWaiter!.isCompleted) {
      _finishWaiter!.complete();
    }
    _finishWaiter = null;
    _semaphore.dispose();
    _threadList.clear();
    _freeThreadList.clear();
    _busyTreadList.clear();
  }

  @override
  Stream<T> executeStream<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) async* {
    final threadResult = await _getThread();
    if (threadResult.itsFailure) throw threadResult.error;

    yield* threadResult.content.executeStream(function: function, parameters: parameters).doOnCancel(() {
      _busyTreadList.remove(threadResult.content);
      _freeThreadList.add(threadResult.content);
    });
  }
}

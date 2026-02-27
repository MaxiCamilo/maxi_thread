import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:rxdart/rxdart.dart';

extension StreamSkillConnectionExtension on ThreadConnection {
  static const _kStreamFuncNameInParameters = '%+*[Mx.sTReAm]?&&¿';
  static const _kStreamEntFuncNameInParameters = '%+*[Mx.sTReAm.E]?&&¿';

  FutureResult<Stream<T>> buildStream<T>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Stream<T>>> Function(InvocationParameters para) function}) async {
    final newChannelResult = await buildChannel<dynamic, T>(
      parameters: InvocationParameters.addParameters(namedParameters: {_kStreamFuncNameInParameters: function}, original: parameters),
      function: _buildSteamOnThread,
    );

    if (newChannelResult.itsFailure) return newChannelResult.cast();

    final channel = newChannelResult.content;
    final streamController = StreamController<T>();

    final streamResult = channel.getReceiver().onCorrectLambda((streamItem) {
      streamItem.listen(
        (x) {
          streamController.add(x);
        },
        onError: (x, y) {
          log('Channel stream emitted an error: $x, stackTrace: $y', name: 'StreamSkillExtension.buildStream -> Channel stream');
        },
        onDone: () {
          streamController.close();
          channel.dispose();
        },
      );
    });

    if (streamResult.itsFailure) {
      channel.dispose();
      return streamResult.cast();
    }

    return streamController.stream.doOnCancel(() => channel.dispose()).asResultValue();
  }

  static FutureOr<Result<void>> _buildSteamOnThread<Y, T>(Channel<Y, T> channel, InvocationParameters para) async {
    final func = para
        .named<Object>(_kStreamFuncNameInParameters)
        .dynamicCastResult<FutureOr<Result<Stream<T>>> Function(InvocationParameters)>(
          errorMessage: FlexibleOration(message: 'The parameter %1 is not of the expected type', textParts: [_kStreamFuncNameInParameters]),
        );
    if (func.itsFailure) return func.cast();

    final streamResult = await volatileFuture(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'An error occurred while building the stream'),
      ),
      function: () => func.content(para),
    );
    if (streamResult.itsFailure) return streamResult.cast();

    final waiter = Completer<void>();
    final stream = streamResult.content;

    final subscription = stream.listen(
      (x) {
        channel.sendItem(x).logIfFails(errorName: 'StreamSkillExtension._buildSteamOnThread -> Failed to send stream item to channel');
      },
      onError: (x, y) {
        log('Stream emitted an error: $x, stackTrace: $y', name: 'StreamSkillExtension._buildSteamOnThread');
      },
      onDone: () {
        if (waiter.isCompleted) return;
        waiter.complete();
      },
    );

    channel.onDispose.whenComplete(() {
      subscription.cancel();
    });

    await waiter.future;
    subscription.cancel();

    return voidResult;
  }
}

extension StreamSkillEntityConnectionExtension<T> on EntityThreadConnection<T> {
  FutureResult<Stream<R>> buildStream<R>({InvocationParameters parameters = InvocationParameters.empty, required FutureOr<Result<Stream<R>>> Function(T item, InvocationParameters para) function}) async {
    final newChannelResult = await buildChannel<dynamic, R>(
      parameters: InvocationParameters.addParameters(namedParameters: {StreamSkillConnectionExtension._kStreamEntFuncNameInParameters: function}, original: parameters),
      function: _buildSteamEntOnThread<T, dynamic, R>,
    );

    if (newChannelResult.itsFailure) return newChannelResult.cast();

    final channel = newChannelResult.content;
    final streamController = StreamController<R>();

    final streamResult = channel.getReceiver().onCorrectLambda((streamItem) {
      streamItem.listen(
        (x) {
          streamController.add(x);
        },
        onError: (x, y) {
          log('Channel stream emitted an error: $x, stackTrace: $y', name: 'StreamSkillExtension.buildStream -> Channel stream');
        },
        onDone: () {
          streamController.close();
          channel.dispose();
        },
      );
    });

    if (streamResult.itsFailure) {
      channel.dispose();
      return streamResult.cast();
    }

    return streamController.stream.doOnCancel(() => channel.dispose()).asResultValue();
  }

  static FutureResult<void> _buildSteamEntOnThread<T, Y, R>(T item, Channel<dynamic, R> channel, InvocationParameters para) async {
    final func = para
        .named<Object>(StreamSkillConnectionExtension._kStreamEntFuncNameInParameters)
        .dynamicCastResult<FutureOr<Result<Stream<R>>> Function(T item, InvocationParameters para)>(
          errorMessage: FlexibleOration(message: 'The parameter %1 is not of the expected type', textParts: [StreamSkillConnectionExtension._kStreamEntFuncNameInParameters]),
        );
    if (func.itsFailure) return func.cast();

    final streamResult = await volatileFuture(
      error: (ex, st) => ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'An error occurred while building the stream'),
      ),
      function: () => func.content(item, para),
    );
    if (streamResult.itsFailure) return streamResult.cast();

    final waiter = Completer<void>();
    final stream = streamResult.content;

    final subscription = stream.listen(
      (x) {
        channel.sendItem(x).logIfFails(errorName: 'StreamSkillEntityConnectionExtension._buildSteamEntOnThread -> Failed to send stream item to channel');
      },
      onError: (x, y) {
        log('Stream emitted an error: $x, stackTrace: $y', name: 'StreamSkillEntityConnectionExtension._buildSteamEntOnThread');
      },
      onDone: () {
        if (waiter.isCompleted) return;
        waiter.complete();
      },
    );

    channel.onDispose.whenComplete(() {
      subscription.cancel();
    });

    await waiter.future;
    subscription.cancel();

    return voidResult;
  }
}

@Timeout(Duration(minutes: 30))
library;

import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:test/test.dart';

import 'entities/first_service.dart';

void main() {
  group('Isolate test', () {
    setUp(() async {
      final appResult = await ApplicationManager.defineSingleton(DartApplicationManager());
      if (appResult.itsFailure) {
        throw appResult.error;
      }
    });

    test('Invocation Test', () async {
      final threadResult = await ThreadSingleton.createThread(name: 'Hola');
      if (threadResult.itsFailure) {
        throw threadResult.error;
      }

      final thread = threadResult.content;
      final result = await thread.execute(
        function: (para) async {
          print('Hi maxi!');
          await Future.delayed(const Duration(seconds: 5));
          print('Bye maxi!');
          return 'byebye';
        },
      );
      if (result.itsFailure) {
        throw threadResult.error;
      }

      print(result.content);

      final anotherResult = await thread.executeResult(
        function: (para) {
          print('Juajua');
          return voidResult;
        },
      );
      if (anotherResult.itsFailure) {
        throw threadResult.error;
      }

      if (thread is IsolatedThread) {
        await (thread as IsolatedThread).closeThread();
      }
      await Future.delayed(const Duration(seconds: 5));
    });

    test('Cancel function', () async {
      await managedFunction((heart) async {
        final threadResult = await ThreadSingleton.createThread(name: 'Hola');
        if (threadResult.itsFailure) {
          throw threadResult.error;
        }

        final thread = threadResult.content;
        final future = thread.execute(
          function: (para) async {
            print('Hi maxi!');
            await LifeCoordinator.zoneHeart.delay(duration: const Duration(seconds: 60));
            if (LifeCoordinator.isZoneHeartCanceled) {
              return CancelationResult();
            }
            print('Bye maxi!');
            return 'byebye';
          },
        );

        await Future.delayed(const Duration(seconds: 5)).whenComplete(() {
          heart.dispose();
        });

        final result = await future;

        print(result);
        return result;
      });

      await Future.delayed(const Duration(seconds: 10));
    });

    test('Interactive function', () async {
      final threadResult = await ThreadSingleton.createThread(name: 'Hola');
      if (threadResult.itsFailure) {
        throw threadResult.error;
      }

      final thread = threadResult.content;

      final result = await thread.executeTextable(
        onText: (item) => print('Event $item'),
        function: (para) async {
          InteractiveSystem.sendItem(FixedOration(message: 'Hi maxi!'));
          await LifeCoordinator.zoneHeart.delay(duration: const Duration(seconds: 3));
          InteractiveSystem.sendItem(FlexibleOration(message: 'let\'s wait %1 seconds', textParts: [3]));
          await LifeCoordinator.zoneHeart.delay(duration: const Duration(seconds: 3));
          InteractiveSystem.sendItem(FixedOration(message: 'Good bye!'));

          return 'byebye';
        },
      );

      print(result);

      if (thread is IsolatedThread) {
        await (thread as IsolatedThread).closeThread();
      }

      await Future.delayed(const Duration(seconds: 1));
    });

    test(
      'Mount and use service',
      () => InteractiveSystem.catchText<void>(
        onText: (item) => print('Event $item'),
        function: () async {
          final mountResult = await ThreadSingleton.createServiceThread<FirstService>(item: FirstService());
          if (mountResult.itsFailure) {
            throw mountResult.error;
          }

          final gettingResult = await ThreadSingleton.getService<FirstService>().onCorrectFuture(
            (x) => x.executeResult(parameters: InvocationParameters.only('Seba'), function: (serv, para) => serv.greet(para.firts<String>())),
          );
          print(gettingResult);

          final gettingResult2 = await ThreadSingleton.getService<FirstService>().onCorrectFuture(
            (x) => x.executeResult(parameters: InvocationParameters.only('Takara'), function: (serv, para) => serv.greet(para.firts<String>())),
          );
          print(gettingResult2);

          final externalMountResult = await ThreadSingleton.getService<FirstService>().onCorrectFuture((x) => x.executeResult(function: (serv, para) => serv.mountSecondService()));
          print(externalMountResult);

          final externalCall = await ThreadSingleton.getService<FirstService>().onCorrectFuture((x) => x.executeResult(function: (serv, para) => serv.callThirdService(5)));
          print(externalCall);

          final externalTimeout = await managedFunction(
            (_) => ThreadSingleton.getService<FirstService>().onCorrectFuture((x) => x.executeResult(function: (serv, para) => serv.callThirdService(999))).cancelIn(timeout: const Duration(seconds: 2)),
          );

          print(externalTimeout);
          await Future.delayed(Duration(seconds: 20));
        },
      ),
    );

    test(
      'Test Steams',
      () => InteractiveSystem.catchText<void>(
        onText: (item) => print('Event $item'),
        function: () async {
          final mountResult = await ThreadSingleton.createServiceThread<FirstService>(item: FirstService());
          if (mountResult.itsFailure) {
            throw mountResult.error;
          }

          final streamResult = ThreadSingleton.instance.services.getServiceInvocator<FirstService>().select((x) => x.executeStream<String>(function: (serv, para) => serv.streamText().asResultValue()));

          if (streamResult.itsFailure) throw streamResult.cast();

          final subscriptionResult = await streamResult.content.waitFinish(
            onData: (event) {
              InteractiveSystem.sendItem(FixedOration(message: event));
            },
            onError: (ex, st) => log('[ERROR!] $ex\n$st'),
            onDone: () => log('Stream closed'),
          );

          if (subscriptionResult.itsFailure) throw subscriptionResult;

          await Future.delayed(const Duration(seconds: 5));

          final anotherStreamResult = ThreadSingleton.instance.services.getServiceInvocator<FirstService>().select((x) => x.executeStream<String>(function: (serv, para) => serv.streamText().asResultValue()));
          await anotherStreamResult.content
              //.cancelIn(timeout: const Duration(seconds: 4))
              .timeout(const Duration(seconds: 4), onTimeout: (sink) => sink.close())
              .waitFinish(
                onData: (event) {
                  InteractiveSystem.sendItem(FixedOration(message: event));
                },
                onError: (ex, st) => log('[ERROR!] $ex\n$st'),
                onDone: () => log('Stream closed'),
              )
              .logIfFails(errorName: 'Another Stream');

          await Future.delayed(const Duration(seconds: 90));
        },
      ),
    );
  });
}

@Timeout(Duration(minutes: 30))
library;

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:test/test.dart';

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
              return const CancelationResult();
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
  });
}

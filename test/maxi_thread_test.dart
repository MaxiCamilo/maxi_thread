@Timeout(Duration(minutes: 30))
library;

import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:test/test.dart';

import 'entities/first_service.dart';
import 'entities/second_service.dart';
import 'entities/third_service.dart';

void main() {
  group('Isolate test', () {
    setUp(() async {});

    test('Mount isolate', () async {
      final newThreadResult = await threadSystem.createThread(name: 'First Test');
      if (newThreadResult.itsFailure) {
        fail('Failed to create thread: ${newThreadResult.error}');
      }
      final thread = newThreadResult.content;
      final result = await thread.execute(
        function: (para) {
          log('Executing function in isolate', name: 'Isolate test');
          return 'Hello from isolate';
        },
      );
      expect(result.itsCorrect, true);
      expect(result.content, 'Hello from isolate');
    });

    test('Communication between 2 client threads', () async {
      final thread1Result = await threadSystem.createThread(name: 'Thread 1');
      final thread2Result = await threadSystem.createThread(name: 'Thread 2');

      if (thread1Result.itsFailure) {
        fail('Failed to create Thread 1: ${thread1Result.error}');
      }
      if (thread2Result.itsFailure) {
        fail('Failed to create Thread 2: ${thread2Result.error}');
      }

      final result = await thread1Result.content.executeResult(
        parameters: InvocationParameters.only(thread2Result.content.identifier),
        function: (para) async {
          final thread2Id = para.first<int>();
          final thread2ConnectionResult = await threadSystem.obtainConnectionFromIdentifier(threadIdentifier: thread2Id);
          if (thread2ConnectionResult.itsFailure) {
            return thread2ConnectionResult.cast();
          }
          final thread2Connection = thread2ConnectionResult.content;
          await Future.delayed(const Duration(seconds: 5));
          return await thread2Connection.execute(
            function: (para) {
              log('Executing function in Thread 2 from Thread 1', name: 'Isolate test');
              return 'Hello from Thread 2';
            },
          );
        },
      );

      if (result.itsFailure) {
        fail('Failed to execute function in Thread 1: ${result.error}');
      }
    });

    test('Mounth service', () async {
      final newSevice = await threadSystem.createEntityThread<FirstService>(instance: FirstService());
      if (newSevice.itsFailure) {
        fail('Failed to create service thread: ${newSevice.error}');
      }

      final invocationResult = await threadSystem.service<FirstService>().executeResult(function: (serv, para) => serv.sayHi());
      if (invocationResult.itsFailure) {
        fail('Failed to invoke service function: ${invocationResult.error}');
      }
      log('Service invocation result: ${invocationResult.content}', name: 'Isolate test');
    });

    test('Interactive Service', () async {
      await threadSystem.createEntityThread<FirstService>(instance: FirstService());
      await threadSystem.createEntityThread<SecondService>(instance: SecondService());

      final creationResult = await threadSystem.service<SecondService>().executeResult(function: (serv, para) => serv.requestThirdService());
      if (creationResult.itsFailure) {
        fail('Failed to request ThirdService from SecondService: ${creationResult.error}');
      }

      final firstServerInvocationResult = await threadSystem.service<FirstService>().executeResult(function: (serv, para) => serv.sayHiFromThridService());
      if (firstServerInvocationResult.itsFailure) {
        fail('Failed to invoke sayHiFromThridService from FirstService: ${firstServerInvocationResult.error}');
      } else {
        log('FirstService sayHiFromThridService result: ${firstServerInvocationResult.content}', name: 'Isolate test');
      }
    });

    test('Test Channels', () async {
      await threadSystem.createEntityThread<FirstService>(instance: FirstService());
      await threadSystem.createEntityThread<SecondService>(instance: SecondService());
      await threadSystem.createEntityThread<ThirdService>(instance: ThirdService(name: 'Third Service from server channel'));

      final invocationResult = await threadSystem.service<FirstService>().executeResult(function: (serv, para) => serv.sayHi());
      if (invocationResult.itsFailure) {
        fail('Failed to invoke service function: ${invocationResult.error}');
      }

      final result = await threadSystem.service<SecondService>().executeResult(function: (serv, para) => serv.createChannel());
      if (result.itsFailure) {
        fail('Failed to create channel from SecondService: ${result.error}');
      }
    });
  });
}

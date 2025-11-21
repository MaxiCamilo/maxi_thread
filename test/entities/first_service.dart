import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

import 'second_service.dart';
import 'third_service.dart';

class FirstService with AsynchronouslyInitializedMixin implements ThreadService {
  @override
  String get serviceName => 'FirstService';

  @override
  Future<Result<void>> performInitialize() async {
    print('Hola maxi!');

    InteractiveSystem.sendItem(FixedOration(message: 'Hi Maxi!'));

    await LifeCoordinator.rootZoneHeart.delay(duration: const Duration(seconds: 2));

    print('Estoy pronto!');
    InteractiveSystem.sendItem(FixedOration(message: 'I am ready!'));

    return voidResult;
  }

  Result<String> greet(String name) {
    InteractiveSystem.sendItem(FixedOration(message: 'Hi $name!'));

    return 'Bye bye'.asResultValue();
  }

  Future<Result<String>> mountSecondService() async {
    InteractiveSystem.sendItem(FixedOration(message: 'Mounted Second Service'));

    final mountResult = await ThreadSingleton.createServiceThread<SecondService>(item: SecondService());
    if (mountResult.itsFailure) {
      return mountResult.cast();
    }

    return 'yeyyyyyy'.asResultValue();
  }

  Future<Result<String>> callSecondService() async {
    InteractiveSystem.sendItem(FixedOration(message: 'Let\'s call a function from the second service'));

    final result = await ThreadSingleton.getService<SecondService>().onCorrectFuture((x) => x.executeResult(function: (serv, para) => serv.callMeBaby()));
    if (result.itsFailure) return result.cast();

    InteractiveSystem.sendItem(FixedOration(message: 'Second server response!'));

    return 'Sending "${result.content}"'.asResultValue();
  }

  Future<Result<String>> callThirdService([int seconds = 5]) async {
    final thirdResult = await ThreadSingleton.getService<ThirdService>().onCorrectFuture(
      (x) => x.executeResult(parameters: InvocationParameters.only(seconds), function: (serv, para) => serv.magicNumber(para.firts<int>())),
    );
    if (thirdResult.itsFailure) return thirdResult.cast();

    return 'Magic number is: ${thirdResult.content}'.asResultValue();
  }

  Stream<String> streamText() {
    return _streamTextReserved().whenCancel(
      onCancel: () {
        log('Oh no! :(');
      },
    );
  }

  Stream<String> _streamTextReserved() async* {
    final heart = LifeCoordinator.zoneHeart;
    yield 'Hi Maxi!';
    await heart.delay(duration: const Duration(seconds: 5));
    if (heart.itWasDiscarded) {
      return;
    }
    yield 'Hi again!';
    await heart.delay(duration: const Duration(seconds: 15));
    if (heart.itWasDiscarded) {
      return;
    }

    yield 'Yipppi!';
    await heart.delay(duration: const Duration(seconds: 20));
    if (heart.itWasDiscarded) {
      return;
    }

    yield 'ByeBye!';
  }
}

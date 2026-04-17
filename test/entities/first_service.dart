import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

import 'third_service.dart';

class FirstService with DisposableMixin, InitializableMixin {
  @override
  Result<void> performInitialization() {
    log('Hi from FirstService');

    return voidResult;
  }

  Result<String> sayHi() {
    log('Another hi from FirstService');
    return 'jejejeje'.asResultValue();
  }

  FutureResult<void> interactiveHi() async {
    log('Sending hi');

    InteractiveSystem.receiveValues().select(
      (stream) => stream.listen((value) {
        log('Received: $value', name: 'FirstService Events');
      }),
    );

    await InteractiveSystem.sendValueAsync(value: 'Hi maxiiii!');

    await Future.delayed(const Duration(seconds: 30));

    await InteractiveSystem.sendValueAsync(value: 'Bye bye');

    await Future.delayed(const Duration(seconds: 40));
    return voidResult;
  }

  FutureResult<String> sayHiFromThridService() {
    return threadSystem
        .service<ThirdService>()
        .executeResult(function: (serv, para) => serv.sayHi())
        .injectLogic((_) {
          InteractiveSystem.sendValue(value: 'FirstService is saying hi through the interactive system!');
          return voidResult;
        })
        .onCorrectFuture((x) => 'Third Service got response from First Service: $x'.asResultValue());
  }

  @override
  void performObjectDiscard() {}
}

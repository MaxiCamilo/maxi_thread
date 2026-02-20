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

  FutureResult<String> sayHiFromThridService() {
    return threadSystem.service<ThirdService>().executeResult(function: (serv, para) => serv.sayHi()).onCorrectFuture((x) => 'Third Service got response from First Service: $x'.asResultValue());
  }

  @override
  void performObjectDiscard() {}
}

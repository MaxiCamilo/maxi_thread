import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

import 'third_service.dart';

class SecondService {
  FutureResult<void> requestThirdService() async {
    final servResult = await threadSystem.createEntityThread<ThirdService>(instance: ThirdService(name: 'Third Service from Second Service'));
    if (servResult.itsFailure) {
      return servResult.cast();
    }

    final callResult = await servResult.content.executeResult(function: (serv, para) => serv.sayHi());
    if (callResult.itsFailure) {
      return callResult.cast();
    }

    return voidResult;
  }

  FutureResult<void> createChannel() {
    return threadSystem
        .service<ThirdService>()
        .buildChannel(function: (serv, para) => serv.createRandomChannel())
        .injectLogic(
          (x) => x.getReceiver().onCorrectLambda(
            (y) => y.listen((data) {
              log('Received data in ThirdService channel: $data', name: 'SecondService');
            }),
          ),
        )
        .onCorrectFutureVoid((x) async => await x.onDispose);
  }
}

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
        .buildChannel<String, int>(function: (serv, channel, para) => serv.createRandomChannel(channel))
        .injectLogic(
          (x) => x.getReceiver().onCorrectLambda(
            (y) => y.listen((data) {
              log('Received data in ThirdService channel: $data', name: 'SecondService');
            }),
          ),
        )
        .injectLogic((channel) {
          Future.delayed(const Duration(seconds: 5)).whenComplete(() {
            channel.sendItem('Hello from SecondService through the channel!');
          });

          Future.delayed(const Duration(seconds: 21)).whenComplete(() {
            channel.sendItem('Hello again from SecondService through the channel!');
          });
          /*
          Future.delayed(const Duration(seconds: 30)).whenComplete(() {
            channel.sendItem('I am going to destroy you hahaha!');
            channel.dispose();
          });*/

          return voidResult;
        })
        .onCorrectFutureVoid((x) async => await x.onDispose)
        .onCorrectFutureVoid((_) => log('Channel was disposed', name: 'SecondService'))
        .onCorrectFutureVoid((x) => Future.delayed(const Duration(seconds: 5)).whenComplete(() => log('Finished waiting after channel disposal', name: 'SecondService')))
        .onCorrectFutureVoid((_) async {
          await threadSystem
              .service<ThirdService>()
              .executeResult(
                function: (serv, para) {
                  return serv.sayHi();
                },
              )
              .logIfFails(errorName: 'Failed to execute sayHi in ThirdService after channel disposal')
              .onCorrectFutureVoid((x) => log('Successfully executed sayHi in ThirdService after channel disposal, result: $x', name: 'SecondService'));
        });
  }
}

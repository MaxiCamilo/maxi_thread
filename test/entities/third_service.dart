import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class ThirdService {
  final String name;

  ThirdService({required this.name});

  Result<String> sayHi() {
    return 'Hola Hola desde el tercer hilo, en español obvio'.asResultValue();
  }

  Future<Result<void>> createRandomChannel(Channel<String, int> channel) async {
    channel.onDispose.whenComplete(() => log('Channel was disposed, stopping channel logic', name: 'ThirdService')).ignore();
    channel
        .getReceiver()
        .onCorrectLambda(
          (x) => x.listen((text) {
            log('Client sent: $text', name: 'ThirdService');
          }),
        )
        .logIfFails(errorName: 'ThirdService -> createRandomChannel: Failed to listen to channel receiver');

    await Future.delayed(const Duration(seconds: 10));
    log('Starting to send data through the channel', name: 'ThirdService');
    channel.sendItem(0);

    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(seconds: 1));
      channel.sendItem(i);
    }


    return voidResult;
  }
}

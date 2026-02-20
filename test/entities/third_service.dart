import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';

class ThirdService {
  final String name;

  ThirdService({required this.name});

  Result<String> sayHi() {
    return 'Hola Hola desde el tercer hilo, en español obvio'.asResultValue();
  }

  Result<Channel<int, String>> createRandomChannel() {
    final channel = MasterChannel<String, int>();
    scheduleMicrotask(() async {
      await Future.delayed(const Duration(seconds: 10));
      log('Starting to send data through the channel', name: 'ThirdService');
      channel
          .getReceiver()
          .onCorrectLambda(
            (x) => x.listen((text) {
              log('Client sent: $text', name: 'ThirdService');
            }),
          )
          .logIfFails(errorName: 'ThirdService -> createRandomChannel: Failed to listen to channel receiver');
      channel.sendItem(0);

      for (int i = 1; i <= 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        channel.sendItem(i);
      }

      channel.dispose();
    });

    return channel.buildConnector();
  }
}

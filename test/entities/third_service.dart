import 'dart:math';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class ThirdService implements ThreadService {
  @override
  String get serviceName => 'Third Service';

  const ThirdService();

  Future<Result<int>> magicNumber([int seconds = 5]) async {
    InteractiveSystem.sendItem(FixedOration(message: 'Your magic number is...'));

    await LifeCoordinator.zoneHeart.delay(duration: Duration(seconds: seconds))/*.makeCancelable(timeout: const Duration(seconds: 5))*/;

    if (LifeCoordinator.isZoneHeartCanceled) {
      return CancelationResult();
    }

    return ResultValue(content: Random().nextInt(99));
  }
}

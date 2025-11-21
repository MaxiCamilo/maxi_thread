import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

import 'third_service.dart';

class SecondService with AsynchronouslyInitializedMixin implements ThreadService {
  @override
  String get serviceName => 'Second Service';

  @override
  Future<Result<void>> performInitialize() async {
    print('Initializing Second Service...');

    InteractiveSystem.sendItem(FixedOration(message: 'Second Service is starting!'));

    await LifeCoordinator.rootZoneHeart.delay(duration: const Duration(seconds: 1));

    print('Second Service is ready!');
    InteractiveSystem.sendItem(FixedOration(message: 'Second Service is ready!'));

    final thirdServiceResult = await ThreadSingleton.createServiceThread(item: ThirdService());
    if (thirdServiceResult.itsFailure) return thirdServiceResult.cast();

    return voidResult;
  }

  Result<String> callMeBaby() {
    InteractiveSystem.sendItem(FixedOration(message: 'Hi beuty!'));
    return '😘'.asResultValue();
  }
}

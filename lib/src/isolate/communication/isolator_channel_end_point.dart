import 'dart:async';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel.dart';

/// The `IsolatorChannelEndPoint` class is an implementation of the `IsolatorChannel` interface that serves as an endpoint for communication between threads in a multi-threaded application. This class utilizes Dart's `SendPort` and `ReceivePort` to facilitate message passing between threads, allowing for effective communication and coordination in a multi-threaded environment. The class manages the lifecycle of the communication channel, ensuring that resources are properly cleaned up when the channel is no longer needed. It provides methods for sending messages to the connected thread and handling incoming messages through a stream, allowing for flexible and efficient communication between threads. The `IsolatorChannelEndPoint` class is a crucial component in managing communication between threads, enabling concurrent processing and efficient resource management in an isolated environment. This implementation ensures that messages are sent and received reliably while providing mechanisms for handling potential errors and ensuring that resources are properly cleaned up when the channel is no longer needed, facilitating effective communication between threads in a multi-threaded application. The `IsolatorChannelEndPoint` class is designed to handle the complexities of thread communication and resource management, ensuring that messages are sent and received reliably while providing mechanisms for handling potential errors and ensuring that resources are properly cleaned up when the channel is no longer needed. Overall, the `IsolatorChannelEndPoint` class serves as a critical component in managing communication between threads, allowing for effective synchronization and resource management in a multi-threaded application, facilitating concurrent processing and efficient handling of resources in an isolated environment.
class IsolatorChannelEndPoint with DisposableMixin implements IsolatorChannel {
  final SendPort sendPoint;

  late final ReceivePort receivePoint;

  late final StreamController _streamController;

  @override
  Stream get stream => _streamController.stream;

  IsolatorChannelEndPoint({required this.sendPoint}) {
    _streamController = StreamController.broadcast();
    receivePoint = ReceivePort();
    receivePoint.listen(_processDataReceived, onDone: dispose);

    sendPoint.send(receivePoint.sendPort);
  }

  @override
  void performObjectDiscard() {
    receivePoint.close();
    _streamController.close();
  }

  void _processDataReceived(dynamic message) {
    _streamController.add(message);
  }

  @override
  Result<void> send(dynamic item) {
    try {
      sendPoint.send(item);
      return voidResult;
    } catch (ex, st) {
      /// An exception may be thrown if the object being sent is not fully serializable or has native attributes, which is incompatible with inter-thread communication in Dart. The exception is caught and an error result with details about the problem is returned, enabling effective error handling and clear communication about issues that may arise when sending messages through the channel. This error handling ensures that serialization-related problems are communicated clearly, allowing developers to identify and resolve inter-thread communication issues effectively.
      return ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'An error occurred while trying to send an object from one thread to another, verify that it does not have native attributes'),
      );
    }
  }

  @override
  Future<Result<void>> waitInitialization({required Duration timeout}) async {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: FixedOration(message: 'The channel was already closed'),
      );
    }

    return voidResult;
  }
}

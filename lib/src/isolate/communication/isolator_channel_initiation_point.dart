import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/communication/isolator_channel.dart';

/// The `IsolatorChannelInitiationPoint` class is an implementation of the `IsolatorChannel` interface that serves as the initiation point for communication between threads in a multi-threaded application. This class utilizes a `ReceivePort` to listen for incoming messages and a `StreamController` to manage the stream of messages received. It also includes a mechanism for waiting for the initialization of the channel, allowing for effective synchronization between threads during the setup process. The class provides methods for sending messages to the connected thread and handling the disposal of resources when the channel is no longer needed. This implementation ensures that communication between threads can be established reliably and that resources are managed effectively in a multi-threaded environment, allowing for concurrent processing and efficient resource management in an isolated environment. The `IsolatorChannelInitiationPoint` class is a crucial component in facilitating communication between threads, allowing for effective synchronization and management of resources in a multi-threaded application. It provides a foundation for building communication channels that can be used to facilitate communication between threads, allowing for concurrent processing and efficient resource management in a multi-threaded environment. This class is designed to handle the complexities of thread communication and resource management, ensuring that messages are sent and received reliably while providing mechanisms for handling potential errors and ensuring that resources are properly cleaned up when the channel is no longer needed. Overall, the `IsolatorChannelInitiationPoint` class serves as a critical component in managing communication between threads, allowing for effective synchronization and resource management in a multi-threaded application, facilitating concurrent processing and efficient handling of resources in an isolated environment.
class IsolatorChannelInitiationPoint with DisposableMixin implements IsolatorChannel {
  late final ReceivePort receivePort;

  SendPort? _sender;

  SendPort get output => receivePort.sendPort;

  late final StreamController _streamController;

  @override
  Stream get stream => _streamController.stream;

  Completer<bool>? _confirmationWaiter;

  IsolatorChannelInitiationPoint() {
    receivePort = ReceivePort();
    receivePort.listen(_processDataReceived, onDone: dispose);

    _streamController = StreamController.broadcast();
  }

  @override
  /// Disposes of the channel by closing the receive port, stream controller, and completing any pending confirmation waiters. This ensures that all resources associated with the channel are properly cleaned up when the channel is discarded, preventing memory leaks and ensuring that ongoing communication is appropriately terminated in response to the disposal of the channel.
  void performObjectDiscard() {
    receivePort.close();
    _streamController.close();
    _confirmationWaiter?.complete(false);
    _confirmationWaiter = null;
  }

  @override
  /// Waits for the initialization of the channel by checking if the sender has been set. If the sender is already set, it returns a void result indicating that the channel is initialized. If the sender is not set, it creates a completer to wait for confirmation of initialization and returns a future that completes when the confirmation is received or when a timeout occurs. This method allows for effective synchronization between threads during the setup process, ensuring that communication can occur reliably once the channel is initialized while handling potential errors and ensuring that operations are not performed on an uninitialized channel.
  Future<Result<void>> waitInitialization({required Duration timeout}) async {
    if (itWasDiscarded) {
      return NegativeResult.controller(
        code: ErrorCode.discontinuedFunctionality,
        message: FixedOration(message: 'The channel was already closed'),
      );
    }

    if (_sender != null) return voidResult;

    _confirmationWaiter ??= Completer<bool>();
    return _confirmationWaiter!.future
        .toFutureResult()
        .timeout(
          timeout,
          onTimeout: () => NegativeResult.controller(
            code: ErrorCode.timeout,
            message: FixedOration(message: 'The channel initialization has timed out'),
          ),
        )
        .onCorrectFuture((confirmed) {
          if (confirmed) {
            return voidResult;
          } else {
            return NegativeResult.controller(
              code: ErrorCode.timeout,
              message: FixedOration(message: 'Could not initialize thread channel'),
            );
          }
        });
  }

  /// Waits for confirmation of the initialization of the channel by checking if the sender has been set. If the sender is already set, it returns true indicating that the channel is initialized. If the sender is not set, it creates a completer to wait for confirmation of initialization and returns a future that completes when the confirmation is received. This method allows for effective synchronization between threads during the setup process, ensuring that communication can occur reliably once the channel is initialized while handling potential errors and ensuring that operations are not performed on an uninitialized channel. If the channel is discarded while waiting for confirmation, it returns false, allowing for effective handling of cases where the channel may be closed before initialization is complete. This method is crucial for ensuring that communication between threads can be established reliably while providing mechanisms for handling potential errors and ensuring that operations are not performed on an uninitialized or discarded channel.
  Future<bool> waitConfirmation() async {
    if (itWasDiscarded) return false;
    if (_sender != null) return true;

    _confirmationWaiter ??= Completer<bool>();
    return _confirmationWaiter!.future;
  }

  /// A private method that processes incoming messages received through the receive port. If the sender has not yet been set, it checks if the message is a `SendPort` and sets it as the sender, completing any pending confirmation waiters. If the sender is already set, it adds the received message to the stream controller for further processing. This method ensures that messages are handled appropriately based on the state of the channel, allowing for effective communication between threads while managing potential errors and ensuring that operations are not performed on an uninitialized or discarded channel. It provides a mechanism for handling incoming messages and managing the state of the channel effectively, ensuring that communication can occur reliably while providing mechanisms for handling potential errors and ensuring that resources are properly cleaned up when the channel is no longer needed.
  void _processDataReceived(dynamic message) {
    if (_sender == null) {
      if (message is SendPort) {
        _sender = message;
        _confirmationWaiter?.complete(true);
        _confirmationWaiter = null;
      } else {
        log('[IsolatorChannelInitiationPoint] The thread has not yet sent its SendPort!');
      }

      return;
    }

    if (_streamController.isClosed) {
      log('[IsolatorChannelInitiationPoint] This point is closed!');
    } else {
      _streamController.add(message);
    }
  }

  @override
  /// Sends a message through the channel by using the sender's send method. If the sender has not yet been set, it logs a message indicating that the sender is not available and returns a negative result. If the sender is available, it attempts to send the message and returns a void result if successful. If an error occurs during the sending process, it catches the exception and returns an exception result with details about the error, allowing for effective error handling and communication about issues that may arise when attempting to send messages through the channel. This method ensures that messages are sent reliably while providing mechanisms for handling potential errors and ensuring that operations are not performed on an uninitialized or discarded channel. It allows for effective communication between threads while managing potential errors and ensuring that resources are properly cleaned up when the channel is no longer needed.
  Result<void> send(dynamic item) {
    if (_sender == null) {
      log('[IsolatorChannelInitiationPoint] The thread has not yet sent its SendPort!');
      return NegativeResult.controller(
        code: ErrorCode.implementationFailure,
        message: FixedOration(message: 'The thread has not yet sent its SendPort'),
      );
    }

    try {
      _sender!.send(item);
      return voidResult;
    } catch (ex, st) {
      /// An exception may be thrown if the object being sent is not fully serializable or has native attributes, which is incompatible with inter-thread communication in Dart. The exception is caught and an error result with details about the problem is returned, enabling effective error handling and clear communication about issues that may arise when sending messages through the channel. This error handling ensures that serialization-related problems are communicated clearly, allowing developers to identify and resolve inter-thread communication issues effectively.
      return ExceptionResult(
        exception: ex,
        stackTrace: st,
        message: const FixedOration(message: 'An error occurred while sending an object between threads. Verify that it does not have native attributes'),
      );
    }
  }
}

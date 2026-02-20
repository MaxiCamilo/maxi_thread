import 'package:maxi_framework/maxi_framework.dart';

/// An interface that defines the contract for an isolator channel, which is responsible for facilitating communication between threads in a multi-threaded application. This interface includes a stream for receiving messages, a method for sending messages, and a method for waiting for the initialization of the channel. Implementations of this interface are expected to provide mechanisms for sending and receiving messages between threads, as well as handling the initialization process to ensure that communication can occur effectively between threads in a multi-threaded environment. The `IsolatorChannel` interface serves as a crucial component in managing communication between threads, allowing for concurrent processing and efficient resource management in an isolated environment. Implementations of this interface should ensure that messages are sent and received reliably, and that the initialization process is handled appropriately to facilitate effective communication between threads in a multi-threaded application. This interface provides a foundation for building communication channels that can be used to facilitate communication between threads, allowing for concurrent processing and efficient resource management in a multi-threaded environment.
abstract interface class IsolatorChannel implements Disposable {
  Stream get stream;
  Result<void> send(dynamic item);

  Future<Result<void>> waitInitialization({required Duration timeout});
}

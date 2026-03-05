# maxi_thread Architecture Guide

## Overview

**maxi_thread** implements a sophisticated multi-threading abstraction that adapts to different Dart runtime environments. This document describes the internal architecture, design decisions, and implementation details.

## Design Principles

1. **Platform Abstraction**: Single API for native and web platforms
2. **Safety**: Result-based error handling prevents uncaught exceptions
3. **Simplicity**: Intuitive API for common threading patterns
4. **Performance**: Minimal overhead over native isolates/async operations
5. **Composability**: Functions and services can be nested and combined

## Architecture Layers

```
┌─────────────────────────────────────┐
│  Application Code                    │
│  (Uses threadSystem, ThreadConnection)|
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│  Public API Layer                    │
│  - ThreadManager interface           │
│  - ThreadConnection interface        │
│  - EntityThreadConnection interface  │
│  - SharedEvent, Channel              │
└─────────────────┬───────────────────┘
                  │
┌─────────────────▼───────────────────┐
│  Factory Layer (Conditional Import) │
│  - Platform detection & selection    │
│  - Appropriate implementation choice  │
└─────────────────┬───────────────────┘
         ┌────────┴────────┐
         │                 │
┌────────▼────────┐  ┌─────▼──────────┐
│ Native Factory  │  │  Web Factory    │
│ (dart.library  │  │  (dart.library  │
│  !html)        │  │   html)        │
└────────┬────────┘  └─────┬──────────┘
         │                 │
┌────────▼────────┐  ┌─────▼──────────┐
│ Isolate Module  │  │  Fake Module    │
│ - Isolate impl. │  │ - Async-based   │
│ - Channels      │  │ - Event loops   │
│ - Communication │  │ - Simulation    │
└────────────────┘  └────────────────┘
```

## Platform-Specific Implementations

### Native Platforms (Android, iOS, Desktop)

**Use Case**: True parallel execution, CPU-intensive tasks

**Implementation**: `isolate/` module

Key components:
- `IsolatedThread`: Wraps a Dart Isolate
- `IsolateThreadConnection`: Communication bridge with isolate
- `IsolateChannel`: Channel implementation using SendPorts
- `IsolateThreadManager`: Manages multiple isolates

**Communication Flow**:
```
Main Isolate
    │
    ├─→ SendPort (to isolate)
    │        │
    │        ▼
    │    Worker Isolate
    │        │
    │        ├─→ SendPort (to main)
    │        │
    │        ◀───────────
    │
    ├─ Receives response
    │
```

**Advantages**:
- True parallelism
- Isolated memory spaces
- No shared state (prevents race conditions)
- Full CPU utilization

**Limitations**:
- Higher overhead per thread
- Only JSON-serializable data can cross bounds
- More complex debugging

### Web Platform

**Use Case**: Web browsers, where true multithreading is unavailable

**Implementation**: `fake/` module

Key components:
- `FakeThread`: Simulates a thread using async/await
- `FakeThreadConnection`: Manages execution queues
- `FakeChannel`: Queue-based message passing
- `FakeThreadManager`: Coordinates fake threads

**Simulation Strategy**:
```
Event Queue
    ├─ Task 1 (execute async)
    ├─ Await completion
    ├─ Task 2 (execute async)
    ├─ Await completion
    └─ ...

Single-threaded JavaScript runtime
    │
    ▼
Process tasks sequentially to simulate concurrency
```

**Advantages**:
- Works on the web
- Maintains API compatibility
- Graceful degradation

**Limitations**:
- No true parallelism
- Still single-threaded
- Useful for organization rather than performance

### Conditional Compilation

The implementation uses Dart's conditional imports:

```dart
import 'factories/native_thread_factory.dart' 
    if (dart.library.html) 'factories/fake_thread_factory.dart';
```

- **Native**: Imports `native_thread_factory.dart` (builds to native binary)
- **Web**: Imports `fake_thread_factory.dart` (builds to web JavaScript)

## Core Interfaces

### ThreadManager

```dart
abstract interface class ThreadManager implements Disposable {
  int get identifier;
  String get name;
  ThreadConnection get serverConnection;
  
  EntityThreadConnection<T> service<T>();
  FutureResult<ThreadConnection> createThread({
    required String name,
    List<Functionality> initializers,
  });
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({
    required T instance,
    bool omitIfExists,
  });
  
  Result<T> getThreadEntity<T>();
  Result<T> obtainThreadObject<T extends Object>({required String name});
  Result<void> defineThreadObject<T extends Object>({
    required String name,
    required T object,
    bool removePrevious,
  });
}
```

**Responsibilities**:
- Lifecycle management of threads
- Thread-local object storage
- Service registration and access
- Identity and naming

### ThreadConnection

```dart
abstract interface class ThreadConnection implements Disposable {
  int get identifier;
  String get name;
  
  Future<Result<T>> execute<T>({
    InvocationParameters parameters,
    required FutureOr<T> Function(InvocationParameters para) function,
  });
  
  Future<Result<T>> executeResult<T>({
    InvocationParameters parameters,
    required FutureOr<Result<T>> Function(InvocationParameters para) function,
  });
  
  FutureResult<Channel<S, R>> buildChannel<R, S>({
    InvocationParameters parameters,
    required FutureOr<Result<void>> Function(Channel<R, S> channel, InvocationParameters para) function,
  });
  
  FutureResult<void> requestClosure();
}
```

**Responsibilities**:
- Execute functions in thread context
- Pass parameters safely
- Enable bidirectional communication
- Manage thread lifecycle

### Channel<S, R>

```dart
abstract interface class Channel<S, R> implements Disposable {
  Result<Stream<R>> getReceiver();
  Result<void> sendItem(S item);
}
```

**Responsibilities**:
- Provide stream for receiving messages
- Support sending messages
- Handle backpressure gracefully
- Proper resource cleanup

## Execution Models

### Model 1: Simple Execute

```dart
connection.execute<String>(
  function: (params) async => "Hello"
);
```

Flow:
1. Function serialized
2. Sent to thread
3. Executed in thread context
4. Result serialized and returned
5. Deserialized in caller context

### Model 2: Result-Based Execute

```dart
connection.executeResult<String>(
  function: (params) async => ResultValue(content: "Hello")
);
```

Flow:
1. Function needs to return `Result<T>`
2. Errors handled within Result
3. Success or Failure returned consistently
4. Type-safe error propagation

### Model 3: Channel Communication

```dart
connection.buildChannel<Response, Request>(
  function: (channel, params) async {
    channel.getReceiver().listen((request) {
      channel.sendItem(Response(data: process(request)));
    });
  }
);
```

Flow:
1. Channel created in thread
2. Setup function runs in thread
3. Channel exposed to caller
4. Bidirectional messaging established
5. Channel persists until disposal

### Model 4: Entity Threading (Service-Based)

```dart
createEntityThread<MyService>(instance: serviceInstance);
```

Flow:
1. Service instance created in caller thread
2. Moved to new thread (serialized)
3. Connection provides access to service
4. Methods invoked in service's thread
5. Results returned to caller

## Shared Resources

### SharedEvent

Enables cross-thread event broadcasting:

```dart
final event = SharedEvent<UserLogin>(name: 'auth_events');
await event.initialize();

// Producer thread
event.sendItem(UserLogin(userId: 123));

// Consumer thread
event.getReceiver().listen((login) => updateUI(login));
```

**Implementation Details**:
- Uses underlying thread connection
- Channels for message delivery
- Async initialization required
- Multiple listeners supported

### Object Storage

Thread-local object storage pattern:

```dart
// In main thread
manager.defineThreadObject(
  name: 'database',
  object: database,
);

// In worker thread
final db = manager.obtainThreadObject<Database>(name: 'database').content;
```

**Benefits**:
- Avoid serialization overhead
- Singleton-like access pattern
- Thread-safe by design
- Lazy initialization possible

## Error Handling

All operations use the Result pattern:

```dart
Result<T> // Success or Failure
  ├─ ResultValue<T>     // Success case
  │   └─ content: T
  └─ ResultError        // Failure case
      ├─ exception
      ├─ stackTrace
      └─ message
```

**Usage**:

```dart
final result = await connection.execute<int>(function: myFunc);

if (result.itsSuccess) {
  print(result.content);
} else {
  print('Error: ${result.exception}');
  print('Stack: ${result.stackTrace}');
}
```

## Zone-Based Context

Uses Dart's Zone for thread context storage:

```dart
class ThreadManager {
  static const kThreadManagerZone = #maxiThreadManager;
  
  static ThreadManager get threadZone => 
    Zone.current[kThreadManagerZone]! as ThreadManager;
}
```

**Benefits**:
- Access to thread manager within execution
- Hierarchical context inheritance
- Exception zone handling
- Runnable error zones

## Memory Management

### Resource Lifecycle

1. **Creation**: Thread created with memory allocation
2. **Usage**: Objects stored in thread-local zones
3. **Disposal**: Resources released, isolate terminated

### Disposal Pattern

```dart
// Implement Disposable interface
class ThreadImpl implements ThreadConnection {
  @override
  void dispose() {
    // Cleanup resources
    // Terminate isolate if native
    // Clear queues if fake
    // Release memory
  }
}
```

## Performance Considerations

### Native Implementation

- Isolate creation overhead: ~50-100ms initially
- Message serialization cost: Depends on data size
- Best for: CPU-intensive, long-running tasks
- Avoids: Frequent thread creation/destruction

### Web Implementation

- No thread creation overhead
- Simulated concurrency via event loop
- Better for: Organization, not performance
- Avoids: Complex synchronization

### Optimization Tips

1. **Reuse Threads**: Create once, use multiple times
2. **Minimize Serialization**: Pass IDs/references when possible
3. **Batch Operations**: Group multiple operations
4. **Entity Threading**: Use for service instances
5. **Channels over Methods**: Better for frequent communication

## Testing Strategy

### Unit Tests

```dart
test('Thread execution returns correct result', () async {
  final result = await connection.execute<int>(
    function: (_) async => 42,
  );
  
  expect(result.itsSuccess, isTrue);
  expect(result.content, equals(42));
});
```

### Platform-Specific Tests

- Isolate-specific: Serialization, isolated memory
- Fake-specific: Queue ordering, event sequencing

### Integration Tests

- Multi-thread coordination
- SharedEvent functionality
- Object storage reliability

## Debugging

### Enable Logging

```dart
// Framework logging (maxi_framework)
maxi_framework.enableLogging();
```

### Common Issues

1. **SendPort Issues**: Ensure data is JSON-serializable
2. **Memory Leaks**: Always dispose threads/channels
3. **Deadlocks**: Avoid circular waits between threads
4. **Zone Access**: Only access manager within thread zone

## Future Enhancements

Potential improvements:
- Thread pooling for efficiency
- Priority queue for execution ordering
- Cancellation tokens for task cancellation
- Thread-local caches for performance
- Monitoring and profiling APIs
- Worker pool management

## Internal Communication Protocol

### Isolate Message Format

```dart
{
  'command': 'execute',
  'function': encodedFunction,
  'parameters': parameters,
  'callId': uniqueId,
}
```

Response:

```dart
{
  'callId': uniqueId,
  'success': true,
  'result': result,
}
```

## Conclusion

**maxi_thread** provides a robust abstraction over platform-specific threading capabilities, allowing developers to write portable concurrent code for Dart and Flutter applications. The architecture balances simplicity, performance, and platform compatibility through thoughtful design patterns and conditional compilation strategies.

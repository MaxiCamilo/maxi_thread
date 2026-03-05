# maxi_thread - Getting Started Guide

## Installation

### For Dart Projects

```bash
cd your_dart_project
dart pub add maxi_thread
```

### For Flutter Projects

```bash
cd your_flutter_project
flutter pub add maxi_thread
```

## Basic Examples

### Example 1: Heavy Computation in Background Thread

Move CPU-intensive work off the main thread to avoid UI freezing.

```dart
import 'package:maxi_thread/maxi_thread.dart';

Future<void> computeExpensive() async {
  // Create a background thread
  final threadResult = await threadSystem.createThread(
    name: 'compute_fibonacci',
  );
  
  if (threadResult.itsFailure) {
    print('Failed to create thread: ${threadResult.exception}');
    return;
  }
  
  final connection = threadResult.content;
  
  // Execute expensive computation in the thread
  final result = await connection.execute<int>(
    parameters: InvocationParameters.from({'n': 30}),
    function: (params) async {
      final n = params.first<int>();
      return fibonacci(n); // Heavy computation
    },
  );
  
  if (result.itsSuccess) {
    print('Fibonacci(30) = ${result.content}');
  }
  
  // Clean up
  await connection.requestClosure();
}

int fibonacci(int n) {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2);
}
```

**Use Cases**:
- Image processing
- JSON parsing of large data
- Mathematical calculations
- Data transformations

---

### Example 2: Service-Based Thread (Entity Threading)

Create thread-specific service instances for stateful operations.

```dart
import 'package:maxi_thread/maxi_thread.dart';

class DatabaseService {
  final String connectionString;
  
  DatabaseService(this.connectionString);
  
  Future<List<User>> fetchUsers() async {
    // Simulate database query
    await Future.delayed(Duration(milliseconds: 500));
    return [
      User(id: 1, name: 'Alice'),
      User(id: 2, name: 'Bob'),
    ];
  }
  
  Future<bool> saveUser(User user) async {
    // Simulate database save
    await Future.delayed(Duration(milliseconds: 300));
    return true;
  }
}

class User {
  final int id;
  final String name;
  User({required this.id, required this.name});
}

void main() async {
  // Create a database service instance
  final dbService = DatabaseService('localhost:5432');
  
  // Create an entity thread with the service
  final entityResult = await threadSystem.createEntityThread(
    instance: dbService,
  );
  
  if (entityResult.itsSuccess) {
    final dbConnection = entityResult.content;
    
    // Use the service - methods execute in the thread
    // The service instance remains in the thread's context
    print('Entity thread created for DatabaseService');
  }
}
```

**Advantages**:
- Service instance lives in isolated thread
- No serialization overhead for service
- Thread-safe by design
- Persistent service state

---

### Example 3: Bidirectional Communication with Channels

Establish ongoing two-way communication between threads.

```dart
import 'package:maxi_thread/maxi_thread.dart';

class RequestData {
  final String query;
  RequestData(this.query);
}

class ResponseData {
  final String result;
  ResponseData(this.result);
}

Future<void> setupChannelCommunication() async {
  // Create thread
  final threadResult = await threadSystem.createThread(
    name: 'request_handler',
  );
  
  if (threadResult.itsFailure) return;
  
  final connection = threadResult.content;
  
  // Build a channel for request-response communication
  final channelResult = await connection.buildChannel<ResponseData, RequestData>(
    function: (channel, parameters) async {
      // Setup receiving in the worker thread
      final receiverResult = channel.getReceiver();
      
      if (receiverResult.itsSuccess) {
        receiverResult.content.listen((request) {
          // Process request in thread context
          final result = processRequest(request.query);
          
          // Send response back
          final sendResult = channel.sendItem(
            ResponseData(result),
          );
          
          if (sendResult.itsFailure) {
            print('Failed to send response: ${sendResult.exception}');
          }
        });
      }
    },
  );
  
  if (channelResult.itsFailure) return;
  
  final channel = channelResult.content;
  
  // Send requests from main thread
  for (int i = 0; i < 5; i++) {
    channel.sendItem(RequestData('query_$i'));
  }
}

String processRequest(String query) {
  // Simulate processing
  return 'Result for: $query';
}
```

**Use Cases**:
- Request-response handlers
- Event streaming
- Command processing
- Interactive services

---

### Example 4: Thread-Local Object Storage

Store and access objects within thread contexts.

```dart
import 'package:maxi_thread/maxi_thread.dart';

class AppConfig {
  final String appName = 'MyApp';
  final String version = '1.0.0';
  final Map<String, String> settings = {
    'theme': 'dark',
    'language': 'en',
  };
}

Future<void> threadLocalStorageExample() async {
  // Define a thread-local object in main thread
  final config = AppConfig();
  threadSystem.defineThreadObject(
    name: 'app_config',
    object: config,
  );
  
  // Create a worker thread
  final threadResult = await threadSystem.createThread(
    name: 'config_reader',
  );
  
  if (threadResult.itsSuccess) {
    final connection = threadResult.content;
    
    // Execute code that accesses the thread-local object
    final result = await connection.execute<String>(
      function: (params) async {
        // Inside the thread, we can store thread-specific objects
        final workerConfig = AppConfig();
        workerConfig.settings['format'] = 'json';
        
        // Store in the worker thread
        // This would need ThreadManager access from within the thread
        return 'Worker thread ready';
      },
    );
  }
}

// More practical: define objects before creating threads
Future<void> betterThreadLocalExample() async {
  // Create thread
  final threadResult = await threadSystem.createThread(
    name: 'worker',
  );
  
  if (threadResult.itsSuccess) {
    final connection = threadResult.content;
    
    // Execute initialization in the thread
    await connection.execute<void>(
      parameters: InvocationParameters.from({
        'appName': 'MyApp',
        'theme': 'dark',
      }),
      function: (params) async {
        final appName = params.first<String>();
        final theme = params.second<String>();
        
        print('Worker initialized: $appName with theme $theme');
      },
    );
  }
}
```

**Use Cases**:
- Configuration sharing
- Resource pooling
- Singleton patterns
- Global state management

---

### Example 5: Multiple Threads with Coordination

Manage multiple threads working together.

```dart
import 'package:maxi_thread/maxi_thread.dart';

Future<void> multiThreadExample() async {
  // Create a pool of worker threads
  final workers = <ThreadConnection>[];
  
  for (int i = 0; i < 3; i++) {
    final result = await threadSystem.createThread(
      name: 'worker_$i',
    );
    
    if (result.itsSuccess) {
      workers.add(result.content);
    }
  }
  
  // Distribute work across threads
  final futures = <Future>[];
  
  for (int i = 0; i < workers.length; i++) {
    final future = workers[i].execute<int>(
      parameters: InvocationParameters.from({'taskId': i}),
      function: (params) async {
        final taskId = params.first<int>();
        // Simulate work
        await Future.delayed(Duration(milliseconds: 100));
        return taskId * 10;
      },
    );
    
    futures.add(future);
  }
  
  // Wait for all to complete
  final results = await Future.wait(futures);
  
  print('Results: ${results.map((r) => r.content).toList()}');
  
  // Cleanup
  for (final worker in workers) {
    await worker.requestClosure();
  }
}
```

**Pattern**: Thread Pool
- Create reusable worker threads
- Distribute tasks across workers
- Collect results
- Reuse threads for multiple batches

---

### Example 6: Error Handling and Recovery

Properly handle errors in threaded operations.

```dart
import 'package:maxi_thread/maxi_thread.dart';

Future<void> errorHandlingExample() async {
  final threadResult = await threadSystem.createThread(
    name: 'risky_thread',
  );
  
  if (threadResult.itsFailure) {
    print('Failed to create thread: ${threadResult.exception}');
    return;
  }
  
  final connection = threadResult.content;
  
  // Execute operation that might fail
  final result = await connection.executeResult<String>(
    function: (params) async {
      try {
        // Risky operation
        final data = parseJSON('invalid json');
        return ResultValue(content: data);
      } catch (e, stackTrace) {
        return ResultError(
          exception: e,
          stackTrace: stackTrace,
          message: 'Failed to parse JSON',
        );
      }
    },
  );
  
  // Handle result
  if (result.itsSuccess) {
    print('Success: ${result.content}');
  } else {
    print('Error: ${result.exception}');
    print('Message: ${result.message}');
    print('Stack: ${result.stackTrace}');
  }
  
  await connection.requestClosure();
}

String parseJSON(String json) {
  if (json == 'invalid json') {
    throw FormatException('Invalid JSON format');
  }
  return json;
}
```

**Best Practices**:
- Always check `itsSuccess` or `itsFailure`
- Log exceptions for debugging
- Handle stack traces appropriately
- Implement retry logic if needed
- Gracefully degrade functionality

---

### Example 7: Shared Events for Cross-Thread Broadcasting

Broadcast events to multiple listeners across threads.

```dart
import 'package:maxi_thread/maxi_thread.dart';

class UserLoginEvent {
  final int userId;
  final String userName;
  UserLoginEvent({required this.userId, required this.userName});
}

Future<void> sharedEventExample() async {
  // Create a shared event
  final loginEvent = SharedEvent<UserLoginEvent>(name: 'user_login');
  
  // Initialize it (connects to the thread system)
  final initResult = await loginEvent.initialize();
  if (initResult.itsFailure) {
    print('Failed to initialize event: ${initResult.exception}');
    return;
  }
  
  // Create listener thread
  final listenerResult = await threadSystem.createThread(
    name: 'event_listener',
  );
  
  if (listenerResult.itsSuccess) {
    final listener = listenerResult.content;
    
    // Listen for events in the thread
    await listener.execute<void>(
      function: (params) async {
        // Subscribe to the event stream
        final eventStream = loginEvent.getReceiver();
        
        if (eventStream.itsSuccess) {
          eventStream.content.listen((event) {
            print('Thread received login: ${event.userName}');
          });
        }
      },
    );
  }
  
  // Create publisher thread
  final publisherResult = await threadSystem.createThread(
    name: 'event_publisher',
  );
  
  if (publisherResult.itsSuccess) {
    final publisher = publisherResult.content;
    
    // Publish events from the thread
    await publisher.execute<void>(
      function: (params) async {
        // Simulate publishing events
        for (int i = 1; i <= 3; i++) {
          final event = UserLoginEvent(
            userId: i,
            userName: 'user_$i',
          );
          
          loginEvent.sendItem(event);
          await Future.delayed(Duration(milliseconds: 100));
        }
      },
    );
  }
}
```

**Use Cases**:
- Application-wide events
- Cross-thread notifications
- Publish-subscribe patterns
- Event broadcasting

---

## Platform-Specific Considerations

### Native Apps (Android, iOS, Desktop)

```dart
// Runs in actual Dart Isolates
final threadResult = await threadSystem.createThread(
  name: 'native_worker',
);

// Pros:
// - True parallelism
// - CPU-intensive tasks run faster
// - Independent memory spaces

// Cons:
// - Higher creation overhead
// - Message serialization costs
// - Careful with non-JSON data
```

### Web

```dart
// Runs in fake/simulated mode
final threadResult = await threadSystem.createThread(
  name: 'web_worker',
);

// Pros:
// - Works in browsers
// - Same API as native
// - No compilation differences

// Cons:
// - Still single-threaded
// - No actual parallelism
// - Better for organization
```

## Common Patterns

### Pattern 1: Worker Pool

```dart
final workerPool = <ThreadConnection>[];

// Initialize
for (int i = 0; i < 4; i++) {
  final result = await threadSystem.createThread(name: 'worker_$i');
  if (result.itsSuccess) workerPool.add(result.content);
}

// Use (round-robin)
int nextWorker = 0;
final result = await workerPool[nextWorker++ % workerPool.length].execute<int>(
  function: (params) async => 42,
);
```

### Pattern 2: Task Queue

```dart
class TaskQueue {
  final ThreadConnection _thread;
  final _queue = <Future>[];
  
  TaskQueue(this._thread);
  
  Future<Result<T>> enqueue<T>(
    FutureOr<T> Function(InvocationParameters) task,
  ) async {
    final future = _thread.execute<T>(function: task);
    _queue.add(future);
    return future;
  }
  
  Future<void> waitAll() => Future.wait(_queue);
}
```

### Pattern 3: Timeout Wrapper

```dart
Future<Result<T>> withTimeout<T>(
  ThreadConnection connection,
  FutureOr<T> Function(InvocationParameters) task, {
  required Duration timeout,
}) async {
  try {
    final result = await connection
        .execute<T>(function: task)
        .timeout(timeout);
    return result;
  } on TimeoutException {
    return ResultError(
      exception: TimeoutException('Thread task exceeded timeout'),
      message: 'Operation timed out after ${timeout.inSeconds}s',
    );
  }
}
```

## Testing Your Threads

### Unit Test Example

```dart
import 'package:test/test.dart';
import 'package:maxi_thread/maxi_thread.dart';

void main() {
  group('Thread execution', () {
    late ThreadConnection connection;
    
    setUp(() async {
      final result = await threadSystem.createThread(name: 'test_thread');
      expect(result.itsSuccess, isTrue);
      connection = result.content;
    });
    
    tearDown(() async {
      await connection.requestClosure();
    });
    
    test('executes function and returns result', () async {
      final result = await connection.execute<int>(
        function: (_) async => 42,
      );
      
      expect(result.itsSuccess, isTrue);
      expect(result.content, equals(42));
    });
    
    test('passes parameters correctly', () async {
      final result = await connection.execute<String>(
        parameters: InvocationParameters.from({'name': 'Alice'}),
        function: (params) async => 'Hello ${params.first<String>()}',
      );
      
      expect(result.content, equals('Hello Alice'));
    });
    
    test('handles errors gracefully', () async {
      final result = await connection.executeResult<int>(
        function: (_) async => ResultError(
          exception: Exception('Test error'),
          message: 'Intentional error',
        ),
      );
      
      expect(result.itsFailure, isTrue);
      expect(result.message, equals('Intentional error'));
    });
  });
}
```

## Performance Tips

1. **Reuse Threads**: Create threads once, reuse them
   ```dart
   // Good
   final worker = await createThread();
   for (int i = 0; i < 100; i++) {
     await worker.execute(task);
   }
   ```

2. **Batch Operations**: Group related tasks
   ```dart
   // Instead of multiple .execute() calls,
   // combine into one
   ```

3. **Minimize Serialization**: Pass references, not copies
   ```dart
   // Pass ID instead of large object
   parameters: InvocationParameters.from({'id': 123})
   ```

4. **Use Channels for Streams**: Better than repeated executions
   ```dart
   // Use buildChannel for continuous communication
   ```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `JSONSerialization error` | Non-serializable data passed | Use IDs or convert to JSON-compatible types |
| `Thread not created` | Thread factory failed | Check `threadResult.exception` |
| `Timeout on channel` | Receiving end disconnected | Ensure listener is active |
| `Memory leak` | Threads not disposed | Always call `requestClosure()` |
| `Zone access error` | Accessing manager outside thread | Use ThreadManager.threadZone within thread |

## Next Steps

1. Read [Architecture Guide](ARCHITECTURE.md) for deep technical details
2. Explore [CHANGELOG.md](CHANGELOG.md) for version updates
3. Check [maxi_framework](../maxi_framework) for core utilities
4. Review test files in `test/` directory for more examples

Happy threading!

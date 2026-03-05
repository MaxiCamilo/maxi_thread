# maxi_thread - API Reference

Complete API documentation for the maxi_thread library.

## Table of Contents

- [Global Functions](#global-functions)
- [ThreadManager Interface](#threadmanager-interface)
- [ThreadConnection Interface](#threadconnection-interface)
- [EntityThreadConnection Interface](#entitythreadconnection-interface)
- [Channel Interface](#channel-interface)
- [SharedEvent Class](#sharedevent-class)
- [Related Types](#related-types)

---

## Global Functions

### threadSystem

```dart
ThreadManager get threadSystem
set threadSystem(ThreadManager newSystem)
```

**Description**: Gets or sets the global thread system singleton.

**Returns**: The current `ThreadManager` instance

**Example**:
```dart
final manager = threadSystem;
```

**Notes**:
- Returns a `ThreadManagerInitializer` on first access (lazy initialization)
- Setting a new system logs a warning if the previous one wasn't disposed
- Use this to access threading functionality globally

---

## ThreadManager Interface

The central hub for thread management and lifecycle.

### Properties

#### identifier: int

```dart
int get identifier
```

Returns the unique identifier of the current thread/thread manager.

#### name: String

```dart
String get name
```

Returns the name of the current thread/thread manager.

#### serverConnection: ThreadConnection

```dart
ThreadConnection get serverConnection
```

Returns the connection to the main/server thread for communication.

#### itWasDiscarded: bool

```dart
bool get itWasDiscarded
```

Indicates if this thread manager has been disposed.

### Methods

#### service\<T\>()

```dart
EntityThreadConnection<T> service<T>()
```

**Description**: Retrieves a service instance of type `T` from the current thread.

**Type Parameters**:
- `T`: The service type to retrieve

**Returns**: `EntityThreadConnection<T>` - Connection to the service

**Example**:
```dart
final dbService = threadSystem.service<DatabaseService>();
```

**Throws**: If service is not registered

#### createThread()

```dart
FutureResult<ThreadConnection> createThread({
  required String name,
  List<Functionality> initializers = const [],
})
```

**Description**: Creates a new thread with the specified name and initializers.

**Parameters**:
- `name` (required): The name identifier for the thread
- `initializers` (optional): List of `Functionality` instances to initialize in the thread

**Returns**: `FutureResult<ThreadConnection>` - Result containing the connection to the new thread

**Example**:
```dart
final result = await threadSystem.createThread(
  name: 'background_worker',
  initializers: [DatabaseInitializer()],
);

if (result.itsSuccess) {
  final connection = result.content;
}
```

**Notes**:
- Thread names should be unique for identification
- Initializers run in the thread's context during creation
- Returns `FutureResult` for error handling

#### createEntityThread\<T\>()

```dart
FutureResult<EntityThreadConnection<T>> createEntityThread<T>({
  required T instance,
  bool omitIfExists = true,
})
```

**Description**: Creates a new thread with an entity/service instance.

**Type Parameters**:
- `T`: The service instance type

**Parameters**:
- `instance` (required): The service instance to run in the thread
- `omitIfExists` (optional, default: true): If true, returns existing entity thread if available

**Returns**: `FutureResult<EntityThreadConnection<T>>` - Result containing the connection to the entity thread

**Example**:
```dart
final service = MyService();
final result = await threadSystem.createEntityThread(instance: service);

if (result.itsSuccess) {
  final connection = result.content;
  // Service methods can now be invoked
}
```

**Notes**:
- The instance is serialized and moved to the new thread
- Ideal for services that maintain state
- `omitIfExists` prevents duplicate entity threads

#### obtainConnectionFromIdentifier()

```dart
FutureResult<ThreadConnection> obtainConnectionFromIdentifier({
  required int threadIdentifier,
})
```

**Description**: Obtains a connection to a thread by its identifier.

**Parameters**:
- `threadIdentifier` (required): The ID of the thread to connect to

**Returns**: `FutureResult<ThreadConnection>` - Result containing the connection, or error if thread not found

**Example**:
```dart
final result = await threadSystem.obtainConnectionFromIdentifier(
  threadIdentifier: 5,
);
```

#### getThreadEntity\<T\>()

```dart
Result<T> getThreadEntity<T>()
```

**Description**: Retrieves the entity instance from the current thread context.

**Type Parameters**:
- `T`: The entity type

**Returns**: `Result<T>` - Success with the entity instance, or error if not found

**Example**:
```dart
final entityResult = threadSystem.getThreadEntity<MyService>();
if (entityResult.itsSuccess) {
  final service = entityResult.content;
}
```

**Notes**:
- Only works within the thread's execution context
- Used to access the entity that owns/manages the thread

#### obtainThreadObject\<T\>()

```dart
Result<T> obtainThreadObject<T extends Object>({
  required String name,
})
```

**Description**: Retrieves a thread-local object by name.

**Type Parameters**:
- `T`: The object type

**Parameters**:
- `name` (required): The name/key of the stored object

**Returns**: `Result<T>` - Success with the object, or error if not found

**Example**:
```dart
final configResult = threadSystem.obtainThreadObject<AppConfig>(
  name: 'app_config',
);
```

#### defineThreadObject\<T\>()

```dart
Result<void> defineThreadObject<T extends Object>({
  required String name,
  required T object,
  bool removePrevious = true,
})
```

**Description**: Stores an object in thread-local storage.

**Type Parameters**:
- `T`: The object type

**Parameters**:
- `name` (required): The name/key to store the object under
- `object` (required): The object instance to store
- `removePrevious` (optional, default: true): If true, removes any previously stored object with the same name

**Returns**: `Result<void>` - Success or error

**Example**:
```dart
threadSystem.defineThreadObject(
  name: 'database_connection',
  object: dbConnection,
  removePrevious: true,
);
```

#### hasThreadObject\<T\>()

```dart
Result<bool> hasThreadObject<T extends Object>({
  required String name,
})
```

**Description**: Checks if a thread-local object exists.

**Type Parameters**:
- `T`: The object type

**Parameters**:
- `name` (required): The name/key to check

**Returns**: `Result<bool>` - Success with boolean, or error

**Example**:
```dart
final hasResult = threadSystem.hasThreadObject<AppConfig>(
  name: 'app_config',
);
```

#### removeThreadObject\<T\>()

```dart
Result<void> removeThreadObject<T extends Object>({
  required String name,
})
```

**Description**: Removes a thread-local object.

**Type Parameters**:
- `T`: The object type

**Parameters**:
- `name` (required): The name/key of the object to remove

**Returns**: `Result<void>` - Success or error

**Example**:
```dart
threadSystem.removeThreadObject<AppConfig>(name: 'app_config');
```

#### dispose()

```dart
void dispose()
```

**Description**: Disposes the thread manager and all associated resources.

**Example**:
```dart
threadSystem.dispose();
```

**Notes**:
- Call this when shutting down the application
- Prevents resource leaks
- After disposal, `itWasDiscarded` returns true

#### threadZone (static getter)

```dart
static ThreadManager get threadZone => 
  Zone.current[kThreadManagerZone]! as ThreadManager
```

**Description**: Retrieves the current thread's manager from the Zone.

**Returns**: `ThreadManager` for the current zone

**Throws**: If called outside a managed thread zone

**Example**:
```dart
// Inside a thread execution
final manager = ThreadManager.threadZone;
```

---

## ThreadConnection Interface

Represents a connection to a specific thread for executing functions and communicating.

### Properties

#### identifier: int

```dart
int get identifier
```

Returns the unique identifier of the connected thread.

#### name: String

```dart
String get name
```

Returns the name of the connected thread.

### Methods

#### execute\<T\>()

```dart
Future<Result<T>> execute<T>({
  InvocationParameters parameters = InvocationParameters.empty,
  required FutureOr<T> Function(InvocationParameters para) function,
})
```

**Description**: Executes a function in the thread's context.

**Type Parameters**:
- `T`: The return type

**Parameters**:
- `parameters` (optional): Parameters to pass to the function
- `function` (required): The async function to execute

**Returns**: `Future<Result<T>>` - Future result of the function execution

**Example**:
```dart
final result = await connection.execute<int>(
  parameters: InvocationParameters.from({'value': 10}),
  function: (params) async {
    final value = params.first<int>();
    return value * 2;
  },
);

if (result.itsSuccess) {
  print(result.content); // 20
}
```

**Notes**:
- Function is serialized and executed in the thread
- Return type must be JSON-serializable (on native)
- Parameters are passed to the function

#### executeResult\<T\>()

```dart
Future<Result<T>> executeResult<T>({
  InvocationParameters parameters = InvocationParameters.empty,
  required FutureOr<Result<T>> Function(InvocationParameters para) function,
})
```

**Description**: Executes a function that returns a `Result<T>`.

**Type Parameters**:
- `T`: The success value type

**Parameters**:
- `parameters` (optional): Parameters to pass to the function
- `function` (required): The async function that returns `Result<T>`

**Returns**: `Future<Result<T>>` - Future result

**Example**:
```dart
final result = await connection.executeResult<String>(
  function: (params) async {
    try {
      final data = await fetchData();
      return ResultValue(content: data);
    } catch (e) {
      return ResultError(exception: e);
    }
  },
);
```

**Notes**:
- Better for error handling within the thread
- Errors are wrapped in Result type
- No need for try-catch at call site

#### buildChannel\<R, S\>()

```dart
FutureResult<Channel<S, R>> buildChannel<R, S>({
  InvocationParameters parameters = InvocationParameters.empty,
  required FutureOr<Result<void>> Function(
    Channel<R, S> channel,
    InvocationParameters para,
  ) function,
})
```

**Description**: Creates a bidirectional channel for ongoing communication.

**Type Parameters**:
- `R`: The type received from the thread
- `S`: The type sent to the thread

**Parameters**:
- `parameters` (optional): Initial parameters
- `function` (required): Setup function that runs in the thread

**Returns**: `FutureResult<Channel<S, R>>` - Result with the channel

**Example**:
```dart
final channelResult = await connection.buildChannel<String, int>(
  function: (channel, params) async {
    final receiver = channel.getReceiver();
    if (receiver.itsSuccess) {
      receiver.content.listen((number) {
        channel.sendItem('Got: $number');
      });
    }
    return voidResult;
  },
);

if (channelResult.itsSuccess) {
  final channel = channelResult.content;
  channel.sendItem(42);
}
```

**Notes**:
- Creates a persistent channel in the thread
- Channel persists until disposed
- Excellent for streaming scenarios

#### requestClosure()

```dart
FutureResult<void> requestClosure()
```

**Description**: Requests the thread to close and cleanup resources.

**Returns**: `FutureResult<void>` - Indicates completion

**Example**:
```dart
await connection.requestClosure();
```

**Notes**:
- Should be called when thread is no longer needed
- On native: terminates the isolate
- On web: clears the task queue
- Prevents resource leaks

#### dispose()

```dart
void dispose()
```

**Description**: Synchronously disposes the connection.

**Example**:
```dart
connection.dispose();
```

#### threadZone (static getter)

```dart
static ThreadConnection get threadZone => 
  Zone.current[kThreadConnectionZone]! as ThreadConnection
```

**Description**: Retrieves the current thread's connection from the Zone.

**Throws**: If called outside a thread zone

---

## EntityThreadConnection Interface

Specialized connection for invoking methods on service entities in threads.

### Properties

Same as `ThreadConnection` plus entity-specific methods.

### Methods

#### invoke\<T\>()

```dart
Future<Result<T>> invoke<T>({
  required String methodName,
  List<dynamic> parameters = const [],
})
```

**Description**: Invokes a method on the entity instance.

**Type Parameters**:
- `T`: The return type of the method

**Parameters**:
- `methodName` (required): The name of the method to invoke
- `parameters` (optional): List of arguments for the method

**Returns**: `Future<Result<T>>` - Result of method execution

**Example**:
```dart
final connection = await threadSystem.createEntityThread(
  instance: userService,
);

if (connection.itsSuccess) {
  final result = await connection.content.invoke<List<User>>(
    methodName: 'getUsers',
    parameters: [10], // limit
  );
}
```

**Notes**:
- Method must exist on the entity class
- Method execution happens in the entity's thread
- Arguments must be serializable

#### dispose()

```dart
void dispose()
```

Disposes the entity and its thread.

---

## Channel Interface

Bidirectional communication channel between threads.

**Type Parameters**:
- `S`: Type sent to the channel
- `R`: Type received from the channel

### Methods

#### getReceiver()

```dart
Result<Stream<R>> getReceiver()
```

**Description**: Gets a stream for receiving messages from the channel.

**Returns**: `Result<Stream<R>>` - Success with stream, or error

**Example**:
```dart
final receiverResult = channel.getReceiver();
if (receiverResult.itsSuccess) {
  receiverResult.content.listen((message) {
    print('Received: $message');
  });
}
```

#### sendItem()

```dart
Result<void> sendItem(S item)
```

**Description**: Sends an item through the channel.

**Parameters**:
- `item`: The item to send

**Returns**: `Result<void>` - Success or error

**Example**:
```dart
final result = channel.sendItem('Hello');
if (result.itsFailure) {
  print('Failed to send: ${result.exception}');
}
```

#### dispose()

```dart
void dispose()
```

**Description**: Closes the channel and cleans up resources.

**Example**:
```dart
channel.dispose();
```

#### onDispose

```dart
Future<void> get onDispose
```

**Description**: A future that completes when the channel is disposed.

**Example**:
```dart
await channel.onDispose;
print('Channel was disposed');
```

---

## SharedEvent Class

Represents a shared event that can broadcast to multiple listeners across threads.

**Type Parameters**:
- `T`: The event data type (must be serializable)

### Constructor

```dart
SharedEvent({required String name})
```

**Parameters**:
- `name`: Unique name identifier for the event

### Methods

#### initialize()

```dart
Future<Result<void>> initialize()
```

**Description**: Initializes the shared event by connecting to the thread system.

**Returns**: `Future<Result<void>>` - Completion result

**Example**:
```dart
final event = SharedEvent<String>(name: 'notifications');
final result = await event.initialize();
if (result.itsFailure) {
  print('Failed to initialize: ${result.exception}');
}
```

**Notes**:
- Must be called before using sendItem or getReceiver
- Initializes asynchronously

#### getReceiver()

```dart
Result<Stream<T>> getReceiver()
```

**Description**: Gets a stream to receive events.

**Returns**: `Result<Stream<T>>` - Stream of events

**Example**:
```dart
final streamResult = event.getReceiver();
if (streamResult.itsSuccess) {
  streamResult.content.listen((event) {
    print('Event: $event');
  });
}
```

#### sendItem()

```dart
Result<void> sendItem(T item)
```

**Description**: Broadcasts an event to all listeners.

**Parameters**:
- `item`: The event data to broadcast

**Returns**: `Result<void>` - Success or error

**Example**:
```dart
event.sendItem('Important notification');
```

#### dispose()

```dart
void dispose()
```

**Description**: Closes the event and all listeners.

---

## Related Types

### InvocationParameters

```dart
class InvocationParameters {
  static const InvocationParameters empty = InvocationParameters._([]);
  
  factory InvocationParameters.from(Map<String, dynamic> map)
  factory InvocationParameters.only(dynamic value)
  
  T first<T>()
  T second<T>()
  T third<T>()
  T get<T>(int index)
  
  List<dynamic> toList()
}
```

**Description**: Container for passing parameters to thread functions.

**Factory Methods**:
- `InvocationParameters.empty`: Empty parameters
- `InvocationParameters.from(map)`: From a map
- `InvocationParameters.only(value)`: Single value

**Accessor Methods**:
- `first<T>()`: Get first parameter as type T
- `second<T>()`: Get second parameter as type T
- `third<T>()`: Get third parameter as type T
- `get<T>(index)`: Get parameter at index as type T

### Result\<T\>

```dart
abstract class Result<T> {
  bool get itsSuccess;
  bool get itsFailure;
  
  T get content;           // Only on success
  Exception? get exception; // Only on failure
  String? get message;      // Error message
}
```

**Description**: Type-safe result wrapper (success or failure).

**Usage**:
```dart
final result = await someAsyncOperation();

if (result.itsSuccess) {
  print(result.content); // Safe access
} else {
  print('Error: ${result.exception}');
}
```

### Functionality

```dart
abstract interface class Functionality implements Disposable {
  FutureResult<void> initialize();
}
```

**Description**: Base interface for initializable components.

**Used For**:
- Thread initializers in `createThread()`
- Setup routines that need to run in thread context

---

## Error Handling

All API methods return `Result<T>` or `FutureResult<T>` for safe error handling:

```dart
// Check for success
if (result.itsSuccess) {
  // Access content safely
  final value = result.content;
}

// Check for failure
if (result.itsFailure) {
  // Handle error
  print('Error: ${result.exception}');
  print('Message: ${result.message}');
}
```

---

## Disposable Interface

```dart
abstract interface class Disposable {
  void dispose();
  bool get itWasDiscarded;
}
```

**Requirements**:
- All thread-related objects implement `Disposable`
- Call `dispose()` when finished
- Check `itWasDiscarded` to verify disposal status

---

## Zone Constants

Accessing thread context from within execution:

```dart
// In thread execution context
final manager = ThreadManager.threadZone;
final connection = ThreadConnection.threadZone;
```

**Throws**: If called outside the appropriate zone context.

---

## Import Statement

```dart
import 'package:maxi_thread/maxi_thread.dart';
```

**Exported Items**:
- `ThreadManager`
- `ThreadConnection`
- `EntityThreadConnection`
- `ThreadChannel`
- `SharedEvent`
- `threadSystem`
- Stream extensions and utilities

---

## Version Info

- **Latest Version**: 1.0.0
- **Minimum Dart SDK**: 3.10.0
- **Status**: Stable

---

## See Also

- [README.md](README.md) - Overview and quick start
- [GETTING_STARTED.md](GETTING_STARTED.md) - Practical examples
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details

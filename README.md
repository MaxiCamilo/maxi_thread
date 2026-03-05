# maxi_thread

A comprehensive Dart/Flutter threading library that enables seamless background task execution and concurrent operations across different platforms.

## Overview

**maxi_thread** is a powerful abstraction layer for multi-threading in Dart and Flutter applications. It simplifies concurrent programming by providing a unified API that adapts to different platform capabilities:

- **Native Platforms** (Android, iOS, Desktop): Uses Dart's `Isolate` API for true concurrent execution
- **Web Platform**: Uses a fake threading implementation that simulates multi-threading without breaking web compatibility

The library provides sophisticated tools for thread management, inter-thread communication, and service-based thread operations, making it easy to build responsive applications with proper resource management.

## Features

- 🔄 **Platform-Aware Threading**: Automatically uses native isolates or fake threads based on the platform
- 📡 **Inter-thread Communication**: Built-in channels for bidirectional communication between threads
- 🎯 **Service-Based Architecture**: Execute services and functions in isolated contexts
- 🔌 **Event System**: Shared events for cross-thread communication
- 🛠️ **Thread Management**: Simplified API for creating, managing, and disposing threads
- 📦 **Object Sharing**: Thread-safe object storage and retrieval across thread boundaries
- ⚙️ **Composable Operations**: Chain thread operations using `InvocationParameters` and `Channel`

## Installation

Add `maxi_thread` to your `pubspec.yaml`:

```yaml
dependencies:
  maxi_thread:
    path: ../maxi_thread
```

Then run:

```bash
dart pub get
# or
flutter pub get
```

## Quick Start

### Basic Thread Creation

```dart
import 'package:maxi_thread/maxi_thread.dart';

// Initialize the thread system
final threadSystem = threadSystem;

// Create a simple thread
final threadResult = await threadSystem.createThread(
  name: 'background_worker',
);

if (threadResult.itsSuccess) {
  final connection = threadResult.content;
  
  // Execute code in the thread
  final result = await connection.execute<String>(
    function: (parameters) async {
      return 'Hello from thread!';
    },
  );
  
  if (result.itsSuccess) {
    print(result.content); // Output: Hello from thread!
  }
}
```

### Creating Entity Threads (Service-Based)

Entity threads allow you to create thread-local service instances:

```dart
// Create an entity thread with a service
class DataProcessor {
  Future<String> processData(String input) async {
    return 'Processed: $input';
  }
}

final processor = DataProcessor();
final entityResult = await threadSystem.createEntityThread(
  instance: processor,
);

if (entityResult.itsSuccess) {
  final connection = entityResult.content;
  
  // Invoke methods on the entity thread
  final result = await connection.invoke<String>(
    methodName: 'processData',
    parameters: ['data_to_process'],
  );
}
```

### Inter-Thread Communication via Channels

Channels enable powerful bidirectional communication between threads:

```dart
final threadConnection = // ... obtain a thread connection

final channelResult = await threadConnection.buildChannel<int, String>(
  function: (channel, parameters) async {
    // Setup the channel consumer
    channel.getReceiver().onCorrectStream((stream) {
      stream.listen((message) {
        print('Received: $message');
        // Send a response
        channel.sendItem(42);
      });
    });
  },
);

if (channelResult.itsSuccess) {
  final channel = channelResult.content;
  
  // Send data through the channel
  channel.sendItem('Hello thread'); // Output: Received: Hello thread
}
```

### Shared Events

Shared events allow cross-thread event broadcasting:

```dart
import 'package:maxi_thread/maxi_thread.dart';

// Create a shared event
final sharedEvent = SharedEvent<String>(name: 'app_events');

// Initialize it
await sharedEvent.initialize();

// Listen for events
sharedEvent.getReceiver().onCorrectStream((stream) {
  stream.listen((event) {
    print('Event received: $event');
  });
});

// Emit events from any thread
sharedEvent.sendItem('Important notification');
```

## Core Concepts

### ThreadManager

The central hub for thread management. Provides:

- Creating new threads with `createThread()`
- Creating entity threads with `createEntityThread<T>()`
- Accessing thread-local services with `service<T>()`
- Managing thread-local objects
- Identifying and accessing threads by ID

```dart
// Get the global thread manager
final manager = threadSystem;

// Get the current thread's identifier
print('Current thread ID: ${manager.identifier}');

// Access the main thread connection
final serverConnection = manager.serverConnection;

// Store thread-local objects
manager.defineThreadObject(
  name: 'config',
  object: configData,
);

// Retrieve thread-local objects
final config = manager.obtainThreadObject<ConfigData>(name: 'config');
```

### ThreadConnection

Represents a connection to a specific thread. Allows:

- Executing functions in the connected thread with `execute<T>()`
- Executing functions that return `Result<T>` with `executeResult<T>()`
- Building bidirectional channels with `buildChannel<R, S>()`
- Requesting thread closure with `requestClosure()`

```dart
final connection = // ... obtain a connection

// Execute a simple function
final result = await connection.execute<int>(
  function: (parameters) async {
    return 42;
  },
);

// Pass parameters
final result2 = await connection.execute<String>(
  parameters: InvocationParameters.from({'key': 'value'}),
  function: (parameters) async {
    final key = parameters.first<String>();
    return 'Value: $key';
  },
);
```

### EntityThreadConnection

A specialized connection for managing service instances in threads:

```dart
// Create an entity connection for your service
final entityConnection = threadSystem.service<MyService>();

// Invoke methods on the service
final result = await entityConnection.invoke<String>(
  methodName: 'getData',
  parameters: [],
);

// The service instance lives in the isolated thread context
```

### Channel

Bidirectional communication between threads or thread contexts:

- `getReceiver()`: Get a stream to receive data
- `sendItem(T)`: Send data through the channel
- Dispose when done

```dart
final channelResult = await connection.buildChannel<Response, Request>(
  function: (channel, parameters) async {
    final receiver = channel.getReceiver();
    if (receiver.itsSuccess) {
      receiver.content.listen((request) {
        // Process request
        final response = handleRequest(request);
        channel.sendItem(response);
      });
    }
  },
);
```

## Platform-Specific Implementation

### Native Platforms (Android, iOS, Desktop)

On native platforms, `maxi_thread` uses **Dart Isolates** under the hood:

```dart
// Automatically uses isolates on native platforms
final threadResult = await threadSystem.createThread(
  name: 'computation',
);
```

Benefits:
- True parallel execution
- Isolated memory spaces
- Full CPU utilization for multi-core processors
- Better performance for computationally intensive tasks

### Web Platform

On web, `maxi_thread` uses a **fake threading implementation** that:

- Maintains compatibility with web constraints (single-threaded JavaScript runtime)
- Simulates thread-like behavior using async/await and microtasks
- Preserves the same API for seamless code portability
- Allows the same application code to run on all platforms

```dart
// Same code works on web (with fake implementation)
final threadResult = await threadSystem.createThread(
  name: 'worker',
);
```

## Advanced Usage

### Thread-Local Storage

Store and retrieve objects in thread-local contexts:

```dart
final manager = threadSystem;

// Define a thread-local object
manager.defineThreadObject(
  name: 'database_connection',
  object: dbConnection,
  removePrevious: true,
);

// Check if it exists
if (manager.hasThreadObject<DatabaseConnection>(name: 'database_connection').content) {
  // Retrieve it
  final connection = manager.obtainThreadObject<DatabaseConnection>(
    name: 'database_connection',
  ).content;
}

// Remove it
manager.removeThreadObject(name: 'database_connection');
```

### Error Handling

All operations return `Result<T>` types for safe error handling:

```dart
final result = await connection.execute<int>(
  function: (parameters) async {
    return 42;
  },
);

if (result.itsSuccess) {
  print('Success: ${result.content}');
} else if (result.itsFailure) {
  print('Error: ${result.exception}');
}
```

### Graceful Thread Shutdown

Request thread closure when no longer needed:

```dart
final connection = // ... obtain a connection

// Request the thread to close
await connection.requestClosure();
```

### Disposable Resources

All thread-related resources should be properly disposed:

```dart
final threadManager = threadSystem;

// When shutting down
threadManager.dispose();
```

## Thread Initialization

You can provide initializers when creating threads:

```dart
final threadResult = await threadSystem.createThread(
  name: 'initialized_thread',
  initializers: [
    // Provide Functionality instances for setup
    DatabaseInitializer(),
    ConfigurationInitializer(),
  ],
);
```

## Zone-Based Architecture

The library uses Dart's `Zone` API for thread context management:

```dart
// Access the current thread's manager from within a thread
try {
  final manager = ThreadManager.threadZone;
  // Use the manager
} catch (e) {
  print('Not in a managed thread zone');
}

// Access the current thread connection
try {
  final connection = ThreadConnection.threadZone;
  // Use the connection
} catch (e) {
  print('Not in a thread zone');
}
```

## Architecture Notes

### Component Structure

```
maxi_thread/
├── lib/
│   ├── maxi_thread.dart              # Main export file
│   └── src/
│       ├── thread_manager.dart        # Core thread management interface
│       ├── thread_connection.dart     # Thread communication interface
│       ├── entity_thread_connection.dart  # Entity service interface
│       ├── thread_singleton.dart      # Global thread system
│       ├── factories/
│       │   ├── native_thread_factory.dart    # Native isolate factory
│       │   └── fake_thread_factory.dart      # Web fake factory (conditional)
│       ├── isolate/                   # Native isolate implementations
│       ├── fake/                      # Web fake implementations
│       └── shared/                    # Shared utilities and event system
└── test/
    └── maxi_thread_test.dart         # Test suite
```

### Key Design Patterns

- **Factory Pattern**: Platform-specific factories create appropriate thread implementations
- **Singleton Pattern**: Global `threadSystem` singleton for accessing the thread manager
- **Result Pattern**: All operations return `Result<T>` for safe error handling
- **Channel Pattern**: Bidirectional communication through channel abstractions
- **Zone Pattern**: Leverages Dart's Zone API for thread context management

## Contributing

Contributions are welcome! Please ensure:

- Code follows Dart conventions
- Tests are added for new features
- Documentation is updated accordingly

## License

This project is part of the MaxiFramework framework suite. See LICENSE file for details.

## Support & Documentation

For more information about the MaxiFramework framework ecosystem, see:

- [maxi_framework](../maxi_framework) - Core framework utilities
- [maxi_reflection](../maxi_reflection) - Reflection and serialization
- [maxi_sql](../maxi_sql) - Database abstractions
- [maxi_flutter_framework](../maxi_flutter_framework) - Flutter-specific utilities

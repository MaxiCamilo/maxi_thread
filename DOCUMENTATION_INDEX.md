# maxi_thread Documentation Index

Welcome to the complete documentation for **maxi_thread**, a comprehensive threading library for Dart and Flutter applications.

## Quick Links

### Getting Started

- **[README.md](README.md)** - Start here! Overview, features, quick start guide, and platform considerations
- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Practical, real-world examples with detailed explanations
- **[API_REFERENCE.md](API_REFERENCE.md)** - Complete API documentation for all public interfaces

### Deep Dives

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Technical architecture, design patterns, and implementation details
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and changes

## Documentation Overview

### 1. README.md → Start Here
**Best for**: Getting a general understanding of what maxi_thread does

- Project overview and features
- Features list
- Installation instructions
- Quick start examples
- Core concepts overview
- Platform-specific notes
- Architecture high-level description

**Read this if**:
- You're new to the library
- You want a quick overview
- You need to understand basic concepts

---

### 2. GETTING_STARTED.md → Learn by Example
**Best for**: Hands-on learning with practical code examples

**Topics covered**:
- Installation step-by-step
- Example 1: Computation in background threads
- Example 2: Service-based threads (Entity Threading)
- Example 3: Bidirectional channels
- Example 4: Thread-local object storage
- Example 5: Multiple threads coordination
- Example 6: Error handling and recovery
- Example 7: Shared events and broadcasting
- Platform-specific considerations
- Common patterns (Worker Pool, Task Queue, Timeouts)
- Testing strategies
- Performance tips
- Troubleshooting guide

**Read this if**:
- You want code examples
- You're solving a specific problem
- You want to understand patterns

---

### 3. API_REFERENCE.md → Detailed Reference
**Best for**: Looking up specific methods and interfaces

**Sections**:
- Global Functions
  - `threadSystem` getter/setter
- ThreadManager Interface
  - Properties (identifier, name, serverConnection, itWasDiscarded)
  - Methods (service, createThread, createEntityThread, etc.)
- ThreadConnection Interface
  - Properties (identifier, name)
  - Methods (execute, executeResult, buildChannel, requestClosure)
- EntityThreadConnection Interface
  - invoke() method
- Channel Interface
  - getReceiver(), sendItem(), dispose()
- SharedEvent Class
  - initialize(), getReceiver(), sendItem()
- Related Types
  - InvocationParameters
  - Result<T>
  - Functionality
- Error Handling patterns
- Disposable Interface
- Zone Constants
- Import statement
- Version info

**Read this if**:
- You need to look up a specific method
- You want to understand return types
- You're writing code and need API details

---

### 4. ARCHITECTURE.md → Technical Deep Dive
**Best for**: Understanding the internal design and implementation

**Topics covered**:
- Design principles
- Architecture layers (diagram)
- Platform-specific implementations
  - Native platforms (Isolates)
  - Web platform (Fake/Simulated)
  - Conditional compilation
- Core interfaces explained
- Execution models
- Shared resources and patterns
- Error handling strategy
- Zone-based context system
- Memory management
- Performance considerations
- Testing strategy
- Debugging techniques
- Future enhancements
- Internal communication protocol

**Read this if**:
- You want to understand how it works internally
- You're contributing to the library
- You need to debug complex issues
- You're optimizing performance

---

## Usage Scenarios

### "I want to use maxi_thread in my app"
→ Start with [README.md](README.md), then [GETTING_STARTED.md](GETTING_STARTED.md)

### "I need to do backgroundwork"
→ See Example 1 in [GETTING_STARTED.md](GETTING_STARTED.md)

### "I need service-based threading"
→ See Example 2 in [GETTING_STARTED.md](GETTING_STARTED.md)

### "I need bidirectional communication"
→ See Example 3 in [GETTING_STARTED.md](GETTING_STARTED.md)

### "I need to look up a method"
→ Use [API_REFERENCE.md](API_REFERENCE.md)

### "I want to understand how it works"
→ Read [ARCHITECTURE.md](ARCHITECTURE.md)

### "I'm having issues"
→ Check Troubleshooting in [GETTING_STARTED.md](GETTING_STARTED.md)

### "I want to contribute/extend the library"
→ Study [ARCHITECTURE.md](ARCHITECTURE.md)

### "What's been changed/updated"
→ See [CHANGELOG.md](CHANGELOG.md)

---

## Learning Path

### For Application Developers

```
1. Read: README.md (10 min)
         ↓
2. Read: GETTING_STARTED.md examples 1-3 (20 min)
         ↓
3. Try: Run examples locally (15 min)
         ↓
4. Reference: Use API_REFERENCE.md as needed (ongoing)
         ↓
5. Advanced: Read ARCHITECTURE.md for optimization (optional)
```

### For Library Contributors

```
1. Read: README.md (10 min)
         ↓
2. Study: ARCHITECTURE.md thoroughly (45 min)
         ↓
3. Review: Test files in test/ directory (20 min)
         ↓
4. Reference: API_REFERENCE.md (ongoing)
         ↓
5. Code: Explore src/ directory (30 min)
```

### For Integrators

```
1. Read: README.md (10 min)
         ↓
2. Skim: GETTING_STARTED.md (10 min)
         ↓
3. Reference: API_REFERENCE.md for specific needs (ongoing)
```

---

## Document Quick Reference

| Document | Length | Level | Best For |
|----------|--------|--------|----------|
| README.md | ~400 lines | Beginner | Overview & quick start |
| GETTING_STARTED.md | ~700 lines | Intermediate | Learning by examples |
| API_REFERENCE.md | ~600 lines | Advanced | Technical reference |
| ARCHITECTURE.md | ~550 lines | Advanced | Deep technical understanding |

---

## Key Concepts Explained Across Docs

### Threading Model

- **README**: High-level overview
- **GETTING_STARTED**: How to create and use threads
- **ARCHITECTURE**: Isolate vs. Fake implementation details

### Communication Patterns

- **README**: Brief introduction
- **GETTING_STARTED**: Examples with channels and events
- **API_REFERENCE**: Complete Channel interface
- **ARCHITECTURE**: Internal message protocol

### Error Handling

- **README**: Result-based pattern
- **GETTING_STARTED**: Example 6 (error handling)
- **API_REFERENCE**: Result<T> type details
- **ARCHITECTURE**: Error handling strategy

### Platform Considerations

- **README**: Platform-specific implementation section
- **GETTING_STARTED**: Platform-specific considerations section
- **ARCHITECTURE**: Detailed native vs. web implementation

---

## Common Tasks Quick Links

### Task: Create your first thread
- Start: [README.md - Quick Start](README.md#quick-start)
- Details: [GETTING_STARTED.md - Example 1](GETTING_STARTED.md#example-1-heavy-computation-in-background-thread)
- API: [API_REFERENCE.md - createThread()](API_REFERENCE.md#createthread)

### Task: Call a service method in a thread
- Start: [GETTING_STARTED.md - Example 2](GETTING_STARTED.md#example-2-service-based-thread-entity-threading)
- API: [API_REFERENCE.md - invoice()](API_REFERENCE.md#invoket)

### Task: Communicate bidirectionally with a thread
- Start: [GETTING_STARTED.md - Example 3](GETTING_STARTED.md#example-3-bidirectional-communication-with-channels)
- API: [API_REFERENCE.md - buildChannel()](API_REFERENCE.md#buildchannelr-s)

### Task: Share objects between threads
- Start: [GETTING_STARTED.md - Example 4](GETTING_STARTED.md#example-4-thread-local-object-storage)
- API: [API_REFERENCE.md - defineThreadObject()](API_REFERENCE.md#definethreadobjectt)

### Task: Broadcast events across threads
- Start: [GETTING_STARTED.md - Example 7](GETTING_STARTED.md#example-7-shared-events-for-cross-thread-broadcasting)
- API: [API_REFERENCE.md - SharedEvent Class](API_REFERENCE.md#sharedevent-class)

### Task: Handle errors in threaded code
- Start: [GETTING_STARTED.md - Example 6](GETTING_STARTED.md#example-6-error-handling-and-recovery)
- API: [API_REFERENCE.md - Result<T>](API_REFERENCE.md#resultt)

### Task: Optimize thread performance
- Start: [GETTING_STARTED.md - Performance Tips](GETTING_STARTED.md#performance-tips)
- Deep: [ARCHITECTURE.md - Performance Considerations](ARCHITECTURE.md#performance-considerations)

### Task: Debug threading issues
- Start: [GETTING_STARTED.md - Troubleshooting](GETTING_STARTED.md#troubleshooting)
- Deep: [ARCHITECTURE.md - Debugging](ARCHITECTURE.md#debugging)

---

## File Structure

```
maxi_thread/
├── README.md                 ← Start here for overview
├── GETTING_STARTED.md        ← Practical examples
├── API_REFERENCE.md          ← Complete API docs
├── ARCHITECTURE.md           ← Technical details
├── DOCUMENTATION_INDEX.md    ← This file
├── CHANGELOG.md              ← Version history
├── pubspec.yaml              ← Package configuration
├── lib/
│   ├── maxi_thread.dart      ← Main export
│   └── src/                  ← Implementation
├── test/                     ← Test files
└── debug/                    ← Debug utilities
```

---

## Setup & Installation

### Quick Install

```bash
# For Dart projects
dart pub add maxi_thread

# For Flutter projects
flutter pub add maxi_thread
```

### Manual Setup

See [GETTING_STARTED.md - Installation](GETTING_STARTED.md#installation)

---

## Support & Resources

### In This Documentation
- [API_REFERENCE.md](API_REFERENCE.md) - Complete API reference
- [GETTING_STARTED.md](GETTING_STARTED.md) - Code examples and patterns
- [ARCHITECTURE.md](ARCHITECTURE.md) - Design and internals

### Related Packages
- [maxi_framework](../maxi_framework) - Core framework utilities
- [maxi_reflection](../maxi_reflection) - Reflection and serialization
- [maxi_sql](../maxi_sql) - Database abstractions
- [maxi_flutter_framework](../maxi_flutter_framework) - Flutter utilities

### Dart/Flutter Resources
- [Dart Isolates Documentation](https://dart.dev/guides/language/concurrency)
- [Flutter Best Practices](https://flutter.dev/docs)
- [Async/Await in Dart](https://dart.dev/guides/language/language-tour#async-await)

---

## Contributing

Contributions are welcome! Please:

1. Read [ARCHITECTURE.md](ARCHITECTURE.md) to understand the design
2. Review test files in `test/` directory
3. Ensure tests pass before submitting
4. Update documentation if adding features

---

## Version Information

- **Current Version**: 1.0.0
- **Dart SDK**: ^3.10.0
- **Status**: Stable

Latest updates documented in [CHANGELOG.md](CHANGELOG.md)

---

## Quick Navigation

**First time here?**
→ Start with [README.md](README.md)

**Want to learn?**
→ Go to [GETTING_STARTED.md](GETTING_STARTED.md)

**Need API details?**
→ Check [API_REFERENCE.md](API_REFERENCE.md)

**Understanding internals?**
→ Study [ARCHITECTURE.md](ARCHITECTURE.md)

**Something not working?**
→ See [Troubleshooting](GETTING_STARTED.md#troubleshooting)

---

*Last Updated: March 5, 2026*
*maxi_thread v1.0.0*

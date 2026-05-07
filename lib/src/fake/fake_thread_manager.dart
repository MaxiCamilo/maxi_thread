import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/fake_entity_connection.dart';
import 'package:maxi_thread/src/fake/fake_thread_connection.dart';
import 'package:maxi_thread/src/isolate/server/masks/unsupported_entity_thread_connection.dart';

class FakeThreadManager with DisposableMixin, LifecycleHub implements ThreadManager {
  int _lastID = 1;

  final _connections = <FakeThreadConnection>[];
  final _entities = <FakeEntityConnection>[];

  @override
  BackgroundThreadService get backgroundService => throw UnimplementedError();

  @override
  ThreadConnection get serverConnection => FakeThreadConnection(identifier: 0, name: 'FakeServerThread', manager: this);

  @override
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) async {
    final exists = _entities.selectType<FakeEntityConnection<T>>();
    if (exists != null) {
      if (omitIfExists) {
        return exists.asResultValue();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'Entity of type %1 already exists', textParts: [T]),
        );
      }
    }

    final newConnectionResult = await createThread(name: name).castFuture<FakeThreadConnection>();
    if (newConnectionResult.itsFailure) {
      return newConnectionResult.cast();
    }

    final newConnection = newConnectionResult.content;
    final entityConnection = FakeEntityConnection(connection: newConnection, instance: instance);
    final initResult = await entityConnection.initialize();
    if (initResult.itsFailure) {
      entityConnection.dispose();
      return initResult.cast();
    }
    _entities.add(entityConnection);
    return entityConnection.asResultValue();
  }

  @override
  FutureResult<ThreadConnection> createThread({required String name, List<Functionality<dynamic>> initializers = const []}) async {
    for (final init in initializers) {
      final initResult = await init.execute();
      if (initResult.itsFailure) return initResult.cast();
    }

    final thread = FakeThreadConnection(identifier: _lastID, name: name, manager: this);

    _connections.add(thread);
    thread.onDispose.whenComplete(() => _connections.remove(thread));

    _lastID++;
    return thread.asResultValue();
  }

  @override
  Result<void> defineThreadEntity<T extends Object>({required T item, bool removePrevious = false}) {
    final exists = _entities.selectType<FakeEntityConnection<T>>();
    if (exists != null) {
      if (removePrevious) {
        exists.dispose();
      } else {
        return NegativeResult.controller(
          code: ErrorCode.invalidFunctionality,
          message: FlexibleOration(message: 'Entity of type %1 already exists', textParts: [T]),
        );
      }
    }

    createEntityThread<T>(instance: item, omitIfExists: false).logIfFails(errorName: 'Failed to define thread entity of type $T');
    return voidResult;
  }

  @override
  Result<void> defineThreadObject<T extends Object>({required String name, required T object, bool removePrevious = true}) {
    // TODO: implement defineThreadObject
    throw UnimplementedError();
  }

  @override
  Result<T> getThreadEntity<T>() {
    final entity = _entities.selectType<FakeEntityConnection<T>>();
    if (entity != null) {
      return entity.instance!.asResultValue();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Entity of type %1 not found', textParts: [T]),
      );
    }
  }

  @override
  Result<bool> hasThreadObject<T extends Object>({required String name}) {
    // TODO: implement hasThreadObject
    throw UnimplementedError();
  }

  @override
  int get identifier => 0;

  @override
  String get name => 'FakeThread';

  @override
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) async {
    final item = _connections.selectItem((x) => x.identifier == threadIdentifier);
    if (item != null) {
      return item.asResultValue();
    } else {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'Thread with identifier %1 not found', textParts: [threadIdentifier]),
      );
    }
  }

  @override
  Result<T> obtainThreadObject<T extends Object>({required String name}) {
    // TODO: implement obtainThreadObject
    throw UnimplementedError();
  }

  @override
  Result<void> removeThreadObject<T extends Object>({required String name}) {
    // TODO: implement removeThreadObject
    throw UnimplementedError();
  }

  @override
  EntityThreadConnection<T> service<T>() {
    final entity = _entities.selectType<FakeEntityConnection<T>>();
    if (entity != null) {
      return entity;
    } else {
      return UnsupportedEntityThreadConnection<T>();
    }
  }

  @override
  void performObjectDiscard() {}
}

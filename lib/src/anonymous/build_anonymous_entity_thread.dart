import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';

class BuildAnonymousEntityThread<T extends Object> with FunctionalityMixin<AnonymousEntityThread<T>> {
  final String name;
  final T item;

  const BuildAnonymousEntityThread({required this.item, required this.name});

  @override
  FutureResult<AnonymousEntityThread<T>> runInternalFuncionality() async {
    final newThreadResult = await threadSystem.createThread(
      name: name,
      initializers: [_InitThreadAsAnonymousThread<T>(item: item)],
    );
    if (newThreadResult.itsFailure) {
      return newThreadResult.cast();
    }

    final newThread = newThreadResult.content;
    return AnonymousEntityThread<T>.rawCreation(connection: newThread).asResultValue();
  }
}

class _InitThreadAsAnonymousThread<T extends Object> with FunctionalityMixin<void> {
  final T item;

  const _InitThreadAsAnonymousThread({required this.item});

  @override
  FutureResult<void> runInternalFuncionality() async {
    if (item is Initializable) {
      final initResult = (item as Initializable).initialize();
      if (initResult.itsFailure) {
        return initResult.cast();
      }
    }

    if (item is AsynchronouslyInitialized) {
      final asyncInitResult = await (item as AsynchronouslyInitialized).initialize();
      if (asyncInitResult.itsFailure) {
        return asyncInitResult.cast();
      }
    }

    if (item is Disposable) {
      (item as Disposable).onDispose.whenComplete(() => threadSystem.dispose());
    }

    final defineResult = threadSystem.defineThreadEntity<T>(item: item);
    if (defineResult.itsFailure) {
      return defineResult.cast();
    }

    return voidResult;
  }
}

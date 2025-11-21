import 'dart:async';
import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_function_pack.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_message.dart';

class IsolatedThreadRequester with DisposableMixin {
  final IsolatorChannel channel;

  final _semaphore = Semaphore();
  final _tasks = <int, Completer>{};
  final _itemStream = <int, StreamController>{};

  Completer<Result<int>>? _taskConfirmationWaiter;

  IsolatedThreadRequester({required this.channel}) {
    channel.onDispose.whenComplete(dispose);
  }

  void confirmNewExecution(int identifier) {
    if (_taskConfirmationWaiter == null) {
      log('[IsolatedThreadRequester] Confirmation of task number $identifier was not expected');
    } else {
      _taskConfirmationWaiter!.complete(ResultValue(content: identifier));
    }
  }

  void processResult(int id, dynamic content) {
    final waiter = _tasks.remove(id);
    if (waiter == null) {
      return;
    }

    if (waiter.isCompleted) {
      log('[IsolatedThreadRequester] The waiter for task number $id has already been completed');
    } else {
      try {
        waiter.complete(content);
      } catch (ex, st) {
        waiter.complete(
          ExceptionResult(
            exception: ex,
            stackTrace: st,
            message: FlexibleOration(message: 'The wait instance of task %1 did not accept the result of type %2', textParts: [id, content.runtimeType]),
          ),
        );
      }
    }
  }

  void processItemInteraction(int id, dynamic content) {
    final controller = _itemStream[id];
    if (controller == null) {
      return;
    }

    if (controller.isClosed) {
      _itemStream.remove(id);
      return;
    }

    try {
      controller.add(content);
    } catch (ex) {
      log('[IsolatedThreadRequester] The interactable item controller did not accept item ${content.runtimeType} (the controller is ${controller.runtimeType})');
    }
  }

  Future<Result<T>> execute<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<T> Function(InvocationParameters para) function}) {
    return executeResult<T>(parameters: InvocationParameters.clone(parameters, avoidConstants: true)..namedParameters['%/#'] = function, function: _executionDirectFunction<T>);
  }

  static Future<Result<T>> _executionDirectFunction<T>(InvocationParameters parameters) async {
    final function = parameters.named<FutureOr<T> Function(InvocationParameters)>('%/#');

    return ResultValue(content: await function(parameters));
  }

  Future<Result<T>> executeResult<T>({InvocationParameters parameters = InvocationParameters.emptry, required FutureOr<Result<T>> Function(InvocationParameters para) function}) async {
    final heart = LifeCoordinator.tryGetZoneHeart;
    final waiterID = Completer<Result<int>>();

    final idResult = await _semaphore.execute(() async {
      if (heart != null && heart.itWasDiscarded) {
        return CancelationResult<int>();
      }

      _taskConfirmationWaiter = waiterID;
      final sendResult = channel.send(
        IsolatedThreadMessage(
          type: IsolatedThreadMessageType.newFunction,
          identifier: 0,
          content: IsolatedThreadFunctionPack<T>(parameters: parameters, functionality: function),
        ),
      );
      if (sendResult.itsFailure) {
        _taskConfirmationWaiter = null;
        return sendResult.cast<int>();
      }

      return await waiterID.future;
    });

    if (idResult.itsFailure) return idResult.cast();
    final id = idResult.content;

    final streamController = StreamController();
    _itemStream[id] = streamController;
    final sendersEvent = InteractiveSystem.getAllSenders();

    streamController.stream.listen((event) => InteractiveSystem.sendItemCertainFunctions(list: sendersEvent, item: event));

    Future? onHeartDone;
    final completer = Completer<Result<T>>();
    _tasks[id] = completer;

    if (heart != null) {
      onHeartDone = heart.onDispose.whenComplete(() {
        if (!completer.isCompleted) {
          channel.send(IsolatedThreadMessage(type: IsolatedThreadMessageType.cancel, identifier: id, content: null));

          completer.complete(CancelationResult<T>());
        }
      });
    }

    final result = await completer.future;
    onHeartDone?.ignore();
    streamController.close();
    _itemStream.remove(id);
    _tasks.remove(id);

    return result;
  }

  @override
  void performObjectDiscard() {
    _itemStream.entries.lambda((x) => x.value.close());
    _itemStream.clear();

    _tasks.entries.lambda((x) => x.value.complete(CancelationResult()));
    _tasks.clear();
  }
}

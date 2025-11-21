import 'dart:developer';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/isolated/channels/isolator_channel.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_function_pack.dart';
import 'package:maxi_thread/src/isolated/messages/isolated_thread_message.dart';

class IsolatedThreadExecutor with DisposableMixin {
  final IsolatorChannel channel;
  final ThreadInstance instance;
  final ThreadInvocator invocator;

  final Map zoneValues;

  final _heartMap = <int, LifeCoordinator>{};
  int _lastID = 0;

  IsolatedThreadExecutor({required this.channel, required this.instance, required this.zoneValues, required this.invocator}) {
    channel.onDispose.whenComplete(dispose);
  }

  Future<void> createFunction(dynamic content) async {
    final id = _lastID;
    _lastID += 1;

    final sendConfirmationResult = channel.send(IsolatedThreadMessage(type: IsolatedThreadMessageType.confirmation, identifier: id, content: id));
    if (sendConfirmationResult.itsFailure) {
      log('[IsolatedThreadExecutor] Send confirmation error: ${sendConfirmationResult.error}');
      return;
    }

    LifeCoordinator? heart;

    await Future.delayed(Duration.zero);

    final container = await separateExecution(
      onHeartCreated: (newHeart) {
        _heartMap[id] = newHeart;
        heart = newHeart;
      },
      function: () async {
        if (content is IsolatedThreadFunctionPack) {
          return await content.execute(onItem: (x) => _sendItem(id, x), zoneValues: {ThreadInstance.isolatedThreadSymbol: instance, ThreadInvocator.originSymbol: invocator, ...zoneValues});
        } else {
          return NegativeResult.controller(
            code: ErrorCode.implementationFailure,
            message: FlexibleOration(message: 'A context was expected to execute the function (%1), but %2 was received', textParts: [IsolatedThreadFunctionPack, content.runtimeType]),
          );
        }
      },
    );

    _heartMap.remove(id);
    heart?.dispose();

    final sendResult = channel.send(IsolatedThreadMessage(type: IsolatedThreadMessageType.result, identifier: id, content: container));
    if (sendResult.itsFailure) {
      log('[IsolatedThreadExecutor] Send result error: ${sendResult.error}');
      final errorResult = channel.send(IsolatedThreadMessage(type: IsolatedThreadMessageType.result, identifier: id, content: container));
      if (errorResult.itsFailure) {
        channel.send(
          IsolatedThreadMessage(
            type: IsolatedThreadMessageType.result,
            identifier: id,
            content: NegativeResult.controller(code: ErrorCode.abnormalOperation, message: emptyOration),
          ),
        );
      }
    }
  }

  void cancelFunction(int id) {
    final heart = _heartMap.remove(id);
    heart?.dispose();
  }

  void _sendItem(int id, dynamic item) {
    final sendResult = channel.send(IsolatedThreadMessage(type: IsolatedThreadMessageType.interactionValue, identifier: id, content: item));
    if (sendResult.itsFailure) {
      log('[IsolatedThreadExecutor] The sending of an item of function number $id failed, the error was ${sendResult.error}');
      return;
    }
  }

  @override
  void performObjectDiscard() {}
}

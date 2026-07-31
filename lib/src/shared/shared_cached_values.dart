import 'dart:async';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/shared/shared_service.dart';

class SharedCachedValues<K, T extends Object> {
  final String name;
  final int maxValues;

  const SharedCachedValues({required this.name, this.maxValues = 0});

  static Result<List<(K, T)>> _getCachedMapOnSharedService<K, T>({required SharedService ss, required String name}) {
    return ss.obtainSharedObject<List<(K, T)>>(name: '&c.$name', defaultValue: <(K, T)>[]);
  }

  FutureResult<T?> tryGetValue(K key) {
    return SharedService.connection().onCorrectFuture((serv) => serv.executeResult(parameters: InvocationParameters.list([name, key]), function: _tryGetValueOnSharedService<K, T>));
  }

  static Result<T?> _tryGetValueOnSharedService<K, T>(SharedService serv, InvocationParameters parameters) {
    final name = parameters.first<String>();
    final key = parameters.second<K>();

    final mapResult = _getCachedMapOnSharedService<K, T>(ss: serv, name: name);
    if (mapResult.itsFailure) {
      return mapResult.asResultValue();
    }

    return ResultValue(content: mapResult.content.selectItem((x) => x.$1 == key)?.$2);
  }

  FutureResult<void> setValue({required K key, required T value}) {
    return SharedService.connection().onCorrectFuture((serv) => serv.executeResult(parameters: InvocationParameters.list([name, key, value, maxValues]), function: _setValueOnSharedService<K, T>));
  }

  static Result<void> _setValueOnSharedService<K, T>(SharedService serv, InvocationParameters parameters) {
    final name = parameters.first<String>();
    final key = parameters.second<K>();
    final value = parameters.third<T>();
    final maxValues = parameters.fourth<int>();

    final mapResult = _getCachedMapOnSharedService<K, T>(ss: serv, name: name);
    if (mapResult.itsFailure) {
      return mapResult.asResultValue();
    }

    final previous = mapResult.content.selectItem((x) => x.$1 == key)?.$2;
    if (previous is Disposable) {
      previous.dispose();
    }

    if (maxValues > 0 && mapResult.content.length >= maxValues) {
      final oldest = mapResult.content.first;
      if (oldest.$2 is Disposable) {
        (oldest.$2 as Disposable).dispose();
      }
      mapResult.content.remove(oldest);
    }

    final item = (key, value);

    mapResult.content.add(item);

    if (value is Disposable) {
      value.onDispose.whenComplete(() {
        mapResult.content.remove(item);
      });
    }

    return voidResult;
  }

  FutureResult<T> getValue({required K key, FutureOr<Result<T>> Function()? generator}) async {
    final tryResult = await tryGetValue(key);
    if (tryResult.itsFailure) {
      return tryResult.cast();
    }

    if (tryResult.content != null) {
      return ResultValue(content: tryResult.content!);
    }

    if (generator == null) {
      return NegativeResult.controller(
        code: ErrorCode.invalidFunctionality,
        message: FlexibleOration(message: 'No value found for key %1 and no generator provided', textParts: [key]),
      );
    }

    final genResult = await generator();
    if (genResult.itsFailure) {
      return genResult.cast();
    }

    return await setValue(key: key, value: genResult.content).onCorrectFuture((_) => genResult);
  }
}

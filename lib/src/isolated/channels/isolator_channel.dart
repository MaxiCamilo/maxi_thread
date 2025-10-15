import 'package:maxi_framework/maxi_framework.dart';

abstract interface class IsolatorChannel implements Disposable {
  Stream get stream;
  Result<void> send(dynamic item);
}

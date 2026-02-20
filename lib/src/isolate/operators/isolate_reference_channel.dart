import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/thread_connection.dart';

class IsolateReferenceChannel<R, S> with DisposableMixin, LifecycleHub {
  final int channelID;
  ThreadConnection connection;
  late final MasterChannel<R, S> channel;

  IsolateReferenceChannel({required this.connection, required this.channelID}) {
    final depResult = createDependency(connection);
    if (depResult.itsFailure) throw depResult.error;

    channel = joinDisposableObject(MasterChannel<R, S>());
  }
}

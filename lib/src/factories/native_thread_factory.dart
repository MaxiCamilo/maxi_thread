import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';
import 'package:maxi_thread/src/thread_manager.dart';

ThreadManager buildThreadManager() {
  return IsolatedThreadServer();
}

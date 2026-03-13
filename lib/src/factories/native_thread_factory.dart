import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/isolate/exception_channel/isolate_excpetion_channel_server.dart';
import 'package:maxi_thread/src/isolate/server/isolated_thread_server.dart';
import 'package:maxi_thread/src/thread_manager.dart';

ThreadManager buildThreadManager() {
  final nativeServer = IsolatedThreadServer();
  final excChannel = IsolateExcpetionChannelServer(threadServer: nativeServer);
  appManager.changeExceptionChannel(excChannel).exceptionIfFails(detail: 'Failed to set the exception channel of the app manager');

  return nativeServer;
}

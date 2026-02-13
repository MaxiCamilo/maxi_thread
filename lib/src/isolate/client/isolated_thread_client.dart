import 'dart:isolate';

import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/src/entity_thread_connection.dart';
import 'package:maxi_thread/src/isolate/channels/isolator_channel_end_point.dart';
import 'package:maxi_thread/src/isolate/connections/isolate_thread_connection.dart';
import 'package:maxi_thread/src/isolate/isolated_thread.dart';
import 'package:maxi_thread/src/thread_connection.dart';

class IsolatedThreadClient extends IsolatedThread {
  @override
  final int identifier;

  @override
  final String name;

  @override
  late final ThreadConnection serverConnection;

  IsolatedThreadClient({required this.identifier, required this.name, required IsolatorChannelEndPoint channel}) {
    final server = IsolateThreadConnection(channel: channel, identifier: 0, name: 'Isolated Thread Server');
    externalConnections.add(server);
    serverConnection = server;
  }

  @override
  FutureResult<EntityThreadConnection<T>> createEntityThread<T>({required T instance, bool omitIfExists = true}) {
    // TODO: implement createEntityThread
    throw UnimplementedError();
  }

  @override
  FutureResult<ThreadConnection> createThread() {
    // TODO: implement createThread
    throw UnimplementedError();
  }

  @override
  EntityThreadConnection<T> service<T>() {
    // TODO: implement service
    throw UnimplementedError();
  }

  @override
  FutureResult<ThreadConnection> obtainConnectionFromIdentifier({required int threadIdentifier}) {
    // TODO: implement obtainConnectionFromIdentifier
    throw UnimplementedError();
  }
}

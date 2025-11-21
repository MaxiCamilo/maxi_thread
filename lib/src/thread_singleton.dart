import 'package:maxi_framework/maxi_framework.dart';
import 'package:maxi_thread/maxi_thread.dart';
import 'package:maxi_thread/src/fake/fake_thread_instance.dart';
import 'package:maxi_thread/src/isolated/server/isolated_thread_server.dart';

mixin ThreadSingleton {
  static ThreadInstance? _instance;

  static ThreadInstance get instance {
    if (_instance == null) {
      if (ApplicationManager.singleton.isWeb) {
        changeInstance(FakeThreadInstance());
      } else {
        changeInstance(IsolatedThreadServer());
      }
    }
    return _instance!;
  }

  static void changeInstance(ThreadInstance instance) {
    if (_instance != null && _instance is Disposable) {
      (_instance as Disposable).dispose();
    }

    _instance = instance;
    if (instance is Disposable) {
      (instance as Disposable).onDispose.whenComplete(() => _instance = null);
    }
  }

  static ThreadInvocator get server => instance.server;
  static ThreadInvocator get background => instance.background;
  static ThreadServiceManager get servicesManager => instance.services;

  static Result<ThreadServiceInvocator<T>> getService<T extends Object>() => instance.services.getServiceInvocator<T>();

  static Future<Result<ThreadInvocator>> createThread({required String name}) => instance.createThread(name: name);
  static Future<Result<ThreadServiceInvocator<T>>> createServiceThread<T extends Object>({required T item, bool skipIfAlreadyMounted = true, String? name}) =>
      instance.services.createServiceThread<T>(item: item, name: name, skipIfAlreadyMounted: skipIfAlreadyMounted);
}

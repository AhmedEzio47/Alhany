import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static Future setupRemoteConfig() async {
    await Firebase.initializeApp();
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    // Allow a fetch every millisecond. Default is 12 hours.
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
        minimumFetchInterval: Duration(milliseconds: 1),
        fetchTimeout: Duration(seconds: 10)));
    remoteConfig.setDefaults(<String, dynamic>{
      'welcome': 'default welcome',
      'hello': 'default hello',
    });
    return remoteConfig;
  }

  static Future getString(String name) async {
    RemoteConfig remoteConfig = await setupRemoteConfig();
    await remoteConfig.fetch();
    await remoteConfig.activate();
    String value = remoteConfig.getString(name);
    return value;
  }
}

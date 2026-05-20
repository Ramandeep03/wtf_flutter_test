import 'package:hive_flutter/hive_flutter.dart';

class HiveInit {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    // Register adapters as models are added in future parts:
    //   Hive.registerAdapter(CachedUserAdapter());
    await Hive.openBox('app_prefs'); // token, user cache
  }
}

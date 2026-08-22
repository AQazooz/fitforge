import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';

class SupabaseConfig {
  const SupabaseConfig._();

  static Future<void> initialize() async {
    if (!AppEnv.isConfigured) {
      return;
    }

    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabasePublishableKey,
    );
  }

  static SupabaseClient? get client =>
      AppEnv.isConfigured ? Supabase.instance.client : null;
}

class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://bbhnpvxqaczxqteznmdp.supabase.co',
  );

  // Publishable keys are intended for client apps. Protect data with RLS.
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_zxgn8u16SuWCMWzj8CaEvw_HP9_hd_A',
  );
}

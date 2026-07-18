/// Application-wide constants.
abstract final class AppConstants {
  static const String appName = 'BillSplit';
  static const String tagline =
      'Scan the bill. Split it fairly. Settle instantly.';
  static const String appVersion = '1.0.0';

  static const Duration splashMinDuration = Duration(milliseconds: 2600);

  /// Simulated latency used by mock data sources.
  static const Duration mockNetworkDelay = Duration(milliseconds: 900);
}

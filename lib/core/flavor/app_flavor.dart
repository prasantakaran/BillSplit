enum AppFlavor {
  dev,
  staging,
  prod;

  String get label {
    switch (this) {
      case AppFlavor.dev:
        return 'Dev';
      case AppFlavor.staging:
        return 'Staging';
      case AppFlavor.prod:
        return 'Prod';
    }
  }
}

class AppFlavorConfig {
  AppFlavorConfig._();

  static AppFlavor _flavor = AppFlavor.prod;

  static AppFlavor get current => _flavor;

  static bool get isProd => _flavor == AppFlavor.prod;

  static void set(AppFlavor flavor) {
    _flavor = flavor;
  }
}

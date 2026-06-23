enum AppEnvironment {
  dev,
  staging,
  production,
}

extension AppEnvironmentX on AppEnvironment {
  String get name {
    switch (this) {
      case AppEnvironment.dev:
        return 'dev';
      case AppEnvironment.staging:
        return 'staging';
      case AppEnvironment.production:
        return 'production';
    }
  }

  bool get isDev => this == AppEnvironment.dev;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;

  String get displayName {
    switch (this) {
      case AppEnvironment.dev:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }
}

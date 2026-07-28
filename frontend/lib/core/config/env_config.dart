enum Environment {
  dev,
  staging,
  prod,
}

class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;

  const EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
  });

  factory EnvConfig.dev() {
    return const EnvConfig._(
      environment: Environment.dev,
      apiBaseUrl: 'http://127.0.0.1:8000',
      connectTimeoutMs: 10000,
      receiveTimeoutMs: 10000,
    );
  }

  factory EnvConfig.staging() {
    return const EnvConfig._(
      environment: Environment.staging,
      apiBaseUrl: 'https://staging-api.srmrmpod.edu.in',
      connectTimeoutMs: 15000,
      receiveTimeoutMs: 15000,
    );
  }

  factory EnvConfig.prod() {
    return const EnvConfig._(
      environment: Environment.prod,
      apiBaseUrl: 'https://api.srmrmpod.edu.in',
      connectTimeoutMs: 15000,
      receiveTimeoutMs: 15000,
    );
  }
}

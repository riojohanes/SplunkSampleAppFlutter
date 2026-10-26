class AppConfig {
  const AppConfig({
    required this.rumAccessToken,
    required this.realm,
    required this.appName,
    required this.deploymentEnvironment,
    required this.demoBaseUrl,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      rumAccessToken: String.fromEnvironment('SPLUNK_RUM_ACCESS_TOKEN'),
      realm: String.fromEnvironment('SPLUNK_REALM', defaultValue: 'us0'),
      appName: String.fromEnvironment(
        'SPLUNK_APP_NAME',
        defaultValue: 'splunk-sample-app-flutter',
      ),
      deploymentEnvironment: String.fromEnvironment(
        'SPLUNK_DEPLOYMENT_ENVIRONMENT',
        defaultValue: 'development',
      ),
      demoBaseUrl: String.fromEnvironment(
        'DEMO_BASE_URL',
        defaultValue: 'https://httpbin.org',
      ),
    );
  }

  final String rumAccessToken;
  final String realm;
  final String appName;
  final String deploymentEnvironment;
  final String demoBaseUrl;
}

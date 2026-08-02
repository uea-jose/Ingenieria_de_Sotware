const _apiBaseUrlFromEnv = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final apiBaseUrl = _apiBaseUrlFromEnv.endsWith('/api')
    ? _apiBaseUrlFromEnv
    : '$_apiBaseUrlFromEnv/api';

/// Where the request service lives (see server/README.md).
///
/// The address is public by nature, every installed app has to know it, so it
/// is committed here rather than kept secret. Never put a secret in this file:
/// the admin token stays in Cloudflare and the password manager.
const String defaultRequestsUrl = 'https://dhikr-requests.gratovo-dhikr.workers.dev';

/// The address this build uses: [defaultRequestsUrl], unless the build says
/// otherwise, for example to try the service on a computer:
///
///     flutter run --dart-define=DHIKR_REQUESTS_URL=http://127.0.0.1:8787
///
/// Passing the variable empty (`--dart-define=DHIKR_REQUESTS_URL=`) builds an
/// app without the feature: it hides everything to do with requesting a dhikr
/// rather than offering something that cannot work.
const String requestsApiUrl = String.fromEnvironment(
  'DHIKR_REQUESTS_URL',
  defaultValue: defaultRequestsUrl,
);

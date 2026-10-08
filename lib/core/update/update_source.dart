import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dhikr_reminder/core/update/update_release.dart';
import 'package:url_launcher/url_launcher.dart';

/// Where releases are published (`scripts/build_windows.ps1 -Mode Publish`
/// creates a GitHub Release with the installer attached).
const githubRepoOwner = 'i-Light';
const githubRepoName = 'dhikr_reminder';

/// The page a copy that cannot update itself is sent to.
final releasesPageUri = Uri.https(
  'github.com',
  '/$githubRepoOwner/$githubRepoName/releases/latest',
);

final _latestReleaseUri = Uri.https(
  'api.github.com',
  '/repos/$githubRepoOwner/$githubRepoName/releases/latest',
);

/// The latest published release, or null if there is none this app can use
/// (nothing published yet, a draft, no installer attached).
///
/// Throws on a network failure or an unexpected answer, so the caller can tell
/// "nothing new" from "could not find out".
Future<UpdateRelease?> fetchLatestRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.getUrl(_latestReleaseUri);
    request.headers
      ..set(HttpHeaders.userAgentHeader, 'dhikr_reminder-updater')
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close().timeout(
          const Duration(seconds: 30),
        );
    // 404 is what a repo with no published release answers: an answer, not a
    // failure.
    if (response.statusCode == HttpStatus.notFound) {
      await response.drain<void>();
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException(
        'GitHub answered ${response.statusCode}',
        uri: _latestReleaseUri,
      );
    }
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 30));
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) return null;
    return UpdateRelease.fromGithubJson(json);
  } finally {
    client.close(force: true);
  }
}

/// Opens [uri] in the default browser (or, on a phone, the browser or app that
/// handles it). False when nothing could be opened.
///
/// Goes through url_launcher on every platform: on Windows that is
/// ShellExecute, with no shell parsing the URL; on Android an ordinary view
/// intent.
Future<bool> openInBrowser(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// The Android application id, which is also the app's address on Google Play.
const androidApplicationId = 'com.gratovo.dhikr_reminder';

/// The app's page in the Play Store app.
final playStoreAppUri = Uri.parse('market://details?id=$androidApplicationId');

/// The same page on the web, for a phone without the Play Store app.
final playStorePageUri = Uri.https(
  'play.google.com',
  '/store/apps/details',
  {'id': androidApplicationId},
);

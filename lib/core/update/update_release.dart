/// A `major.minor.patch` version, as written in `pubspec.yaml` and in the
/// `vX.Y.Z` tags `release.yml` builds from.
class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final _pattern = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)');

  /// Reads the leading `X.Y.Z` of [text] (a leading `v` and anything after the
  /// patch — `+1`, `-beta` — are ignored), or null if it does not start with
  /// one.
  static AppVersion? tryParse(String text) {
    final match = _pattern.firstMatch(text.trim());
    if (match == null) return null;
    return AppVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  bool isNewerThan(AppVersion other) => compareTo(other) > 0;

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  @override
  bool operator ==(Object other) =>
      other is AppVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}

/// The installer of one published GitHub Release.
class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.assetName,
    required this.assetUrl,
    required this.size,
    this.sha256,
  });

  final AppVersion version;
  final String assetName;
  final Uri assetUrl;

  /// Bytes, as GitHub reports them. What was downloaded has to match.
  final int size;

  /// Lowercase hex, when GitHub reported a digest for the asset.
  final String? sha256;

  /// The setup exe `build_windows.ps1 -Installer` produces
  /// (`dhikr_reminder-<ver>-setup.exe`). The portable `.zip` beside it is not
  /// something a running app can swap in for itself.
  static final _installerName = RegExp(r'-setup\.exe$', caseSensitive: false);

  /// Builds a release from one entry of GitHub's `releases/latest` JSON, or
  /// null when it is a draft or pre-release, has no parseable tag, or carries
  /// no installer this app could run.
  static UpdateRelease? fromGithubJson(Map<String, dynamic> json) {
    if (json['draft'] == true || json['prerelease'] == true) return null;

    final tag = json['tag_name'];
    final version = tag is String ? AppVersion.tryParse(tag) : null;
    if (version == null) return null;

    final assets = json['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = asset['name'];
      final url = asset['browser_download_url'];
      final size = asset['size'];
      if (name is! String || url is! String || size is! int) continue;
      if (!_installerName.hasMatch(name)) continue;

      final uri = Uri.tryParse(url);
      // Release assets are served from github.com (then redirected to its
      // CDN). Anything else in this field is not something to run.
      if (uri == null || uri.scheme != 'https' || uri.host != 'github.com') {
        continue;
      }

      final digest = asset['digest'];
      final sha256 = digest is String && digest.startsWith('sha256:')
          ? digest.substring('sha256:'.length).toLowerCase()
          : null;

      return UpdateRelease(
        version: version,
        assetName: name,
        assetUrl: uri,
        size: size,
        sha256: sha256,
      );
    }
    return null;
  }
}

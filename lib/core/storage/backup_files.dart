import 'dart:convert';
import 'dart:io';

import 'package:dhikr_reminder/core/storage/backup_file.dart';
import 'package:dhikr_reminder/platform/app_platform.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where a backup goes to and comes from: a file the person picks. Overridden in
/// tests.
abstract class BackupFiles {
  /// Asks where to put [text] and writes it there. False when the person
  /// cancelled or it could not be written.
  Future<bool> save(String fileName, String text);

  /// Asks which file to read and returns its text, or null when the person
  /// cancelled or it could not be read.
  Future<String?> pick();
}

/// [BackupFiles] over the system's save and open dialogs. Windows uses
/// `file_selector` for both; Android uses it to open, and its own "create
/// document" screen (MainActivity) to save, which the package does not offer.
class DeviceBackupFiles implements BackupFiles {
  DeviceBackupFiles({required this.onPhone, MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('dhikr_reminder/share');

  final bool onPhone;
  final MethodChannel _channel;

  @override
  Future<bool> save(String fileName, String text) async {
    try {
      if (onPhone) {
        return await _channel.invokeMethod<bool>(
              'saveFile',
              {'name': fileName, 'text': text},
            ) ??
            false;
      }
      final location = await getSaveLocation(
        suggestedName: fileName,
        acceptedTypeGroups: const [
          XTypeGroup(label: 'JSON', extensions: ['json']),
        ],
      );
      if (location == null) return false;
      await XFile.fromData(
        utf8.encode(text),
        mimeType: 'application/json',
        name: fileName,
      ).saveTo(location.path);
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    } on FileSystemException {
      return false;
    }
  }

  @override
  Future<String?> pick() async {
    try {
      // A phone's file picker often does not know a backup is "json", so it
      // shows everything there; Windows is given the extension.
      final file = await openFile(
        acceptedTypeGroups: onPhone
            ? const []
            : const [
                XTypeGroup(label: 'JSON', extensions: ['json']),
              ],
      );
      if (file == null) return null;
      if (await file.length() > backupMaxBytes) return '';
      return await file.readAsString();
    } on PlatformException {
      return null;
    } on FileSystemException {
      return null;
    } on FormatException {
      // Not text at all.
      return '';
    }
  }
}

final backupFilesProvider = Provider<BackupFiles>(
  (ref) => DeviceBackupFiles(
    onPhone: ref.read(appPlatformProvider).usesNotifications,
  ),
);

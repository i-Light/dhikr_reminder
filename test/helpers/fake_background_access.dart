import 'package:dhikr_reminder/features/mobile_reminders/background_access.dart';

/// A [BackgroundAccess] that remembers what it was asked to do.
class FakeBackgroundAccess implements BackgroundAccess {
  FakeBackgroundAccess({this.unrestricted = false});

  bool unrestricted;
  int requests = 0;

  @override
  Future<bool> isUnrestricted() async => unrestricted;

  @override
  Future<void> request() async => requests++;
}

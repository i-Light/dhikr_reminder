import 'package:dhikr_reminder/features/requests/application/request_controller.dart';
import 'package:dhikr_reminder/features/requests/domain/dhikr_request.dart';
import 'package:dhikr_reminder/features/requests/domain/request_rules.dart';
import 'package:dhikr_reminder/l10n/gen/app_localizations.dart';

/// What to tell the person when a request could not be made.
String requestProblemMessage(
  AppLocalizations l10n,
  RequestProblem problem, {
  int? seconds,
}) {
  return switch (problem) {
    RequestProblem.tooShort => l10n.requestProblemTooShort,
    RequestProblem.tooLong => l10n.requestProblemTooLong(requestTextMax),
    RequestProblem.notArabic => l10n.requestProblemNotArabic,
    RequestProblem.hasLink => l10n.requestProblemHasLink,
    RequestProblem.repeated => l10n.requestProblemRepeated,
    RequestProblem.tooManyOpen =>
      l10n.requestProblemTooManyOpen(requestMaxOpen),
    RequestProblem.dailyLimit => l10n.requestProblemDailyLimit,
    RequestProblem.tooSoon =>
      l10n.requestProblemTooSoon((seconds ?? 20).clamp(1, 3600)),
    RequestProblem.busy => l10n.requestProblemBusy,
    RequestProblem.rejected => l10n.requestProblemRejected,
  };
}

/// The short name of a request's status.
String requestStatusLabel(AppLocalizations l10n, RequestStatus status) {
  return switch (status) {
    RequestStatus.queued => l10n.requestStatusQueued,
    RequestStatus.pending => l10n.requestStatusPending,
    RequestStatus.inProgress => l10n.requestStatusInProgress,
    RequestStatus.done => l10n.requestStatusDone,
    RequestStatus.declined => l10n.requestStatusDeclined,
  };
}

/// The sentence under a request: patience while it waits, thanks when it is
/// added, and a kind explanation when it is not.
///
/// [inLibrary] says whether this copy of the app already has the entry the
/// request became, which decides between "it is here" and "it comes with the
/// next update".
String requestNote(
  AppLocalizations l10n,
  DhikrRequest request, {
  required bool inLibrary,
}) {
  return switch (request.status) {
    RequestStatus.queued => l10n.requestNoteQueued,
    RequestStatus.pending => l10n.requestNotePending,
    RequestStatus.inProgress => l10n.requestNoteInProgress,
    RequestStatus.done => inLibrary
        ? l10n.requestNoteDone
        : request.shippedIn != null
            ? l10n.requestNoteDoneVersion(request.shippedIn!)
            : l10n.requestNoteDoneLater,
    RequestStatus.declined => switch (request.reason) {
        DeclineReason.duplicate => l10n.requestNoteDuplicate,
        DeclineReason.unclear => l10n.requestNoteUnclear,
        DeclineReason.notSuitable => l10n.requestNoteNotSuitable,
        _ => l10n.requestNoteOther,
      },
  };
}

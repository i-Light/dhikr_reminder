import 'package:flutter/foundation.dart';

/// Where a request stands, as the person sees it.
enum RequestStatus {
  /// Written on this device and not sent yet (no connection).
  queued,

  /// Received, waiting for the dev team.
  pending,

  /// The dev team is working on it.
  inProgress,

  /// Added to the library.
  done,

  /// Not going to be added; see [DeclineReason].
  declined;

  /// Whether the request is still going through, so it counts against the
  /// number a person may have open at once.
  bool get isOpen =>
      this == RequestStatus.queued ||
      this == RequestStatus.pending ||
      this == RequestStatus.inProgress;

  /// Whether the dev team has had its say.
  bool get isFinished => !isOpen;
}

/// Why a request was declined. Each one has its own kind message.
enum DeclineReason { duplicate, unclear, notSuitable, other }

/// One dhikr a person asked to have added, as kept on their device.
@immutable
class DhikrRequest {
  const DhikrRequest({
    required this.localId,
    required this.text,
    required this.createdAt,
    required this.status,
    this.serverId,
    this.source,
    this.reason,
    this.libraryId,
    this.shippedIn,
    this.votes = 1,
    this.unseen = false,
  });

  /// Known only to this device; the key of the request in the list.
  final String localId;

  /// The service's id for it, once it has been sent.
  final String? serverId;

  final String text;
  final String? source;
  final DateTime createdAt;
  final RequestStatus status;
  final DeclineReason? reason;

  /// The id of the library entry, once the dhikr was added.
  final String? libraryId;

  /// The app version that carries it.
  final String? shippedIn;

  /// How many people asked for this same dhikr.
  final int votes;

  /// Whether its status changed since the person last looked.
  final bool unseen;

  DhikrRequest copyWith({
    String? serverId,
    RequestStatus? status,
    DeclineReason? reason,
    String? libraryId,
    String? shippedIn,
    int? votes,
    bool? unseen,
  }) {
    return DhikrRequest(
      localId: localId,
      serverId: serverId ?? this.serverId,
      text: text,
      source: source,
      createdAt: createdAt,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      libraryId: libraryId ?? this.libraryId,
      shippedIn: shippedIn ?? this.shippedIn,
      votes: votes ?? this.votes,
      unseen: unseen ?? this.unseen,
    );
  }

  Map<String, Object?> toJson() => {
        'localId': localId,
        if (serverId != null) 'serverId': serverId,
        'text': text,
        if (source != null) 'source': source,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'status': status.name,
        if (reason != null) 'reason': reason!.name,
        if (libraryId != null) 'libraryId': libraryId,
        if (shippedIn != null) 'shippedIn': shippedIn,
        'votes': votes,
        'unseen': unseen,
      };

  /// Reads a saved request; null when it is too damaged to use, so one bad
  /// entry never costs the person the rest of their list.
  static DhikrRequest? tryFromJson(Object? raw) {
    if (raw is! Map) return null;
    final localId = raw['localId'];
    final text = raw['text'];
    final createdAt = raw['createdAt'];
    if (localId is! String || text is! String || createdAt is! int) return null;
    return DhikrRequest(
      localId: localId,
      serverId: raw['serverId'] as String?,
      text: text,
      source: raw['source'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      status: RequestStatus.values.asNameMap()[raw['status']] ??
          RequestStatus.pending,
      reason: DeclineReason.values.asNameMap()[raw['reason']],
      libraryId: raw['libraryId'] as String?,
      shippedIn: raw['shippedIn'] as String?,
      votes: raw['votes'] is int ? raw['votes'] as int : 1,
      unseen: raw['unseen'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DhikrRequest &&
      other.localId == localId &&
      other.serverId == serverId &&
      other.text == text &&
      other.source == source &&
      other.createdAt == createdAt &&
      other.status == status &&
      other.reason == reason &&
      other.libraryId == libraryId &&
      other.shippedIn == shippedIn &&
      other.votes == votes &&
      other.unseen == unseen;

  @override
  int get hashCode => Object.hash(
        localId,
        serverId,
        text,
        source,
        createdAt,
        status,
        reason,
        libraryId,
        shippedIn,
        votes,
        unseen,
      );
}

/// Connection status of the DevTools extension to the running application.
enum ConnectionStatus {
  /// Waiting for VM service and library availability.
  connecting,

  /// Successfully connected, data is available.
  connected,

  /// The puer_time_travel package is not found in the running application.
  unavailable,

  /// An error occurred during communication.
  error,
}

/// A snapshot of the time travel state received from the running application.
final class TimeTravelSnapshot {
  final List<TimelineEntry> timeline;
  final NavigationState navigation;
  final List<String> featureNames;

  const TimeTravelSnapshot({
    required this.timeline,
    required this.navigation,
    required this.featureNames,
  });

  factory TimeTravelSnapshot.fromJson(Map<String, dynamic> json) {
    final timelineJson = json['timeline'] as List;
    final navigationJson = json['navigation'] as Map<String, dynamic>;
    final featuresJson = json['features'] as List;

    return TimeTravelSnapshot(
      timeline: timelineJson
          .map((e) => TimelineEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      navigation: NavigationState.fromJson(navigationJson),
      featureNames: featuresJson.cast<String>(),
    );
  }
}

/// A single entry in the time travel timeline.
final class TimelineEntry {
  /// The name of the feature that produced this message.
  final String featureName;

  /// String representation of the message.
  final String message;

  /// Milliseconds since the time travel controller started recording.
  final int millisecondsSinceStart;

  const TimelineEntry({
    required this.featureName,
    required this.message,
    required this.millisecondsSinceStart,
  });

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      featureName: json['featureName'] as String,
      message: json['message'] as String,
      millisecondsSinceStart: json['millisecondsSinceStart'] as int,
    );
  }
}

/// The current navigation position within the timeline.
final class NavigationState {
  /// Index of the currently viewed event.
  /// `null` means viewing the initial state (before any messages).
  final int? currentIndex;

  /// Whether the application is currently in time travel mode.
  final bool isTimeTraveling;

  const NavigationState({
    required this.currentIndex,
    required this.isTimeTraveling,
  });

  factory NavigationState.fromJson(Map<String, dynamic> json) {
    return NavigationState(
      currentIndex: json['currentIndex'] as int?,
      isTimeTraveling: json['isTimeTraveling'] as bool,
    );
  }
}

final class TimeTravelViewState {
  final ConnectionStatus status;
  final TimeTravelSnapshot? snapshot;
  final String? errorMessage;

  const TimeTravelViewState({
    required this.status,
    this.snapshot,
    this.errorMessage,
  });

  const TimeTravelViewState.connecting()
    : status = ConnectionStatus.connecting,
      snapshot = null,
      errorMessage = null;

  const TimeTravelViewState.unavailable()
    : status = ConnectionStatus.unavailable,
      snapshot = null,
      errorMessage = null;

  TimeTravelViewState.connected(TimeTravelSnapshot this.snapshot)
    : status = ConnectionStatus.connected,
      errorMessage = null;

  TimeTravelViewState.withError(String this.errorMessage)
    : status = ConnectionStatus.error,
      snapshot = null;
}

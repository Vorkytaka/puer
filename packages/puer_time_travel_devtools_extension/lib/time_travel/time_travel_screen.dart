import 'package:flutter/material.dart';

import 'time_travel_controller.dart';
import 'time_travel_state.dart';

final class TimeTravelScreen extends StatefulWidget {
  const TimeTravelScreen({super.key});

  @override
  State<TimeTravelScreen> createState() => _TimeTravelScreenState();
}

class _TimeTravelScreenState extends State<TimeTravelScreen> {
  late final TimeTravelController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TimeTravelController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TimeTravelViewState>(
      valueListenable: _controller.state,
      builder: (context, viewState, _) {
        return switch (viewState.status) {
          ConnectionStatus.connecting => const _ConnectingView(),
          ConnectionStatus.unavailable => const _UnavailableView(),
          ConnectionStatus.error => _ErrorView(
              message: viewState.errorMessage!,
            ),
          ConnectionStatus.connected => _ConnectedView(
              snapshot: viewState.snapshot!,
              controller: _controller,
            ),
        };
      },
    );
  }
}

// -- Placeholder views for non-connected states --

class _ConnectingView extends StatelessWidget {
  const _ConnectingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Connecting to application...'),
        ],
      ),
    );
  }
}

class _UnavailableView extends StatelessWidget {
  const _UnavailableView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Package puer_time_travel is not found in the running application.\n\n'
        'Make sure the application uses TimeTravelFeature and the package is included.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Error: $message',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

// -- Main connected view --

class _ConnectedView extends StatelessWidget {
  final TimeTravelSnapshot snapshot;
  final TimeTravelController controller;

  const _ConnectedView({required this.snapshot, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NavigationToolbar(snapshot: snapshot, controller: controller),
        const Divider(height: 1),
        Expanded(
          child: snapshot.timeline.isEmpty
              ? const Center(child: Text('No events recorded yet.'))
              : _TimelineList(snapshot: snapshot, controller: controller),
        ),
      ],
    );
  }
}

// -- Navigation toolbar --

class _NavigationToolbar extends StatelessWidget {
  final TimeTravelSnapshot snapshot;
  final TimeTravelController controller;

  const _NavigationToolbar({required this.snapshot, required this.controller});

  @override
  Widget build(BuildContext context) {
    final nav = snapshot.navigation;
    final totalEvents = snapshot.timeline.length;
    final isTimeTraveling = nav.isTimeTraveling;

    // Position label: "Initial" or "Event X / Y"
    final String positionLabel;
    if (!isTimeTraveling) {
      positionLabel = 'Live ($totalEvents events)';
    } else if (nav.currentIndex == null) {
      positionLabel = 'Initial state';
    } else {
      positionLabel = 'Event ${nav.currentIndex! + 1} / $totalEvents';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Go to start',
            onPressed: totalEvents > 0 ? controller.goToStart : null,
          ),
          IconButton(
            icon: const Icon(Icons.navigate_before),
            tooltip: 'Step back',
            onPressed: totalEvents > 0 ? controller.goBack : null,
          ),
          Expanded(
            child: Text(
              positionLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.navigate_next),
            tooltip: 'Step forward',
            onPressed: isTimeTraveling ? controller.goForward : null,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Go to end',
            onPressed: isTimeTraveling ? controller.goToEnd : null,
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: isTimeTraveling ? controller.endTimeTravel : null,
            child: const Text('End Time Travel'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: controller.refresh,
          ),
        ],
      ),
    );
  }
}

// -- Timeline list --

class _TimelineList extends StatelessWidget {
  final TimeTravelSnapshot snapshot;
  final TimeTravelController controller;

  const _TimelineList({required this.snapshot, required this.controller});

  @override
  Widget build(BuildContext context) {
    final nav = snapshot.navigation;
    final timeline = snapshot.timeline;

    return ListView.builder(
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final entry = timeline[index];
        final isCurrentPosition =
            nav.isTimeTraveling && nav.currentIndex == index;

        return _TimelineEntryTile(
          entry: entry,
          index: index,
          isHighlighted: isCurrentPosition,
          onTap: () => controller.goToIndex(index),
        );
      },
    );
  }
}

class _TimelineEntryTile extends StatelessWidget {
  final TimelineEntry entry;
  final int index;
  final bool isHighlighted;
  final VoidCallback? onTap;

  const _TimelineEntryTile({
    required this.entry,
    required this.index,
    required this.isHighlighted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final duration = Duration(milliseconds: entry.millisecondsSinceStart);
    final timestamp = _formatDuration(duration);

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: isHighlighted ? null : onTap,
      child: Container(
        color: isHighlighted ? theme.colorScheme.primaryContainer : null,
        child: ListTile(
          dense: true,
          leading: Text(
            '#$index',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(
            entry.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : null,
            ),
          ),
          subtitle: Text(entry.featureName),
          trailing: Text(
            timestamp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final millis = duration.inMilliseconds % 1000;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else if (seconds > 0) {
      return '$seconds.${millis ~/ 100}s';
    } else {
      return '${millis}ms';
    }
  }
}

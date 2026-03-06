import 'package:flutter/material.dart';
import 'package:puer_flutter/puer_flutter.dart';

import 'data/in_memory_counter_storage.dart';
import 'domain/counter_feature.dart';
import 'presentation/counter_page.dart';

Future<void> main() async {
  final feature = createCounterFeature(storage: InMemoryCounterStorage());
  await feature.init();

  feature.transitions.listen(_onTransition);

  runApp(
    FeatureProvider.value(
      value: feature,
      child: const CounterApp(),
    ),
  );
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Travel Counter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

void _onTransition(
  Transition<CounterState, CounterMessage, CounterEffect> transition,
) {
  debugPrint('---');
  debugPrint('CounterFeature transition:');
  debugPrint('\tState before: ${transition.stateBefore}');
  debugPrint('\tMessage: ${transition.message}');
  if (transition.stateAfter != null) {
    debugPrint('\tState after: ${transition.stateAfter}');
  }
  if (transition.effects.isNotEmpty) {
    debugPrint('\tEffects: ${transition.effects}');
  }
}

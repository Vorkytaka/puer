import 'package:flutter/material.dart';
import 'package:puer/puer.dart';
import 'package:puer_flutter/puer_flutter.dart';

typedef CounterFeature = Feature<CounterState, CounterMessage, CounterEffect>;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeatureProvider<CounterFeature>.create(
        create: (context) =>
            Feature<CounterState, CounterMessage, CounterEffect>(
          initialState: const CounterState(count: 0),
          update: counterUpdate,
        ),
        child: const CounterPage(),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final feature = FeatureProvider.of<CounterFeature>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('puer_flutter example')),
      body: Center(
        child: FeatureBuilder<CounterFeature, CounterState>(
          builder: (context, state) => Text(
            '${state.count}',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => feature.accept(Increment()),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- Minimal feature implementation used by the example ---

sealed class CounterMessage {}

final class Increment extends CounterMessage {}

sealed class CounterEffect {}

final class CounterState {
  const CounterState({required this.count});

  final int count;
}

Next<CounterState, CounterEffect> counterUpdate(
  CounterState state,
  CounterMessage msg,
) {
  if (msg is Increment) {
    return next(
      state: CounterState(
        count: state.count + 1,
      ),
    );
  }
  return next();
}

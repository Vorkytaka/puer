import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:puer_flutter/puer_flutter.dart';

import '../domain/counter_feature.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final feature = FeatureProvider.of<CounterFeature>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Travel Counter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Counter Value:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            FeatureSelector<CounterFeature, CounterState, int>(
              selector: (state) => state.count,
              builder: (context, count) {
                return Text(
                  '$count',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CounterButton(
                  onPressed: () =>
                      feature.accept(const CounterMessage.decrement()),
                  text: 'Decrement',
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 24),
                CounterButton(
                  onPressed: () =>
                      feature.accept(const CounterMessage.increment()),
                  text: 'Increment',
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const LoadingButton(),
          ],
        ),
      ),
    );
  }
}

final class LoadingButton extends StatelessWidget {
  const LoadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureSelector<CounterFeature, CounterState, bool>(
      selector: (state) => state.status == CounterStatus.loading,
      builder: (context, isLoading) => ElevatedButton.icon(
        onPressed: isLoading
            ? null
            : () => context.read<CounterFeature>().accept(
                const CounterMessage.requestLoading(),
              ),
        icon: isLoading
            ? const SizedBox.square(
                dimension: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: const Text('Load Saved'),
      ),
    );
  }
}

final class CounterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String text;

  const CounterButton({
    required this.onPressed,
    required this.icon,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FeatureSelector<CounterFeature, CounterState, bool>(
      selector: (state) => state.status == CounterStatus.loading,
      builder: (context, isLoading) => FloatingActionButton(
        onPressed: isLoading ? null : onPressed,
        tooltip: text,
        child: icon,
      ),
    );
  }
}

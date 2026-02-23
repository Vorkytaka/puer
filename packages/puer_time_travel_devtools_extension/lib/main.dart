import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';
import 'time_travel/time_travel_screen.dart';

void main() {
  runApp(const PuerTimeTravelDevToolsExtension());
}

class PuerTimeTravelDevToolsExtension extends StatelessWidget {
  const PuerTimeTravelDevToolsExtension({super.key});

  @override
  Widget build(BuildContext context) {
    return const DevToolsExtension(child: TimeTravelScreen());
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:puer_flutter/puer_flutter.dart';

import 'github_search/domain/github_search_feature.dart';
import 'github_search/presentation/search_screen.dart';

void main() {
  runApp(
    FeatureProvider.create(
      create: (context) => githubSearchFeatureFactory(client: Client()),
      child: const MyApp(),
    ),
  );
}

final class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SearchScreen(),
    );
  }
}

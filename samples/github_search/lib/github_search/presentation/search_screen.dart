import 'package:flutter/material.dart';

import 'search_form.dart';

final class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Search')),
      body: const SearchForm(),
    );
  }
}

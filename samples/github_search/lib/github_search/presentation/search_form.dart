import 'package:flutter/material.dart';
import 'package:puer_flutter/puer_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/search_result.dart';
import '../domain/github_search_feature.dart';
import '../domain/github_search_message.dart';
import '../domain/github_search_state.dart';

class SearchForm extends StatelessWidget {
  const SearchForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _SearchBar(),
        _SearchBody(),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _textController,
      autocorrect: false,
      onChanged: (text) {
        final feature = FeatureProvider.of<GithubSearchFeature>(context);
        feature.accept(TextChangedMessage(text: text));
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        suffixIcon: GestureDetector(
          onTap: _onClearTapped,
          child: const Icon(Icons.clear),
        ),
        border: InputBorder.none,
        hintText: 'Enter a search term',
      ),
    );
  }

  void _onClearTapped() {
    _textController.text = '';
    final feature = FeatureProvider.of<GithubSearchFeature>(context);
    feature.accept(const TextChangedMessage(text: ''));
  }
}

class _SearchBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FeatureBuilder<GithubSearchFeature, GithubSearchState>(
      builder: (context, state) {
        final result = state.result;

        return switch (result) {
          GithubSearchEmpty() => const Text('Please enter a term to begin'),
          GithubSearchLoading() => const CircularProgressIndicator.adaptive(),
          GithubSearchFailure() => Text(result.error),
          GithubSearchSuccess() =>
            result.items.isEmpty
                ? const Text('No Results')
                : Expanded(child: _SearchResults(items: result.items)),
        };
      },
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.items});

  final List<SearchResultItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index) {
        return _SearchResultItem(item: items[index]);
      },
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({required this.item});

  final SearchResultItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Image.network(item.owner.avatarUrl),
      ),
      title: Text(item.fullName),
      onTap: () => launchUrl(Uri.parse(item.htmlUrl)),
    );
  }
}

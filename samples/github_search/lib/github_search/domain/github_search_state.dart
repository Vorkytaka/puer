import '../../models/search_result.dart';

final class GithubSearchState {
  static const initial = GithubSearchState(
    query: '',
    result: GithubSearchEmpty(),
  );

  final String query;
  final GithubSearchResult result;

  const GithubSearchState({
    required this.query,
    required this.result,
  });

  GithubSearchState copyWith({
    String? query,
    GithubSearchResult? result,
  }) => GithubSearchState(
    query: query ?? this.query,
    result: result ?? this.result,
  );
}

sealed class GithubSearchResult {}

final class GithubSearchEmpty implements GithubSearchResult {
  const GithubSearchEmpty();
}

final class GithubSearchLoading implements GithubSearchResult {
  const GithubSearchLoading();
}

final class GithubSearchSuccess implements GithubSearchResult {
  final List<SearchResultItem> items;

  const GithubSearchSuccess({required this.items});
}

final class GithubSearchFailure implements GithubSearchResult {
  final String error;

  const GithubSearchFailure({required this.error});
}

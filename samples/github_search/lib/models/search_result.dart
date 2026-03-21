class SearchResult {
  const SearchResult({required this.items});

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>)
        .map(
          (item) => SearchResultItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    return SearchResult(items: items);
  }

  final List<SearchResultItem> items;
}

class SearchResultItem {
  const SearchResultItem({
    required this.fullName,
    required this.htmlUrl,
    required this.owner,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      fullName: json['full_name'] as String,
      htmlUrl: json['html_url'] as String,
      owner: GithubUser.fromJson(json['owner'] as Map<String, dynamic>),
    );
  }

  final String fullName;
  final String htmlUrl;
  final GithubUser owner;
}

class GithubUser {
  const GithubUser({
    required this.login,
    required this.avatarUrl,
  });

  factory GithubUser.fromJson(Map<String, dynamic> json) {
    return GithubUser(
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String,
    );
  }

  final String login;
  final String avatarUrl;
}

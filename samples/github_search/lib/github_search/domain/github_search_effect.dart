sealed class GithubSearchEffect {}

final class SendRequestEffect implements GithubSearchEffect {
  final String query;

  const SendRequestEffect({required this.query});
}

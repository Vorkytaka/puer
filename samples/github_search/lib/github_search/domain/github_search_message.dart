import '../../models/search_result.dart';

sealed class GithubSearchMessage {}

final class TextChangedMessage implements GithubSearchMessage {
  final String text;

  const TextChangedMessage({required this.text});
}

final class RequestStartedMessage implements GithubSearchMessage {
  const RequestStartedMessage();
}

final class SuccessRequestMessage implements GithubSearchMessage {
  final List<SearchResultItem> items;

  const SuccessRequestMessage({required this.items});
}

final class FailureRequestMessage implements GithubSearchMessage {
  final int? statusCode;
  final Object exception;
  final StackTrace? stacktrace;

  const FailureRequestMessage({
    required this.statusCode,
    required this.exception,
    required this.stacktrace,
  });

  @override
  String toString() {
    return 'FailureRequestMessage{statusCode: $statusCode, exception: $exception, stacktrace: $stacktrace}';
  }
}

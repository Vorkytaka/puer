final class BadResponseException implements Exception {
  final int statusCode;
  final String body;

  const BadResponseException({required this.statusCode, required this.body});
}

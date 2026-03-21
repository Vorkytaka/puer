sealed class HttpMessage {
  const HttpMessage._();
}

final class SuccessHttpMessage implements HttpMessage {
  final String body;

  const SuccessHttpMessage({
    required this.body,
  });
}

final class FailureHttpMessage implements HttpMessage {
  final int? httpCode;
  final Object exception;
  final StackTrace? stackTrace;

  const FailureHttpMessage({
    required this.httpCode,
    required this.exception,
    required this.stackTrace,
  });
}

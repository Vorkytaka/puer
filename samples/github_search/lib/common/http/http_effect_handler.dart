import 'dart:async';

import 'package:http/http.dart';
import 'package:puer_flutter/puer_flutter.dart';

import '../bad_response_exception.dart';
import 'http_effect.dart';
import 'http_message.dart';

final class HttpEffectHandler
    implements EffectHandler<HttpEffect, HttpMessage> {
  final Client _httpClient;

  const HttpEffectHandler({
    required Client httpClient,
  }) : _httpClient = httpClient;

  @override
  Future<void> call(
    HttpEffect effect,
    MsgEmitter<HttpMessage> emit,
  ) {
    return switch (effect) {
      HttpGetEffect() => _get(effect, emit),
    };
  }

  Future<void> _get(
    HttpGetEffect effect,
    MsgEmitter<HttpMessage> emit,
  ) async {
    try {
      final response = await _httpClient.get(effect.url);

      if (response.statusCode >= 400) {
        throw BadResponseException(
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      emit(SuccessHttpMessage(body: response.body));
    } on BadResponseException catch (e, st) {
      emit(
        FailureHttpMessage(
          httpCode: e.statusCode,
          exception: e,
          stackTrace: st,
        ),
      );
    } on Object catch (e, st) {
      emit(
        FailureHttpMessage(
          httpCode: null,
          exception: e,
          stackTrace: st,
        ),
      );
    }
  }
}

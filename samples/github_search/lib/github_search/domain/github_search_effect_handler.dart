import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:puer_flutter/puer_flutter.dart';

import '../../common/bad_response_exception.dart';
import '../../models/search_result.dart';
import 'github_search_effect.dart';
import 'github_search_message.dart';

final class GithubSearchEffectHandler
    implements EffectHandler<GithubSearchEffect, GithubSearchMessage> {
  static const _baseUrl = 'https://api.github.com/search/repositories?q=';

  final Client _client;

  const GithubSearchEffectHandler({
    required Client client,
  }) : _client = client;

  @override
  Future<void> call(
    GithubSearchEffect effect,
    MsgEmitter<GithubSearchMessage> emit,
  ) {
    return switch (effect) {
      SendRequestEffect() => _sendRequestEffect(effect, emit),
    };
  }

  Future<void> _sendRequestEffect(
    SendRequestEffect effect,
    MsgEmitter<GithubSearchMessage> emit,
  ) async {
    try {
      final response = await _client.get(Uri.parse('$_baseUrl${effect.query}'));

      if (response.statusCode >= 400) {
        throw BadResponseException(
          statusCode: response.statusCode,
          body: response.body,
        );
      }

      final json = jsonDecode(response.body);
      final result = SearchResult.fromJson(json);

      emit(SuccessRequestMessage(items: result.items));
    } on BadResponseException catch (e, st) {
      emit(
        FailureRequestMessage(
          statusCode: e.statusCode,
          exception: e,
          stacktrace: st,
        ),
      );
    } on Object catch (e, st) {
      emit(
        FailureRequestMessage(
          statusCode: null,
          exception: e,
          stacktrace: st,
        ),
      );
    }
  }
}

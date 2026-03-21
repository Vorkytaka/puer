import 'package:puer_flutter/puer_flutter.dart';

import 'github_search_effect.dart';
import 'github_search_message.dart';
import 'github_search_state.dart';

Next<GithubSearchState, GithubSearchEffect> githubSearchUpdate(
  GithubSearchState state,
  GithubSearchMessage message,
) {
  switch (message) {
    case TextChangedMessage():
      if (state.result is GithubSearchLoading) {
        return next();
      }

      return next(
        state: state.copyWith(
          query: message.text,
          result: const GithubSearchEmpty(),
        ),
        effects: [
          if (message.text.isNotEmpty) SendRequestEffect(query: message.text),
        ],
      );
    case RequestStartedMessage():
      return next(
        state: state.copyWith(
          result: const GithubSearchLoading(),
        ),
      );
    case SuccessRequestMessage():
      return next(
        state: state.copyWith(
          result: GithubSearchSuccess(items: message.items),
        ),
      );
    case FailureRequestMessage():
      return next(
        state: state.copyWith(
          result: const GithubSearchFailure(error: 'something went wrong'),
        ),
      );
  }
}

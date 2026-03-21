import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:puer_effect_handlers/puer_effect_handlers.dart';
import 'package:puer_time_travel/puer_time_travel.dart';

import 'github_search_effect.dart';
import 'github_search_effect_handler.dart';
import 'github_search_message.dart';
import 'github_search_state.dart';
import 'github_search_update.dart';

typedef GithubSearchFeature =
    Feature<GithubSearchState, GithubSearchMessage, GithubSearchEffect>;

GithubSearchFeature githubSearchFeatureFactory({
  required Client client,
}) {
  if (!kReleaseMode) {
    return TimeTravelFeature(
      name: 'Github Search Feature',
      initialState: GithubSearchState.initial,
      update: githubSearchUpdate,
      effectHandlers: [
        GithubSearchEffectHandler(
          client: client,
        ).debounced(const Duration(milliseconds: 300)),
      ],
    );
  }

  return Feature(
    initialState: GithubSearchState.initial,
    update: githubSearchUpdate,
    effectHandlers: [
      GithubSearchEffectHandler(
        client: client,
      ).debounced(const Duration(milliseconds: 300)),
    ],
  );
}

import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:devtools_app_shared/utils.dart';
import 'package:devtools_extensions/devtools_extensions.dart';

import 'time_travel_controller.dart' show TimeTravelController;
import 'time_travel_state.dart';

/// Abstracts communication with the running application's
/// [TimeTravelController] via VM Service.
///
/// Uses a hybrid approach:
/// - **Service Extension** to read the full state as JSON.
/// - **Eval** to invoke navigation commands (goBack, goForward, etc.).
///
/// Listens for `ext.puer.stateChanged` events posted by the app
/// to know when to re-fetch the state.
final class TimeTravelService {
  static const _libraryUri =
      'package:puer_time_travel/src/time_travel_controller.dart';

  static const _serviceExtensionMethod = 'ext.puer.getTimeTravelState';
  static const _stateChangedEventKind = 'ext.puer.stateChanged';

  EvalOnDartLibrary? _eval;
  Disposable? _disposable;
  StreamSubscription? _eventSubscription;

  /// Initializes the eval library and starts listening for state change events.
  ///
  /// Throws [LibraryNotFound] if the target library is not available in the
  /// running application.
  Future<void> init() async {
    await serviceManager.onServiceAvailable.timeout(const Duration(seconds: 5));

    _disposable = Disposable();
    _eval = EvalOnDartLibrary(
      _libraryUri,
      serviceManager.service!,
      serviceManager: serviceManager,
    );

    _eventSubscription = serviceManager.service!.onExtensionEvent.listen((
      event,
    ) {
      if (event.extensionKind == _stateChangedEventKind) {
        _stateChangedController.add(null);
      }
    });
  }

  final _stateChangedController = StreamController<void>.broadcast();

  /// Emits when the app notifies that [TimeTravelController] state has changed.
  ///
  /// The extension should call [getState] in response.
  Stream<void> get onStateChanged => _stateChangedController.stream;

  /// Fetches the current time travel state from the running application
  /// via the registered service extension.
  Future<TimeTravelSnapshot> getState() async {
    final response = await serviceManager.callServiceExtensionOnMainIsolate(
      _serviceExtensionMethod,
    );

    final json = response.json!;
    return TimeTravelSnapshot.fromJson(json);
  }

  // -- Navigation commands (via Eval) --

  Future<void> goBack() => _evalCommand('TimeTravelController.global.goBack()');

  Future<void> goForward() =>
      _evalCommand('TimeTravelController.global.goForward()');

  Future<void> goToStart() =>
      _evalCommand('TimeTravelController.global.goToStart()');

  Future<void> goToEnd() =>
      _evalCommand('TimeTravelController.global.goToEnd()');

  Future<void> endTimeTravel() =>
      _evalCommand('TimeTravelController.global.endTimeTravel()');

  Future<void> goToIndex(int index) =>
      _evalCommand('TimeTravelController.global.goToIndex($index)');

  Future<void> _evalCommand(String expression) async {
    final eval = _eval;
    final disposable = _disposable;
    if (eval == null || disposable == null || disposable.disposed) {
      return;
    }

    await eval.eval(expression, isAlive: disposable);
  }

  void dispose() {
    _eventSubscription?.cancel();
    _stateChangedController.close();
    _disposable?.dispose();
    _eval?.dispose();
  }
}

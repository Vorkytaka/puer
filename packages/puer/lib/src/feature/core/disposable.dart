part of 'feature.dart';

/// Interface for resources that require cleanup.
///
/// The main purpose of this interface is to be used with [EffectHandler].
/// If [EffectHandler] implements it, then [Feature] will dispose this handler.
///
/// But [Feature] itself also implements it, just because it can.
@experimental
abstract interface class Disposable {
  /// Disposes of resources held by the implementing class.
  ///
  /// This method should be used to release any resources, such as open
  /// streams, database connections, or event listeners.
  Future<void> dispose();
}

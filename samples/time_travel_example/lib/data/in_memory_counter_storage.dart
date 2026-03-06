import 'counter_storage.dart';

final class InMemoryCounterStorage implements CounterStorage {
  int? _value;

  @override
  Future<int?> getValue() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return _value;
  }

  @override
  Future<void> saveValue(int value) async {
    _value = value;
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

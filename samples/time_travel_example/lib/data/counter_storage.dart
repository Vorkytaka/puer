abstract interface class CounterStorage {
  Future<int?> getValue();

  Future<void> saveValue(int value);
}

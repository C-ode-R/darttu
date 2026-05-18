enum ScreenState { lobby, serverSelection, auth, roomList, room }

class AppState {
  ScreenState screenState;
  final Map<String, Object?> _values;

  AppState({required this.screenState, Map<String, Object?>? values})
    : _values = values ?? <String, Object?>{};

  factory AppState.initial() {
    return AppState(screenState: ScreenState.lobby);
  }

  T? get<T>(String key) {
    final value = _values[key];
    if (value == null) {
      return null;
    }

    if (value is! T) {
      throw StateError(
        'State value for "$key" is ${value.runtimeType}, not $T.',
      );
    }

    return value as T;
  }

  T getOrDefault<T>(String key, T defaultValue) {
    final value = get<T>(key);
    return value ?? defaultValue;
  }

  bool has(String key) {
    return _values.containsKey(key);
  }

  bool setValue<T>(String key, T? value) {
    final hadKey = _values.containsKey(key);
    final previous = _values[key];

    if (value == null) {
      if (!hadKey) {
        return false;
      }

      _values.remove(key);
      return true;
    }

    if (hadKey && previous == value) {
      return false;
    }

    _values[key] = value;
    return true;
  }
}

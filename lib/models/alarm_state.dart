enum AlarmStatus { standby, monitoring, alarming }

enum AlarmLevel {
  none, level1, level2, level3, level4, level5;

  double get volume {
    switch (this) {
      case AlarmLevel.none:   return 0.0;
      case AlarmLevel.level1: return 0.2;
      case AlarmLevel.level2: return 0.4;
      case AlarmLevel.level3: return 0.6;
      case AlarmLevel.level4: return 0.8;
      case AlarmLevel.level5: return 1.0;
    }
  }

  int get step {
    switch (this) {
      case AlarmLevel.none:   return 0;
      case AlarmLevel.level1: return 1;
      case AlarmLevel.level2: return 2;
      case AlarmLevel.level3: return 3;
      case AlarmLevel.level4: return 4;
      case AlarmLevel.level5: return 5;
    }
  }

  String get label {
    switch (this) {
      case AlarmLevel.none:   return '待機中';
      case AlarmLevel.level1: return 'レベル1（小）';
      case AlarmLevel.level2: return 'レベル2';
      case AlarmLevel.level3: return 'レベル3（中）';
      case AlarmLevel.level4: return 'レベル4';
      case AlarmLevel.level5: return 'レベル5（最大）';
    }
  }

  AlarmLevel get next {
    switch (this) {
      case AlarmLevel.none:   return AlarmLevel.level1;
      case AlarmLevel.level1: return AlarmLevel.level2;
      case AlarmLevel.level2: return AlarmLevel.level3;
      case AlarmLevel.level3: return AlarmLevel.level4;
      case AlarmLevel.level4: return AlarmLevel.level5;
      case AlarmLevel.level5: return AlarmLevel.level5;
    }
  }
}

class AppState {
  final AlarmStatus status;
  final AlarmLevel level;
  final double sensitivity;  // 0.5=高感度 〜 3.0=低感度
  final double currentDelta;
  final int selectedSound;   // 0〜4

  const AppState({
    this.status = AlarmStatus.standby,
    this.level = AlarmLevel.none,
    this.sensitivity = 1.2,
    this.currentDelta = 0.0,
    this.selectedSound = 0,
  });

  AppState copyWith({
    AlarmStatus? status,
    AlarmLevel? level,
    double? sensitivity,
    double? currentDelta,
    int? selectedSound,
  }) => AppState(
    status: status ?? this.status,
    level: level ?? this.level,
    sensitivity: sensitivity ?? this.sensitivity,
    currentDelta: currentDelta ?? this.currentDelta,
    selectedSound: selectedSound ?? this.selectedSound,
  );

  bool get isActive => status != AlarmStatus.standby;
  bool get isAlarming => status == AlarmStatus.alarming;
}

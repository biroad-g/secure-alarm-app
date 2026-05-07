// 盗難防止アプリの状態モデル

enum AlarmStatus {
  standby,    // 待機中（モードOFF）
  monitoring, // 監視中（モードON、静止）
  detected,   // 振動検知中
  alarming,   // アラーム鳴動中
}

enum AlarmLevel {
  none,    // レベル0（無音）
  level1,  // レベル1（小）
  level2,  // レベル2（中小）
  level3,  // レベル3（中）
  level4,  // レベル4（大）
  level5,  // レベル5（最大）
}

extension AlarmLevelExtension on AlarmLevel {
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

  int get index2 {
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
      case AlarmLevel.none:   return '停止';
      case AlarmLevel.level1: return 'レベル1';
      case AlarmLevel.level2: return 'レベル2';
      case AlarmLevel.level3: return 'レベル3';
      case AlarmLevel.level4: return 'レベル4';
      case AlarmLevel.level5: return 'レベル5（最大）';
    }
  }
}

class AlarmStateModel {
  final AlarmStatus status;
  final AlarmLevel level;
  final double sensitivity; // 0.5 〜 3.0 (加速度の閾値)
  final bool isProtectionEnabled;
  final double currentAcceleration;

  const AlarmStateModel({
    this.status = AlarmStatus.standby,
    this.level = AlarmLevel.none,
    this.sensitivity = 1.5,
    this.isProtectionEnabled = false,
    this.currentAcceleration = 0.0,
  });

  AlarmStateModel copyWith({
    AlarmStatus? status,
    AlarmLevel? level,
    double? sensitivity,
    bool? isProtectionEnabled,
    double? currentAcceleration,
  }) {
    return AlarmStateModel(
      status: status ?? this.status,
      level: level ?? this.level,
      sensitivity: sensitivity ?? this.sensitivity,
      isProtectionEnabled: isProtectionEnabled ?? this.isProtectionEnabled,
      currentAcceleration: currentAcceleration ?? this.currentAcceleration,
    );
  }
}

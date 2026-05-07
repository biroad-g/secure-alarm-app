import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm_state.dart';
import 'web_audio_bridge.dart';

class AlarmService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  Timer? _levelUpTimer;
  Timer? _detectionCooldown;
  Timer? _audioLoopTimer;

  AlarmStateModel _state = const AlarmStateModel();
  AlarmStateModel get state => _state;

  double _prevX = 0, _prevY = 0, _prevZ = 0;
  bool _initialized = false;
  bool _cooldownActive = false;
  bool _isPlayingAlarm = false;

  int _selectedSoundType = 0;
  int get selectedSoundType => _selectedSoundType;

  static const int _levelUpIntervalSeconds = 3;

  // ============================================================
  //  サウンドタイプ定義（5種類）
  // ============================================================
  static const List<Map<String, dynamic>> soundTypes = [
    {
      'id': 0,
      'name': '🚨 緊急サイレン',
      'desc': '救急車風・周波数が上下するサイレン音',
    },
    {
      'id': 1,
      'name': '📢 電子ビープ',
      'desc': '短く鋭いビープ音の連続',
    },
    {
      'id': 2,
      'name': '🔊 警告ブザー',
      'desc': '低音の警告ブザー音',
    },
    {
      'id': 3,
      'name': '📣 高音アラーム',
      'desc': '高音で鋭いアラーム音',
    },
    {
      'id': 4,
      'name': '🆘 爆発的警報',
      'desc': '複数音の重なる強烈な警報',
    },
  ];

  // ============================================================
  //  公開メソッド
  // ============================================================

  void selectSoundType(int type) {
    _selectedSoundType = type.clamp(0, 4);
    notifyListeners();
  }

  /// テスト音を再生する
  void playTestSound(int soundType) {
    if (kIsWeb) {
      WebAudioBridge.play(soundType, 0.7);
    } else {
      _vibrateDevice();
    }
  }

  /// 盗難防止モードを有効化
  Future<void> enableProtection() async {
    _state = _state.copyWith(
      isProtectionEnabled: true,
      status: AlarmStatus.monitoring,
      level: AlarmLevel.none,
    );
    notifyListeners();
    _startListening();
  }

  /// 盗難防止モードを無効化
  Future<void> disableProtection() async {
    await _stopAlarmInternal();
    _stopListening();
    _state = _state.copyWith(
      isProtectionEnabled: false,
      status: AlarmStatus.standby,
      level: AlarmLevel.none,
      currentAcceleration: 0.0,
    );
    notifyListeners();
  }

  /// アラームを手動停止
  Future<void> stopAlarm() async {
    await _stopAlarmInternal();
    if (_state.isProtectionEnabled) {
      _state = _state.copyWith(
        status: AlarmStatus.monitoring,
        level: AlarmLevel.none,
      );
      notifyListeners();
    }
  }

  void setSensitivity(double value) {
    _state = _state.copyWith(sensitivity: value);
    notifyListeners();
  }

  // ============================================================
  //  センサー処理
  // ============================================================

  void _startListening() {
    _initialized = false;
    try {
      _accelerometerSubscription = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(
        _onAccelerometerEvent,
        onError: (e) {
          if (kDebugMode) debugPrint('Sensor error: $e');
        },
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Cannot start sensor: $e');
    }
  }

  void _stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _levelUpTimer?.cancel();
    _detectionCooldown?.cancel();
    _audioLoopTimer?.cancel();
    _initialized = false;
    _cooldownActive = false;
    _isPlayingAlarm = false;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    if (!_initialized) {
      _prevX = event.x;
      _prevY = event.y;
      _prevZ = event.z;
      _initialized = true;
      return;
    }

    final dx = event.x - _prevX;
    final dy = event.y - _prevY;
    final dz = event.z - _prevZ;
    final delta = sqrt(dx * dx + dy * dy + dz * dz);

    _prevX = event.x;
    _prevY = event.y;
    _prevZ = event.z;

    _state = _state.copyWith(currentAcceleration: delta);
    notifyListeners();

    if (_state.status == AlarmStatus.monitoring && !_cooldownActive) {
      if (delta > _state.sensitivity) {
        _triggerAlarm();
      }
    }
  }

  // ============================================================
  //  アラーム処理
  // ============================================================

  void _triggerAlarm() {
    _isPlayingAlarm = true;
    _state = _state.copyWith(
      status: AlarmStatus.alarming,
      level: AlarmLevel.level1,
    );
    notifyListeners();
    _playByLevel(AlarmLevel.level1);
    _startLevelUpTimer();
    _vibrateDevice();
  }

  void _startLevelUpTimer() {
    _levelUpTimer?.cancel();
    _levelUpTimer = Timer.periodic(
      const Duration(seconds: _levelUpIntervalSeconds),
      (timer) {
        if (!_isPlayingAlarm) {
          timer.cancel();
          return;
        }
        final currentIdx = _state.level.index2;
        if (currentIdx < 5) {
          final nextLevel = _alarmLevelFromIndex(currentIdx + 1);
          _state = _state.copyWith(level: nextLevel);
          notifyListeners();
          _playByLevel(nextLevel);
          if (kDebugMode) debugPrint('🔊 レベルアップ: ${nextLevel.label}');
        } else {
          timer.cancel();
        }
      },
    );
  }

  void _playByLevel(AlarmLevel level) {
    final volume = level.volume;

    if (kIsWeb) {
      // まず1回即時再生
      WebAudioBridge.play(_selectedSoundType, volume);
      // ループタイマーで繰り返し再生
      _audioLoopTimer?.cancel();
      _audioLoopTimer = Timer.periodic(
        const Duration(milliseconds: 1800),
        (_) {
          if (_isPlayingAlarm) {
            WebAudioBridge.play(_selectedSoundType, volume);
          } else {
            _audioLoopTimer?.cancel();
          }
        },
      );
    } else {
      // Androidはバイブレーションで代替
      _vibrateDevice();
    }
  }

  Future<void> _stopAlarmInternal() async {
    _isPlayingAlarm = false;
    _levelUpTimer?.cancel();
    _levelUpTimer = null;
    _audioLoopTimer?.cancel();
    _audioLoopTimer = null;

    if (kIsWeb) {
      WebAudioBridge.stop();
    }

    _cooldownActive = true;
    _detectionCooldown?.cancel();
    _detectionCooldown = Timer(const Duration(seconds: 3), () {
      _cooldownActive = false;
    });
  }

  void _vibrateDevice() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Vibration error: $e');
    }
  }

  AlarmLevel _alarmLevelFromIndex(int index) {
    switch (index) {
      case 1: return AlarmLevel.level1;
      case 2: return AlarmLevel.level2;
      case 3: return AlarmLevel.level3;
      case 4: return AlarmLevel.level4;
      case 5: return AlarmLevel.level5;
      default: return AlarmLevel.none;
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

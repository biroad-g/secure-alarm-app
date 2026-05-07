import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm_state.dart';

class AlarmService extends ChangeNotifier {
  // センサー・オーディオ
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _levelUpTimer;
  Timer? _detectionCooldown;

  // 状態
  AlarmStateModel _state = const AlarmStateModel();
  AlarmStateModel get state => _state;

  // 直前の加速度（変化量を計算するため）
  double _prevX = 0, _prevY = 0, _prevZ = 0;
  bool _initialized = false;
  bool _cooldownActive = false;

  // 段階アップの間隔(秒)
  static const int _levelUpIntervalSeconds = 3;

  // ============================================================
  //  公開メソッド
  // ============================================================

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
    await _stopAlarm();
    _stopListening();
    _state = _state.copyWith(
      isProtectionEnabled: false,
      status: AlarmStatus.standby,
      level: AlarmLevel.none,
      currentAcceleration: 0.0,
    );
    notifyListeners();
  }

  /// アラームを手動停止（盗難防止モードはONのまま監視継続）
  Future<void> stopAlarm() async {
    await _stopAlarm();
    if (_state.isProtectionEnabled) {
      _state = _state.copyWith(
        status: AlarmStatus.monitoring,
        level: AlarmLevel.none,
      );
      notifyListeners();
    }
  }

  /// 感度を変更
  void setSensitivity(double value) {
    _state = _state.copyWith(sensitivity: value);
    notifyListeners();
  }

  // ============================================================
  //  内部処理
  // ============================================================

  void _startListening() {
    _initialized = false;
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 100),
    ).listen(_onAccelerometerEvent);
  }

  void _stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _levelUpTimer?.cancel();
    _detectionCooldown?.cancel();
    _initialized = false;
    _cooldownActive = false;
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // 初回は基準値として設定するだけ
    if (!_initialized) {
      _prevX = event.x;
      _prevY = event.y;
      _prevZ = event.z;
      _initialized = true;
      return;
    }

    // 加速度変化量（差分のノルム）
    final dx = event.x - _prevX;
    final dy = event.y - _prevY;
    final dz = event.z - _prevZ;
    final delta = sqrt(dx * dx + dy * dy + dz * dz);

    _prevX = event.x;
    _prevY = event.y;
    _prevZ = event.z;

    // 現在の加速度値を更新
    _state = _state.copyWith(currentAcceleration: delta);
    notifyListeners();

    // 監視中かつクールダウン中でない場合のみ検知
    if (_state.status == AlarmStatus.monitoring && !_cooldownActive) {
      if (delta > _state.sensitivity) {
        _triggerAlarm();
      }
    }
  }

  void _triggerAlarm() {
    _state = _state.copyWith(
      status: AlarmStatus.alarming,
      level: AlarmLevel.level1,
    );
    notifyListeners();
    _playAlarm(AlarmLevel.level1);
    _startLevelUpTimer();
    _vibrateDevice();
  }

  void _startLevelUpTimer() {
    _levelUpTimer?.cancel();
    _levelUpTimer = Timer.periodic(
      const Duration(seconds: _levelUpIntervalSeconds),
      (timer) {
        final currentIdx = _state.level.index2;
        if (currentIdx < 5) {
          final nextLevel = _alarmLevelFromIndex(currentIdx + 1);
          _state = _state.copyWith(level: nextLevel);
          notifyListeners();
          _playAlarm(nextLevel);
          if (kDebugMode) debugPrint('🔊 アラームレベルアップ: ${nextLevel.label}');
        } else {
          timer.cancel();
        }
      },
    );
  }

  void _playAlarm(AlarmLevel level) async {
    try {
      await _audioPlayer.setVolume(level.volume);
      // Webではネットワーク音源を使用、モバイルでは生成した音
      if (kIsWeb) {
        // Web: 440Hzの警告音（外部URL）
        await _audioPlayer.play(
          UrlSource('https://www.soundjay.com/misc/sounds/fail-buzzer-01.mp3'),
        );
      } else {
        await _audioPlayer.play(
          UrlSource('https://www.soundjay.com/misc/sounds/fail-buzzer-01.mp3'),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Audio error: $e');
    }
  }

  Future<void> _stopAlarm() async {
    _levelUpTimer?.cancel();
    _levelUpTimer = null;
    try {
      await _audioPlayer.stop();
    } catch (e) {
      if (kDebugMode) debugPrint('Stop audio error: $e');
    }
    // クールダウン開始（誤検知防止）
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
    _audioPlayer.dispose();
    super.dispose();
  }
}

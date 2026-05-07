import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm_state.dart';

// ── Web Audio API ブリッジ（条件付きインポート）
// Web プラットフォームのみ js_interop を使用
import 'alarm_service_stub.dart'
    if (dart.library.js_interop) 'alarm_service_js.dart' as jsbridge;

class AlarmService extends ChangeNotifier {
  AppState _s = const AppState();
  AppState get state => _s;

  StreamSubscription<AccelerometerEvent>? _sensorSub;
  Timer? _levelTimer;
  Timer? _loopTimer;
  Timer? _coolTimer;

  bool _alarming = false;
  bool _cooldown = false;
  double _px = 0, _py = 0, _pz = 0;
  bool _sensorReady = false;

  static const int _stepSec = 3;

  // ── 5種類のサウンド定義 ──
  static const List<Map<String, String>> sounds = [
    {'name': '🚨 緊急サイレン',  'desc': '440↔880Hz 上下するサイレン'},
    {'name': '📢 電子ビープ',    'desc': '1200Hz の短いビープ×5'},
    {'name': '🔊 警告ブザー',    'desc': '220Hz 低音ブザー×3'},
    {'name': '📣 高音アラーム',  'desc': '2400+3200Hz 鋭い高音'},
    {'name': '🆘 爆発的警報',   'desc': '低音＋3段重ねビープ'},
  ];

  // ── JS音声関数を呼び出す ──
  void _jsPlay(int soundType, double volume) {
    jsbridge.jsPlay(soundType, volume);
  }

  void _jsStop() {
    jsbridge.jsStop();
  }

  // ── テスト再生 ──
  void playTest(int type) {
    _jsPlay(type, 0.7);
  }

  // ── サウンド選択 ──
  void selectSound(int type) {
    _s = _s.copyWith(selectedSound: type.clamp(0, 4));
    notifyListeners();
  }

  // ── 感度変更 ──
  void setSensitivity(double v) {
    _s = _s.copyWith(sensitivity: v);
    notifyListeners();
  }

  // ── 防犯モード ON ──
  Future<void> enable() async {
    _s = _s.copyWith(status: AlarmStatus.monitoring, level: AlarmLevel.none);
    notifyListeners();
    _startSensor();
  }

  // ── 防犯モード OFF ──
  Future<void> disable() async {
    _stopAll();
    _s = _s.copyWith(
      status: AlarmStatus.standby,
      level: AlarmLevel.none,
      currentDelta: 0,
    );
    notifyListeners();
  }

  // ── アラーム停止（監視は継続） ──
  Future<void> stopAlarm() async {
    _stopAlarmSound();
    _s = _s.copyWith(
      status: AlarmStatus.monitoring,
      level: AlarmLevel.none,
    );
    notifyListeners();
    _cooldown = true;
    _coolTimer?.cancel();
    _coolTimer = Timer(const Duration(seconds: 4), () => _cooldown = false);
  }

  // ── センサー開始 ──
  void _startSensor() {
    _sensorReady = false;
    _sensorSub?.cancel();
    try {
      _sensorSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 80),
      ).listen(_onSensor, onError: (e) {
        if (kDebugMode) debugPrint('[AlarmService] sensor error: $e');
      });
    } catch (e) {
      if (kDebugMode) debugPrint('[AlarmService] cannot start sensor: $e');
    }
  }

  void _onSensor(AccelerometerEvent e) {
    if (!_sensorReady) {
      _px = e.x; _py = e.y; _pz = e.z;
      _sensorReady = true;
      return;
    }
    final dx = e.x - _px, dy = e.y - _py, dz = e.z - _pz;
    final delta = sqrt(dx*dx + dy*dy + dz*dz);
    _px = e.x; _py = e.y; _pz = e.z;

    _s = _s.copyWith(currentDelta: delta);
    notifyListeners();

    if (_s.status == AlarmStatus.monitoring && !_cooldown && !_alarming && delta > _s.sensitivity) {
      _triggerAlarm();
    }
  }

  void _triggerAlarm() {
    _alarming = true;
    _s = _s.copyWith(status: AlarmStatus.alarming, level: AlarmLevel.level1);
    notifyListeners();
    _playLoop(AlarmLevel.level1);
    _startLevelUp();
    _vibrate();
  }

  void _startLevelUp() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(seconds: _stepSec), (t) {
      if (!_alarming) { t.cancel(); return; }
      final next = _s.level.next;
      if (next != _s.level) {
        _s = _s.copyWith(level: next);
        notifyListeners();
        _playLoop(next);
      }
    });
  }

  void _playLoop(AlarmLevel lv) {
    _loopTimer?.cancel();
    _jsPlay(_s.selectedSound, lv.volume);
    _loopTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (_alarming) {
        _jsPlay(_s.selectedSound, lv.volume);
      }
    });
  }

  void _stopAlarmSound() {
    _alarming = false;
    _levelTimer?.cancel();
    _loopTimer?.cancel();
    _jsStop();
  }

  void _stopAll() {
    _stopAlarmSound();
    _sensorSub?.cancel();
    _coolTimer?.cancel();
    _sensorReady = false;
    _cooldown = false;
  }

  void _vibrate() async {
    try {
      if (await Vibration.hasVibrator() ?? false) {
        Vibration.vibrate(pattern: [0, 400, 200, 400, 200, 400]);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}

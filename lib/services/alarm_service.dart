import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/alarm_state.dart';

import 'alarm_service_stub.dart'
    if (dart.library.js_interop) 'alarm_service_js.dart' as jsbridge;

class AlarmService extends ChangeNotifier {
  AppState _s = const AppState();
  AppState get state => _s;

  StreamSubscription<AccelerometerEvent>? _nativeSub;
  Timer? _levelTimer;
  Timer? _loopTimer;
  Timer? _coolTimer;

  bool _alarming = false;
  bool _cooldown = false;
  double _px = 0, _py = 0, _pz = 0;
  bool _first = true;

  // Webセンサーが起動済みか（UI表示用）
  bool _webSensorActive = false;
  bool get webSensorActive => _webSensorActive;

  static const int _stepSec = 3;

  static const List<Map<String, String>> sounds = [
    {'name': '🚨 緊急サイレン',  'desc': '440↔880Hz サイレン'},
    {'name': '📢 電子ビープ',    'desc': '1200Hz ビープ×5'},
    {'name': '🔊 警告ブザー',    'desc': '220Hz ブザー×3'},
    {'name': '📣 高音アラーム',  'desc': '2400Hz 鋭い高音'},
    {'name': '🆘 爆発的警報',   'desc': '低音＋3段ビープ'},
  ];

  // ── テスト再生 ──
  void playTest(int type) => jsbridge.jsPlay(type, 0.7);

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
  void enable() {
    _alarming = false;
    _cooldown = false;
    _first = true;
    _s = _s.copyWith(
      status: AlarmStatus.monitoring,
      level: AlarmLevel.none,
      currentDelta: 0,
    );
    notifyListeners();

    if (kIsWeb) {
      // Web: JSブリッジ経由でDeviceMotion＋マウス移動を監視
      _webSensorActive = true;
      jsbridge.jsStartSensor(
        sensitivity: _s.sensitivity,
        onAlarm: _onSensorAlarm,
        onDelta: _onSensorDelta,
      );
    } else {
      // Native: sensors_plus
      _nativeSub?.cancel();
      _nativeSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100),
      ).listen(_onNativeEvent, onError: (_) {});
    }
  }

  // ── 防犯モード OFF ──
  void disable() {
    _stopAll();
    _s = _s.copyWith(
      status: AlarmStatus.standby,
      level: AlarmLevel.none,
      currentDelta: 0,
    );
    notifyListeners();
  }

  // ── アラーム停止（監視継続）──
  void stopAlarm() {
    _stopSound();
    _s = _s.copyWith(status: AlarmStatus.monitoring, level: AlarmLevel.none);
    notifyListeners();
    _cooldown = true;
    _coolTimer?.cancel();
    _coolTimer = Timer(const Duration(seconds: 5), () => _cooldown = false);
  }

  // ── Nativeセンサーイベント ──
  void _onNativeEvent(AccelerometerEvent e) {
    if (_first) {
      _px = e.x; _py = e.y; _pz = e.z;
      _first = false;
      return;
    }
    final dx = e.x - _px, dy = e.y - _py, dz = e.z - _pz;
    final delta = sqrt(dx * dx + dy * dy + dz * dz);
    _px = e.x; _py = e.y; _pz = e.z;
    _onSensorDelta(delta);
    if (delta > _s.sensitivity) _onSensorAlarm(delta);
  }

  // ── JS側から呼ばれるコールバック ──
  void _onSensorDelta(double delta) {
    if (_s.status == AlarmStatus.standby) return;
    _s = _s.copyWith(currentDelta: delta);
    notifyListeners();
  }

  void _onSensorAlarm(double delta) {
    if (_s.status != AlarmStatus.monitoring) return;
    if (_cooldown || _alarming) return;
    _triggerAlarm();
  }

  // ── アラーム発火 ──
  void _triggerAlarm() {
    _alarming = true;
    _s = _s.copyWith(status: AlarmStatus.alarming, level: AlarmLevel.level1);
    notifyListeners();
    _playLoop(AlarmLevel.level1);
    _startLevelUp();
  }

  void _startLevelUp() {
    _levelTimer?.cancel();
    _levelTimer = Timer.periodic(const Duration(seconds: _stepSec), (t) {
      if (!_alarming) { t.cancel(); return; }
      final next = _s.level.next;
      if (next == _s.level) return; // level5 で停止
      _s = _s.copyWith(level: next);
      notifyListeners();
      _playLoop(next);
    });
  }

  void _playLoop(AlarmLevel lv) {
    _loopTimer?.cancel();
    jsbridge.jsPlay(_s.selectedSound, lv.volume);
    _loopTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (_alarming) jsbridge.jsPlay(_s.selectedSound, lv.volume);
    });
  }

  void _stopSound() {
    _alarming = false;
    _levelTimer?.cancel();
    _loopTimer?.cancel();
    jsbridge.jsStop();
  }

  void _stopAll() {
    _stopSound();
    _nativeSub?.cancel();
    _coolTimer?.cancel();
    _cooldown = false;
    _first = true;
    _webSensorActive = false;
    if (kIsWeb) jsbridge.jsStopSensor();
  }

  @override
  void dispose() {
    _stopAll();
    super.dispose();
  }
}

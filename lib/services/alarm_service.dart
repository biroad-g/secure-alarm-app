import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';
import '../models/alarm_state.dart';

import 'alarm_service_stub.dart'
    if (dart.library.js_interop) 'alarm_service_js.dart' as jsbridge;

class AlarmService extends ChangeNotifier {
  AppState _s = const AppState();
  AppState get state => _s;

  StreamSubscription<AccelerometerEvent>? _sensorSub;
  Timer? _levelTimer;
  Timer? _loopTimer;
  Timer? _coolTimer;
  // Webセンサー用：DeviceMotion値を受け取るストリームコントローラ
  Timer? _webSensorTimer;

  bool _alarming = false;
  bool _cooldown = false;
  double _px = 0, _py = 0, _pz = 0;
  bool _sensorReady = false;

  // センサー許可状態
  bool _sensorPermissionDenied = false;
  bool get sensorPermissionDenied => _sensorPermissionDenied;

  // Webセンサーが動いているか
  bool _webSensorActive = false;
  bool get webSensorActive => _webSensorActive;

  static const int _stepSec = 3;

  static const List<Map<String, String>> sounds = [
    {'name': '🚨 緊急サイレン',  'desc': '440↔880Hz 上下するサイレン'},
    {'name': '📢 電子ビープ',    'desc': '1200Hz の短いビープ×5'},
    {'name': '🔊 警告ブザー',    'desc': '220Hz 低音ブザー×3'},
    {'name': '📣 高音アラーム',  'desc': '2400+3200Hz 鋭い高音'},
    {'name': '🆘 爆発的警報',   'desc': '低音＋3段重ねビープ'},
  ];

  void _jsPlay(int soundType, double volume) {
    jsbridge.jsPlay(soundType, volume);
  }
  void _jsStop() {
    jsbridge.jsStop();
  }

  void playTest(int type) => _jsPlay(type, 0.7);
  void selectSound(int type) {
    _s = _s.copyWith(selectedSound: type.clamp(0, 4));
    notifyListeners();
  }
  void setSensitivity(double v) {
    _s = _s.copyWith(sensitivity: v);
    notifyListeners();
  }

  // ── 防犯モード ON ──
  Future<void> enable() async {
    _s = _s.copyWith(status: AlarmStatus.monitoring, level: AlarmLevel.none);
    notifyListeners();

    if (kIsWeb) {
      await _startWebSensor();
    } else {
      _startNativeSensor();
    }
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

  // ── アラーム停止（監視継続） ──
  Future<void> stopAlarm() async {
    _stopAlarmSound();
    _s = _s.copyWith(status: AlarmStatus.monitoring, level: AlarmLevel.none);
    notifyListeners();
    _cooldown = true;
    _coolTimer?.cancel();
    _coolTimer = Timer(const Duration(seconds: 5), () {
      _cooldown = false;
    });
  }

  // ──────────────────────────────────────────
  //  Webセンサー：JS側でDeviceMotionを受け取り
  //  Dartタイマーで定期的にポーリングする
  // ──────────────────────────────────────────
  Future<void> _startWebSensor() async {
    _webSensorTimer?.cancel();
    _sensorReady = false;
    _webSensorActive = false;
    _sensorPermissionDenied = false;

    // JS側でDeviceMotion許可リクエスト＋リスナー登録
    final ok = jsbridge.requestDeviceMotion();
    if (!ok) {
      // DeviceMotionEvent非対応（PCブラウザ等）→ マウス移動で代替
      _startMouseFallback();
      return;
    }

    // 100msごとにJS側の最新値をポーリング
    _webSensorTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_s.status == AlarmStatus.standby) return;

      final vals = jsbridge.getLatestMotion(); // [x, y, z, timestamp]
      if (vals == null || vals.length < 4) return;

      final x = vals[0], y = vals[1], z = vals[2];
      // vals[3] はタイムスタンプ（未使用）

      // 初回
      if (!_sensorReady) {
        _px = x; _py = y; _pz = z;
        _sensorReady = true;
        _webSensorActive = true;
        notifyListeners();
        return;
      }

      final dx = x - _px, dy = y - _py, dz = z - _pz;
      final delta = sqrt(dx*dx + dy*dy + dz*dz);
      _px = x; _py = y; _pz = z;

      _s = _s.copyWith(currentDelta: delta);
      notifyListeners();

      if (_s.status == AlarmStatus.monitoring && !_cooldown && !_alarming && delta > _s.sensitivity) {
        _triggerAlarm();
      }
    });
  }

  // マウス/タッチ移動でセンサー代替（PCブラウザ向け）
  void _startMouseFallback() {
    _webSensorActive = true;
    // JS側のマウス移動デルタをポーリング
    _webSensorTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_s.status == AlarmStatus.standby) return;

      final delta = jsbridge.getMouseDelta();
      _s = _s.copyWith(currentDelta: delta);
      notifyListeners();

      if (_s.status == AlarmStatus.monitoring && !_cooldown && !_alarming && delta > _s.sensitivity) {
        _triggerAlarm();
      }
    });
  }

  // ──────────────────────────────────────────
  //  ネイティブセンサー（Android/iOS）
  // ──────────────────────────────────────────
  void _startNativeSensor() {
    _sensorReady = false;
    _sensorSub?.cancel();
    try {
      _sensorSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 80),
      ).listen(_onNativeSensor, onError: (_) {});
    } catch (_) {}
  }

  void _onNativeSensor(AccelerometerEvent e) {
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

  // ──────────────────────────────────────────
  //  アラームロジック
  // ──────────────────────────────────────────
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
      if (_alarming) _jsPlay(_s.selectedSound, lv.volume);
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
    _webSensorTimer?.cancel();
    _coolTimer?.cancel();
    _sensorReady = false;
    _cooldown = false;
    _webSensorActive = false;
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

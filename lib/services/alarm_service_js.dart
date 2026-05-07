import 'dart:js_interop';

/// Web プラットフォーム用 JS ブリッジ
/// index.html に定義された window.saXxx 関数を呼び出す

// ── 音声 ──────────────────────────────────────
@JS('saPlay')
external void _saPlay(JSNumber soundType, JSNumber volume);

@JS('saStop')
external void _saStop();

// ── センサー ─────────────────────────────────
/// Dartのコールバック関数をJSに登録する
/// JS側は delta が閾値を超えたとき saOnMotion(delta) を呼ぶ
@JS('saSetCallbacks')
external void _saSetCallbacks(JSFunction onMotion, JSFunction onDelta);

/// DeviceMotionリスナーを開始する
@JS('saStartMotion')
external void _saStartMotion();

/// DeviceMotionリスナーを停止する
@JS('saStopMotion')
external void _saStopMotion();

// ── 公開関数 ──────────────────────────────────
void jsPlay(int soundType, double volume) {
  try { _saPlay(soundType.toJS, volume.toJS); } catch (_) {}
}

void jsStop() {
  try { _saStop(); } catch (_) {}
}

/// コールバックを登録してモーション監視を開始
/// [onMotionTriggered] アラーム発火通知 (delta値を受け取る)
/// [onDeltaUpdate]     delta値の定期更新
void jsStartSensor({
  required void Function(double delta) onMotionTriggered,
  required void Function(double delta) onDeltaUpdate,
}) {
  try {
    final jsTrigger = ((JSNumber d) => onMotionTriggered(d.toDartDouble)).toJS;
    final jsUpdate  = ((JSNumber d) => onDeltaUpdate(d.toDartDouble)).toJS;
    _saSetCallbacks(jsTrigger, jsUpdate);
    _saStartMotion();
  } catch (_) {}
}

void jsStopSensor() {
  try { _saStopMotion(); } catch (_) {}
}

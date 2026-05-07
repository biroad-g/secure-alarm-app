import 'dart:js_interop';

/// Web プラットフォーム用 JS ブリッジ
/// window.saPlay / window.saStop / window.saRequestMotion /
/// window.saGetMotion / window.saGetMouseDelta を呼び出す

@JS('saPlay')
external void _saPlay(JSNumber soundType, JSNumber volume);

@JS('saStop')
external void _saStop();

@JS('saRequestMotion')
external JSBoolean _saRequestMotion();

@JS('saGetMotion')
external JSArray<JSNumber>? _saGetMotion();

@JS('saGetMouseDelta')
external JSNumber _saGetMouseDelta();

void jsPlay(int soundType, double volume) {
  try { _saPlay(soundType.toJS, volume.toJS); } catch (_) {}
}

void jsStop() {
  try { _saStop(); } catch (_) {}
}

/// DeviceMotionリスナーを登録し、対応していれば true を返す
bool requestDeviceMotion() {
  try {
    return _saRequestMotion().toDart;
  } catch (_) {
    return false;
  }
}

/// 最新のモーション値 [x, y, z, timestamp] を返す（値がなければ null）
List<double>? getLatestMotion() {
  try {
    final arr = _saGetMotion();
    if (arr == null) return null;
    final list = arr.toDart;
    if (list.length < 4) return null;
    return [
      list[0].toDartDouble,
      list[1].toDartDouble,
      list[2].toDartDouble,
      list[3].toDartDouble,
    ];
  } catch (_) {
    return null;
  }
}

/// マウス移動デルタ（PCブラウザ代替）
double getMouseDelta() {
  try {
    return _saGetMouseDelta().toDartDouble;
  } catch (_) {
    return 0.0;
  }
}

import 'dart:js_interop';

/// Web プラットフォームで window.saPlay / window.saStop を呼び出す
@JS('saPlay')
external void _saPlay(JSNumber soundType, JSNumber volume);

@JS('saStop')
external void _saStop();

void jsPlay(int soundType, double volume) {
  try {
    _saPlay(soundType.toJS, volume.toJS);
  } catch (_) {}
}

void jsStop() {
  try {
    _saStop();
  } catch (_) {}
}

// Web専用：dart:js_interopを使ってWeb Audio APIを呼び出す
@JS()
library web_audio_bridge;

import 'package:js/js.dart';

@JS('secureAlarmPlay')
external void _jsPlay(int soundType, double volume);

@JS('secureAlarmStop')
external void _jsStop();

/// Web Audio APIをJavaScript経由で操作するクラス
class WebAudioBridge {
  /// 音を再生する（soundType: 0〜4、volume: 0.0〜1.0）
  static void play(int soundType, double volume) {
    try {
      _jsPlay(soundType, volume);
    } catch (e) {
      // ignore
    }
  }

  /// 音を停止する
  static void stop() {
    try {
      _jsStop();
    } catch (e) {
      // ignore
    }
  }
}

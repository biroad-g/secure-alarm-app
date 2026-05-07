/// スタブ（Android / iOS 用）
void jsPlay(int soundType, double volume) {}
void jsStop() {}
void jsStopSensor() {}
void jsStartSensor({
  required double sensitivity,
  required void Function(double) onAlarm,
  required void Function(double) onDelta,
}) {}

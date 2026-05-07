/// スタブ実装（モバイルプラットフォーム用）
void jsPlay(int soundType, double volume) {}
void jsStop() {}
void jsStartSensor({
  required void Function(double delta) onMotionTriggered,
  required void Function(double delta) onDeltaUpdate,
}) {}
void jsStopSensor() {}

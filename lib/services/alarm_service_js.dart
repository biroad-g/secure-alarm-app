import 'dart:js_interop';

@JS('saPlay')
external void _saPlay(JSNumber t, JSNumber v);

@JS('saStop')
external void _saStop();

@JS('saStartSensor')
external void _saStartSensor(JSNumber sensitivity, JSFunction onAlarm, JSFunction onDelta);

@JS('saStopSensor')
external void _saStopSensor();

void jsPlay(int t, double v) {
  try { _saPlay(t.toJS, v.toJS); } catch (_) {}
}

void jsStop() {
  try { _saStop(); } catch (_) {}
}

void jsStartSensor({
  required double sensitivity,
  required void Function(double) onAlarm,
  required void Function(double) onDelta,
}) {
  try {
    _saStartSensor(
      sensitivity.toJS,
      ((JSNumber d) => onAlarm(d.toDartDouble)).toJS,
      ((JSNumber d) => onDelta(d.toDartDouble)).toJS,
    );
  } catch (_) {}
}

void jsStopSensor() {
  try { _saStopSensor(); } catch (_) {}
}

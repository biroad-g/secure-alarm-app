import 'package:flutter/material.dart';

class SensitivitySlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const SensitivitySlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  // スライダーの内部値は 0.5(高感度)〜3.0(低感度)
  // 表示は「左=低感度 / 右=高感度」に見せるため、
  // 表示値 = max + min - value で反転する
  static const double _min = 0.5;
  static const double _max = 3.0;

  double get _displayValue => _max + _min - value; // 反転した表示用値

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune,
                      color: Colors.white.withValues(alpha: 0.85), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '検知感度',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _sensitivityLabel(value),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.orangeAccent,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
              thumbColor: Colors.white,
              overlayColor: Colors.orangeAccent.withValues(alpha: 0.2),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 10),
              trackHeight: 6,
            ),
            child: Slider(
              // 表示値（反転済み）でスライダーを描画
              value: _displayValue,
              min: _min,
              max: _max,
              divisions: 25,
              // ユーザーが動かしたら反転して実際の感度値に変換して返す
              onChanged: (displayVal) {
                final actualVal = _max + _min - displayVal;
                onChanged(actualVal);
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 左=低感度、右=高感度
              Text(
                '低感度',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
              Text(
                '高感度',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '閾値: ${value.toStringAsFixed(1)} m/s²  ─  右にするほど敏感に反応します',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _sensitivityLabel(double v) {
    // v が小さい = 高感度
    if (v <= 0.8) return '最高感度';
    if (v <= 1.3) return '高感度';
    if (v <= 1.8) return '標準';
    if (v <= 2.4) return '低感度';
    return '最低感度';
  }
}

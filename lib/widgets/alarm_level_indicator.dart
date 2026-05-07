import 'package:flutter/material.dart';
import '../models/alarm_state.dart';

class AlarmLevelIndicator extends StatelessWidget {
  final AlarmStateModel state;
  const AlarmLevelIndicator({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final level = state.level.index2;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.volume_up,
                  color: Colors.white.withValues(alpha: 0.85), size: 18),
              const SizedBox(width: 8),
              Text(
                'アラームレベル',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isActive = level > index;
              final barLevel = index + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  width: 32,
                  height: 24.0 + (barLevel * 10.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isActive
                        ? _barColor(barLevel)
                        : Colors.white.withValues(alpha: 0.15),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _barColor(barLevel).withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : [],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              level == 0 ? '待機中' : state.level.label,
              key: ValueKey(level),
              style: TextStyle(
                color: level == 0
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (level > 0) ...[
            const SizedBox(height: 8),
            Text(
              '音量: ${(state.level.volume * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _barColor(int level) {
    switch (level) {
      case 1:
        return Colors.greenAccent;
      case 2:
        return Colors.lightGreenAccent;
      case 3:
        return Colors.yellowAccent;
      case 4:
        return Colors.orangeAccent;
      case 5:
        return Colors.redAccent;
      default:
        return Colors.white;
    }
  }
}

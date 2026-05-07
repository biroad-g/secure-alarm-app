import 'package:flutter/material.dart';
import '../models/alarm_state.dart';

class StatusDisplay extends StatelessWidget {
  final AlarmStateModel state;
  const StatusDisplay({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: _getStatusColor(state.status).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor(state.status).withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusIcon(state.status),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusTitle(state.status),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getStatusSubtitle(state.status),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(AlarmStatus status) {
    if (status == AlarmStatus.alarming) {
      return const _PulseIcon(
        icon: Icons.warning_amber_rounded,
        color: Colors.orangeAccent,
        size: 36,
      );
    }
    return Icon(
      _getStatusIconData(status),
      color: _getStatusColor(status),
      size: 36,
    );
  }

  IconData _getStatusIconData(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.standby:    return Icons.pause_circle_outline;
      case AlarmStatus.monitoring: return Icons.remove_red_eye;
      case AlarmStatus.detected:   return Icons.sensors;
      case AlarmStatus.alarming:   return Icons.warning_amber_rounded;
    }
  }

  Color _getStatusColor(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.standby:    return Colors.grey;
      case AlarmStatus.monitoring: return Colors.greenAccent;
      case AlarmStatus.detected:   return Colors.orangeAccent;
      case AlarmStatus.alarming:   return Colors.redAccent;
    }
  }

  String _getStatusTitle(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.standby:    return '待機中';
      case AlarmStatus.monitoring: return '監視中';
      case AlarmStatus.detected:   return '動き検知！';
      case AlarmStatus.alarming:   return 'アラーム発動中！';
    }
  }

  String _getStatusSubtitle(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.standby:    return '盗難防止モードをONにしてください';
      case AlarmStatus.monitoring: return '振動を検知するとアラームが鳴ります';
      case AlarmStatus.detected:   return '振動を検知しました';
      case AlarmStatus.alarming:   return '不審な動きを検知しました！';
    }
  }
}

// 点滅アニメーションアイコン
class _PulseIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  const _PulseIcon({required this.icon, required this.color, required this.size});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.6, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Icon(widget.icon, color: widget.color, size: widget.size),
    );
  }
}

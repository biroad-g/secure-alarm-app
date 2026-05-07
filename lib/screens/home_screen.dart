import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/alarm_service.dart';
import '../models/alarm_state.dart';
import '../widgets/protection_toggle.dart';
import '../widgets/alarm_level_indicator.dart';
import '../widgets/sensitivity_slider.dart';
import '../widgets/status_display.dart';
import '../widgets/stop_alarm_button.dart';
import '../widgets/sound_test_panel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmService>(
      builder: (context, service, child) {
        final state = service.state;
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: _buildGradient(state),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── ヘッダー ──
                    _buildHeader(state),
                    const SizedBox(height: 16),

                    // ── ステータス表示 ──
                    StatusDisplay(state: state),
                    const SizedBox(height: 16),

                    // ── シールドアイコン ──
                    Center(child: _buildShieldIcon(state)),
                    const SizedBox(height: 16),

                    // ── アラームレベルインジケーター ──
                    AlarmLevelIndicator(state: state),
                    const SizedBox(height: 16),

                    // ── アラーム停止ボタン（アラーム中のみ） ──
                    if (state.status == AlarmStatus.alarming) ...[
                      StopAlarmButton(
                          onStop: () => service.stopAlarm()),
                      const SizedBox(height: 16),
                    ],

                    // ── 盗難防止モード ON/OFF ──
                    if (state.status != AlarmStatus.alarming) ...[
                      ProtectionToggle(
                        isEnabled: state.isProtectionEnabled,
                        onChanged: (val) async {
                          if (val) {
                            await service.enableProtection();
                          } else {
                            await service.disableProtection();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 検知感度スライダー（待機中・監視中のみ） ──
                    if (state.status != AlarmStatus.alarming) ...[
                      SensitivitySlider(
                        value: state.sensitivity,
                        onChanged: service.setSensitivity,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 振動センサー表示（監視中・アラーム中） ──
                    if (state.isProtectionEnabled) ...[
                      _buildAccelerometerDisplay(state),
                      const SizedBox(height: 16),
                    ],

                    // ── テスト音パネル（待機中・監視中のみ） ──
                    if (state.status != AlarmStatus.alarming) ...[
                      SoundTestPanel(service: service),
                      const SizedBox(height: 16),
                    ],

                    // ── 使い方 ──
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  LinearGradient _buildGradient(AlarmStateModel state) {
    if (state.status == AlarmStatus.alarming) {
      final intensity = (state.level.index2 / 5.0).clamp(0.0, 1.0);
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(
              const Color(0xFF8B0000), const Color(0xFFFF0000), intensity)!,
          Color.lerp(
              const Color(0xFFFF4500), const Color(0xFFFF6B00), intensity)!,
        ],
      );
    } else if (state.status == AlarmStatus.monitoring) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6A1B9A), Color(0xFFE65100)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
      );
    }
  }

  Widget _buildHeader(AlarmStateModel state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Secure Alarm',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '盗難防止システム',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            state.isProtectionEnabled
                ? Icons.security
                : Icons.security_outlined,
            color: Colors.white,
            size: 26,
          ),
        ),
      ],
    );
  }

  Widget _buildShieldIcon(AlarmStateModel state) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.05),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: state.status == AlarmStatus.alarming ? scale : 1.0,
          child: child,
        );
      },
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          _getShieldIcon(state.status),
          size: 72,
          color: Colors.white,
        ),
      ),
    );
  }

  IconData _getShieldIcon(AlarmStatus status) {
    switch (status) {
      case AlarmStatus.standby:
        return Icons.shield_outlined;
      case AlarmStatus.monitoring:
        return Icons.shield;
      case AlarmStatus.detected:
        return Icons.warning_rounded;
      case AlarmStatus.alarming:
        return Icons.warning_amber_rounded;
    }
  }

  Widget _buildAccelerometerDisplay(AlarmStateModel state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sensors,
                  color: Colors.white.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 6),
              Text(
                '振動センサー',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMeterBar(state.currentAcceleration, state.sensitivity),
              Column(
                children: [
                  Text(
                    state.currentAcceleration.toStringAsFixed(2),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'm/s²',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '閾値: ${state.sensitivity.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeterBar(double current, double threshold) {
    final ratio = (current / (threshold * 2)).clamp(0.0, 1.0);
    return SizedBox(
      width: 36,
      height: 72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 36,
            height: 72 * ratio,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.greenAccent,
                  ratio > 0.7 ? Colors.redAccent : Colors.orangeAccent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  color: Colors.white.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 6),
              Text(
                '使い方',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.toggle_on_outlined, '盗難防止モードをONにして起動'),
          _buildInfoRow(Icons.phone_android, 'スマホを置いてその場を離れる'),
          _buildInfoRow(Icons.vibration, '動きを検知すると自動でアラーム発動'),
          _buildInfoRow(Icons.volume_up, '3秒ごとに音量が段階的に増加（5段階）'),
          _buildInfoRow(Icons.stop_circle_outlined, 'アラーム停止ボタンで解除'),
          _buildInfoRow(Icons.music_note, '▶️ボタンで試し聴き後、好みの音を選択'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.65), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/alarm_service.dart';
import '../models/alarm_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AlarmService>(
      builder: (context, svc, _) {
        final s = svc.state;
        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(gradient: _gradient(s)),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(s: s),
                    const SizedBox(height: 14),
                    _StatusCard(s: s),
                    const SizedBox(height: 14),
                    _ShieldIcon(s: s),
                    const SizedBox(height: 14),

                    // ── アラームレベルバー（常に表示・状態反映）──
                    _LevelBar(s: s),
                    const SizedBox(height: 14),

                    // アラーム停止ボタン
                    if (s.isAlarming) ...[
                      _StopButton(onTap: () => svc.stopAlarm()),
                      const SizedBox(height: 14),
                    ],

                    // 防犯モード ON/OFF
                    if (!s.isAlarming)
                      _ToggleButton(
                        isOn: s.isActive,
                        onTap: () => s.isActive ? svc.disable() : svc.enable(),
                      ),
                    const SizedBox(height: 14),

                    // 感度スライダー（防犯モードOFF or 監視中のみ）
                    if (!s.isAlarming) ...[
                      _SensSlider(value: s.sensitivity, onChange: svc.setSensitivity),
                      const SizedBox(height: 14),
                    ],

                    // 振動センサー表示（監視中・アラーム中）
                    if (s.isActive) ...[
                      _SensorDisplay(s: s, webSensorActive: svc.webSensorActive),
                      const SizedBox(height: 14),
                    ],

                    // サウンドテストパネル
                    _SoundPanel(svc: svc),
                    const SizedBox(height: 14),

                    _InfoCard(),
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

  LinearGradient _gradient(AppState s) {
    if (s.isAlarming) {
      final t = (s.level.step / 5.0).clamp(0.0, 1.0);
      return LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [
          Color.lerp(const Color(0xFF8B0000), const Color(0xFFFF0000), t)!,
          Color.lerp(const Color(0xFFCC3300), const Color(0xFFFF6600), t)!,
        ],
      );
    } else if (s.status == AlarmStatus.monitoring) {
      return const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [Color(0xFF1A237E), Color(0xFF6A1B9A)],
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
    );
  }
}

// ── ヘッダー ──────────────────────────────────
class _Header extends StatelessWidget {
  final AppState s;
  const _Header({required this.s});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Secure Alarm',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.95),
            fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        Text('盗難防止システム',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
      ]),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          s.isActive ? Icons.security : Icons.security_outlined,
          color: Colors.white, size: 26,
        ),
      ),
    ],
  );
}

// ── ステータスカード ──────────────────────────
class _StatusCard extends StatelessWidget {
  final AppState s;
  const _StatusCard({required this.s});
  @override
  Widget build(BuildContext context) {
    final (color, icon, title, sub) = switch (s.status) {
      AlarmStatus.standby    => (Colors.grey, Icons.pause_circle_outline, '待機中', '防犯モードをONにしてください'),
      AlarmStatus.monitoring => (Colors.greenAccent, Icons.remove_red_eye, '🛡️ 監視中', '振動を検知するとアラームが鳴ります'),
      AlarmStatus.alarming   => (Colors.redAccent, Icons.warning_amber_rounded, '🚨 アラーム発動中！', '不審な動きを検知しました！'),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 34),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
          Text(sub,   style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 12)),
        ])),
      ]),
    );
  }
}

// ── シールドアイコン ──────────────────────────
class _ShieldIcon extends StatelessWidget {
  final AppState s;
  const _ShieldIcon({required this.s});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 110, height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 18)],
      ),
      child: Icon(
        switch (s.status) {
          AlarmStatus.standby    => Icons.shield_outlined,
          AlarmStatus.monitoring => Icons.shield,
          AlarmStatus.alarming   => Icons.warning_amber_rounded,
        },
        size: 62, color: Colors.white,
      ),
    ),
  );
}

// ── アラームレベルバー（改良版）─────────────
class _LevelBar extends StatelessWidget {
  final AppState s;
  const _LevelBar({required this.s});

  Color _barColor(int idx) => switch (idx) {
    0 => Colors.greenAccent,
    1 => Colors.lightGreenAccent,
    2 => Colors.yellowAccent,
    3 => Colors.orangeAccent,
    _ => Colors.redAccent,
  };

  @override
  Widget build(BuildContext context) {
    final lv = s.level.step; // 0〜5
    return _Card(child: Column(children: [
      // タイトル行
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.volume_up, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 6),
          Text('アラームレベル',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        // 音量バッジ（アラーム中のみ）
        if (lv > 0)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _barColor(lv - 1).withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _barColor(lv - 1).withValues(alpha: 0.8), width: 1.5),
            ),
            child: Text('音量 ${(s.level.volume * 100).toInt()}%',
              style: TextStyle(color: _barColor(lv - 1), fontSize: 13, fontWeight: FontWeight.bold)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('停止中',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          ),
      ]),
      const SizedBox(height: 16),

      // 5本のバー（高さが左から右に増加）
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (i) {
          final on = lv > i;
          final barH = 28.0 + i * 12.0; // 28, 40, 52, 64, 76
          final col = _barColor(i);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // バー本体
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 34, height: barH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: on ? col : Colors.white.withValues(alpha: 0.12),
                    boxShadow: on ? [BoxShadow(color: col.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)] : [],
                  ),
                ),
                const SizedBox(height: 6),
                // レベル番号
                Text('Lv${i + 1}',
                  style: TextStyle(
                    color: on ? col : Colors.white.withValues(alpha: 0.35),
                    fontSize: 11, fontWeight: on ? FontWeight.bold : FontWeight.normal,
                  )),
              ],
            ),
          );
        }),
      ),
      const SizedBox(height: 12),

      // 状態テキスト
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: lv == 0
          ? Text('センサー待機中 — 防犯モードをONにすると監視開始',
              key: const ValueKey('off'),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 12))
          : Row(
              key: ValueKey(lv),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.graphic_eq, color: _barColor(lv - 1), size: 16),
                const SizedBox(width: 6),
                Text('レベル $lv  ／  音量 ${(s.level.volume * 100).toInt()}%  — 3秒ごとに上昇',
                  style: TextStyle(color: _barColor(lv - 1), fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
      ),
    ]));
  }
}

// ── アラーム停止ボタン ────────────────────────
class _StopButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StopButton({required this.onTap});
  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.stop_circle_outlined, size: 26),
    label: const Text('アラームを停止する', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
    ),
  );
}

// ── ON/OFF トグルボタン ───────────────────────
class _ToggleButton extends StatelessWidget {
  final bool isOn;
  final VoidCallback onTap;
  const _ToggleButton({required this.isOn, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: isOn
          ? const LinearGradient(colors: [Color(0xFF00C853), Color(0xFF1B5E20)])
          : LinearGradient(colors: [Colors.white.withValues(alpha: 0.12), Colors.white.withValues(alpha: 0.05)]),
        border: Border.all(
          color: isOn ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(isOn ? Icons.lock : Icons.lock_open, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isOn ? '防犯モード ON' : '防犯モード OFF',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(isOn ? 'タップして無効化' : 'タップして有効化',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
          ]),
        ]),
        Switch(
          value: isOn, onChanged: (_) => onTap(),
          activeThumbColor: Colors.white,
          activeTrackColor: Colors.greenAccent.withValues(alpha: 0.5),
          inactiveThumbColor: Colors.white60,
          inactiveTrackColor: Colors.white24,
        ),
      ]),
    ),
  );
}

// ── 感度スライダー ────────────────────────────
class _SensSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChange;
  const _SensSlider({required this.value, required this.onChange});

  double get _disp => 3.5 - value;

  String get _label {
    if (value <= 0.8) return '最高感度';
    if (value <= 1.2) return '高感度';
    if (value <= 1.8) return '標準';
    if (value <= 2.4) return '低感度';
    return '最低感度';
  }

  @override
  Widget build(BuildContext context) => _Card(child: Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Row(children: [
        Icon(Icons.tune, color: Colors.white.withValues(alpha: 0.85), size: 18),
        const SizedBox(width: 8),
        Text('検知感度', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14, fontWeight: FontWeight.w600)),
      ]),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
        child: Text(_label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    ]),
    const SizedBox(height: 8),
    SliderTheme(
      data: SliderThemeData(
        activeTrackColor: Colors.orangeAccent,
        inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
        thumbColor: Colors.white,
        overlayColor: Colors.orangeAccent.withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        trackHeight: 6,
      ),
      child: Slider(
        value: _disp, min: 0.5, max: 3.0, divisions: 25,
        onChanged: (v) => onChange(3.5 - v),
      ),
    ),
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text('低感度', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
      Text('高感度', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
    ]),
    const SizedBox(height: 4),
    Text('閾値: ${value.toStringAsFixed(1)} m/s²',
      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
  ]));
}

// ── 振動センサー表示（改良版）─────────────────
class _SensorDisplay extends StatelessWidget {
  final AppState s;
  final bool webSensorActive;
  const _SensorDisplay({required this.s, required this.webSensorActive});

  @override
  Widget build(BuildContext context) {
    final ratio = (s.currentDelta / (s.sensitivity * 1.5)).clamp(0.0, 1.0);
    final overThreshold = s.currentDelta > s.sensitivity;

    return _Card(child: Column(children: [
      // タイトル
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(Icons.sensors, color: Colors.white.withValues(alpha: 0.8), size: 18),
          const SizedBox(width: 6),
          Text('振動センサー', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        // センサー状態バッジ
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (kIsWeb ? webSensorActive : true)
              ? Colors.greenAccent.withValues(alpha: 0.2)
              : Colors.orangeAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (kIsWeb ? webSensorActive : true)
                ? Colors.greenAccent.withValues(alpha: 0.7)
                : Colors.orangeAccent.withValues(alpha: 0.7),
            ),
          ),
          child: Text(
            kIsWeb
              ? (webSensorActive ? '✅ センサーON' : '⏳ 待機中')
              : '✅ センサーON',
            style: TextStyle(
              color: (kIsWeb ? webSensorActive : true) ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 11, fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ]),
      const SizedBox(height: 14),

      // メーター + 数値
      Row(children: [
        // 縦型バーメーター
        SizedBox(width: 36, height: 80,
          child: Stack(children: [
            Container(decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.1),
            )),
            Align(alignment: Alignment.bottomCenter,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 100),
                heightFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: overThreshold
                        ? [Colors.redAccent, Colors.orangeAccent]
                        : [Colors.greenAccent, Colors.tealAccent],
                    ),
                  ),
                ),
              ),
            ),
            // 閾値ライン
            Positioned(
              bottom: 80 / 1.5 * 1, // sensitivity位置
              left: 0, right: 0,
              child: Container(height: 2,
                color: Colors.white.withValues(alpha: 0.6)),
            ),
          ]),
        ),
        const SizedBox(width: 16),

        // 数値情報
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // 現在値
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 80),
              child: Text(s.currentDelta.toStringAsFixed(2),
                key: ValueKey(s.currentDelta.toStringAsFixed(1)),
                style: TextStyle(
                  color: overThreshold ? Colors.redAccent : Colors.white,
                  fontSize: 32, fontWeight: FontWeight.bold,
                )),
            ),
            const SizedBox(width: 4),
            Text('m/s²', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
          ]),
          const SizedBox(height: 6),
          // 閾値
          Row(children: [
            Icon(Icons.horizontal_rule, color: Colors.white.withValues(alpha: 0.5), size: 14),
            const SizedBox(width: 4),
            Text('閾値: ${s.sensitivity.toStringAsFixed(1)} m/s²',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          // 状態インジケーター
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: overThreshold
                ? Colors.redAccent.withValues(alpha: 0.25)
                : Colors.greenAccent.withValues(alpha: 0.15),
            ),
            child: Text(
              overThreshold ? '⚠️ 閾値超過！アラーム発動' : '✅ 正常範囲内',
              style: TextStyle(
                color: overThreshold ? Colors.redAccent : Colors.greenAccent,
                fontSize: 11, fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ])),
      ]),

      // Webブラウザ向け注意書き
      if (kIsWeb && !webSensorActive) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.4)),
          ),
          child: const Row(children: [
            Icon(Icons.phone_android, color: Colors.orangeAccent, size: 16),
            SizedBox(width: 8),
            Expanded(child: Text(
              'スマートフォンのブラウザで開くと振動センサーが使えます\nPCでは画面を動かして代わりにテストできます',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11),
            )),
          ]),
        ),
      ],
    ]));
  }
}

// ── サウンドテストパネル ──────────────────────
class _SoundPanel extends StatefulWidget {
  final AlarmService svc;
  const _SoundPanel({required this.svc});
  @override
  State<_SoundPanel> createState() => _SoundPanelState();
}

class _SoundPanelState extends State<_SoundPanel> {
  int _playing = -1;

  void _play(int i) {
    widget.svc.playTest(i);
    setState(() => _playing = i);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _playing = -1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.svc.state.selectedSound;
    return _Card(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.music_note, color: Colors.white.withValues(alpha: 0.85), size: 18),
          const SizedBox(width: 8),
          Text('アラーム音テスト（5種類）',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        Text('▶ を押して試し聴き → 行をタップして選択',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11)),
        const SizedBox(height: 12),
        ...List.generate(AlarmService.sounds.length, (i) {
          final isOn = sel == i;
          final isPlaying = _playing == i;
          return GestureDetector(
            onTap: () => widget.svc.selectSound(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isOn ? Colors.orangeAccent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isOn ? Colors.orangeAccent.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.15),
                  width: isOn ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isOn ? Colors.orangeAccent : Colors.white38, width: 2),
                    color: isOn ? Colors.orangeAccent : Colors.transparent,
                  ),
                  child: isOn ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(AlarmService.sounds[i]['name']!,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: isOn ? FontWeight.bold : FontWeight.normal)),
                  Text(AlarmService.sounds[i]['desc']!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10)),
                ])),
                GestureDetector(
                  onTap: () => _play(i),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPlaying
                        ? Colors.greenAccent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      isPlaying ? Icons.volume_up : Icons.play_arrow,
                      color: isPlaying ? Colors.greenAccent : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ]),
            ),
          );
        }),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.35)),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, color: Colors.orangeAccent, size: 14),
            SizedBox(width: 8),
            Expanded(child: Text('選択した音がアラーム発動時に使用されます',
              style: TextStyle(color: Colors.orangeAccent, fontSize: 11))),
          ]),
        ),
      ],
    ));
  }
}

// ── 使い方カード ──────────────────────────────
class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _Card(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(Icons.info_outline, color: Colors.white.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 6),
        Text('使い方', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      _row(Icons.toggle_on_outlined,  '防犯モードをONにして起動'),
      _row(Icons.phone_android,       'スマホを置いてその場を離れる'),
      _row(Icons.vibration,           '動きを検知→自動でアラーム発動'),
      _row(Icons.volume_up,           '3秒ごとに音量が5段階で増加'),
      _row(Icons.stop_circle_outlined,'停止ボタンでアラームを解除'),
      _row(Icons.music_note,          '▶ボタンで試し聴き→好みの音を選択'),
      if (kIsWeb) _row(Icons.language, 'スマートフォンのブラウザで振動センサーが動作します'),
    ],
  ));

  Widget _row(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(children: [
      Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 14),
      const SizedBox(width: 6),
      Expanded(child: Text(text, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11))),
    ]),
  );
}

// ── 共通カード ────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: child,
  );
}

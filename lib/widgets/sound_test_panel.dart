import 'package:flutter/material.dart';
import '../services/alarm_service.dart';

class SoundTestPanel extends StatelessWidget {
  final AlarmService service;
  const SoundTestPanel({super.key, required this.service});

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
          // ヘッダー
          Row(
            children: [
              Icon(Icons.music_note,
                  color: Colors.white.withValues(alpha: 0.85), size: 18),
              const SizedBox(width: 8),
              Text(
                'アラーム音テスト（5種類）',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'タップして試し聴き → 使いたい音を選択してください',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 14),

          // 5つのサウンドボタン
          ...List.generate(AlarmService.soundTypes.length, (index) {
            final sound = AlarmService.soundTypes[index];
            final isSelected = service.selectedSoundType == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SoundButton(
                soundId: index,
                icon: sound['icon'] as String,
                name: sound['name'] as String,
                desc: sound['desc'] as String,
                isSelected: isSelected,
                onPlay: () => service.playTestSound(index),
                onSelect: () => service.selectSoundType(index),
              ),
            );
          }),

          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.orangeAccent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.orangeAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '選択した音がアラーム発動時に使用されます',
                    style: TextStyle(
                      color: Colors.orangeAccent.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundButton extends StatefulWidget {
  final int soundId;
  final String icon;
  final String name;
  final String desc;
  final bool isSelected;
  final VoidCallback onPlay;
  final VoidCallback onSelect;

  const _SoundButton({
    required this.soundId,
    required this.icon,
    required this.name,
    required this.desc,
    required this.isSelected,
    required this.onPlay,
    required this.onSelect,
  });

  @override
  State<_SoundButton> createState() => _SoundButtonState();
}

class _SoundButtonState extends State<_SoundButton> {
  bool _isPlaying = false;

  void _handlePlay() {
    setState(() => _isPlaying = true);
    widget.onPlay();
    // 2秒後に再生中フラグをリセット
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: widget.isSelected
            ? Colors.orangeAccent.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        border: Border.all(
          color: widget.isSelected
              ? Colors.orangeAccent.withValues(alpha: 0.7)
              : Colors.white.withValues(alpha: 0.15),
          width: widget.isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // ラジオ選択部分
          GestureDetector(
            onTap: widget.onSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.isSelected
                            ? Colors.orangeAccent
                            : Colors.white38,
                        width: 2,
                      ),
                      color: widget.isSelected
                          ? Colors.orangeAccent
                          : Colors.transparent,
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 12)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Text(widget.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: TextStyle(
                          color: widget.isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: widget.isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        widget.desc,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // 再生ボタン
          GestureDetector(
            onTap: _isPlaying ? null : _handlePlay,
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isPlaying
                    ? Colors.greenAccent.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.15),
              ),
              child: Icon(
                _isPlaying ? Icons.volume_up : Icons.play_arrow,
                color: _isPlaying ? Colors.greenAccent : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

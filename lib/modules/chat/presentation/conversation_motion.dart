part of 'conversation_screen.dart';

class _VoicePreview extends StatefulWidget {
  const _VoicePreview({required this.duration});
  final String duration;
  @override
  State<_VoicePreview> createState() => _VoicePreviewState();
}

class _VoicePreviewState extends State<_VoicePreview>
    with SingleTickerProviderStateMixin {
  late final clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  static const bars = [
    8,
    14,
    20,
    12,
    24,
    18,
    10,
    22,
    16,
    26,
    12,
    8,
    18,
    22,
    14,
    10,
    20,
    24,
    12,
    16,
    10,
    6,
  ];
  bool playing = false;
  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    spacing: 8,
    children: [
      IconButton.filled(
        tooltip: context.tr(
          playing ? 'chat.pause_voice_message' : 'chat.play_voice_message',
        ),
        icon: Icon(playing ? TmsIcons.pause : TmsIcons.play),
        onPressed: () => setState(() {
          playing = !playing;
          if (playing && !MediaQuery.disableAnimationsOf(context)) {
            clock.repeat();
          } else {
            clock.stop();
          }
        }),
      ),
      Expanded(
        child: AnimatedBuilder(
          animation: clock,
          builder: (_, _) => SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final (i, h) in bars.indexed)
                  Flexible(
                    child: Container(
                      width: 3,
                      height:
                          h *
                          (playing
                              ? 0.7 +
                                    .3 *
                                        math.cos(
                                          2 *
                                              math.pi *
                                              (clock.value - i % 6 * .1),
                                        )
                              : 1.0),
                      decoration: BoxDecoration(
                        color: playing ? context.lavender : context.muted,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      DesignLabel(widget.duration),
    ],
  );
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      clock.stop();
    } else if (!clock.isAnimating) {
      clock.repeat();
    }
  }

  @override
  void dispose() {
    clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('chat.typing'),
    child: AnimatedBuilder(
      animation: clock,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          for (var i = 0; i < 3; i++)
            Transform.translate(
              offset: Offset(
                0,
                -4 *
                    math
                        .pow(math.sin(math.pi * (clock.value - i * .15)), 2)
                        .toDouble(),
              ),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: context.muted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

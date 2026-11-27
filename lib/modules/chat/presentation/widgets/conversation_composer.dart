part of '../conversation_screen.dart';

class _ConversationComposer extends StatelessWidget {
  const _ConversationComposer({
    required this.input,
    required this.firstName,
    required this.send,
  });
  final TextEditingController input;
  final String firstName;
  final VoidCallback send;
  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: context.outline),
    );
    return Container(
      decoration: BoxDecoration(
        color: context.background,
        border: Border(
          top: BorderSide(color: context.outline.withValues(alpha: .08)),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        spacing: 8,
        children: [
          Tooltip(
            message: context.tr('chat.attach_action'),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(TmsIcons.add, size: 20),
            ),
          ),
          Expanded(
            child: TextField(
              controller: input,
              onSubmitted: (_) => send(),
              textInputAction: TextInputAction.send,
              style: const TextStyle(fontSize: 15, letterSpacing: 0),
              decoration: InputDecoration(
                hintText: context.tr(
                  'chat.message_person',
                  namedArgs: {'name': firstName},
                ),
                hintStyle: TextStyle(
                  color: context.muted,
                  fontSize: 14,
                  letterSpacing: 0,
                ),
                isDense: true,
                filled: true,
                fillColor: context.panel,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                enabledBorder: border,
                focusedBorder: border.copyWith(
                  borderSide: const BorderSide(color: DesignColor.purple),
                ),
              ),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: input,
            builder: (_, value, _) {
              if (value.text.trim().isNotEmpty) {
                return IconButton.filled(
                  tooltip: context.tr('chat.send'),
                  onPressed: send,
                  icon: const Icon(TmsIcons.send, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: DesignColor.purple,
                    foregroundColor: DesignColor.ink,
                  ),
                );
              }
              return Tooltip(
                message: context.tr('chat.record_voice_message'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.panel,
                    border: Border.all(color: context.outline),
                  ),
                  child: const Icon(TmsIcons.microphone, size: 19),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

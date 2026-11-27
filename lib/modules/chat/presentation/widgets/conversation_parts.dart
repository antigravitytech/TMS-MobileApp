part of '../conversation_screen.dart';

/// Back button, avatar, name and an optional status line (typing, online).
class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader({
    required this.peer,
    this.status,
    this.call = true,
  });
  final ChatRow peer;
  final String? status;

  /// Calls have no backend yet, so server threads leave the button out.
  final bool call;

  @override
  Widget build(BuildContext context) => Container(
    color: context.background,
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
    child: Row(
      spacing: 10,
      children: [
        IconButton(
          icon: const Icon(TmsIcons.chevronBack, size: 18),
          tooltip: context.tr('common.back'),
          onPressed: () async {
            if (!await context.router.maybePop() && context.mounted) {
              TmsRoute.chat.reset(context);
            }
          },
        ),
        ChatAvatar(peer, size: 36),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                peer.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (status case final text?)
                Text(
                  text,
                  style: const TextStyle(
                    color: DesignColor.green,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        if (call)
          Tooltip(
            message: context.tr('chat.voice_call'),
            child: const SizedBox.square(
              dimension: 44,
              child: Icon(TmsIcons.phone, size: 19),
            ),
          ),
      ],
    ),
  );
}

/// A chat bubble: mine on the right, theirs on the left.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.child, this.mine = false});
  final Widget child;
  final bool mine;

  @override
  Widget build(BuildContext context) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(
        maxWidth: (MediaQuery.sizeOf(context).width - 40) * .78,
      ),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine
            ? (context.dark ? const Color(0xff3b3a57) : const Color(0xffe6e2ff))
            : context.panel,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: Radius.circular(mine ? 20 : 6),
          bottomRight: Radius.circular(mine ? 6 : 20),
        ),
      ),
      child: child,
    ),
  );
}

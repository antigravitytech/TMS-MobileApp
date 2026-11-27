part of '../conversation_screen.dart';

/// A server conversation: the latest messages, polled while open, with
/// send and a ❤️ reaction on long press.
class _LiveThread extends ConsumerStatefulWidget {
  const _LiveThread({super.key, required this.peer});
  final ChatRow peer;
  @override
  ConsumerState<_LiveThread> createState() => _LiveThreadState();
}

class _LiveThreadState extends ConsumerState<_LiveThread> {
  final input = TextEditingController();
  final scroll = ScrollController();
  var sending = false;

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void scrollToLatest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scroll.hasClients) scroll.jumpTo(scroll.position.maxScrollExtent);
  });

  Future<void> act(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (mounted) designToast(context, chatErrorMessage(context, error));
    }
  }

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    await act(() async {
      await ref.read(chatThreadProvider(widget.peer.id).notifier).send(text);
      input.clear();
      scrollToLatest();
    });
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final provider = chatThreadProvider(widget.peer.id);
    final thread = ref.watch(provider);
    ref.listen(provider.select((t) => t.value?.lastOrNull?.id), (old, next) {
      if (next != old) scrollToLatest();
    });
    final locale = context.locale.toString();
    final bg = context.dark ? const Color(0xff11121b) : const Color(0xffeef0f7);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _ConversationHeader(peer: widget.peer, call: false),
            Expanded(
              child: switch (thread) {
                AsyncValue(value: final messages?) => ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  children: [
                    if (messages.isEmpty)
                      Center(child: DesignLabel(context.tr('chat.say_hello'))),
                    for (final (i, m) in messages.indexed) ...[
                      if (i == 0 ||
                          !DateUtils.isSameDay(messages[i - 1].at, m.at)) ...[
                        Center(
                          child: DesignLabel(
                            DateUtils.isSameDay(m.at, DateTime.now())
                                ? context.tr('common.today')
                                : DateFormat.MMMEd(locale).format(m.at),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (m.system)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Center(child: DesignLabel(m.body)),
                        )
                      else
                        GestureDetector(
                          onLongPress: () => act(
                            () => ref.read(provider.notifier).toggleHeart(m),
                          ),
                          child: _Bubble(
                            mine: m.mine,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 2,
                              children: [
                                if (!m.mine && m.sender.isNotEmpty)
                                  Text(
                                    m.sender,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: context.lavender,
                                    ),
                                  ),
                                Text(m.body),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      DateFormat.Hm(locale).format(m.at),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.muted,
                                      ),
                                    ),
                                    if (m.hearts > 0) ...[
                                      Icon(
                                        TmsIcons.heart,
                                        size: 14,
                                        color: m.hearted
                                            ? DesignColor.red
                                            : context.muted,
                                      ),
                                      if (m.hearts > 1)
                                        Text(
                                          '${m.hearts}',
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
                AsyncValue(:final error?) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      DesignLabel(chatErrorMessage(context, error)),
                      DesignButton(
                        context.tr('workspaces.try_again'),
                        secondary: true,
                        onPressed: () => ref.invalidate(provider),
                      ),
                    ],
                  ),
                ),
                _ => const Center(child: CircularProgressIndicator()),
              },
            ),
            _ConversationComposer(
              input: input,
              firstName: widget.peer.name.split(' ').first,
              send: send,
            ),
          ],
        ),
      ),
    );
  }
}

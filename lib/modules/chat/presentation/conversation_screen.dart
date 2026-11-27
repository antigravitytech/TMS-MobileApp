import 'dart:math' as math;

import '../../../shared/kit/kit.dart';
import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/chat_session.dart';
import '../data/chat_directory.dart';
import 'widgets/chat_widgets.dart';

part 'widgets/conversation_motion.dart';
part 'widgets/conversation_composer.dart';

class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(chatDirectoryProvider)
      .when(
        data: (d) => _Thread(key: ValueKey(d.workspace), directory: d),
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => Scaffold(
          body: Center(
            child: DesignButton(
              context.tr('workspaces.try_again'),
              onPressed: () => ref.invalidate(chatDirectoryProvider),
            ),
          ),
        ),
      );
}

class _Thread extends ConsumerStatefulWidget {
  const _Thread({super.key, required this.directory});
  final ChatDirectory directory;
  @override
  ConsumerState<_Thread> createState() => _ThreadState();
}

class _ThreadState extends ConsumerState<_Thread> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final reactions = <int>{};
  bool voiceReaction = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration:
              DesignMotion.duration(context, DesignMotion.fast) == Duration.zero
              ? const Duration(milliseconds: 1)
              : DesignMotion.fast,
          curve: DesignMotion.curve,
        );
      }
    });
  }

  void cardAction() {
    final kind = widget.directory.kind;
    if (kind == WorkspaceKind.business) {
      final preview = ref.read(workspacePreviewProvider);
      final task = preview.tasks.where((t) => t.id == 'TK-142').firstOrNull;
      if (task != null) {
        preview.selectTask(task);
        TmsRoute.task.open(context);
      }
    } else if (kind == WorkspaceKind.family) {
      WorkspaceSection.school.open(context);
    } else if (kind == WorkspaceKind.individual) {
      WorkspaceSection.gigs.open(context);
    } else {
      TmsRoute.home.open(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.directory;
    final provider = chatSessionProvider(book.workspace);
    final session = ref.watch(provider);
    final peer = session.selected ?? book.example?.peer.row;
    if (peer == null) {
      return DesignPage(
        title: context.tr('common.chat'),
        children: [DesignLabel(context.tr('chat.empty_space'))],
      );
    }
    final example =
        peer.name == book.example?.peer.row.name ||
            peer.name == book.task.firstOrNull
        ? book.example
        : null;
    final legacy =
        book.kind == WorkspaceKind.business &&
        peer.name == book.example?.peer.row.name;
    final sent = legacy
        ? ref.watch(workspacePreviewProvider.select((p) => p.messages.toList()))
        : session.messages[peer.name] ?? const <String>[];
    final typing = session.typing.contains(peer.name);
    ref.listen(provider.select((s) => s.replied.contains(peer.name)), (
      _,
      replied,
    ) {
      if (replied) scrollToLatest();
    });
    void send() {
      final value = input.text.trim();
      if (value.isEmpty) return;
      if (legacy) ref.read(workspacePreviewProvider).sendMessage(value);
      ref
          .read(provider.notifier)
          .send(peer.name, value, demoReply: example != null);
      input.clear();
      scrollToLatest();
    }

    final bg = context.dark ? const Color(0xff11121b) : const Color(0xffeef0f7);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (typing || peer.online)
                          Text(
                            context.tr(typing ? 'chat.typing' : 'chat.online'),
                            style: const TextStyle(
                              color: DesignColor.green,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Tooltip(
                    message: context.tr('chat.voice_call'),
                    child: const SizedBox.square(
                      dimension: 44,
                      child: Icon(TmsIcons.phone, size: 19),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                children: [
                  Center(child: DesignLabel(context.tr('common.today'))),
                  const SizedBox(height: 10),
                  if (example != null) ...[
                    message(example.intro, 0),
                    bubble(
                      DesignCard(
                        onTap: cardAction,
                        padding: const EdgeInsets.all(11),
                        color: context.background,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 6,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                KitStatus(
                                  context.tr(example.card[0]),
                                  DesignColor.amber,
                                ),
                                KitTag(example.card[1]),
                              ],
                            ),
                            Text(
                              example.card[2],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            DesignLabel(example.card[3]),
                          ],
                        ),
                      ),
                    ),
                    message(example.mine, 1, mine: true),
                    bubble(_VoicePreview(duration: example.voice)),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: DesignPill(
                        '${voiceReaction ? 2 : 1}',
                        icon: TmsIcons.like,
                        selected: voiceReaction,
                        onTap: () =>
                            setState(() => voiceReaction = !voiceReaction),
                      ),
                    ),
                  ] else if (peer.preview.isNotEmpty)
                    message(peer.preview, 0),
                  for (final (i, text) in sent.indexed)
                    message(text, i + 3, mine: true),
                  if (typing)
                    bubble(const _TypingDots())
                  else if (example != null &&
                      session.replied.contains(peer.name))
                    message(example.reply, 2),
                ],
              ),
            ),
            _ConversationComposer(
              input: input,
              firstName: peer.name.split(' ').first,
              send: send,
            ),
          ],
        ),
      ),
    );
  }

  Widget message(String text, int id, {bool mine = false}) => GestureDetector(
    onLongPress: () => setState(() {
      if (!reactions.add(id)) reactions.remove(id);
    }),
    child: bubble(
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (reactions.contains(id)) const Icon(TmsIcons.heart, size: 14),
        ],
      ),
      mine: mine,
    ),
  );
  Widget bubble(Widget child, {bool mine = false}) => Align(
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

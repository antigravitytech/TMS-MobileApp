import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/chat_session.dart';
import '../data/chat_directory.dart';
import '../data/chat_repository.dart';
import 'widgets/chat_widgets.dart';
import 'widgets/compose_chat.dart';

export 'conversation_screen.dart';

part 'widgets/chat_inbox_request.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(chatDirectoryProvider)
      .when(
        data: (directory) =>
            _Inbox(key: ValueKey(directory.workspace), directory: directory),
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

class _Inbox extends ConsumerStatefulWidget {
  const _Inbox({super.key, required this.directory});
  final ChatDirectory directory;
  @override
  ConsumerState<_Inbox> createState() => _InboxState();
}

class _InboxState extends ConsumerState<_Inbox> {
  int tab = 0, filter = 0;
  ChatDirectory get book => widget.directory;
  ChatSessionController get controller =>
      ref.read(chatSessionProvider(book.workspace).notifier);
  void open(ChatRow row) {
    controller.open(row);
    TmsRoute.conversation.open(context);
  }

  Future<void> compose() async {
    final result = await showModalBottomSheet<ComposeResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => ComposeChat(directory: book),
    );
    if (result == null || !mounted) return;
    try {
      final row = await ref
          .read(chatRepositoryProvider)
          .start(book, result.people, group: result.group, title: result.title);
      if (!mounted) return;
      if (row.id.isEmpty) {
        controller.create(row, group: result.group);
      } else {
        controller.open(row);
        ref.invalidate(chatDirectoryProvider);
      }
      TmsRoute.conversation.open(context);
    } catch (error) {
      if (mounted) designToast(context, chatErrorMessage(context, error));
    }
  }

  Future<void> respond(ChatRequest request, {required bool accept}) async {
    try {
      await ref.read(chatRepositoryProvider).respond(request, accept: accept);
      if (!mounted) return;
      controller.resolveRequest(accept ? request.row : null);
      if (request.id.isNotEmpty) ref.invalidate(chatDirectoryProvider);
      designToast(
        context,
        context.tr(
          accept ? request.accepted : 'chat.chat_request_declined',
          namedArgs: {'name': request.row.name.split(' ').first},
        ),
      );
    } catch (error) {
      if (mounted) designToast(context, chatErrorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(chatSessionProvider(book.workspace));
    final recent = [
      ...session.contacts,
      ...book.recent.where(
        (r) => !session.contacts.any((c) => c.name == r.name),
      ),
    ];
    final groups = [...session.groups, ...book.groups];
    final tasks = book.tasks;
    final request = book.request;
    return Scaffold(
      backgroundColor: context.background,
      bottomNavigationBar: WorkspaceNavigation(
        kind: book.kind,
        active: TmsRoute.chat,
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (book.name.isNotEmpty) DesignLabel(book.name),
                            Text(
                              context.tr('common.chat'),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DesignIcon(
                        icon: TmsIcons.search,
                        label: context.tr('common.search'),
                        onPressed: () => TmsRoute.search.open(context),
                      ),
                      DesignIcon(
                        icon: TmsIcons.edit,
                        label: context.tr('chat.new_conversation'),
                        onPressed: compose,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ChatSegments(
                    labels: [
                      context.tr(
                        'chat.chat_count',
                        namedArgs: {
                          'count':
                              '${recent.length + (tasks.isEmpty ? 0 : tasks.length + 1)}',
                        },
                      ),
                      context.tr(
                        'chat.group_count',
                        namedArgs: {'count': '${groups.length}'},
                      ),
                    ],
                    selected: tab,
                    select: (i) => setState(() => tab = i),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      if (book.online.isNotEmpty) ...[
                        _label(
                          context.tr(
                            'chat.online_count',
                            namedArgs: {'count': '${book.online.length}'},
                          ),
                        ),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 6,
                            children: [
                              for (final p in book.online)
                                InkWell(
                                  onTap: () => open(
                                    book.people
                                            .where(
                                              (c) => c.initials == p.initials,
                                            )
                                            .firstOrNull
                                            ?.row ??
                                        p.row,
                                  ),
                                  child: SizedBox(
                                    width: 62,
                                    child: Column(
                                      spacing: 5,
                                      children: [
                                        ChatAvatar(p.row, size: 52),
                                        Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (book.filters.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            spacing: 8,
                            children: [
                              for (var i = 0; i < book.filters.length; i++)
                                _ChatFilter(
                                  context.tr(book.filters[i]),
                                  selected: filter == i,
                                  onTap: () => setState(() => filter = i),
                                ),
                            ],
                          ),
                        ),
                      if (tab == 0) ...[
                        if (request != null && !session.requestHandled)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: _requestCard(request),
                          ),
                        if (book.pinned case final pin?) ...[
                          _heading(context.tr('common.pinned')),
                          ChatListRow(pin, group: true, onTap: () => open(pin)),
                        ],
                        if (tasks.isNotEmpty) ...[
                          _heading(context.tr(book.section)),
                          for (final row in tasks)
                            ChatListRow(
                              row,
                              leading: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: DesignColor.amber.withValues(
                                    alpha: .12,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: DesignColor.amber.withValues(
                                      alpha: .3,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  TmsIcons.checkSquare,
                                  size: 20,
                                  color: DesignColor.amber,
                                ),
                              ),
                              onTap: () => open(row),
                            ),
                        ],
                        _heading(context.tr('chat.recent')),
                        if (recent.isEmpty)
                          DesignLabel(context.tr('chat.empty_space')),
                        for (final row in recent.where(
                          (r) => switch (filter) {
                            1 => r.badge.isNotEmpty,
                            2 => r.badge == '@',
                            _ => true,
                          },
                        ))
                          ChatListRow(row, onTap: () => open(row)),
                      ] else ...[
                        const SizedBox(height: 14),
                        for (final row in groups)
                          ChatListRow(row, group: true, onTap: () => open(row)),
                        if (groups.isEmpty)
                          DesignLabel(context.tr('chat.empty_space')),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: context.muted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );
  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 2),
    child: _label(text),
  );
}

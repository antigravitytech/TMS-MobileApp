import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/presentation/workspace_ui.dart';
import '../application/chat_session.dart';
import '../data/chat_directory.dart';
import 'chat_widgets.dart';

export 'conversation_screen.dart';

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
    final result = await designSheet<(ChatRow, bool)>(
      context,
      title: context.tr('chat.new_conversation'),
      builder: (_) => ComposeChat(directory: book),
    );
    if (result == null || !mounted) return;
    controller.create(result.$1, group: result.$2);
    TmsRoute.conversation.open(context);
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
    final task = book.task;
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
                  padding: EdgeInsets.fromLTRB(
                    20,
                    (58 - MediaQuery.viewPaddingOf(context).top).clamp(8, 58),
                    20,
                    10,
                  ),
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
                          'count': '${recent.length + (task.isEmpty ? 0 : 2)}',
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
                                        ChatAvatar(p.row),
                                        Text(
                                          p.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DesignChoices(
                          items: [
                            for (final key in book.filters) context.tr(key),
                          ],
                          selected: filter,
                          onChanged: (i) => setState(() => filter = i),
                        ),
                      ],
                      if (tab == 0) ...[
                        if (request.isNotEmpty && !session.requestHandled)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: DesignCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 10,
                                children: [
                                  _label(context.tr('chat.chat_request')),
                                  Row(
                                    spacing: 12,
                                    children: [
                                      DesignAvatar(
                                        request[0],
                                        color: chatColor(request[1]),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${request[2]} · ${context.tr(request[3])}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            DesignLabel(request[4]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    spacing: 8,
                                    children: [
                                      for (final accept in [true, false])
                                        Expanded(
                                          child: DesignButton(
                                            context.tr(
                                              accept
                                                  ? 'chat.accept'
                                                  : 'chat.decline',
                                            ),
                                            secondary: !accept,
                                            onPressed: () {
                                              controller.resolveRequest(
                                                accept
                                                    ? ChatRow(
                                                        initials: request[0],
                                                        color: request[1],
                                                        name: request[2],
                                                      )
                                                    : null,
                                              );
                                              designToast(
                                                context,
                                                context.tr(
                                                  accept
                                                      ? request[6]
                                                      : 'chat.chat_request_declined',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    ],
                                  ),
                                  DesignLabel(context.tr(request[5])),
                                ],
                              ),
                            ),
                          ),
                        if (book.pinned case final pin?) ...[
                          _heading(context.tr('common.pinned')),
                          ChatListRow(pin, group: true, onTap: () => open(pin)),
                        ],
                        if (task.isNotEmpty) ...[
                          _heading(context.tr(book.section)),
                          Builder(
                            builder: (context) {
                              final row = ChatRow(
                                initials: '',
                                color: 'a3',
                                name: task[0],
                                preview: task[1],
                                time: task[2],
                                badge: '@',
                              );
                              return ChatListRow(
                                row,
                                leading: const Icon(
                                  TmsIcons.checkSquare,
                                  size: 42,
                                  color: DesignColor.amber,
                                ),
                                onTap: () => open(row),
                              );
                            },
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

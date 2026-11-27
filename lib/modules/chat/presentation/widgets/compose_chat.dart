import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../data/chat_directory.dart';
import 'chat_widgets.dart';

class ComposeChat extends StatefulWidget {
  const ComposeChat({super.key, required this.directory});
  final ChatDirectory directory;
  @override
  State<ComposeChat> createState() => _ComposeChatState();
}

class _ComposeChatState extends State<ComposeChat> {
  bool group = false;
  String query = '', name = '';
  final picked = <ChatContact>{};
  @override
  Widget build(BuildContext context) {
    final matches = widget.directory.people.where(
      (p) => '${p.name} ${p.role}'.toLowerCase().contains(
        query.toLowerCase().trim(),
      ),
    );
    final ready = group ? picked.length >= 2 : picked.length == 1;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .84,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: context.muted.withValues(alpha: .3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('chat.new_message'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(TmsIcons.close, size: 18),
                  ),
                ],
              ),
              ChatSegments(
                labels: [
                  context.tr('chat.direct_tab'),
                  context.tr('chat.new_group_tab'),
                ],
                selected: group ? 1 : 0,
                select: (i) => setState(() {
                  group = i == 1;
                  if (!group && picked.length > 1) {
                    picked.removeAll(picked.skip(1).toList());
                  }
                }),
              ),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: context.tr('chat.search_people'),
                  prefixIcon: const Icon(TmsIcons.search, size: 18),
                  filled: true,
                  fillColor: context.panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              if (group)
                TextField(
                  onChanged: (v) => setState(() => name = v),
                  decoration: InputDecoration(
                    hintText: context.tr('chat.group_name_hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              Text(
                context
                    .tr(
                      'chat.in_workspace',
                      namedArgs: {'workspace': widget.directory.name},
                    )
                    .toUpperCase(),
                style: TextStyle(
                  color: context.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    if (matches.isEmpty)
                      DesignLabel(context.tr('chat.no_matches')),
                    for (final p in matches)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ChatAvatar(p.row, size: 36),
                        title: Text(
                          p.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          p.role,
                          style: TextStyle(fontSize: 12, color: context.muted),
                        ),
                        trailing: Container(
                          width: 23,
                          height: 23,
                          decoration: BoxDecoration(
                            shape: group ? BoxShape.rectangle : BoxShape.circle,
                            borderRadius: group
                                ? BorderRadius.circular(6)
                                : null,
                            border: Border.all(
                              color: context.muted.withValues(alpha: .45),
                            ),
                            color: picked.contains(p)
                                ? DesignColor.purple
                                : Colors.transparent,
                          ),
                          child: picked.contains(p)
                              ? const Icon(
                                  TmsIcons.check,
                                  size: 16,
                                  color: DesignColor.ink,
                                )
                              : null,
                        ),
                        onTap: () => setState(() {
                          if (picked.remove(p)) return;
                          if (!group) picked.clear();
                          picked.add(p);
                        }),
                      ),
                  ],
                ),
              ),
              DesignButton(
                group
                    ? (ready
                          ? context.tr(
                              'chat.start_group',
                              namedArgs: {'count': '${picked.length + 1}'},
                            )
                          : context.tr('chat.pick_group'))
                    : (ready
                          ? context.tr(
                              'chat.message_person',
                              namedArgs: {
                                'name': picked.first.name.split(' ').first,
                              },
                            )
                          : context.tr('chat.pick_direct')),
                onPressed: !ready
                    ? null
                    : () {
                        final row = group
                            ? ChatRow(
                                initials: picked
                                    .take(2)
                                    .map((p) => p.initials[0])
                                    .join(),
                                color: 'a1',
                                name: name.trim().isEmpty
                                    ? picked
                                          .map((p) => p.name.split(' ').first)
                                          .join(', ')
                                    : name.trim(),
                              )
                            : picked.first.row;
                        Navigator.pop(context, (row, group));
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../data/chat_directory.dart';
import '../../../shared/design/tms_icons.dart';

Color chatColor(String value) {
  const palette = [
    0xffc4bdf6,
    0xff86d6cb,
    0xffeccb84,
    0xffeeabb0,
    0xffa3c8f1,
    0xffbcd995,
    0xffd8b4ec,
    0xffb2b6ca,
  ];
  if (value.startsWith('#')) {
    return Color(int.parse('ff${value.substring(1)}', radix: 16));
  }
  final index = int.tryParse(value.replaceFirst('a', '')) ?? 1;
  return Color(palette[(index - 1).clamp(0, palette.length - 1)]);
}

class ChatAvatar extends StatelessWidget {
  const ChatAvatar(this.row, {super.key, this.size = 52, this.group = false});
  final ChatRow row;
  final double size;
  final bool group;
  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: chatColor(row.color),
          borderRadius: BorderRadius.circular(group ? 16 : size / 2),
        ),
        child: Text(
          row.initials,
          style: TextStyle(
            color: DesignColor.ink,
            fontWeight: FontWeight.w800,
            fontSize: size * .32,
          ),
        ),
      ),
      if (row.online)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DesignColor.green,
              border: Border.all(color: context.background, width: 2),
            ),
          ),
        ),
    ],
  );
}

class ChatListRow extends StatelessWidget {
  const ChatListRow(
    this.row, {
    super.key,
    required this.onTap,
    this.group = false,
    this.leading,
  });
  final ChatRow row;
  final VoidCallback onTap;
  final bool group;
  final Widget? leading;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.outline.withValues(alpha: .09)),
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          leading ?? ChatAvatar(row, group: group),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  row.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: row.badge.isEmpty
                        ? context.muted
                        : context.foreground,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 5,
            children: [
              Text(
                row.time,
                style: TextStyle(fontSize: 12, color: context.muted),
              ),
              if (row.badge.isNotEmpty)
                Badge(
                  backgroundColor: row.badge == '@'
                      ? DesignColor.amber
                      : DesignColor.purple,
                  textColor: DesignColor.ink,
                  label: Text(row.badge),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class ChatSegments extends StatelessWidget {
  const ChatSegments({
    super.key,
    required this.labels,
    required this.selected,
    required this.select,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> select;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.panel,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        for (final (i, name) in labels.indexed)
          Expanded(
            child: Semantics(
              selected: selected == i,
              button: true,
              child: InkWell(
                onTap: () => select(i),
                child: AnimatedContainer(
                  duration: DesignMotion.duration(context, DesignMotion.fast),
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? context.raised : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: selected == i ? context.foreground : context.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        ChatSegments(
          labels: [
            context.tr('chat.direct_message'),
            context.tr('chat.group_chat'),
          ],
          selected: group ? 1 : 0,
          select: (i) => setState(() {
            group = i == 1;
            if (!group && picked.length > 1) {
              picked.removeAll(picked.skip(1).toList());
            }
          }),
        ),
        if (group)
          DesignField(
            label: context.tr('chat.group_name'),
            initialValue: name,
            onChanged: (v) => setState(() => name = v),
          ),
        DesignField(
          label: context.tr('chat.find_people'),
          onChanged: (v) => setState(() => query = v),
        ),
        if (matches.isEmpty) DesignLabel(context.tr('chat.no_matches')),
        for (final p in matches)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ChatAvatar(p.row, size: 40),
            title: Text(p.name),
            subtitle: Text(p.role),
            trailing: Icon(
              picked.contains(p) ? TmsIcons.checkCircle : TmsIcons.circle,
            ),
            onTap: () => setState(() {
              if (picked.remove(p)) return;
              if (!group) picked.clear();
              picked.add(p);
            }),
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
                        namedArgs: {'name': picked.first.name.split(' ').first},
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
    );
  }
}

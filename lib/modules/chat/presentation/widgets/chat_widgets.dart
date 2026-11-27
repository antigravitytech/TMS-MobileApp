import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../authentication/domain/account.dart';
import '../../../authentication/presentation/widgets/account_action_form.dart';
import '../../data/chat_directory.dart';

/// A failed chat request, in words.
String chatErrorMessage(BuildContext context, Object error) =>
    error is AccountFailure
    ? accountErrorMessage(context, error)
    : context.tr('network.errors.unknown');

/// The row's time: the prototype's label, or how long ago the last message
/// arrived.
String chatTime(BuildContext context, ChatRow row) {
  final at = row.at;
  if (row.time.isNotEmpty || at == null) return row.time;
  final age = DateTime.now().difference(at);
  if (age.inMinutes < 1) return context.tr('chat.now');
  if (age.inHours < 1) return '${age.inMinutes}m';
  if (age.inDays < 1) return '${age.inHours}h';
  if (age.inDays < 7) return DateFormat.E(context.locale.toString()).format(at);
  return DateFormat.MMMd(context.locale.toString()).format(at);
}

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
      padding: const EdgeInsets.symmetric(vertical: 12),

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
                chatTime(context, row),
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
      border: Border.all(color: context.outline),
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

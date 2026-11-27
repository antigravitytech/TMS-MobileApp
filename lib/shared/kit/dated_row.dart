import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../design/design_tokens.dart';

/// `.li` row with a month/day block (`.dblock`), a title and a meta line.
class DatedRow extends StatelessWidget {
  const DatedRow({
    super.key,
    required this.date,
    required this.title,
    this.meta = '',
    this.trailing,
    this.onTap,
  });
  final DateTime date;
  final String title, meta;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) {
    final locale = c.locale.toString();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            SizedBox(
              width: 46,
              child: Column(
                children: [
                  Text(
                    DateFormat.MMM(locale).format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .4,
                      color: c.lavender,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: const TextStyle(
                      fontSize: 21,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Text(meta, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

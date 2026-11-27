import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../data/school_items.dart';

IconData schoolIcon(String type) => switch (type) {
  'hw' => TmsIcons.file,
  'form' => TmsIcons.edit,
  'pta' => TmsIcons.people,
  'buy' => TmsIcons.shoppingCart,
  'test' => TmsIcons.note,
  'event' => TmsIcons.trophy,
  _ => TmsIcons.receipt,
};
Color schoolColor(String type) => switch (type) {
  'hw' => DesignColor.blue,
  'form' => DesignColor.purple,
  'pta' => DesignColor.teal,
  'buy' || 'event' => DesignColor.green,
  'test' => DesignColor.amber,
  _ => DesignColor.red,
};

class SchoolChildChip extends StatelessWidget {
  const SchoolChildChip({
    super.key,
    required this.name,
    required this.initials,
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final String name, initials;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => Material(
    color: selected ? c.foreground : c.panel,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
      side: BorderSide(color: c.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 5, 12, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DesignAvatar(initials, size: 30, color: color),
            const SizedBox(width: 7),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? c.background : c.foreground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SchoolItemCard extends StatelessWidget {
  const SchoolItemCard({super.key, required this.item, required this.onToggle});
  final SchoolItem item;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext c) {
    final color = schoolColor(item.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border.all(
          color: item.group == 'od' && !item.done
              ? DesignColor.red.withValues(alpha: .45)
              : c.outline,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: .25)),
                ),
                child: Icon(schoolIcon(item.type), size: 19, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${c.tr('school.type_${item.type}')}${item.subject.isNotEmpty ? ' · ${c.tr(item.subject)}' : ''}',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: item.done ? c.muted : c.foreground,
                        decoration: item.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.child.isNotEmpty) ...[
                          DesignAvatar(
                            kitPerson(item.child).$1,
                            size: 26,
                            color: kitPerson(item.child).$2,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            '${item.child.isNotEmpty ? '${item.child} · ' : ''}${c.tr(item.when)}',
                            style: TextStyle(fontSize: 11, color: c.muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              KitTick(
                on: item.done,
                label: c.tr('school.toggle', namedArgs: {'title': item.title}),
                onTap: onToggle,
              ),
            ],
          ),
          if (item.note.isNotEmpty && !item.done) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: c.raised,
                border: const Border(
                  left: BorderSide(color: DesignColor.purple, width: 2),
                ),
              ),
              child: Text(
                '“${c.tr(item.note)}”',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SchoolReview extends StatelessWidget {
  const SchoolReview({
    super.key,
    required this.onApprove,
    required this.onRedo,
  });
  final VoidCallback onApprove, onRedo;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DesignColor.purple.withValues(alpha: .17),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DesignColor.purple),
    ),
    child: Column(
      children: [
        Row(
          children: [
            const DesignAvatar('TI', color: DesignColor.amber, size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.tr('school.worksheet_title'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    c.tr('school.worksheet_detail'),
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 110,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xfff3efdf),
            borderRadius: BorderRadius.circular(14),
          ),
          child: CustomPaint(
            painter: _Paper(),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '½ + ¼ = ¾\n⅔ − ⅙ = ½\n3 × ⅓ = 1',
                style: const TextStyle(
                  color: Color(0xff263d71),
                  fontFamily: 'Inter',
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                  height: 1.7,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRedo,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  foregroundColor: const Color(0xfff59562),
                  side: const BorderSide(color: Color(0xff986a50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  c.tr('school.again'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FilledButton(
                onPressed: onApprove,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: DesignColor.green,
                  foregroundColor: DesignColor.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(TmsIcons.check, size: 15),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        c.tr('school.looks_good'),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Paper extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xffd4d4c4)
      ..strokeWidth = .5;
    for (double y = 20; y < s.height; y += 18) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_Paper old) => false;
}

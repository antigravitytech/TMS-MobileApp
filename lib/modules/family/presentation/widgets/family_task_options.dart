part of '../family_task_screen.dart';

class _FamilyOptions extends StatelessWidget {
  const _FamilyOptions({required this.draft, required this.space});
  final FamilyTaskDraft draft;
  final LocalWorkspace space;
  @override
  Widget build(BuildContext context) {
    final d = draft;
    Widget choices(List<String> keys, int index, ValueChanged<int> set) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < keys.length; i++)
          _FamilyChip(
            context.tr('family.${keys[i]}'),
            selected: index == i,
            onTap: () => d.change(() => set(i)),
          ),
      ],
    );
    Widget toggle(String key, bool value, ValueChanged<bool> set) =>
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('family.$key')),
          subtitle: Text(context.tr('family.${key}_detail')),
          value: value,
          onChanged: (v) => d.change(() => set(v)),
        );
    final shopping = space
        .items(WorkspaceSection.shopping)
        .where((r) => r.status != WorkspaceStatus.done);
    return DesignCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: switch (d.type) {
          FamilyTaskType.chore => [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('family.points'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.tr('family.trade'),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PointStep(
                  icon: TmsIcons.minus,
                  label: context.tr('family.less'),
                  onTap: d.points == 0
                      ? null
                      : () => d.change(
                          () => d.points = (d.points - 5).clamp(0, 99999),
                        ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: DesignColor.amber.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        TmsIcons.star,
                        size: 12,
                        color: DesignColor.amber,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        NumberFormat.decimalPattern(
                          context.locale.toString(),
                        ).format(d.points),
                        style: const TextStyle(
                          color: DesignColor.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _PointStep(
                  icon: TmsIcons.add,
                  label: context.tr('family.more'),
                  onTap: () => d.change(() => d.points += 5),
                ),
              ],
            ),
            Divider(height: 16, color: context.outline),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('family.repeat'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.outline),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        GestureDetector(
                          onTap: () => d.change(() => d.repeat = i),
                          child: AnimatedContainer(
                            duration: DesignMotion.fast,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: d.repeat == i
                                  ? context.raised
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.tr(
                                'family.${['once', 'daily', 'weekly'][i]}',
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: d.repeat == i
                                    ? context.foreground
                                    : context.muted,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          FamilyTaskType.homework => [
            Text(context.tr('family.subject')),
            choices(
              ['maths', 'english', 'science', 'social', 'other'],
              d.subject,
              (i) => d.subject = i,
            ),
            toggle('photo', d.photo, (v) => d.photo = v),
            toggle('review', d.review, (v) => d.review = v),
          ],
          FamilyTaskType.errand => [
            Text(context.tr('family.cash')),
            DesignLabel(context.tr('family.cash_detail')),
            Wrap(
              spacing: 6,
              children: [
                for (final cash in [0, 5000, 10000, 20000, 50000])
                  DesignPill(
                    cash == 0
                        ? context.tr('family.none')
                        : NumberFormat.currency(
                            locale: context.locale.toString(),
                            symbol: '₦',
                            decimalDigits: 0,
                          ).format(cash),
                    selected: d.cash == cash,
                    onTap: () => d.change(() => d.cash = cash),
                  ),
              ],
            ),
            Text(context.tr('family.buy_list')),
            for (final item in shopping)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.title),
                value: d.shopping.contains(item.id),
                onChanged: (_) => d.change(() {
                  if (!d.shopping.remove(item.id)) d.shopping.add(item.id);
                }),
              ),
          ],
          FamilyTaskType.reminder => [
            Text(context.tr('family.remind_at')),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < 4; i++)
                  _FamilyChip(
                    [
                      const TimeOfDay(hour: 7, minute: 0),
                      const TimeOfDay(hour: 12, minute: 0),
                      const TimeOfDay(hour: 17, minute: 0),
                      const TimeOfDay(hour: 20, minute: 30),
                    ][i].format(context),
                    selected: d.time == i,
                    onTap: () => d.change(() => d.time = i),
                  ),
              ],
            ),
            toggle('tablet', d.tablet, (v) => d.tablet = v),
          ],
        },
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.selected,
    required this.index,
    required this.onTap,
  });
  final FamilyTaskType type;
  final bool selected;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final color = [
      DesignColor.amber,
      DesignColor.blue,
      DesignColor.teal,
      DesignColor.rose,
    ][index];
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignMotion.duration(context, DesignMotion.fast),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.raised : context.panel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? DesignColor.purple : context.outline,
          ),
        ),
        child: Column(
          spacing: 6,
          children: [
            AnimatedRotation(
              turns: selected ? -1 / 60 : 0,
              duration: DesignMotion.fast,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  [
                    TmsIcons.shoppingBag,
                    TmsIcons.file,
                    TmsIcons.shoppingCart,
                    TmsIcons.clock,
                  ][index],
                  color: color,
                ),
              ),
            ),
            Text(
              context.tr('family.${type.name}'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyChip extends StatelessWidget {
  const _FamilyChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => Material(
    color: selected ? c.foreground : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: c.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? c.background : c.muted,
          ),
        ),
      ),
    ),
  );
}

class _PointStep extends StatelessWidget {
  const _PointStep({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext c) => SizedBox.square(
    dimension: 40,
    child: IconButton(
      onPressed: onTap,
      tooltip: label,
      style: IconButton.styleFrom(
        backgroundColor: c.raised,
        foregroundColor: c.foreground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: c.outline),
        ),
      ),
      icon: Icon(icon, size: 18),
    ),
  );
}

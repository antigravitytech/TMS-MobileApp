part of 'family_task_screen.dart';

class _FamilyOptions extends StatelessWidget {
  const _FamilyOptions({required this.draft, required this.space});
  final FamilyTaskDraft draft;
  final LocalWorkspace space;
  @override
  Widget build(BuildContext context) {
    final d = draft;
    Widget choices(List<String> keys, int index, ValueChanged<int> set) =>
        DesignChoices(
          items: [for (final k in keys) context.tr('family.$k')],
          selected: index,
          onChanged: (i) => d.change(() => set(i)),
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
                      Text(context.tr('family.points')),
                      DesignLabel(context.tr('family.trade')),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: context.tr('family.less'),
                  icon: const Icon(TmsIcons.removeCircle),
                  onPressed: d.points == 0
                      ? null
                      : () => d.change(() => d.points -= 5),
                ),
                Text('${d.points}'),
                IconButton(
                  tooltip: context.tr('family.more'),
                  icon: const Icon(TmsIcons.add),
                  onPressed: () => d.change(() => d.points += 5),
                ),
              ],
            ),
            Text(context.tr('family.repeat')),
            choices(['once', 'daily', 'weekly'], d.repeat, (i) => d.repeat = i),
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
            DesignChoices(
              items: [
                for (final t in const [
                  TimeOfDay(hour: 7, minute: 0),
                  TimeOfDay(hour: 12, minute: 0),
                  TimeOfDay(hour: 17, minute: 0),
                  TimeOfDay(hour: 20, minute: 30),
                ])
                  t.format(context),
              ],
              selected: d.time,
              onChanged: (i) => d.change(() => d.time = i),
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
                    TmsIcons.checkSquare,
                    TmsIcons.school,
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

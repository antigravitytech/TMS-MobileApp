part of 'family_home_sections.dart';

class FamilyErrandsPanel extends ConsumerWidget {
  const FamilyErrandsPanel({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext c, WidgetRef ref) => DesignCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final r in workspace.items(WorkspaceSection.errands))
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.outline)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    DesignAvatar(
                      r.person == 'Kwame' ? 'KM' : 'BO',
                      size: 28,
                      color: r.person == 'Kwame'
                          ? DesignColor.blue
                          : const Color(0xffd8b4ec),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c.tr(
                              'family_reference.issued',
                              namedArgs: {
                                'name': r.person,
                                'amount': naira(
                                  c,
                                  (int.tryParse(r.fields['issued'] ?? '0') ??
                                          0) *
                                      100,
                                ),
                              },
                            ),
                            style: TextStyle(color: c.muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.tr(
                        r.fields.containsKey('spent')
                            ? 'family_reference.change_due'
                            : 'family_reference.out_now',
                      ),
                      style: TextStyle(
                        color: r.fields.containsKey('spent')
                            ? DesignColor.amber
                            : DesignColor.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (r.fields.containsKey('spent'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12, left: 38),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            c.tr('family_reference.change_summary'),
                            style: TextStyle(color: c.muted, fontSize: 11),
                          ),
                        ),
                        _action(
                          c,
                          c.tr(
                            r.fields['changeReceived'] == 'true'
                                ? 'family_reference.received'
                                : 'family_reference.change_received',
                          ),
                          () => saveWorkspaceChange(
                            c,
                            () => ref
                                .read(localWorkspacesProvider.notifier)
                                .updateRecord(
                                  workspace.id,
                                  r.id,
                                  (old) => old.copyWith(
                                    fields: {
                                      ...old.fields,
                                      'changeReceived': 'true',
                                    },
                                  ),
                                ),
                          ),
                          green: true,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}

class FamilyUpcomingPanel extends StatelessWidget {
  const FamilyUpcomingPanel({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  Widget build(BuildContext c) => DesignCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, r)
            in workspace.records.where((r) => r.date != null).indexed)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.outline)),
            ),
            child: InkWell(
              onTap: () => r.section.open(c),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Column(
                      children: [
                        Text(
                          DateFormat.MMM(
                            c.locale.toString(),
                          ).format(r.date!).toUpperCase(),
                          style: TextStyle(
                            color: c.lavender,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          DateFormat.d(c.locale.toString()).format(r.date!),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat.E(c.locale.toString()).format(r.date!)} · ${[r.person, r.notes].where((s) => s.isNotEmpty).join(' · ')}',
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _tile(
                    [
                      TmsIcons.edit,
                      TmsIcons.people,
                      TmsIcons.file,
                      TmsIcons.trophy,
                      TmsIcons.receipt,
                    ][i % 5],
                    [
                      DesignColor.purple,
                      DesignColor.teal,
                      DesignColor.amber,
                      DesignColor.green,
                      DesignColor.red,
                    ][i % 5],
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

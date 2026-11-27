import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../bills/presentation/widgets/bills_widgets.dart' show naira;
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../../../shared/kit/payment_sheet.dart';
import '../../../workspace/presentation/widgets/workspace_record_form.dart';
import '../../application/special_actions.dart';
import 'special_compose.dart';
import 'special_hero.dart';

/// Payment methods on Specials payment sheets.
const specialMethods = ['transfer', 'cash', 'pos'];

extension SpecialPollVotes on WorkspaceRecord {
  /// Votes per option, counting my own vote.
  List<int> get votes {
    final base = (fields['votes'] ?? '')
        .split(',')
        .map((v) => int.tryParse(v.trim()) ?? 0)
        .toList();
    return [
      for (var i = 0; i < options.length; i++)
        (i < base.length ? base[i] : 0) + (vote == i ? 1 : 0),
    ];
  }
}

/// A muted intro line at the top of a tab.
Widget specialIntro(BuildContext c, String key) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: Text(c.tr(key), style: TextStyle(fontSize: 13.5, color: c.muted)),
);

/// Opens the shared record form for [section] and saves what comes back.
Future<void> addSpecialRecord(
  BuildContext c,
  WidgetRef ref,
  LocalWorkspace workspace,
  WorkspaceSection section,
) async {
  final actions = ref.read(specialActionsProvider(workspace.id));
  final draft = await editWorkspaceRecord(c, workspace, section);
  if (draft == null) return;
  final ok = await actions.add(draft.record);
  if (!ok && c.mounted) designToast(c, c.tr('workspaces.try_again'));
}

/// Money collected per person or house against a target: hero, rows with
/// paid bars and a payment sheet, then an add button. Alumni dues and
/// Estate levies both use it.
class SpecialCollectionTab extends ConsumerWidget {
  const SpecialCollectionTab({
    super.key,
    required this.workspace,
    required this.section,
    required this.records,
    required this.target,
    required this.intro,
    required this.record,
    required this.add,
  });
  final LocalWorkspace workspace;
  final WorkspaceSection section;
  final List<WorkspaceRecord> records;

  /// Target in kobo; zero falls back to the total pledged.
  final int target;

  /// Copy keys: tab intro, the record action, the add button.
  final String intro, record, add;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final collected = records.fold(0, (s, r) => s + r.paid.clamp(0, r.amount));
    final goal = target > 0 ? target : records.fold(0, (s, r) => s + r.amount);
    final owing = records.where((r) => r.outstanding > 0).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        specialIntro(c, intro),
        DesignEntrance(
          child: SpecialMoneyHero(
            label: c.tr('specials.collected'),
            amount: naira(c, collected),
            sub: c.tr('specials.target', namedArgs: {'amount': naira(c, goal)}),
            ratio: goal == 0 ? 0 : collected / goal,
            trio: [
              (
                c.tr('specials.outstanding'),
                naira(c, owing.fold(0, (s, r) => s + r.outstanding)),
              ),
              (c.tr('specials.paid'), '${records.length - owing.length}'),
              (c.tr('specials.owing'), '${owing.length}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (records.isEmpty)
          SpecialEmpty(section.name)
        else
          KitList(
            children: [
              for (final r in records)
                _CollectionRow(
                  key: ValueKey(r.id),
                  item: r,
                  record: record,
                  onPay: (kobo, method) => ref
                      .read(specialActionsProvider(workspace.id))
                      .recordPayment(
                        r,
                        kobo: kobo,
                        method: method,
                        giver: r.title,
                      ),
                ),
            ],
          ),
        const SizedBox(height: 12),
        DesignButton(
          c.tr(add),
          secondary: true,
          onPressed: () => addSpecialRecord(c, ref, workspace, section),
        ),
      ],
    );
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    super.key,
    required this.item,
    required this.record,
    required this.onPay,
  });
  final WorkspaceRecord item;
  final String record;
  final Future<bool> Function(int kobo, String method) onPay;
  @override
  Widget build(BuildContext c) {
    final face = kitPerson(item.title);
    final initials = item.fields['short'] ?? face.$1;
    final half = (item.outstanding / 2).round();
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 68),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            DesignAvatar(initials, size: 36, color: face.$2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: naira(c, item.paid),
                      style: TextStyle(
                        color: c.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                      children: [
                        TextSpan(
                          text: ' / ${naira(c, item.amount)}',
                          style: TextStyle(
                            color: c.muted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  KitBar(
                    value: item.amount == 0 ? 0 : item.paid / item.amount,
                    color: KitColor.done,
                  ),
                ],
              ),
            ),
            if (item.outstanding == 0)
              KitStatus(c.tr('specials.paid'), KitColor.done)
            else
              KitMiniButton(
                c.tr(record),
                primary: true,
                onPressed: () => showPaymentSheet(
                  c,
                  eyebrow: c.tr(record),
                  title: item.title,
                  balance: c.tr(
                    'specials.balance',
                    namedArgs: {'amount': naira(c, item.outstanding)},
                  ),
                  shares: [
                    (
                      c.tr(
                        'specials.full',
                        namedArgs: {'amount': naira(c, item.outstanding)},
                      ),
                      item.outstanding,
                    ),
                    (
                      c.tr(
                        'specials.half',
                        namedArgs: {'amount': naira(c, half)},
                      ),
                      half,
                    ),
                  ],
                  methods: specialMethods,
                  method: (m) => c.tr('specials.methods.$m'),
                  amount: (kobo) => naira(c, kobo),
                  onConfirm: onPay,
                  saved: (kobo) => c.tr(
                    'specials.payment_saved',
                    namedArgs: {'amount': naira(c, kobo), 'name': item.title},
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../specials/presentation/widgets/special_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../bills/presentation/widgets/bills_widgets.dart' show naira;
import '../../../workspace/application/workspace_preview.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit_controls.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/church_controller.dart';

class ChurchGiving extends StatelessWidget {
  const ChurchGiving({super.key, required this.view, required this.actions});
  final ChurchView view;
  final ChurchController actions;
  @override
  Widget build(BuildContext c) {
    Widget eyebrow(String key) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Text(
        c.tr(key).toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: c.muted,
        ),
      ),
    );
    if (view.funds.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
        children: const [SpecialEmpty('giving')],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        DesignEntrance(
          child: Row(
            spacing: 8,
            children: [
              for (final (value, label) in [
                (view.givingTotal, 'church.this_month'),
                (view.givingOf('tithes'), 'church.tithes'),
                (view.givingOf('offerings'), 'church.offerings'),
              ])
                Expanded(
                  child: KitCard(
                    radius: 20,
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      height: 48,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label == 'church.this_month'
                                  ? naira(c, value)
                                  : specialMoney(c, value),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            c.tr(label),
                            style: TextStyle(fontSize: 12.5, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        eyebrow('church.funds'),
        for (final (i, f) in view.targetFunds.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DesignEntrance(
              order: i + 1,
              child: KitCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            f.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(f.paid * 100 / f.amount).round().clamp(1, 999)}%',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ],
                    ),
                    if (f.notes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        f.notes,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                    const SizedBox(height: 10),
                    KitBar(
                      value: (f.paid / f.amount).clamp(.02, 1),
                      color: const Color(0xff2bb3a3),
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        text: naira(c, f.paid),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        children: [
                          TextSpan(
                            text: c.tr(
                              'church.of_target',
                              namedArgs: {'target': naira(c, f.amount)},
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.w400,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        eyebrow('church.recent_giving'),
        KitList(
          children: [
            for (final (fund, gift) in view.recentGifts)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    DesignAvatar(
                      gift.name.isEmpty ? 'AN' : kitPerson(gift.name).$1,
                      size: 36,
                      color: gift.name.isEmpty
                          ? KitColor.avatar(8)
                          : kitPerson(gift.name).$2,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gift.name.isEmpty
                                ? c.tr('church.anonymous')
                                : gift.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${fund.title} · ${c.tr('church.methods.${gift.method}')}',
                            style: TextStyle(fontSize: 12, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      naira(c, gift.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        DesignButton(
          c.tr('church.record_giving'),
          onPressed: () => showGivingSheet(c, view, actions),
        ),
      ],
    );
  }
}

/// Record a gift: fund, amount, method and whether it is anonymous.
Future<void> showGivingSheet(
  BuildContext context,
  ChurchView view,
  ChurchController actions,
) => designSheet<void>(
  context,
  title: context.tr('church.record_giving'),
  builder: (_) => _GivingForm(view: view, actions: actions),
);

class _GivingForm extends ConsumerStatefulWidget {
  const _GivingForm({required this.view, required this.actions});
  final ChurchView view;
  final ChurchController actions;
  @override
  ConsumerState<_GivingForm> createState() => _GivingFormState();
}

class _GivingFormState extends ConsumerState<_GivingForm> {
  final _amount = TextEditingController();
  late WorkspaceRecord fund = widget.view.funds.firstWhere(
    (f) => f.fields['kind'] == 'offerings',
    orElse: () => widget.view.funds.first,
  );
  String method = giftMethods.first;
  bool anonymous = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final preview = ref.read(workspacePreviewProvider);
    final naira = int.tryParse(_amount.text.replaceAll(RegExp('[^0-9]'), ''));
    final kobo = (naira == null || naira == 0 ? 20000 : naira) * 100;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final done = context.tr(
      'church.gift_saved',
      namedArgs: {'amount': nairaOf(context, kobo), 'fund': fund.title},
    );
    final failed = context.tr('workspaces.try_again');
    final ok = await widget.actions.recordGift(
      fund,
      kobo: kobo,
      method: method,
      giver: anonymous ? '' : '${preview.firstName} ${preview.lastName}',
    );
    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? done : failed),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final f in widget.view.funds)
            KitChip(
              label: f.title.split(' — ').first,
              selected: f.id == fund.id,
              onTap: () => setState(() => fund = f),
            ),
        ],
      ),
      const SizedBox(height: 14),
      KitInput(
        controller: _amount,
        hint: c.tr('church.amount_hint'),
        keyboardType: TextInputType.number,
      ),
      const SizedBox(height: 12),
      KitSegment<String>(
        values: giftMethods,
        selected: method,
        label: (m) => c.tr('church.methods.$m'),
        onChanged: (m) => setState(() => method = m),
      ),
      const SizedBox(height: 6),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: anonymous,
        activeTrackColor: DesignColor.purple,
        title: Text(
          c.tr('church.anonymous'),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        onChanged: (v) => setState(() => anonymous = v),
      ),
      const SizedBox(height: 10),
      DesignButton(c.tr('church.record'), onPressed: _save),
    ],
  );
}

String nairaOf(BuildContext c, int kobo) => naira(c, kobo);

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../bills/presentation/widgets/bills_widgets.dart' show naira;
import '../../../specials/presentation/widgets/special_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';
import '../../application/event_controller.dart';

class EventVendors extends StatelessWidget {
  const EventVendors({super.key, required this.view, required this.actions});
  final EventView view;
  final EventController actions;
  @override
  Widget build(BuildContext c) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
    children: [
      DesignEntrance(
        child: SpecialMoneyHero(
          label: c.tr('event.budget'),
          amount: naira(c, view.space.eventBudget),
          trio: [
            (c.tr('event.committed'), specialMoney(c, view.committed)),
            (c.tr('event.paid'), naira(c, view.paid)),
            (c.tr('event.to_pay'), naira(c, view.committed - view.paid)),
          ],
        ),
      ),
      const SizedBox(height: 14),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            for (final stage in vendorStages)
              SizedBox(
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Text(
                            c.tr('event.vendor_stages.$stage').toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .7,
                              color: c.muted,
                            ),
                          ),
                        ),
                        KitCount(
                          view.vendors
                              .where((v) => v.vendorStage == stage)
                              .length,
                        ),
                      ],
                    ),
                    for (final v in view.vendors.where(
                      (v) => v.vendorStage == stage,
                    ))
                      _VendorCard(
                        key: ValueKey(v.id),
                        vendor: v,
                        actions: actions,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({super.key, required this.vendor, required this.actions});
  final WorkspaceRecord vendor;
  final EventController actions;
  @override
  Widget build(BuildContext c) {
    final v = vendor;
    final note = v.paid >= v.amount && v.amount > 0
        ? c.tr('event.paid_full')
        : v.notes.isNotEmpty
        ? v.notes
        : v.date == null
        ? ''
        : c.tr(
            'event.next_payment',
            namedArgs: {
              'date': DateFormat.MMMEd(c.locale.toString()).format(v.date!),
            },
          );
    return KitCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          Text(
            v.fields['vendorCategory'] ?? '',
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: naira(c, v.paid),
              style: const TextStyle(fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text:
                      ' / ${v.amount == 0 ? c.tr('event.no_quote') : naira(c, v.amount)}',
                  style: TextStyle(fontWeight: FontWeight.w400, color: c.muted),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 6),
          KitBar(
            value: v.amount == 0 ? 0 : v.paid / v.amount,
            color: KitColor.done,
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(note, style: TextStyle(fontSize: 12, color: c.muted)),
          ],
          if (v.amount > 0 && v.paid < v.amount) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: KitMiniButton(
                c.tr('specials.record_payment'),
                primary: true,
                onPressed: () async {
                  final kobo = await actions.payVendor(v);
                  if (!c.mounted) return;
                  designToast(
                    c,
                    kobo == null
                        ? c.tr('workspaces.try_again')
                        : c.tr(
                            'event.vendor_paid',
                            namedArgs: {
                              'amount': naira(c, kobo),
                              'name': v.title,
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

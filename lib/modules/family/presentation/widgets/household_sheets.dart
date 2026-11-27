import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../router/tms_routes.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../../shared/kit/kit.dart';

Color householdColor(String name) => kitPerson(name).$2;

class HouseholdMemberSheet extends StatelessWidget {
  const HouseholdMemberSheet({super.key, required this.member});
  final WorkspaceRecord member;
  @override
  Widget build(BuildContext c) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          DesignAvatar(
            member.title
                .split(' ')
                .where((v) => v.isNotEmpty)
                .map((v) => v[0])
                .take(2)
                .join(),
            color: householdColor(member.title),
            size: 52,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.tr(
                    'household.roles.${member.fields['householdRole'] ?? 'child'}',
                  ),
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      DesignCard(
        color: DesignColor.purple.withValues(alpha: .17),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.tr(
                'household.can',
                namedArgs: {'name': member.title.split(' ').first},
              ),
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
            const SizedBox(height: 6),
            Text(
              c.tr(
                'household.permissions.${member.fields['householdRole'] ?? 'child'}',
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: DesignButton(
              c.tr('household.message'),
              secondary: true,
              onPressed: () => Navigator.pop(c, 'message'),
            ),
          ),
          Expanded(
            child: DesignButton(
              c.tr('household.give_task'),
              onPressed: () => Navigator.pop(c, 'task'),
            ),
          ),
        ],
      ),
    ],
  );
}

Future<void> showHouseholdTablet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _Tablet(),
    );

class _Tablet extends StatefulWidget {
  const _Tablet();
  @override
  State<_Tablet> createState() => _TabletState();
}

class _TabletState extends State<_Tablet> {
  int child = 0;
  final pin = TextEditingController();
  @override
  void dispose() {
    pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.viewInsetsOf(c).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: c.muted.withValues(alpha: .3),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            c.tr('household.whos_using'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 18,
            children: [
              for (var i = 0; i < 2; i++)
                GestureDetector(
                  onTap: () => setState(() {
                    child = i;
                    pin.clear();
                  }),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: child == i
                                ? DesignColor.purple
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: DesignAvatar(
                          i == 0 ? 'TI' : 'AI',
                          color: i == 0
                              ? DesignColor.amber
                              : const Color(0xffbcd995),
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        i == 0 ? 'Tobi' : 'Ada',
                        style: TextStyle(
                          color: child == i ? c.foreground : c.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 224,
            height: 56,
            child: Stack(
              children: [
                Row(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Expanded(
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.panel,
                            border: Border.all(color: c.outline),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            i < pin.text.length ? '•' : '·',
                            style: TextStyle(
                              fontSize: 26,
                              color: i < pin.text.length
                                  ? c.foreground
                                  : c.muted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: pin,
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {});
                        if (RegExp(r'^\d{4}$').hasMatch(value)) {
                          Navigator.pop(c);
                          TmsRoute.kidHome.open(context);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            c.tr(
              'household.pin',
              namedArgs: {'name': child == 0 ? 'Tobi' : 'Ada'},
            ),
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ],
      ),
    ),
  );
}

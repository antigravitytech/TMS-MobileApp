import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../workspace/application/workspace_preview.dart';
import 'personal_setup_controls.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/workspace_setup.dart';
import '../../application/workspace_personalization_draft.dart';

part 'personalization_family_roles.dart';

class FamilyPersonalization extends ConsumerWidget {
  const FamilyPersonalization({super.key, required this.draft});
  final PersonalizationDraft draft;
  Future<void> edit(BuildContext context, [int? index]) async {
    final member = index == null ? null : draft.members[index];
    final next = await designSheet<SetupMember>(
      context,
      title: context.tr(
        index == null
            ? 'workspaces.sections.household.add'
            : 'workspaces.edit_record',
      ),
      builder: (_) => _MemberForm(initial: member),
    );
    if (next != null && context.mounted) draft.saveMember(next, index);
  }

  Future<void> pickRole(BuildContext context, int index) async {
    final member = draft.members[index];
    final role = await designSheet<HouseholdRole>(
      context,
      title: context.tr(
        'setup_details.role_for',
        namedArgs: {'name': member.name},
      ),
      builder: (context) => Column(
        children: [
          for (final role in HouseholdRole.values)
            ListTile(
              leading: SetupIconTile(
                _roleIcons[role.index],
                _roleColors[role.index],
                size: 36,
              ),
              title: Text(_roleName(context, role)),
              subtitle: Text(context.tr('setup_details.roles.${role.name}')),
              selected: member.role == role,
              onTap: () => Navigator.pop(context, role),
            ),
        ],
      ),
    );
    if (role != null && context.mounted) {
      draft.saveMember((name: member.name, role: role), index);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(
      workspacePreviewProvider.select((value) => value.firstName),
    );
    final crestColor = const [
      DesignColor.teal,
      DesignColor.purple,
      DesignColor.amber,
      DesignColor.rose,
    ][draft.crest];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 16,
          children: [
            AnimatedContainer(
              duration: DesignMotion.duration(
                context,
                const Duration(milliseconds: 400),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: crestColor.withValues(alpha: .62),
                    offset: const Offset(0, 18),
                    blurRadius: 30,
                    spreadRadius: -14,
                  ),
                ],
              ),
              child: IconButton.filled(
                tooltip: context.tr('setup_details.crest'),
                onPressed: draft.nextCrest,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(84),
                  backgroundColor: crestColor,
                  foregroundColor: DesignColor.ink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                icon: Icon(
                  const [
                    TmsIcons.home,
                    TmsIcons.heart,
                    TmsIcons.star,
                    TmsIcons.flame,
                  ][draft.crest],
                  size: 36,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SetupNameInput(
                    label: context.tr('setup_details.family_name'),
                    hint: context.tr('setup_details.family_hint'),
                    value: draft.name,
                    onChanged: draft.setName,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.tr('setup_details.crest_hint'),
                    style: TextStyle(color: context.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          spacing: 6,
          children: [
            Text(
              context.tr('setup_details.member_heading'),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: context.raised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                NumberFormat.decimalPattern(
                  context.locale.toString(),
                ).format(draft.members.length + 1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _MemberCard(
          head: true,
          children: [
            DesignAvatar(_initials(name), size: 36, color: DesignColor.teal),
            Expanded(
              child: Text(
                context.tr('setup_details.owner', namedArgs: {'name': name}),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: DesignColor.purple.withValues(alpha: .17),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr('setup_details.head').toUpperCase(),
                style: TextStyle(
                  color: context.lavender,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        for (final (index, member) in draft.members.indexed) ...[
          const SizedBox(height: 8),
          _MemberCard(
            children: [
              DesignAvatar(
                _initials(member.name),
                size: 36,
                color: _memberColors[index % _memberColors.length],
              ),
              Expanded(
                child: InkWell(
                  onTap: () => edit(context, index),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        context.tr(
                          member.role == HouseholdRole.child
                              ? 'setup_details.tablet_pin'
                              : 'setup_details.invite_by_link',
                        ),
                        style: TextStyle(fontSize: 12, color: context.muted),
                      ),
                    ],
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: () => pickRole(context, index),
                style: OutlinedButton.styleFrom(
                  backgroundColor: context.raised,
                  foregroundColor: context.foreground,
                  side: BorderSide(color: context.outline),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(_roleName(context, member.role)),
              ),
              IconButton(
                tooltip: context.tr('workspaces.remove'),
                onPressed: () => draft.removeMember(index),
                style: IconButton.styleFrom(
                  minimumSize: const Size.square(30),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(TmsIcons.close, color: context.muted, size: 16),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        CustomPaint(
          painter: _AddMemberOutline(context.outline),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 56),
              foregroundColor: context.lavender,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(TmsIcons.add, size: 20),
            label: Text(context.tr('setup_details.add_member')),
            onPressed: () => edit(context),
          ),
        ),
        const SizedBox(height: 16),
        SetupInfo(
          icon: TmsIcons.tablet,
          color: DesignColor.teal,
          child: Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13.5, height: 1.5),
              children: [
                TextSpan(text: context.tr('setup_details.tablet_info_start')),
                TextSpan(
                  text: context.tr('setup_details.tablet_info_bold'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: context.tr('setup_details.tablet_info_end')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _FamilyRoleGuide(),
      ],
    );
  }
}

const _roleIcons = [
  TmsIcons.heart,
  TmsIcons.star,
  TmsIcons.people,
  TmsIcons.shoppingBag,
  TmsIcons.shield,
  TmsIcons.car,
];
const _roleColors = [
  DesignColor.purple,
  DesignColor.amber,
  DesignColor.blue,
  DesignColor.teal,
  DesignColor.green,
  DesignColor.red,
];
const _memberColors = [
  DesignColor.rose,
  DesignColor.amber,
  Color(0xffbedb9a),
  DesignColor.blue,
  Color(0xffd8b4ec),
];

String _roleName(BuildContext context, HouseholdRole role) => context.tr(
  role == HouseholdRole.coHead
      ? 'setup_details.co_head'
      : 'workspaces.roles.${role.name}',
);

String _initials(String name) => name
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.characters.first.toUpperCase())
    .join();

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.children, this.head = false});
  final List<Widget> children;
  final bool head;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
    decoration: BoxDecoration(
      color: context.panel,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: head ? DesignColor.purple : context.outline),
    ),
    child: Row(spacing: 10, children: children),
  );
}

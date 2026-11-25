import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/workspace_setup.dart';
import '../../application/workspace_personalization_draft.dart';

class FamilyPersonalization extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 14,
    children: [
      Row(
        spacing: 12,
        children: [
          IconButton.filled(
            tooltip: context.tr('setup_details.crest'),
            onPressed: draft.nextCrest,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(56),
              backgroundColor: [
                DesignColor.teal,
                DesignColor.purple,
                DesignColor.amber,
                DesignColor.rose,
              ][draft.crest],
            ),
            icon: Icon(
              [
                TmsIcons.home,
                TmsIcons.heart,
                TmsIcons.star,
                TmsIcons.flame,
              ][draft.crest],
              color: DesignColor.ink,
            ),
          ),
          Expanded(
            child: DesignField(
              label: context.tr('setup_details.family_name'),
              initialValue: draft.name,
              onChanged: draft.setName,
            ),
          ),
        ],
      ),
      DesignTitle(
        context.tr(
          'setup_details.members',
          namedArgs: {'n': '${draft.members.length + 1}'},
        ),
      ),
      DesignSection(
        children: [
          DesignTile(
            title: context.tr('setup_details.you'),
            subtitle: context.tr('setup_details.head'),
            leading: const DesignAvatar('★', color: DesignColor.teal),
          ),
          for (final (i, m) in draft.members.indexed)
            DesignTile(
              title: m.name,
              subtitle: context.tr('workspaces.roles.${m.role.name}'),
              leading: DesignAvatar(m.name.characters.first),
              onTap: () => edit(context, i),
              trailing: IconButton(
                tooltip: context.tr('workspaces.remove'),
                icon: const Icon(TmsIcons.close),
                onPressed: () => draft.removeMember(i),
              ),
            ),
          DesignTile(
            title: context.tr('workspaces.sections.household.add'),
            icon: TmsIcons.addPerson,
            onTap: () => edit(context),
          ),
        ],
      ),
      DesignLabel(context.tr('setup_details.role_guide').toUpperCase()),
      for (final r in HouseholdRole.values)
        DesignTile(
          title: context.tr('workspaces.roles.${r.name}'),
          subtitle: context.tr('setup_details.roles.${r.name}'),
          icon: TmsIcons.person,
        ),
    ],
  );
}

class _MemberForm extends StatefulWidget {
  const _MemberForm({this.initial});
  final SetupMember? initial;
  @override
  State<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends State<_MemberForm> {
  late String name = widget.initial?.name ?? '';
  late HouseholdRole role = widget.initial?.role ?? HouseholdRole.child;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      DesignField(
        label: context.tr('workspaces.name'),
        initialValue: name,
        onChanged: (s) => setState(() => name = s.trim()),
      ),
      DesignTitle(context.tr('workspaces.setup.member_role')),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final r in HouseholdRole.values)
            DesignPill(
              context.tr('workspaces.roles.${r.name}'),
              selected: r == role,
              onTap: () => setState(() => role = r),
            ),
        ],
      ),
      DesignLabel(context.tr('setup_details.roles.${role.name}')),
      DesignButton(
        context.tr('workspaces.save'),
        onPressed: name.isEmpty
            ? null
            : () => Navigator.pop(context, (name: name, role: role)),
      ),
    ],
  );
}

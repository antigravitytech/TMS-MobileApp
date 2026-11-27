part of '../workspace_setup_screen.dart';

extension on _WorkspaceSetupScreenState {
  Widget _doorChoices(BuildContext context) {
    final tr = context.tr;
    return Column(
      key: const ValueKey('door'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('onboarding.new_workspace').toUpperCase(),
          style: TextStyle(
            color: context.muted,
            fontSize: 11,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          tr('onboarding.what_are_you_setting_up'),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.12,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 10),
        DesignLabel(
          tr('onboarding.well_shape_tasks_roles_and_reminders_around'),
        ),
        const SizedBox(height: 24),
        WorkspaceSetupChoice(
          title: tr('onboarding.setup_business'),
          subtitle: tr('onboarding.setup_business_description'),
          icon: TmsIcons.building,
          selected: door == _WorkspaceDoor.business,
          onTap: () => selectDoor(_WorkspaceDoor.business),
        ),
        const SizedBox(height: 12),
        WorkspaceSetupChoice(
          title: tr('onboarding.setup_personal'),
          subtitle: tr('onboarding.setup_personal_short'),
          icon: TmsIcons.home,
          color: DesignColor.teal,
          selected: door == _WorkspaceDoor.personal,
          onTap: () => selectDoor(_WorkspaceDoor.personal),
        ),
        if (!ref.watch(environmentProvider).isLive) ...[
          const SizedBox(height: 12),
          WorkspaceSetupChoice(
            title: tr('workspaces.specials'),
            subtitle: tr('onboarding.setup_specials_short'),
            icon: TmsIcons.star,
            color: DesignColor.amber,
            selected: door == _WorkspaceDoor.specials,
            onTap: () => selectDoor(_WorkspaceDoor.specials),
          ),
        ],
        const SizedBox(height: 24),
        WorkspaceNameField(
          fieldType: door.name,
          name: name,
          slug: slug,
          onChanged: _setName,
        ),
      ],
    );
  }
}

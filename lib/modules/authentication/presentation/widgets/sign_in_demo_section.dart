part of '../sign_in_screen.dart';

extension on _SignInScreenState {
  Widget _demoSection(BuildContext context, TextStyle muted) {
    final tr = context.tr;
    return DesignEntrance(
      order: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                Text(
                  tr('onboarding.try_a_demo'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: Text(
                    tr('sign_in.demo_caption'),
                    style: muted,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              spacing: 10,
              children: [
                for (final (kind, label, icon, color) in const [
                  (
                    WorkspaceKind.business,
                    'sign_in.company',
                    TmsIcons.building,
                    DesignColor.purple,
                  ),
                  (
                    WorkspaceKind.individual,
                    'sign_in.freelancer',
                    TmsIcons.monitor,
                    DesignColor.blue,
                  ),
                  (
                    WorkspaceKind.family,
                    'common.family',
                    TmsIcons.home,
                    DesignColor.teal,
                  ),
                  (
                    WorkspaceKind.event,
                    'sign_in.wedding',
                    TmsIcons.wedding,
                    DesignColor.amber,
                  ),
                ])
                  SignInDemoCard(
                    label: tr(label),
                    icon: icon,
                    color: color,
                    onTap: _busy ? null : () => _demo(kind),
                  ),
                SignInDemoCard(
                  label: tr('workspaces.specials'),
                  icon: TmsIcons.star,
                  color: DesignColor.purple,
                  onTap: _busy
                      ? null
                      : () => showWorkspacePicker(
                          context,
                          ref,
                          ref.read(workspacePreviewProvider).workspace,
                          returnHome: true,
                          specialsOnly: true,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

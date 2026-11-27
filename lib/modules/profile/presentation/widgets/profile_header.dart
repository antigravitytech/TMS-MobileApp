part of '../profile_screen.dart';

Color _presenceColor(Presence presence) => switch (presence) {
  Presence.available => DesignColor.green,
  Presence.meeting => DesignColor.amber,
  Presence.focusing => DesignColor.purple,
  Presence.away => const Color(0xff75798c),
};

/// The gradient header: name, job, status and roles.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader(this.profile);
  final ProfileSummary profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget action(IconData icon, String label, VoidCallback tap) => IconButton(
      onPressed: tap,
      tooltip: context.tr(label),
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: const Color(0xfff3f5fe),
        backgroundColor: const Color(0x17ffffff),
        minimumSize: const Size.square(44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x22ffffff)),
        ),
      ),
    );
    final p = profile;
    final roles = [
      (
        switch (p.role) {
          'owner' => 'profile.owner',
          'admin' => 'profile.admin',
          _ => 'common.member',
        },
        DesignColor.teal,
      ),
      if (p.lineManager) ('common.line_manager', const Color(0xffd2cefd)),
      if (p.projectManager) ('profile.pm', const Color(0xffd2cefd)),
      if (p.teamLead) ('common.team_lead', const Color(0xffd2cefd)),
    ];
    return CustomPaint(
      painter: const DesignHeroGradient(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                action(TmsIcons.chevronBack, 'common.back', () async {
                  if (!await context.router.maybePop() && context.mounted) {
                    TmsRoute.home.reset(context);
                  }
                }),
                action(
                  TmsIcons.edit,
                  'common.edit_profile',
                  () => TmsRoute.settings.open(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              spacing: 16,
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x22ffffff), spreadRadius: 4),
                    ],
                  ),
                  child: DesignAvatar(
                    _initials('${p.firstName} ${p.lastName}'),
                    size: 84,
                    color: const Color(0xffc4bdf6),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${p.firstName} ${p.lastName}'.trim(),
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.12,
                          letterSpacing: -.6,
                          fontWeight: FontWeight.w700,
                          color: Color(0xfff3f5fe),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        p.department.isEmpty
                            ? p.jobTitle
                            : context.tr(
                                'profile.jobtitle_department',
                                namedArgs: {
                                  'jobTitle': p.jobTitle,
                                  'department': p.department,
                                },
                              ),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Color(0xffc9cbe0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          backgroundColor: const Color(0x17ffffff),
                          foregroundColor: const Color(0xfff3f5fe),
                          textStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        onPressed: () => _changeStatus(context, ref, p),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 7,
                          children: [
                            CircleAvatar(
                              radius: 4,
                              backgroundColor: _presenceColor(p.presence),
                            ),
                            Flexible(
                              child: Text(
                                context.tr(presenceLabelKey(p.presence)),
                              ),
                            ),
                            const Icon(TmsIcons.chevronDown, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (label, color) in roles)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      context.tr(label),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    ProfileSummary p,
  ) async {
    final picked = await _pickStatus(context, p.presence);
    if (picked == null || picked == p.presence) return;
    try {
      await ref.read(profileProvider.notifier).setPresence(picked);
    } catch (error) {
      if (context.mounted) designToast(context, _profileError(context, error));
    }
  }
}

String _initials(String name) => name
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part.characters.first.toUpperCase())
    .join();

String _profileError(BuildContext context, Object? error) =>
    error is AccountFailure
    ? error.type.localizedMessage(context)
    : context.tr('network.errors.unknown');

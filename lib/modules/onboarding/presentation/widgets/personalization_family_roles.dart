part of 'personalization_family.dart';

class _FamilyRoleGuide extends StatelessWidget {
  const _FamilyRoleGuide();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        context.tr('setup_details.role_guide').toUpperCase(),
        style: setupLabel(context).copyWith(
          fontSize: 11.5,
          letterSpacing: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 6),
      DesignCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (final (index, role) in HouseholdRole.values.indexed) ...[
              if (index > 0)
                Divider(
                  height: 1,
                  color: context.outline.withValues(alpha: .08),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    SetupIconTile(
                      _roleIcons[index],
                      _roleColors[index],
                      size: 32,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            _roleName(context, role),
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            context.tr('setup_details.roles.${role.name}'),
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.35,
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
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

class _AddMemberOutline extends CustomPainter {
  const _AddMemberOutline(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(.5),
          const Radius.circular(18),
        ),
      );
    final border = path.computeMetrics().first;
    final pen = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double start = 0; start < border.length; start += 5) {
      canvas.drawPath(border.extractPath(start, start + 2.5), pen);
    }
  }

  @override
  bool shouldRepaint(_AddMemberOutline old) => old.color != color;
}

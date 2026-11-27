part of '../building_screen.dart';

class _WorkspaceInvite extends StatelessWidget {
  const _WorkspaceInvite({required this.name, required this.kind});
  final String name;
  final WorkspaceKind kind;
  String get link =>
      'sabipipu.app/j/${name.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "-").replaceAll(RegExp(r"^-|-$"), "")}';
  Future<void> copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: 'https://$link'));
    if (context.mounted) designToast(context, context.tr('building.copied'));
  }

  void activate(BuildContext context, String action) {
    switch (action) {
      case 'link':
        copy(context);
      case 'qr':
        designSheet<void>(
          context,
          title: context.tr('building.qr'),
          builder: (_) => Center(
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: CustomPaint(
                  size: const Size.square(200),
                  painter: QrPainter('https://$link'),
                ),
              ),
            ),
          ),
        );
      default:
        designToast(context, context.tr('building.${action}_feedback'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      WorkspaceKind.family => 'family',
      WorkspaceKind.individual => 'individual',
      _ => 'members',
    };
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: 1,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                  color: DesignColor.purple,
                ),
              ),
              Text(
                context.tr('building.step'),
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: TweenAnimationBuilder<double>(
            duration: DesignMotion.duration(
              context,
              const Duration(milliseconds: 450),
            ),
            curve: DesignMotion.curve,
            tween: Tween(begin: 0, end: 1),
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset((1 - t) * 30, 0),
                child: child,
              ),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
              children: [
                Text(
                  context
                      .tr('building.ready', namedArgs: {'name': name})
                      .toUpperCase(),
                  style: TextStyle(
                    color: context.lavender,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('building.$title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('building.hint'),
                  style: TextStyle(color: context.muted),
                ),
                const SizedBox(height: 22),
                Column(
                  spacing: 10,
                  children: [
                    for (final pair in const [
                      [
                        ('contacts', TmsIcons.phone, DesignColor.purple),
                        ('link', TmsIcons.link, DesignColor.teal),
                      ],
                      [
                        ('qr', TmsIcons.qrCode, DesignColor.amber),
                        ('email', TmsIcons.email, DesignColor.blue),
                      ],
                    ])
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 10,
                          children: [
                            for (final (key, icon, color) in pair)
                              Expanded(
                                child: Material(
                                  color: context.panel,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(color: context.outline),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => activate(context, key),
                                    child: Container(
                                      constraints: const BoxConstraints(
                                        minHeight: 118,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: .12,
                                              ),
                                              border: Border.all(
                                                color: color.withValues(
                                                  alpha: .25,
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                            ),
                                            child: Icon(
                                              icon,
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            context.tr('building.$key'),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Text(
                                            context.tr('building.${key}_hint'),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: context.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: context.panel,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('building.url'),
                        style: TextStyle(color: context.muted, fontSize: 12),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              link,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.lavender,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: DesignColor.purple,
                              foregroundColor: DesignColor.ink,
                              minimumSize: const Size(58, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                            onPressed: () => copy(context),
                            child: Text(context.tr('building.copy')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.outline)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignColor.purple,
                    foregroundColor: DesignColor.ink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => TmsRoute.home.reset(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      Text(
                        context.tr('building.open'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Icon(TmsIcons.arrowForward, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => TmsRoute.home.reset(context),
                child: Text(context.tr('onboarding.skip_for_now')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

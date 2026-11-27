part of '../profile_screen.dart';

class _ProfileCaption extends StatelessWidget {
  const _ProfileCaption(this.text, {this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontSize: 12,
      height: 1.4,
      color: color ?? context.muted,
      letterSpacing: 0,
    ),
  );
}

class _ProfileRelation extends StatelessWidget {
  const _ProfileRelation({
    required this.avatar,
    required this.title,
    required this.detail,
    required this.route,
    this.captionFirst = false,
    this.beforeOpen,
  });
  final Widget avatar;
  final String title, detail;
  final TmsRoute route;
  final VoidCallback? beforeOpen;
  final bool captionFirst;
  @override
  Widget build(BuildContext context) {
    final heading = Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    );
    final caption = _ProfileCaption(detail);
    return InkWell(
      onTap: () {
        beforeOpen?.call();
        route.open(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          spacing: 12,
          children: [
            avatar,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (captionFirst) ...[
                    caption,
                    heading,
                  ] else ...[
                    heading,
                    caption,
                  ],
                ],
              ),
            ),
            Icon(TmsIcons.chevronNext, size: 15, color: context.muted),
          ],
        ),
      ),
    );
  }
}

class _ReportAvatars extends StatelessWidget {
  const _ReportAvatars();
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 86,
    height: 28,
    child: Stack(
      children: [
        for (final (index, (initial, color)) in const [
          ('TB', Color(0xff86d6cb)),
          ('AE', Color(0xffeeabb0)),
          ('DM', Color(0xffbcd995)),
          ('SJ', DesignColor.amber),
        ].indexed)
          PositionedDirectional(
            start: 19.0 * index,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.panel,
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: DesignAvatar(initial, size: 25, color: color),
              ),
            ),
          ),
      ],
    ),
  );
}

class _StreakGrid extends StatelessWidget {
  const _StreakGrid();
  @override
  Widget build(BuildContext context) {
    final colors = [
      context.raised,
      const Color(0xff9184d9).withValues(alpha: .35),
      const Color(0xff9184d9).withValues(alpha: .65),
      DesignColor.purple,
    ];
    var seed = 11;
    Widget cell(int i) {
      seed = (seed * 9301 + 49297) % 233280;
      final sample = seed / 233280;
      final level = i >= 101
          ? 0
          : i % 15 > 11
          ? (sample > .3 ? 3 : 2)
          : sample > .75
          ? 3
          : sample > .45
          ? 2
          : sample > .2
          ? 1
          : 0;
      return Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors[level],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    }

    return DesignCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 10,
        children: [
          Semantics(
            label: context.tr('profile.activity_description'),
            child: Column(
              spacing: 4,
              children: [
                for (var row = 0; row < 7; row++)
                  Row(
                    spacing: 4,
                    children: [
                      for (var col = 0; col < 15; col++) cell(row * 15 + col),
                    ],
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 5,
            children: [
              _ProfileCaption(context.tr('profile.less')),
              for (final color in colors)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              _ProfileCaption(context.tr('common.more')),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (index, (key, icon, color)) in const [
          ('first_time', TmsIcons.check, DesignColor.green),
          ('week_streak', TmsIcons.flame, Color(0xfff29962)),
          ('early', TmsIcons.clock, DesignColor.amber),
          ('zero_overdue', TmsIcons.clock, DesignColor.purple),
          ('century', TmsIcons.star, DesignColor.purple),
        ].indexed)
          SizedBox(
            width: (size.maxWidth - 20) / 3,
            child: Opacity(
              opacity: index < 3 ? 1 : .45,
              child: DesignCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 14,
                ),
                child: Column(
                  spacing: 8,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: index < 3 ? color : context.raised,
                      foregroundColor: index < 3
                          ? DesignColor.ink
                          : context.muted,
                      child: Icon(icon, size: 18),
                    ),
                    Text(
                      context.tr('profile.medals.$key.title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      context.tr('profile.medals.$key.detail'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: context.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

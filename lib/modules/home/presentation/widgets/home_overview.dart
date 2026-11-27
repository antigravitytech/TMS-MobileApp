part of '../home_screen.dart';

class _HomeOverview extends StatelessWidget {
  const _HomeOverview({
    required this.firstName,
    required this.due,
    required this.reviews,
    this.overdue = 0,
    this.preview = true,
    this.birthday,
  });
  final String firstName;
  final int? due, reviews, overdue;
  final bool preview;
  final Widget? birthday;
  @override
  Widget build(BuildContext context) {
    final greeting = context.tr('home.greeting').split('{name}');
    final numbers = NumberFormat.decimalPattern(context.locale.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text.rich(
          TextSpan(
            text: greeting.first,
            children: [
              for (final suffix in greeting.skip(1)) ...[
                TextSpan(
                  text: firstName,
                  style: TextStyle(color: context.lavender),
                ),
                TextSpan(text: suffix),
              ],
            ],
          ),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.12,
            letterSpacing: -.7,
          ),
        ),
        if (preview) const SizedBox(height: 16),
        if (preview)
          Material(
            color: context.panel,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: context.outline),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => TmsRoute.search.open(context),
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 5, 6, 5),
                child: Row(
                  spacing: 12,
                  children: [
                    Icon(TmsIcons.search, size: 19, color: context.muted),
                    Expanded(
                      child: Text(
                        context.tr('common.search_tasks_people_or_actions'),
                        style: TextStyle(
                          fontSize: 15,
                          color: context.muted,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: DesignColor.purple.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        TmsIcons.microphone,
                        size: 17,
                        color: context.lavender,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              if (due case final count?)
                _Metric(
                  context.tr(
                    'home.due_today',
                    namedArgs: {'count': numbers.format(count)},
                  ),
                  DesignColor.amber,
                  preview ? TmsRoute.tasks : null,
                ),
              if (overdue case final count?)
                _Metric(
                  context.tr(
                    'home.live_overdue',
                    namedArgs: {'count': numbers.format(count)},
                  ),
                  DesignColor.red,
                  preview ? TmsRoute.tasks : null,
                ),
              if (reviews case final count?)
                _Metric(
                  context.tr(
                    'home.to_review',
                    namedArgs: {'count': numbers.format(count)},
                  ),
                  DesignColor.purple,
                  preview ? TmsRoute.approvals : null,
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: DesignMotion.duration(context, DesignMotion.page),
          alignment: Alignment.topCenter,
          child: birthday == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: birthday!,
                ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color, {this.size = 7});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.color, this.route);
  final String label;
  final Color color;
  final TmsRoute? route;
  @override
  Widget build(BuildContext context) => Material(
    color: context.panel,
    shape: StadiumBorder(side: BorderSide(color: context.outline)),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: route == null ? null : () => route!.open(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 32),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          spacing: 7,
          children: [
            _Dot(color),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BirthdayBanner extends StatelessWidget {
  const _BirthdayBanner({required this.onClose, this.name, this.onWish});
  final VoidCallback? onClose, onWish;
  final String? name;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xff6d4bd4), Color(0xffc2449b)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0xffc2449b),
          blurRadius: 26,
          spreadRadius: -16,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 6, 4),
      child: Row(
        spacing: 8,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: DesignMotion.duration(
              context,
              const Duration(milliseconds: 1800),
            ),
            builder: (_, progress, child) {
              final turn = ((progress - 1 / 3) * 1.5).clamp(0.0, 1.0);
              return Transform.rotate(
                angle:
                    math.sin(turn * math.pi * 4) *
                    .14 *
                    math.sin(turn * math.pi),
                child: child,
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0x26ffffff),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                TmsIcons.birthday,
                color: Colors.white,
                size: 17,
              ),
            ),
          ),
          Expanded(
            child: Text(
              context.tr('home.happy_birthday'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          if (name == null || onWish != null)
            TextButton(
              onPressed: name == null
                  ? () => TmsRoute.birthdays.open(context)
                  : onWish,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xff4a2d8f),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(
                name == null
                    ? context.tr('home.wish_tunde')
                    : context.tr(
                        'home.wish_person',
                        namedArgs: {'name': name!},
                      ),
              ),
            ),
          if (onClose != null)
            IconButton(
              tooltip: context.tr('home.dismiss_birthday_banner'),
              onPressed: onClose,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 44),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(TmsIcons.close, size: 14, color: Colors.white70),
            ),
        ],
      ),
    ),
  );
}

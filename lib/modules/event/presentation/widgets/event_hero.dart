import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';

/// `.ev-hero`: a sunset card with the countdown and invite actions.
class EventHero extends StatelessWidget {
  const EventHero({
    super.key,
    required this.days,
    required this.hosts,
    required this.title,
    required this.line,
    required this.style,
    required this.onShare,
  });
  final int days;
  final String hosts, title, line, style;
  final VoidCallback onShare;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const RadialGradient(
        center: Alignment.topRight,
        radius: 1.25,
        colors: [Color(0xffeccb84), Color(0xffb4572f), Color(0xff3b1d3f)],
        stops: [0, .4, .95],
      ),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 14,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$days',
                    style: const TextStyle(
                      fontSize: 56,
                      height: .95,
                      letterSpacing: -2.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    c.plural('specials.days_to_go', days).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .7,
                      color: Color(0xffffe7c2),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hosts.isNotEmpty)
                      Opacity(
                        opacity: .85,
                        child: Text(
                          c
                              .tr(
                                'event.hosted_by',
                                namedArgs: {'hosts': hosts},
                              )
                              .toUpperCase(),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Opacity(
                      opacity: .85,
                      child: Text(
                        line,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (style.isNotEmpty) ...[
            const SizedBox(height: 12),
            Opacity(
              opacity: .9,
              child: Text(style, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: HeroButton(
                  c.tr('event.share_invite'),
                  light: true,
                  onTap: onShare,
                ),
              ),
              Expanded(
                child: HeroButton(c.tr('event.guest_page'), onTap: onShare),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A button on the sunset hero; [light] is the filled one.
class HeroButton extends StatelessWidget {
  const HeroButton(
    this.label, {
    super.key,
    required this.onTap,
    this.light = false,
  });
  final String label;
  final bool light;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext c) => SizedBox(
    height: 44,
    child: TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: light
            ? const Color(0xfff3f5fe)
            : const Color(0x26ffffff),
        foregroundColor: light ? DesignColor.ink : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: Theme.of(c).textTheme.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    ),
  );
}

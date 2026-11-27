part of '../visitors_screen.dart';

/// "Today", "Tomorrow" or a short date.
String _visitDay(BuildContext context, DateTime day) {
  final now = DateTime.now();
  final days = DateTime(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime(now.year, now.month, now.day)).inDays;
  if (days == 0) return context.tr('common.today');
  if (days == 1) return context.tr('common.tomorrow');
  return DateFormat('EEE, d MMM', context.locale.toString()).format(day);
}

class _WaitingVisitor extends StatelessWidget {
  const _WaitingVisitor({required this.pass, required this.onDecision});
  final VisitPass pass;
  final ValueChanged<GuestAnswer> onDecision;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      gradient: const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [Color(0xff203750), Color(0xff242445), Color(0xff44478d)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            DesignAvatar(
              kitPerson(pass.guest).$1,
              color: kitPerson(pass.guest).$2,
              size: 52,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pass.guest,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.plural(
                      'visitors.arrived_minutes_ago',
                      DateTime.now()
                          .difference(pass.arrivedAt ?? DateTime.now())
                          .inMinutes,
                    ),
                    style: TextStyle(fontSize: 12, color: context.lavender),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: DesignColor.amber.withValues(alpha: .2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: DesignColor.amber,
                ),
              ),
            ),
          ],
        ),
        if (pass.purpose.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            pass.purpose,
            style: TextStyle(fontSize: 13, color: context.lavender),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          spacing: 8,
          children: [
            for (final (key, decision) in const [
              ('visitors.come_in', GuestAnswer.admit),
              ('visitors.wait_10_min', GuestAnswer.hold),
              ('visitors.not_today', GuestAnswer.decline),
            ])
              Expanded(
                child: decision == GuestAnswer.admit
                    ? DesignButton(
                        context.tr(key),
                        color: DesignColor.green,
                        onPressed: () => onDecision(decision),
                      )
                    : OutlinedButton(
                        onPressed: () => onDecision(decision),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          padding: EdgeInsets.zero,
                          foregroundColor: context.foreground,
                          backgroundColor: context.raised,
                          side: BorderSide(color: context.outline),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          context.tr(key),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ],
    ),
  );
}

/// What reception was told about a guest I answered.
class _AnsweredVisitor extends StatelessWidget {
  const _AnsweredVisitor({
    super.key,
    required this.name,
    required this.decision,
  });
  final String name;
  final GuestAnswer decision;
  @override
  Widget build(BuildContext context) => DesignCard(
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: DesignColor.green.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: DesignColor.green.withValues(alpha: .3)),
          ),
          child: const Icon(TmsIcons.check, color: DesignColor.green),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  switch (decision) {
                    GuestAnswer.admit => 'visitors.asked_to_come',
                    GuestAnswer.hold => 'visitors.asked_to_wait',
                    GuestAnswer.decline => 'visitors.told_not_today',
                  },
                  namedArgs: {'name': name},
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('visitors.reception_has_been_told'),
                style: TextStyle(fontSize: 12, color: context.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VisitorHeading extends StatelessWidget {
  const _VisitorHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 2),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: context.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
    ),
  );
}

class _VisitorInput extends StatelessWidget {
  const _VisitorInput({
    required this.label,
    required this.initialValue,
    required this.onChanged,
  });
  final String label, initialValue;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: context.muted, fontSize: 13)),
      const SizedBox(height: 10),
      TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: context.raised.withValues(alpha: .35),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.outline),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ],
  );
}

class _VisitorDateField extends StatelessWidget {
  const _VisitorDateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: context.muted, fontSize: 13)),
      const SizedBox(height: 10),
      Material(
        color: context.raised.withValues(alpha: .35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 58,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(value, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    ],
  );
}

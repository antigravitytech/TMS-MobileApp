part of '../visitors_screen.dart';

class _WaitingVisitor extends StatelessWidget {
  const _WaitingVisitor({required this.onDecision});
  final ValueChanged<String> onDecision;
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
            const DesignAvatar('FA', color: DesignColor.amber, size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Folake Adebayo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('visitors.at_reception_arrived_2_min_ago'),
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
        const SizedBox(height: 16),
        Text(
          context.tr('visitors.interview_backend_engineer_role'),
          style: TextStyle(fontSize: 13, color: context.lavender),
        ),
        const SizedBox(height: 18),
        Row(
          spacing: 8,
          children: [
            for (final key in [
              'visitors.come_in',
              'visitors.wait_10_min',
              'visitors.not_today',
            ])
              Expanded(
                child: key == 'visitors.come_in'
                    ? DesignButton(
                        context.tr(key),
                        color: DesignColor.green,
                        onPressed: () => onDecision(key),
                      )
                    : OutlinedButton(
                        onPressed: () => onDecision(key),
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

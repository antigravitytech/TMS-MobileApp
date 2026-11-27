part of '../reports_screen.dart';

class _ReportInput extends StatelessWidget {
  const _ReportInput({
    this.initialValue,
    this.hint,
    this.onChanged,
    required this.lines,
  });
  final String? initialValue, hint;
  final ValueChanged<String>? onChanged;
  final int lines;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: initialValue,
    maxLines: lines,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 16, height: 1.5),
    decoration: InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: context.panel,
      contentPadding: const EdgeInsets.all(16),
      hintStyle: TextStyle(color: context.muted.withValues(alpha: .65)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: context.outline),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class _ReportTabs extends StatelessWidget {
  const _ReportTabs({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: context.panel,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: context.outline),
    ),
    child: Row(
      children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: DesignMotion.fast,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tab == i ? context.raised : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  context.tr(
                    i == 0 ? 'reports.log_today' : 'reports.team_summaries',
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: tab == i ? context.foreground : context.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ReportChip extends StatelessWidget {
  const _ReportChip(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.foreground : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: context.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? context.background : context.muted,
          ),
        ),
      ),
    ),
  );
}

class _ReportSuccessMark extends StatelessWidget {
  const _ReportSuccessMark();
  @override
  Widget build(BuildContext context) => Center(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: .5, end: 1),
      duration: DesignMotion.duration(
        context,
        const Duration(milliseconds: 450),
      ),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xff2eb4a5),
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color(0x5530b5a6),
              offset: Offset(0, 25),
              blurRadius: 45,
              spreadRadius: -12,
            ),
          ],
        ),
        child: const Icon(TmsIcons.check, size: 48, color: DesignColor.ink),
      ),
    ),
  );
}

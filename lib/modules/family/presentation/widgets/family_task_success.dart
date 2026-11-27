part of '../family_task_screen.dart';

class _FamilyTaskSuccess extends StatelessWidget {
  const _FamilyTaskSuccess({
    required this.draft,
    required this.names,
    required this.onAgain,
  });
  final FamilyTaskDraft draft;
  final String names;
  final VoidCallback onAgain;
  @override
  Widget build(BuildContext context) {
    final when = draft.when == FamilyWhen.pick
        ? DateFormat.MMMd(context.locale.toString()).format(draft.date)
        : context.tr('family.confirm_when_${draft.when.name}');
    var detail = context.tr(
      'family.done',
      namedArgs: {
        'type': context.tr('family.${draft.type.name}'),
        'names': names,
        'when': when,
      },
    );
    if (draft.type == FamilyTaskType.chore && draft.points > 0) {
      detail +=
          ' · ${context.plural('workspaces.points', draft.points, name: 'count')}';
    }
    return Scaffold(
      backgroundColor: const Color(0xff1d1f2a),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: .7, end: 1),
                      duration: DesignMotion.duration(
                        context,
                        const Duration(milliseconds: 450),
                      ),
                      curve: Curves.easeOutBack,
                      builder: (_, value, child) =>
                          Transform.scale(scale: value, child: child),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: DesignColor.teal,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x445fd3c4),
                              blurRadius: 40,
                              offset: Offset(0, 22),
                              spreadRadius: -8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          TmsIcons.check,
                          size: 54,
                          color: DesignColor.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    draft.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    detail,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.muted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  DesignButton(
                    context.tr('family.back_home'),
                    onPressed: () => TmsRoute.home.reset(context),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: onAgain,
                    style: TextButton.styleFrom(
                      foregroundColor: context.muted,
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      context.tr('family.another'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

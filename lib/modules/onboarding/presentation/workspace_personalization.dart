import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import 'widgets/special_setup_options.dart';
import 'widgets/special_personalization.dart';
import '../application/workspace_personalization_draft.dart';
import 'widgets/personalization_family.dart';
import 'widgets/personalization_work.dart';
import 'widgets/personal_setup_controls.dart';

class WorkspacePersonalization extends ConsumerWidget {
  const WorkspacePersonalization({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = context.routeData.args is PersonalizationInput
        ? context.routeData.args as PersonalizationInput
        : (kind: WorkspaceKind.individual, name: '');
    final kind = input.kind,
        work = kind == WorkspaceKind.individual,
        family = kind == WorkspaceKind.family;
    final d = ref.watch(personalizationDraftProvider(input));
    final personal = work || family;
    return Scaffold(
      backgroundColor: context.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    spacing: 12,
                    children: [
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () => context.router.maybePop(),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          backgroundColor: context.raised,
                          color: DesignColor.purple,
                          value: work || family ? .6 : .7,
                          minHeight: 6,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                      ),
                      DesignLabel(context.tr('setup_details.step')),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20, family ? 24 : 28, 20, 20),
                    children: [
                      Text(
                        (work || family
                                ? kind.label(context)
                                : specialSetupTitle(context, kind))
                            .toUpperCase(),
                        style: TextStyle(
                          color: context.muted,
                          fontSize: 11.5,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          work
                              ? 'setup_details.work'
                              : family
                              ? 'setup_details.family'
                              : kind == WorkspaceKind.alumni
                              ? 'setup_details.set'
                              : 'setup_details.community',
                        ),
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.12,
                          letterSpacing: -.7,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (personal) ...[
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            work
                                ? 'setup_details.work_sub'
                                : 'setup_details.family_sub',
                          ),
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 15,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      if (work)
                        WorkPersonalization(draft: d)
                      else if (family)
                        FamilyPersonalization(draft: d)
                      else
                        SpecialPersonalization(kind: kind, draft: d),
                    ],
                  ),
                ),
                PersonalSetupFooter(
                  labelKey: personal
                      ? 'common.continue'
                      : 'setup_details.build',
                  onPressed: () => context.router.maybePop(d.finish(kind)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

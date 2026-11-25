import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/domain/workspace_setup.dart';
import '../../workspace/presentation/workspace_ui.dart';
import 'widgets/workspace_setup_choice.dart';
import 'widgets/workspace_kind_choices.dart';
import '../application/workspace_personalization_draft.dart';

enum _WorkspaceDoor { business, personal, specials }

class WorkspaceSetupScreen extends ConsumerStatefulWidget {
  const WorkspaceSetupScreen({super.key});

  @override
  ConsumerState<WorkspaceSetupScreen> createState() =>
      _WorkspaceSetupScreenState();
}

class _WorkspaceSetupScreenState extends ConsumerState<WorkspaceSetupScreen> {
  _WorkspaceDoor door = _WorkspaceDoor.business;
  WorkspaceKind? kind = WorkspaceKind.business;
  bool choosingKind = false;
  bool saving = false;
  String name = '';

  String get slug => name
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  void back() {
    if (choosingKind) {
      setState(() => choosingKind = false);
    } else {
      context.router.maybePop();
    }
  }

  void selectDoor(_WorkspaceDoor value) {
    setState(() {
      door = value;
      kind = value == _WorkspaceDoor.business ? WorkspaceKind.business : null;
      name = '';
    });
  }

  Future<void> proceed() async {
    if (saving) return;
    if (!choosingKind && door != _WorkspaceDoor.business) {
      setState(() => choosingKind = true);
      return;
    }
    final selected = kind;
    if (selected == null) return;
    setState(() => saving = true);
    WorkspaceSetup setup = const WorkspaceSetup();
    var workspaceName = name.trim();
    if (selected != WorkspaceKind.business) {
      final details = await context.router.push<PersonalizationResult>(
        NamedRoute(
          TmsRoute.personalize.name,
          args: (kind: selected, name: workspaceName),
        ),
      );
      if (!mounted) return;
      if (details == null) {
        setState(() => saving = false);
        return;
      }
      setup = details.settings;
      if (details.name.isNotEmpty) workspaceName = details.name;
    }
    final saved = await saveWorkspaceChange(
      context,
      () => selected == WorkspaceKind.business
          ? ref
                .read(localWorkspacesProvider.notifier)
                .select(WorkspaceDirectory.companyId)
          : ref
                .read(localWorkspacesProvider.notifier)
                .create(selected, workspaceName, setup: setup),
    );
    if (!mounted) return;
    setState(() => saving = false);
    if (!saved) return;
    if (selected == WorkspaceKind.business) {
      ref.read(workspacePreviewProvider).setWorkspace(name.trim());
    }
    if (selected != WorkspaceKind.business) {
      TmsRoute.building.reset(context);
      return;
    }
    if (context.routeData.queryParams.getString('from', '') == 'switch') {
      TmsRoute.home.reset(context);
    } else {
      TmsRoute.profileSetup.open(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final selected = kind;
    final canContinue =
        !saving &&
        (choosingKind
            ? selected != null
            : name.trim().isNotEmpty && slug.isNotEmpty);
    final choices = door == _WorkspaceDoor.personal
        ? const [WorkspaceKind.individual, WorkspaceKind.family]
        : WorkspaceKind.specials;
    return PopScope(
      canPop: !choosingKind,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && choosingKind) back();
      },
      child: Scaffold(
        backgroundColor: context.background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                    child: Row(
                      children: [
                        DesignIcon(
                          icon: TmsIcons.chevronBack,
                          label: tr('common.back'),
                          onPressed: back,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: choosingKind ? .5 : .25,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(5),
                            color: DesignColor.purple,
                            backgroundColor: context.raised,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tr('onboarding.1_of_4'),
                          style: TextStyle(color: context.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: AnimatedSwitcher(
                        duration: DesignMotion.duration(
                          context,
                          DesignMotion.page,
                        ),
                        switchInCurve: DesignMotion.curve,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(.06, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        ),
                        child: choosingKind
                            ? WorkspaceKindChoices(
                                key: const ValueKey('kind'),
                                personal: door == _WorkspaceDoor.personal,
                                choices: choices,
                                selected: selected,
                                onSelected: (choice) => setState(() {
                                  kind = choice;
                                }),
                              )
                            : Column(
                                key: const ValueKey('door'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    tr(
                                      'onboarding.new_workspace',
                                    ).toUpperCase(),
                                    style: TextStyle(
                                      color: context.muted,
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    tr('onboarding.what_are_you_setting_up'),
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      height: 1.12,
                                      letterSpacing: -.7,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DesignLabel(
                                    tr(
                                      'onboarding.well_shape_tasks_roles_and_reminders_around',
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  WorkspaceSetupChoice(
                                    title: tr('onboarding.setup_business'),
                                    subtitle: tr(
                                      'onboarding.setup_business_description',
                                    ),
                                    icon: TmsIcons.building,
                                    selected: door == _WorkspaceDoor.business,
                                    onTap: () =>
                                        selectDoor(_WorkspaceDoor.business),
                                  ),
                                  const SizedBox(height: 12),
                                  WorkspaceSetupChoice(
                                    title: tr('onboarding.setup_personal'),
                                    subtitle: tr(
                                      'onboarding.setup_personal_short',
                                    ),
                                    icon: TmsIcons.home,
                                    color: DesignColor.teal,
                                    selected: door == _WorkspaceDoor.personal,
                                    onTap: () =>
                                        selectDoor(_WorkspaceDoor.personal),
                                  ),
                                  const SizedBox(height: 12),
                                  WorkspaceSetupChoice(
                                    title: tr('workspaces.specials'),
                                    subtitle: tr(
                                      'onboarding.setup_specials_short',
                                    ),
                                    icon: TmsIcons.star,
                                    color: DesignColor.amber,
                                    selected: door == _WorkspaceDoor.specials,
                                    onTap: () =>
                                        selectDoor(_WorkspaceDoor.specials),
                                  ),
                                  const SizedBox(height: 24),
                                  WorkspaceNameField(
                                    fieldType: door.name,
                                    name: name,
                                    slug: slug,
                                    onChanged: (value) =>
                                        setState(() => name = value),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: context.outline.withValues(alpha: .5),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DesignButton(
                          tr('common.continue'),
                          onPressed: canContinue ? proceed : null,
                        ),
                        if (!choosingKind)
                          TextButton(
                            onPressed: () => TmsRoute.signIn.open(context),
                            child: Text.rich(
                              TextSpan(
                                text: tr('onboarding.setup_invite_prefix'),
                                style: TextStyle(color: context.muted),
                                children: [
                                  TextSpan(
                                    text: tr('onboarding.setup_invite_action'),
                                    style: TextStyle(
                                      color: context.lavender,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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

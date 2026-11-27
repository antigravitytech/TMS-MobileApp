import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/environment.dart';
import '../../../router/tms_routes.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../authentication/presentation/widgets/account_action_form.dart';
import '../application/workspace_enrollment.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/application/workspace_preview.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/domain/workspace_setup.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import 'widgets/workspace_setup_choice.dart';
import 'widgets/workspace_kind_choices.dart';
import 'widgets/personal_kind_choices.dart';
import 'widgets/personal_setup_controls.dart';
import '../application/workspace_personalization_draft.dart';

part 'widgets/workspace_setup_doors.dart';

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

  void _setName(String value) => setState(() => name = value);

  void selectDoor(_WorkspaceDoor value) {
    setState(() {
      door = value;
      kind = value == _WorkspaceDoor.business ? WorkspaceKind.business : null;
      name = '';
    });
  }

  Future<void> proceed() async {
    if (saving) return;
    if (door == _WorkspaceDoor.specials &&
        ref.read(environmentProvider).isLive) {
      return;
    }
    if (!choosingKind && door != _WorkspaceDoor.business) {
      setState(() {
        choosingKind = true;
        kind ??= door == _WorkspaceDoor.personal
            ? WorkspaceKind.family
            : WorkspaceKind.alumni;
      });
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
    if (ref.read(environmentProvider).isLive) {
      await _enroll(WorkspaceSignup(workspaceName, selected, setup));
      return;
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

  Future<void> _enroll(WorkspaceSignup signup) async {
    try {
      if (ref.read(accountSessionProvider) != null) {
        await ref.read(workspaceEnrollmentProvider).create(signup);
        if (mounted) {
          ref.invalidate(accountWorkspacesProvider);
          TmsRoute.account.reset(context);
        }
      } else {
        final registered = await showAccountAction(
          context,
          AccountAction.register,
          signup: signup.fields,
        );
        if (mounted && registered == true) TmsRoute.profileSetup.reset(context);
      }
    } on AccountFailure catch (error) {
      if (mounted) designToast(context, accountErrorMessage(context, error));
    } catch (_) {
      if (mounted) designToast(context, context.tr('network.errors.unknown'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final selected = kind;
    final personalKind = choosingKind && door == _WorkspaceDoor.personal;
    final canContinue =
        !saving &&
        !(door == _WorkspaceDoor.specials &&
            ref.watch(environmentProvider).isLive) &&
        (choosingKind
            ? selected != null
            : name.trim().isNotEmpty && slug.isNotEmpty);
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
                    padding: EdgeInsets.fromLTRB(
                      20,
                      8,
                      20,
                      choosingKind ? 0 : 12,
                    ),
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
                            value: choosingKind ? .4 : .25,
                            minHeight: choosingKind ? 6 : 5,
                            borderRadius: BorderRadius.circular(5),
                            color: DesignColor.purple,
                            backgroundColor: context.raised,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tr(
                            choosingKind
                                ? 'setup_details.kind_step'
                                : 'onboarding.1_of_4',
                          ),
                          style: TextStyle(color: context.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        personalKind
                            ? 28
                            : choosingKind
                            ? 26
                            : 8,
                        20,
                        20,
                      ),
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
                        child: personalKind
                            ? PersonalKindChoices(
                                key: const ValueKey('personal'),
                                selected: selected,
                                onSelected: (choice) =>
                                    setState(() => kind = choice),
                              )
                            : choosingKind
                            ? WorkspaceKindChoices(
                                key: const ValueKey('kind'),
                                selected: selected,
                                onSelected: (choice) => setState(() {
                                  kind = choice;
                                }),
                              )
                            : _doorChoices(context),
                      ),
                    ),
                  ),
                  if (choosingKind)
                    PersonalSetupFooter(onPressed: canContinue ? proceed : null)
                  else
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
                                      text: tr(
                                        'onboarding.setup_invite_action',
                                      ),
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

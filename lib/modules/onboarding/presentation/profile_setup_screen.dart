import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../application/profile_setup_notifier.dart';
import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import 'widgets/profile_avatar_picker.dart';
import 'widgets/birthday_setup.dart';
import 'widgets/profile_setup_form.dart';
import 'widgets/profile_setup_steps.dart';

class ProfileSetupScreen extends ConsumerWidget {
  const ProfileSetupScreen({super.key});

  Future<void> _handleResult(
    BuildContext context,
    WidgetRef ref,
    Future<ProfileSetupResult> action,
  ) async {
    final result = await action;
    if (!context.mounted) return;
    switch (result) {
      case ProfileSetupResult.stay:
        break;
      case ProfileSetupResult.complete:
        final directory = await ref
            .read(localWorkspacesProvider.future)
            .then<WorkspaceDirectory?>(
              (directory) => directory,
              onError: (Object _) => null,
            );
        if (!context.mounted) return;
        final destination = directory?.activeId == WorkspaceDirectory.companyId
            ? TmsRoute.businessReady
            : TmsRoute.home;
        destination.reset(context);
      case ProfileSetupResult.photoFailed:
        designToast(context, context.tr('onboarding.photo_pick_failed'));
      case ProfileSetupResult.saveFailed:
        designToast(
          context,
          context.tr('onboarding.profile_preferences_save_failed'),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setup = ref.watch(profileSetupProvider);
    final notifier = ref.read(profileSetupProvider.notifier);
    final step = setup.step;
    final isProfile = step == ProfileSetupStep.profile;
    final canPop = isProfile && !setup.saving;

    void back() {
      if (canPop) {
        context.router.maybePop();
      } else {
        notifier.previousStep();
      }
    }

    void next({bool skip = false}) {
      FocusScope.of(context).unfocus();
      _handleResult(context, ref, notifier.advance(skip: skip));
    }

    final tr = context.tr;
    final caption = tr(switch (step) {
      ProfileSetupStep.profile => 'onboarding.about_you',
      ProfileSetupStep.birthday => 'common.birthday',
      ProfileSetupStep.notifications => 'onboarding.stay_in_loop',
    });
    final title = tr(switch (step) {
      ProfileSetupStep.profile => 'onboarding.let_your_team_know_who_you_are',
      ProfileSetupStep.birthday => 'onboarding.birthday_heading',
      ProfileSetupStep.notifications => 'onboarding.nudges_heading',
    });
    final body = switch (step) {
      ProfileSetupStep.profile => ProfileSetupForm(
        first: setup.first,
        last: setup.last,
        job: setup.job,
        color: setup.color,
        photo: setup.photo,
        roles: setup.roles,
        onFirst: notifier.setFirstName,
        onLast: notifier.setLastName,
        onJob: notifier.setJobTitle,
        onPhoto: () => _handleResult(context, ref, notifier.choosePhoto()),
        onColor: notifier.selectColor,
        onRole: notifier.toggleRole,
      ),
      ProfileSetupStep.birthday => BirthdaySetup(
        date: setup.birthday,
        daysInMonth: setup.daysInBirthdayMonth,
        years: setup.birthdayYears,
        visible: setup.birthdayVisible,
        name: setup.first,
        onDay: (day) => notifier.setBirthday(day: day),
        onMonth: (month) => notifier.setBirthday(month: month),
        onYear: (year) => notifier.setBirthday(year: year),
        onVisible: notifier.setBirthdayVisibility,
      ),
      ProfileSetupStep.notifications => NotificationSetup(
        values: setup.notices,
        onChanged: notifier.setNotice,
      ),
    };
    final buttonText = Theme.of(context).textTheme.labelLarge?.copyWith(
      fontSize: 15.5,
      fontWeight: FontWeight.w600,
      letterSpacing: -.08,
    );

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isProfile) notifier.previousStep();
      },
      child: Scaffold(
        backgroundColor: context.background,
        body: SafeArea(
          minimum: const EdgeInsets.only(top: 58, bottom: 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      spacing: 12,
                      children: [
                        SizedBox.square(
                          dimension: 44,
                          child: IconButton(
                            tooltip: tr('common.back'),
                            icon: const Icon(TmsIcons.chevronBack, size: 18),
                            onPressed: setup.saving ? null : back,
                            style: IconButton.styleFrom(
                              foregroundColor: context.foreground,
                              backgroundColor: context.panel,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: context.outline),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: (step.index + 2) / 4,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                            backgroundColor: context.raised,
                            color: DesignColor.purple,
                          ),
                        ),
                        Text(
                          tr(
                            'onboarding.step_of_four',
                            namedArgs: {
                              'step': NumberFormat.decimalPattern(
                                context.locale.toString(),
                              ).format(step.index + 2),
                            },
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.profileSetupMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey(step),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: DesignMotion.duration(
                          context,
                          DesignMotion.object,
                        ),
                        curve: DesignMotion.curve,
                        builder: (context, progress, child) => Opacity(
                          opacity: progress,
                          child: Transform.translate(
                            offset: Offset(30 * (1 - progress), 0),
                            child: child,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              caption.toUpperCase(),
                              style: TextStyle(
                                color: context.profileSetupMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                height: 1.12,
                                letterSpacing: -.7,
                              ),
                            ),
                            SizedBox(height: isProfile ? 22 : 10),
                            body,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: DesignColor.purple,
                            foregroundColor: DesignColor.ink,
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            textStyle: buttonText,
                          ),
                          onPressed: setup.canContinue ? next : null,
                          child: Text(
                            tr(
                              step == ProfileSetupStep.notifications
                                  ? 'onboarding.finish_setup'
                                  : 'common.continue',
                            ),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: context.profileSetupMuted,
                            minimumSize: const Size(0, 52),
                            textStyle: buttonText,
                          ),
                          onPressed: setup.saving
                              ? null
                              : () => next(skip: true),
                          child: Text(tr('onboarding.skip_for_now')),
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

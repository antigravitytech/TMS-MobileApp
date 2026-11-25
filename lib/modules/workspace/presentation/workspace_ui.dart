import 'package:auto_route/auto_route.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../domain/local_workspace.dart';
import '../domain/workspace_kind.dart';
import '../../../shared/design/tms_icons.dart';

part 'workspace_navigation.dart';

extension WorkspaceKindUi on WorkspaceKind {
  Color get accent => switch (this) {
    WorkspaceKind.family || WorkspaceKind.club => DesignColor.teal,
    WorkspaceKind.event => DesignColor.rose,
    WorkspaceKind.alumni || WorkspaceKind.committee => DesignColor.amber,
    WorkspaceKind.estate => DesignColor.blue,
    _ => DesignColor.purple,
  };

  Color ink(BuildContext context) => context.dark
      ? Color.lerp(accent, Colors.white, .28)!
      : Color.lerp(accent, DesignColor.ink, .54)!;
  String label(BuildContext context) =>
      context.tr('workspaces.kinds.$name.title');
  String description(BuildContext context) =>
      context.tr('workspaces.kinds.$name.description');

  IconData get icon => switch (this) {
    WorkspaceKind.business => TmsIcons.building,
    WorkspaceKind.individual => TmsIcons.laptop,
    WorkspaceKind.family => TmsIcons.home,
    WorkspaceKind.event => TmsIcons.celebration,
    WorkspaceKind.church => TmsIcons.church,
    WorkspaceKind.alumni => TmsIcons.school,
    WorkspaceKind.estate => TmsIcons.city,
    WorkspaceKind.committee => TmsIcons.groups,
    WorkspaceKind.club => TmsIcons.trophy,
  };
}

extension WorkspaceSectionUi on WorkspaceSection {
  String label(BuildContext context) =>
      context.tr('workspaces.sections.$name.title');
  String addLabel(BuildContext context) =>
      context.tr('workspaces.sections.$name.add');

  IconData get icon => switch (this) {
    WorkspaceSection.gigs => TmsIcons.work,
    WorkspaceSection.proposals => TmsIcons.file,
    WorkspaceSection.visitors => TmsIcons.badge,
    WorkspaceSection.rewards => TmsIcons.trophy,
    WorkspaceSection.shopping => TmsIcons.shoppingCart,
    WorkspaceSection.giving => TmsIcons.giving,
    WorkspaceSection.prayers => TmsIcons.heart,
    WorkspaceSection.school => TmsIcons.school,
    WorkspaceSection.passes => TmsIcons.badge,
    WorkspaceSection.seating => TmsIcons.seat,
    _ => switch (view) {
      WorkspaceView.checklist || WorkspaceView.review => TmsIcons.checkSquare,
      WorkspaceView.people => TmsIcons.people,
      WorkspaceView.money => TmsIcons.receipt,
      WorkspaceView.time => TmsIcons.timer,
      WorkspaceView.schedule => TmsIcons.calendar,
      WorkspaceView.board => TmsIcons.board,
      WorkspaceView.poll => TmsIcons.barChart,
      WorkspaceView.notice => TmsIcons.announcement,
      WorkspaceView.seating => TmsIcons.seat,
    },
  };

  String statusLabel(BuildContext context, WorkspaceStatus status) {
    final override = switch ((this, status)) {
      (WorkspaceSection.visitors, WorkspaceStatus.confirmed) => 'allowed',
      (WorkspaceSection.visitors, WorkspaceStatus.declined) => 'wait',
      (WorkspaceSection.visitors, _) => 'at_gate',
      (WorkspaceSection.programme, WorkspaceStatus.inProgress) => 'live',
      (WorkspaceSection.directory, WorkspaceStatus.confirmed) => 'active',
      (WorkspaceSection.directory, WorkspaceStatus.pending) => 'occasional',
      (WorkspaceSection.directory, WorkspaceStatus.declined) => 'inactive',
      (WorkspaceSection.shopping, WorkspaceStatus.inProgress) => 'in_cart',
      (WorkspaceSection.proposals, WorkspaceStatus.todo) => 'draft',
      (WorkspaceSection.shopping, WorkspaceStatus.done) => 'bought',
      (WorkspaceSection.shopping, WorkspaceStatus.todo) => 'to_buy',
      (WorkspaceSection.prayers, WorkspaceStatus.done) => 'answered',
      (WorkspaceSection.proposals, WorkspaceStatus.inProgress) => 'sent',
      (WorkspaceSection.proposals, WorkspaceStatus.done) => 'accepted',
      (WorkspaceSection.clients, WorkspaceStatus.pending) => 'lead',
      (WorkspaceSection.clients, WorkspaceStatus.confirmed) => 'active',
      (WorkspaceSection.clients, WorkspaceStatus.declined) => 'past',
      (WorkspaceSection.guests, WorkspaceStatus.pending) => 'invited',
      (WorkspaceSection.guests, WorkspaceStatus.confirmed) => 'coming',
      (WorkspaceSection.guests, WorkspaceStatus.declined) => 'not_coming',
      (WorkspaceSection.attendance, WorkspaceStatus.pending) => 'maybe',
      (WorkspaceSection.attendance, WorkspaceStatus.confirmed) => 'present',
      (WorkspaceSection.attendance, WorkspaceStatus.declined) => 'absent',
      (WorkspaceSection.firstTimers, WorkspaceStatus.pending) => 'follow_up',
      (WorkspaceSection.firstTimers, WorkspaceStatus.confirmed) => 'joined',
      (WorkspaceSection.firstTimers, WorkspaceStatus.declined) =>
        'not_returning',
      (WorkspaceSection.issues, WorkspaceStatus.todo) => 'reported',
      (WorkspaceSection.issues, WorkspaceStatus.done) => 'fixed',
      _ => status.name,
    };
    return context.tr('workspaces.status.$override');
  }

  List<WorkspaceStatus> get peopleStatuses => [
    if (this == WorkspaceSection.guests) WorkspaceStatus.notInvited,
    WorkspaceStatus.pending,
    if (this == WorkspaceSection.firstTimers) ...[
      WorkspaceStatus.contacted,
      WorkspaceStatus.visited,
      WorkspaceStatus.membershipClass,
    ],
    if (this == WorkspaceSection.guests) WorkspaceStatus.maybe,
    WorkspaceStatus.confirmed,
    WorkspaceStatus.declined,
  ];

  bool get tracksPeopleStatus => const {
    WorkspaceSection.clients,
    WorkspaceSection.guests,
    WorkspaceSection.attendance,
    WorkspaceSection.firstTimers,
    WorkspaceSection.directory,
  }.contains(this);

  bool get tracksProgress => const {
    WorkspaceSection.gigs,
    WorkspaceSection.proposals,
    WorkspaceSection.shopping,
    WorkspaceSection.prep,
    WorkspaceSection.actions,
    WorkspaceSection.issues,
  }.contains(this);

  void open(BuildContext context, {WorkspaceStatus? filter, String? recordId}) {
    final path = Uri(
      path: TmsRoute.workspacePlan.path,
      queryParameters: {
        'section': name,
        'item': ?recordId,
        if (filter != null) 'status': filter.name,
      },
    ).toString();
    final router = context.router;
    if (TmsRoute.values.any(
      (route) => route.name == router.current.name && route.isTab,
    )) {
      router.replacePath(path);
    } else {
      router.pushPath(path);
    }
  }
}

String workspaceName(BuildContext context, LocalWorkspace space) =>
    space.name.isEmpty ? space.kind.label(context) : space.name;

String workspaceAmount(BuildContext context, int kobo) => context.tr(
  'workspaces.currency_amount',
  namedArgs: {
    'currency': 'NGN',
    'amount': NumberFormat.decimalPatternDigits(
      locale: context.locale.toString(),
      decimalDigits: kobo % 100 == 0 ? 0 : 2,
    ).format(kobo / 100),
  },
);

int? parseWorkspaceAmount(String raw) {
  final match = RegExp(
    r'^(\d{1,10})(?:[.,](\d{1,2}))?$',
  ).firstMatch(raw.trim());
  if (match == null) return null;
  return int.parse(match[1]!) * 100 +
      int.parse((match[2] ?? '').padRight(2, '0'));
}

Future<bool> saveWorkspaceChange(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
    return true;
  } catch (error) {
    if (context.mounted) {
      designToast(
        context,
        context.tr(
          error is PointsAlreadySpent
              ? 'workspaces.points_spent'
              : 'workspaces.save_failed',
        ),
      );
    }
    return false;
  }
}

Future<DateTime?> pickWorkspaceDate(BuildContext context, DateTime? selected) {
  final now = DateTime.now();
  return showDatePicker(
    switchToInputEntryModeIcon: const Icon(TmsIcons.keyboard),
    switchToCalendarEntryModeIcon: const Icon(TmsIcons.calendar),
    context: context,
    initialDate: selected ?? now,
    firstDate: DateTime(1900),
    lastDate: DateTime(now.year + 50),
  );
}

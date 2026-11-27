import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../domain/workspace_kind.dart';

/// A quick add bubble: copy key, icon, colour and the section it opens.
typedef QuickAddAction = (String, IconData, Color, WorkspaceSection);

/// The quick add bubbles for [kind], in the prototype's order.
List<QuickAddAction> quickAddActions(WorkspaceKind kind) {
  final family = kind == WorkspaceKind.family;
  return family
      ? [
          (
            'workspace_quick_add.plan',
            TmsIcons.calendar,
            DesignColor.green,
            WorkspaceSection.plans,
          ),
          (
            'workspace_quick_add.bill',
            TmsIcons.receipt,
            DesignColor.rose,
            WorkspaceSection.bills,
          ),
          (
            'workspace_quick_add.shopping',
            TmsIcons.shoppingCart,
            DesignColor.teal,
            WorkspaceSection.shopping,
          ),
          (
            'workspace_quick_add.errand',
            TmsIcons.microphone,
            DesignColor.purple,
            WorkspaceSection.errands,
          ),
          (
            'workspace_quick_add.homework',
            TmsIcons.school,
            DesignColor.blue,
            WorkspaceSection.school,
          ),
          (
            'workspace_quick_add.chore',
            TmsIcons.shoppingBag,
            DesignColor.amber,
            WorkspaceSection.chores,
          ),
        ]
      : kind == WorkspaceKind.event
      ? const [
          (
            'workspace_quick_add.check_in',
            TmsIcons.checkSquare,
            Color(0xffb3a8f2),
            WorkspaceSection.guests,
          ),
          (
            'workspace_quick_add.seat_guests',
            TmsIcons.seat,
            DesignColor.teal,
            WorkspaceSection.seating,
          ),
          (
            'workspace_quick_add.pay_vendor',
            TmsIcons.card,
            DesignColor.blue,
            WorkspaceSection.vendors,
          ),
          (
            'workspace_quick_add.run_day',
            TmsIcons.timer,
            DesignColor.amber,
            WorkspaceSection.programme,
          ),
        ]
      : kind == WorkspaceKind.club
      ? const [
          (
            'workspace_quick_add.take_attendance',
            TmsIcons.checkSquare,
            Color(0xffb3a8f2),
            WorkspaceSection.attendance,
          ),
          (
            'workspace_quick_add.record_fee',
            TmsIcons.card,
            DesignColor.teal,
            WorkspaceSection.fees,
          ),
          (
            'workspace_quick_add.add_session',
            TmsIcons.calendar,
            DesignColor.blue,
            WorkspaceSection.sessions,
          ),
          (
            'workspace_quick_add.post_notice',
            TmsIcons.announcement,
            DesignColor.amber,
            WorkspaceSection.notices,
          ),
        ]
      : kind == WorkspaceKind.committee
      ? const [
          (
            'workspace_quick_add.schedule_meeting',
            TmsIcons.calendar,
            Color(0xffb3a8f2),
            WorkspaceSection.meetings,
          ),
          (
            'workspace_quick_add.action_item',
            TmsIcons.checkSquare,
            DesignColor.teal,
            WorkspaceSection.actions,
          ),
          (
            'workspace_quick_add.take_minutes',
            TmsIcons.file,
            DesignColor.blue,
            WorkspaceSection.minutes,
          ),
          (
            'workspace_quick_add.put_to_vote',
            TmsIcons.barChart,
            DesignColor.amber,
            WorkspaceSection.decisions,
          ),
        ]
      : kind == WorkspaceKind.estate
      ? const [
          (
            'workspace_quick_add.new_gate_pass',
            TmsIcons.badge,
            Color(0xffb3a8f2),
            WorkspaceSection.passes,
          ),
          (
            'workspace_quick_add.report_issue',
            TmsIcons.edit,
            DesignColor.teal,
            WorkspaceSection.issues,
          ),
          (
            'workspace_quick_add.record_levy',
            TmsIcons.card,
            DesignColor.blue,
            WorkspaceSection.levies,
          ),
          (
            'workspace_quick_add.post_notice',
            TmsIcons.announcement,
            DesignColor.amber,
            WorkspaceSection.notices,
          ),
          (
            'workspace_quick_add.new_poll',
            TmsIcons.barChart,
            DesignColor.rose,
            WorkspaceSection.poll,
          ),
        ]
      : kind == WorkspaceKind.alumni
      ? const [
          (
            'workspace_quick_add.record_dues',
            TmsIcons.card,
            Color(0xffb3a8f2),
            WorkspaceSection.dues,
          ),
          (
            'workspace_quick_add.new_poll',
            TmsIcons.barChart,
            DesignColor.teal,
            WorkspaceSection.poll,
          ),
          (
            'workspace_quick_add.post_notice',
            TmsIcons.announcement,
            DesignColor.blue,
            WorkspaceSection.notices,
          ),
          (
            'workspace_quick_add.committee_todo',
            TmsIcons.checkSquare,
            DesignColor.amber,
            WorkspaceSection.committees,
          ),
          (
            'workspace_quick_add.add_classmate',
            TmsIcons.addPerson,
            DesignColor.rose,
            WorkspaceSection.directory,
          ),
        ]
      : kind == WorkspaceKind.church
      ? const [
          (
            'workspace_quick_add.record_attendance',
            TmsIcons.people,
            Color(0xffb3a8f2),
            WorkspaceSection.services,
          ),
          (
            'workspace_quick_add.record_giving',
            TmsIcons.giving,
            DesignColor.teal,
            WorkspaceSection.giving,
          ),
          (
            'workspace_quick_add.prayer_request',
            TmsIcons.heart,
            DesignColor.blue,
            WorkspaceSection.prayers,
          ),
          (
            'workspace_quick_add.add_first_timer',
            TmsIcons.addPerson,
            DesignColor.amber,
            WorkspaceSection.firstTimers,
          ),
          (
            'workspace_quick_add.post_notice',
            TmsIcons.announcement,
            DesignColor.rose,
            WorkspaceSection.notices,
          ),
        ]
      : kind == WorkspaceKind.individual
      ? const [
          (
            'workspace_quick_add.new_task',
            TmsIcons.checkSquare,
            Color(0xffb3a8f2),
            WorkspaceSection.tasks,
          ),
          (
            'workspace_quick_add.start_timer',
            TmsIcons.timer,
            DesignColor.teal,
            WorkspaceSection.time,
          ),
          (
            'workspace_quick_add.new_invoice',
            TmsIcons.card,
            DesignColor.blue,
            WorkspaceSection.invoices,
          ),
          (
            'workspace_quick_add.new_proposal',
            TmsIcons.file,
            DesignColor.amber,
            WorkspaceSection.proposals,
          ),
          (
            'workspace_quick_add.start_gig',
            TmsIcons.work,
            DesignColor.rose,
            WorkspaceSection.gigs,
          ),
          (
            'workspace_quick_add.add_client',
            TmsIcons.person,
            DesignColor.green,
            WorkspaceSection.clients,
          ),
        ]
      : [
          for (final section in kind.sections.take(6))
            (
              'workspaces.sections.${section.name}',
              TmsIcons.add,
              DesignColor.teal,
              section,
            ),
        ];
}

/// The quick add title for [kind].
String quickAddHeading(WorkspaceKind kind) => switch (kind) {
  WorkspaceKind.family => 'workspace_quick_add.family_heading',
  WorkspaceKind.individual => 'workspace_quick_add.individual_heading',
  WorkspaceKind.church => 'workspace_quick_add.church_heading',
  WorkspaceKind.alumni => 'workspace_quick_add.alumni_heading',
  WorkspaceKind.estate => 'workspace_quick_add.estate_heading',
  WorkspaceKind.committee => 'workspace_quick_add.committee_heading',
  WorkspaceKind.club => 'workspace_quick_add.club_heading',
  WorkspaceKind.event => 'workspace_quick_add.event_heading',
  _ => 'workspace_quick_add.heading',
};

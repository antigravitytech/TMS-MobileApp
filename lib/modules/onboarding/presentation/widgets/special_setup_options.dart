import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/workspace_kind.dart';

const specialSetupOptions = <WorkspaceKind, (IconData, Color, List<String>)>{
  WorkspaceKind.church: (
    TmsIcons.church,
    DesignColor.purple,
    ['services', 'giving', 'units', 'prayers', 'first_timers', 'notices'],
  ),
  WorkspaceKind.alumni: (
    TmsIcons.school,
    DesignColor.teal,
    ['committees', 'dues', 'polls', 'notices', 'directory', 'whatsapp'],
  ),
  WorkspaceKind.estate: (
    TmsIcons.city,
    DesignColor.blue,
    ['levies', 'passes', 'issues', 'notices', 'polls'],
  ),
  WorkspaceKind.event: (
    TmsIcons.heart,
    DesignColor.red,
    ['guests', 'seating', 'vendors', 'programme', 'guest_page'],
  ),
  WorkspaceKind.committee: (
    TmsIcons.file,
    DesignColor.amber,
    ['meetings', 'actions', 'minutes', 'decisions'],
  ),
  WorkspaceKind.club: (
    TmsIcons.sportsBall,
    DesignColor.green,
    ['sessions', 'fees', 'attendance', 'notices'],
  ),
};

String specialSetupTitle(BuildContext context, WorkspaceKind kind) =>
    context.tr('setup_specials.kinds.${kind.name}.title');

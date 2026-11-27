import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_widgets.dart';
import 'event_invitation.dart';

/// Opens the existing guest page: date, venue, dress code and RSVP.
Future<void> showGuestPage(BuildContext context, String workspaceId) =>
    designSheet<void>(
      context,
      title: context.tr('workspaces.guest_page'),
      builder: (_) => EventInvitation(workspaceId: workspaceId),
    );

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../specials/presentation/special_home_shell.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../../shared/kit/kit.dart';
import '../application/event_controller.dart';
import 'widgets/event_guests.dart';
import 'widgets/event_overview.dart';
import 'widgets/event_programme.dart';
import 'widgets/event_vendors.dart';
import 'widgets/event_seating.dart';

/// Chinwe & Dayo's wedding: five tabs on the shared Specials shell.
class EventHomeScreen extends ConsumerWidget {
  const EventHomeScreen({
    super.key,
    required this.workspace,
    this.initial = EventTab.overview,
  });
  final LocalWorkspace workspace;
  final EventTab initial;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final args = (workspace.id, initial);
    final state = ref.watch(eventControllerProvider(args));
    final actions = ref.read(eventControllerProvider(args).notifier);
    final view = ref.watch(eventViewProvider(workspace.id));
    return SpecialHomeShell<EventTab>(
      workspace: workspace,
      logoColor: KitColor.avatar(4),
      logo: view?.info?.fields['hosts'] == null
          ? null
          : kitPerson(view!.info!.fields['hosts']!).$1,
      tabs: EventTab.values,
      selected: state.tab,
      label: (t) => c.tr('event.tabs.${t.name}'),
      onTab: actions.tab,
      body: view == null
          ? const SizedBox()
          : switch (state.tab) {
              EventTab.overview => EventOverview(
                view: view,
                onTab: actions.tab,
              ),
              EventTab.guests => EventGuests(
                view: view,
                state: state,
                actions: actions,
              ),
              EventTab.seating => EventSeating(
                view: view,
                state: state,
                actions: actions,
              ),
              EventTab.vendors => EventVendors(view: view, actions: actions),
              EventTab.programme => EventProgramme(
                view: view,
                state: state,
                actions: actions,
              ),
            },
    );
  }
}

part of '../more_screen.dart';

/// What the business More page shows about me and my workspace. Live data
/// comes from the signed-in account and the server; the preview supplies it
/// otherwise.
typedef _MoreHeader = ({
  String name,
  String job,
  String? statusKey,
  String workspace,
  int unread,
});

_MoreHeader _moreHeader(WidgetRef ref, bool live) {
  final state = ref.watch(workspacePreviewProvider);
  final presence = ref.watch(myPresenceProvider).value;
  if (!live) {
    return (
      name: '${state.firstName} ${state.lastName}',
      job: state.jobTitle,
      statusKey: presence == null ? state.status : presenceLabelKey(presence),
      workspace: state.workspace,
      unread: 6 - state.readNotifications.length,
    );
  }
  final account = ref.watch(accountSessionProvider);
  final workspace = ref.watch(activeLiveWorkspaceProvider);
  return (
    name: '${account?.firstName ?? ''} ${account?.lastName ?? ''}'.trim(),
    job: account?.jobTitle ?? '',
    statusKey: presence == null ? null : presenceLabelKey(presence),
    workspace: workspace?.name ?? '',
    unread: workspace == null
        ? 0
        : ref.watch(notificationUnreadProvider(workspace.id)).value ?? 0,
  );
}

/// Lists my approved workspaces; picking one opens its Home.
Future<void> _switchLiveWorkspace(BuildContext context, WidgetRef ref) async {
  final picked = await designSheet<AccountWorkspace>(
    context,
    title: context.tr('more.switch'),
    builder: (sheet) => Consumer(
      builder: (sheet, ref, _) {
        final active = ref.watch(activeLiveWorkspaceProvider)?.id;
        return ref
            .watch(accountWorkspacesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => DesignLabel(
                error is AccountFailure
                    ? error.type.localizedMessage(sheet)
                    : sheet.tr('network.errors.unknown'),
              ),
              data: (items) => Column(
                children: [
                  for (final item in items.where(
                    (w) => w.approval == 'approved',
                  ))
                    DesignTile(
                      title: item.name,
                      leading: _Logo(item.name),
                      trailing: item.id == active
                          ? const Icon(TmsIcons.check)
                          : null,
                      onTap: () => Navigator.pop(sheet, item),
                    ),
                ],
              ),
            );
      },
    ),
  );
  if (picked == null || !context.mounted) return;
  ref.read(liveWorkspaceSelectionProvider.notifier).select(picked);
  TmsRoute.home.reset(context);
}

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(accountSessionProvider.notifier).signOut();
  } catch (_) {
    // Signing out locally still clears the session; carry on.
  }
  if (context.mounted) TmsRoute.welcome.reset(context);
}

part of 'home_screen.dart';

class LiveHomeScreen extends ConsumerStatefulWidget {
  const LiveHomeScreen({super.key});

  @override
  ConsumerState<LiveHomeScreen> createState() => _LiveHomeState();
}

class _LiveHomeState extends ConsumerState<LiveHomeScreen> {
  late final Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (!mounted ||
          ModalRoute.isCurrentOf(context) != true ||
          (lifecycle != null && lifecycle != AppLifecycleState.resumed)) {
        return;
      }
      final workspace = ref.read(activeLiveWorkspaceProvider);
      if (workspace == null) return;
      ref.invalidate(liveHomeProvider(workspace));
      ref.invalidate(notificationUnreadProvider(workspace.id));
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountSessionProvider);
    final directory = ref.watch(accountWorkspacesProvider);
    if (account == null || directory.hasError) return const AccountScreen();
    if (directory.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final workspace = ref.watch(activeLiveWorkspaceProvider);
    if (workspace == null) return const AccountScreen();

    ref.listen(accountSessionProvider, (previous, next) {
      if (previous != null && next == null && context.mounted) {
        TmsRoute.signIn.reset(context);
      }
    });
    final dashboard = ref.watch(liveHomeProvider(workspace));
    return dashboard.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text(workspace.name)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_dashboardError(context, error)),
              TextButton(
                onPressed: () => ref.invalidate(liveHomeProvider(workspace)),
                child: Text(context.tr('workspaces.try_again')),
              ),
              TextButton(
                onPressed: () => TmsRoute.account.open(context),
                child: Text(context.tr('authentication.account')),
              ),
            ],
          ),
        ),
      ),
      data: (dashboard) {
        final data = dashboard.data;
        Future<void> refresh() {
          ref.invalidate(notificationUnreadProvider(workspace.id));
          return ref
              .refresh(liveHomeProvider(workspace).future)
              .then<void>((_) {}, onError: (Object _, StackTrace _) {});
        }

        return workspace.kind == 'business'
            ? _LiveBusinessHome(
                key: ValueKey(workspace.id),
                account: account,
                data: data,
                refresh: refresh,
              )
            : LiveSpaceDashboard(
                key: ValueKey(workspace.id),
                account: account,
                data: data,
                workspace: dashboard.space!,
                refresh: refresh,
              );
      },
    );
  }
}

String _dashboardError(BuildContext context, Object error) =>
    error is AccountFailure
    ? accountErrorMessage(context, error)
    : context.tr('network.errors.unknown');

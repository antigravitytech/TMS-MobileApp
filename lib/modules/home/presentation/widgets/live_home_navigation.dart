part of '../home_screen.dart';

class _LiveHomeNavigation extends StatelessWidget {
  const _LiveHomeNavigation({required this.data, required this.home});

  final LiveHomeData data;
  final GlobalKey home;

  @override
  Widget build(BuildContext context) => DesignTabs(
    active: TmsRoute.home,
    items: [
      for (final (route, label, icon, _) in DesignTabs.companyTabs)
        (
          route,
          label,
          icon,
          switch (route) {
            TmsRoute.chat => data.count('chat', 'total_unread') ?? 0,
            TmsRoute.approvals => dashboardInteger(
              dashboardObject(data.object('summary')['review'])['waiting'],
            ),
            _ => 0,
          },
        ),
    ],
    onSelect: (tab) {
      switch (tab.$1) {
        case TmsRoute.home:
          _scrollTo(home);
        case TmsRoute.tasks:
          TmsRoute.tasks.open(context);
        case TmsRoute.approvals:
          TmsRoute.approvals.open(context);
        case TmsRoute.more:
          TmsRoute.more.open(context);
        case TmsRoute.chat:
          TmsRoute.chat.open(context);
        default:
          break;
      }
    },
  );

  void _scrollTo(GlobalKey key) {
    if (key.currentContext case final target?) {
      Scrollable.ensureVisible(target, duration: DesignMotion.fast);
    }
  }
}

Future<String?> _returnNote(BuildContext context) {
  var note = '';
  return designSheet<String>(
    context,
    title: context.tr('common.return'),
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: context.tr('home.live_return_note'),
            ),
            maxLines: 3,
            onChanged: (value) => setState(() => note = value.trim()),
          ),
          FilledButton(
            onPressed: note.isEmpty
                ? null
                : () => Navigator.of(context).pop(note),
            child: Text(context.tr('common.return')),
          ),
        ],
      ),
    ),
  );
}

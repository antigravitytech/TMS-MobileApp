import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/network_calls_repository.dart';
import '../../authentication/domain/account.dart';
import 'live_dashboard_data.dart';

export 'live_dashboard_data.dart';

final liveHomeRepositoryProvider = Provider<LiveHomeRepository>(
  (ref) => LiveHomeRepository(ref.watch(networkCallsRepositoryProvider)),
);

class LiveHomeRepository {
  const LiveHomeRepository(this._network);

  final NetworkCallsRepository _network;

  Future<LiveHomeData> load(AccountWorkspace workspace) async {
    final id = Uri.encodeComponent(workspace.id);
    final requests = <String, (String, Map<String, dynamic>?)>{
      'workspace': ('/workspace/get-workspace/$id/', null),
      'context': ('/people/my-context/$id/', null),
      'team': ('/routine/list-summaries/$id/', {'days': 1}),
      if (workspace.kind == 'business') ...{
        'summary': ('/task/get-summary/$id/', null),
        'due': ('/task/list-tasks/$id/', _tasks('today')),
        'upcoming': ('/task/list-tasks/$id/', _tasks('week')),
        'review': (
          '/task/list-approvals/$id/',
          {'sort': 'oldest', 'page_size': 10},
        ),
        'birthdays': ('/birthday/get-feed/$id/', null),
        'routines': ('/routine/list-my-routines/$id/', null),
        'chat': ('/chat/get-unread-summary/$id/', null),
      } else ...{
        if (workspace.subtype != 'church' && workspace.subtype != 'event')
          'space': ('/home/get-space/$id/', null),
        if (workspace.kind == 'family') ...{
          'family': ('/home/get-family/$id/', null),
          'school': ('/school/list-items/$id/', null),
          'polls': ('/poll/list-polls/$id/', {'page_size': 10}),
        },
        if (workspace.kind == 'individual') ...{
          'projects': ('/project/list-projects/$id/', {'page_size': 10}),
          'tasks': ('/task/list-tasks/$id/', _tasks('week')),
        },
        if (workspace.subtype == 'church')
          'church': ('/church/get-church/$id/', null),
        if (workspace.subtype == 'event') ...{
          'event': ('/event/get-event/$id/', null),
          'guests': ('/event/list-guests/$id/', null),
          'vendors': ('/event/list-vendors/$id/', null),
          'programme': ('/event/list-programme/$id/', null),
        },
      },
    };
    final responses = await Future.wait([
      for (final request in requests.entries)
        _network
            .get<Object?>(
              request.value.$1,
              withToken: true,
              queryParameters: request.value.$2,
            )
            .then((result) => (request.key, result)),
    ]);
    final payloads = <String, Object?>{};
    final failed = <String>{};
    for (final (key, response) in responses) {
      if (response.statusCode == 401 ||
          response.failureType == NetworkFailureType.unauthorized ||
          (response.statusCode == 403 &&
              (key == 'workspace' || key == 'context'))) {
        accountPayload(response);
      }
      if (response.hasData) {
        payloads[key] = response.data;
      } else {
        failed.add(key);
      }
    }
    if (payloads.isEmpty) accountPayload(responses.first.$2);
    return LiveHomeData(workspace, payloads, failed);
  }

  Map<String, dynamic> _tasks(String due) => {
    'scope': 'mine',
    'due': due,
    'sort_by': 'due',
    'sort_dir': 'asc',
    'page_size': 10,
  };

  Future<DashboardJson> routine(String id) async => accountPayload(
    await _network.get<DashboardJson>(
      '/routine/get-routine/${Uri.encodeComponent(id)}/',
      withToken: true,
    ),
  );

  Future<void> submitReport(
    String id,
    String date,
    Map<String, Object> answers,
  ) async {
    accountPayload(
      await _network.post<Object?>(
        '/routine/submit-log/${Uri.encodeComponent(id)}/',
        data: {'occurrence_date': date, 'answers': answers},
        withToken: true,
      ),
    );
  }
}

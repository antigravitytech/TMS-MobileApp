import '../../authentication/domain/account.dart';

typedef DashboardJson = Map<String, dynamic>;

class LiveHomeData {
  const LiveHomeData(this.workspace, this._payloads, this.failed);

  final AccountWorkspace workspace;
  final Map<String, Object?> _payloads;
  final Set<String> failed;

  DashboardJson object(String key) => dashboardObject(_payloads[key]);

  List<DashboardJson> rows(String key) {
    final value = _payloads[key];
    return dashboardRows(value is Map ? value['items'] : value);
  }

  String get name => dashboardText(object('workspace')['name'], workspace.name);

  int? count(String key, String field) => dashboardCount(object(key)[field]);

  List<DashboardJson> get modules => dashboardRows(object('space')['modules']);
}

DashboardJson dashboardObject(Object? value) =>
    value is DashboardJson ? value : const {};

List<DashboardJson> dashboardRows(Object? value) =>
    value is List ? value.whereType<DashboardJson>().toList() : const [];

String dashboardText(Object? value, [String fallback = '']) =>
    value is String && value.trim().isNotEmpty ? value : fallback;

int? dashboardCount(Object? value) => value is num ? value.toInt() : null;

int dashboardInteger(Object? value) => dashboardCount(value) ?? 0;

DateTime? dashboardDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/application/local_workspaces.dart';

enum FamilyTaskType { chore, homework, errand, reminder }

enum FamilyWhen { today, tomorrow, weekend, pick }

enum FamilyTaskResult { saved, invalid, failed }

final familyTaskDraftProvider = ChangeNotifierProvider.autoDispose
    .family<FamilyTaskDraft, String>(
      (ref, id) =>
          FamilyTaskDraft(id, ref.read(localWorkspacesProvider.notifier)),
    );

class FamilyTaskDraft extends ChangeNotifier {
  FamilyTaskDraft(this.workspaceId, this.directory);
  final String workspaceId;
  final LocalWorkspaces directory;
  FamilyTaskType type = FamilyTaskType.chore;
  FamilyWhen when = FamilyWhen.today;
  int points = 10, repeat = 0, subject = 0, cash = 20000, time = 0;
  bool photo = true, review = true, tablet = true, saving = false, sent = false;
  String title = '';
  DateTime date = DateTime.now();
  final people = <String>{}, shopping = <String>{};
  bool _disposed = false;
  void change(VoidCallback fn) {
    if (saving) return;
    fn();
    notifyListeners();
  }

  void togglePerson(String name) => change(() {
    if (!people.remove(name)) people.add(name);
  });
  void toggleEveryone(List<String> names) => change(() {
    if (names.every(people.contains)) {
      people.clear();
    } else {
      people.addAll(names);
    }
  });
  void chooseWhen(FamilyWhen value) => change(() {
    when = value;
    final today = DateTime.now();
    final after = switch (value) {
      FamilyWhen.today => 0,
      FamilyWhen.tomorrow || FamilyWhen.pick => 1,
      FamilyWhen.weekend => (DateTime.saturday - today.weekday + 7) % 7,
    };
    date = DateTime(today.year, today.month, today.day + after);
  });
  Future<FamilyTaskResult> submit(String fallbackTitle) async {
    if (people.isEmpty || saving || sent) return FamilyTaskResult.invalid;
    saving = true;
    notifyListeners();
    final name = title.trim().isEmpty ? fallbackTitle : title.trim();
    final section = switch (type) {
      FamilyTaskType.chore => WorkspaceSection.chores,
      FamilyTaskType.homework => WorkspaceSection.school,
      FamilyTaskType.errand => WorkspaceSection.errands,
      FamilyTaskType.reminder => WorkspaceSection.plans,
    };
    final separate = section.view == WorkspaceView.review;
    try {
      await directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: section,
          title: name,
          person: separate ? people.first : people.join(', '),
          date: date,
          points: type == FamilyTaskType.chore ? points : 0,
          requiresReview: type == FamilyTaskType.homework && review,
          group: type == FamilyTaskType.homework ? 'homework' : '',
          fields: switch (type) {
            FamilyTaskType.chore => {
              'repeat': ['once', 'daily', 'weekly'][repeat],
            },
            FamilyTaskType.homework => {
              'subject': [
                'maths',
                'english',
                'science',
                'social',
                'other',
              ][subject],
              'photo': '$photo',
            },
            FamilyTaskType.errand => {
              'issued': '$cash',
              'shoppingIds': shopping.join(','),
            },
            FamilyTaskType.reminder => {
              'remindAt': ['07:00', '12:00', '17:00', '20:30'][time],
              'tablet': '$tablet',
            },
          },
        ),
        alsoAssignTo: separate ? people.skip(1) : const [],
      );
      sent = true;
      title = name;
      return FamilyTaskResult.saved;
    } catch (_) {
      return FamilyTaskResult.failed;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  void again() => change(() {
    sent = false;
    title = '';
    people.clear();
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

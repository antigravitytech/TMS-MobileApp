import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

final workspacePreviewProvider = ChangeNotifierProvider<WorkspacePreview>(
  (ref) => WorkspacePreview(),
);

class PreviewTask {
  const PreviewTask(
    this.id,
    this.title,
    this.project,
    this.person,
    this.due,
    this.status,
    this.priority, {
    this.group = 'Requested',
    this.note = '',
  });

  final String id, title, project, person, due, status, priority, group, note;

  PreviewTask withStatus(String value) => PreviewTask(
    id,
    title,
    project,
    person,
    due,
    value,
    priority,
    group: group,
    note: note,
  );
}

class WorkspacePreview extends ChangeNotifier {
  ThemeMode theme = ThemeMode.dark;
  String workspace = 'Acme Group';
  String firstName = 'Chioma';
  String lastName = 'Okafor';
  String status = 'profile.in_a_meeting';
  String jobTitle = 'Tech Lead';
  PreviewTask? selectedTask;
  bool birthdayDismissed = false;
  bool clockedIn = false;
  bool clockedOut = false;
  bool reportSent = false;
  final approved = <String>{};
  final returned = <String>{};
  final readNotifications = <int>{};
  final birthdayCards = <String>{};
  final messages = <String>[];
  final comments = <String, List<String>>{};
  int _nextTaskNumber = 193;
  final tasks = <PreviewTask>[
    const PreviewTask(
      'TK-190',
      'Q4 hiring plan for Tech Team',
      'Standalone',
      'Ibrahim',
      'Today',
      'In progress',
      'High',
      group: 'Mine',
      note:
          'Headcount, roles and timeline for Q4. Include the backend and QA openings and a draft budget.',
    ),
    const PreviewTask(
      'TK-192',
      'Sprint 14 retro notes',
      'Tech Team',
      'Ibrahim',
      'Wed, 25 Nov',
      'Not started',
      'Low',
      group: 'Mine',
    ),
    const PreviewTask(
      'TK-121',
      'Password reset emails',
      'Customer Portal Revamp',
      'Tunde',
      '2 days overdue',
      'In progress',
      'High',
    ),
    const PreviewTask(
      'TK-127',
      'Session timeout handling',
      'Customer Portal Revamp',
      'Tunde',
      '1 day overdue',
      'Returned',
      'Medium',
    ),
    const PreviewTask(
      'TK-133',
      'Onboarding flow usability test',
      'Customer Portal Revamp',
      'Sarah Johnson',
      'Today',
      'Submitted',
      'High',
      note: 'Ran 5 sessions. Findings, severity ranking and clips attached.',
    ),
    const PreviewTask(
      'TK-158',
      'Error states for portal forms',
      'Customer Portal Revamp',
      'Amaka Eze',
      'Today',
      'Submitted',
      'Medium',
      note:
          'Inline errors, summary banner and focus management for all 4 forms.',
    ),
    const PreviewTask(
      'TK-142',
      'Payment webhook retry handler',
      'Customer Portal Revamp',
      'Tunde Bakare',
      'Wed, 25 Nov',
      'Submitted',
      'High',
      note:
          'Exponential backoff with jitter, dead-letter after 6 tries. Tests attached.',
    ),
    const PreviewTask(
      'TK-171',
      'App store screenshots',
      'Mobile App Launch',
      'Sarah',
      'Today',
      'In progress',
      'High',
      group: 'Team',
    ),
    const PreviewTask(
      'TK-165',
      'Accessibility pass on forms',
      'Customer Portal Revamp',
      'Amaka',
      'Today',
      'In progress',
      'Medium',
      group: 'Team',
    ),
    const PreviewTask(
      'TK-108',
      'Smoke test suite',
      'Mobile App Launch',
      'David',
      'Fri, 13 Nov',
      'Completed',
      'Medium',
      group: 'Team',
    ),
  ];

  Iterable<PreviewTask> get reviewQueue =>
      tasks.where((task) => task.status == 'Submitted' && task.group != 'Mine');
  PreviewTask get activeTask => tasks.firstWhere(
    (task) => task.id == selectedTask?.id,
    orElse: () => tasks.first,
  );

  void setTheme(ThemeMode value) {
    theme = value;
    notifyListeners();
  }

  void setWorkspace(String value) {
    workspace = value;
    notifyListeners();
  }

  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  void saveProfile(String first, String last, String job) {
    if (first.trim().isNotEmpty) firstName = first.trim();
    if (last.trim().isNotEmpty) lastName = last.trim();
    if (job.trim().isNotEmpty) jobTitle = job.trim();
    notifyListeners();
  }

  void selectTask(PreviewTask task) {
    selectedTask = task;
    notifyListeners();
  }

  void addTask(
    String title,
    String description,
    String person,
    String due,
    String priority,
    String project,
  ) {
    final task = PreviewTask(
      'TK-${_nextTaskNumber++}',
      title,
      project,
      person,
      due,
      'Not started',
      priority,
      group: person == 'Me' ? 'Mine' : 'Requested',
      note: description,
    );
    tasks.add(task);
    selectedTask = task;
    notifyListeners();
  }

  void updateTask(PreviewTask task, String status) {
    final index = tasks.indexWhere((element) => element.id == task.id);
    if (index < 0) return;
    tasks[index] = tasks[index].withStatus(status);
    notifyListeners();
  }

  void review(PreviewTask task, {required bool approve}) {
    (approve ? approved : returned).add(task.id);
    updateTask(task, approve ? 'Completed' : 'Returned');
  }

  void dismissBirthday() {
    birthdayDismissed = true;
    notifyListeners();
  }

  void sendCard(String person) {
    birthdayCards.add(person);
    notifyListeners();
  }

  void setAttendance({required bool inOffice}) {
    clockedIn = inOffice;
    clockedOut = !inOffice;
    notifyListeners();
  }

  void sendReport() {
    reportSent = true;
    notifyListeners();
  }

  void markRead(Iterable<int> ids) {
    readNotifications.addAll(ids);
    notifyListeners();
  }

  void sendMessage(String message) {
    messages.add(message);
    notifyListeners();
  }

  void addComment(String id, String line) {
    (comments[id] ??= []).add(line);
    notifyListeners();
  }
}

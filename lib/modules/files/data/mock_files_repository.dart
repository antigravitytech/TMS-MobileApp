part of 'files_repository.dart';

/// The prototype's file library, dated around today. Uploads are kept for
/// the session.
class MockFilesRepository implements FilesRepository {
  MockFilesRepository(this._me);
  final String _me;
  var _next = 0;

  late final List<FileItem> _files = () {
    final now = DateTime.now();
    DateTime ago(int days) => DateTime(now.year, now.month, now.day - days, 10);
    FileItem file(
      String name,
      String who,
      String task,
      String title,
      int days,
      int kb,
    ) => FileItem(
      id: 'mock-$name',
      name: name,
      kind: fileKindOf(name),
      size: kb * 1024,
      uploader: who,
      taskId: task,
      taskTitle: title,
      project: 'Customer Portal Revamp',
      createdAt: ago(days),
    );
    const webhook = 'Payment webhook retry handler';
    const errors = 'Error states for portal forms';
    const usability = 'Onboarding flow usability test';
    const checkout = 'Checkout screens to approved mockup';
    return [
      file('webhook-retry-tests.pdf', 'Tunde', 'TK-142', webhook, 0, 240),
      file('form-errors.png', 'Amaka', 'TK-158', errors, 0, 420),
      file('usability-findings.pdf', 'Sarah', 'TK-133', usability, 1, 2355),
      file('session-3-clip.mp4', 'Sarah', 'TK-133', usability, 1, 49152),
      file('checkout-step2.png', 'Amaka', 'TK-171', checkout, 4, 640),
      file('retry-sequence.png', 'Tunde', 'TK-142', webhook, 6, 1126),
      file('checkout-v2-mockup.fig', 'Amaka', 'TK-171', checkout, 7, 3482),
    ];
  }();

  @override
  Future<List<FileItem>> list() async => List.of(_files);

  @override
  Future<FileItem> upload(PickedFile file, TaskItem task) async {
    final item = FileItem(
      id: 'mock-upload-${_next++}',
      name: file.name,
      kind: fileKindOf(file.name),
      size: file.size,
      uploader: _me,
      taskId: task.id,
      taskTitle: task.title,
      project: task.project,
      createdAt: DateTime.now(),
    );
    _files.insert(0, item);
    return item;
  }
}

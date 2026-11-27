import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sabi_pipu_tms/modules/workspace/data/workspace_repository.dart';
import 'package:sabi_pipu_tms/modules/chat/application/chat_session.dart';
import 'package:sabi_pipu_tms/modules/chat/data/chat_directory.dart';
import 'package:sabi_pipu_tms/modules/family/application/family_task_draft.dart';
import 'package:sabi_pipu_tms/modules/individual/application/focus_timer.dart';
import 'package:sabi_pipu_tms/modules/workspace/application/local_workspaces.dart';
import 'package:sabi_pipu_tms/modules/workspace/domain/workspace_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer(
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(
          const LiveWorkspaceRepository(),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());
  test(
    'family homework creates a separate review for every selected person',
    () async {
      final directory = container.read(localWorkspacesProvider.notifier);
      await directory.select('family');
      final sub = container.listen(
        familyTaskDraftProvider('family'),
        (_, _) {},
      );
      addTearDown(sub.close);
      final draft = container.read(familyTaskDraftProvider('family'));
      draft.change(() => draft.type = FamilyTaskType.homework);
      draft.togglePerson('A');
      draft.togglePerson('B');
      expect(await draft.submit('Read a chapter'), FamilyTaskResult.saved);
      final work = container
          .read(localWorkspacesProvider)
          .requireValue
          .active!
          .items(WorkspaceSection.school);
      expect(work.map((r) => r.person), ['A', 'B']);
      expect(
        work.every((r) => r.title == 'Read a chapter' && r.requiresReview),
        isTrue,
      );
      expect(await draft.submit('Read a chapter'), FamilyTaskResult.invalid);
    },
  );
  test(
    'stopping a client timer writes one billable entry in its workspace',
    () async {
      await container
          .read(localWorkspacesProvider.notifier)
          .select('individual');
      final timer = container.read(focusTimerProvider('individual'));
      timer.choose('Studio');
      timer.start();
      timer.choose('Other');
      expect(await timer.finish('Focus session', 'Admin'), isTrue);
      final entry = container
          .read(localWorkspacesProvider)
          .requireValue
          .active!
          .items(WorkspaceSection.time)
          .single;
      expect(
        (entry.person, entry.duration, entry.flagged),
        ('Studio', 15, true),
      );
      expect(await timer.finish('Focus session', 'Admin'), isFalse);
    },
  );
  test('chat drafts and new groups stay within their workspace', () {
    final ctl = container.read(chatSessionProvider('family').notifier);
    ctl.create(
      const ChatRow(initials: 'AB', color: 'a1', name: 'Weekend'),
      group: true,
    );
    ctl.send('Weekend', 'Book tickets', demoReply: false);
    expect(container.read(chatSessionProvider('family')).messages['Weekend'], [
      'Book tickets',
    ]);
    expect(container.read(chatSessionProvider('club')).groups, isEmpty);
    expect(container.read(chatSessionProvider('club')).messages, isEmpty);
  });
}

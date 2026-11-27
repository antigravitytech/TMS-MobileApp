import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../workspace/domain/workspace_setup.dart';

typedef PersonalizationInput = ({WorkspaceKind kind, String name});
typedef PersonalizationResult = ({String name, WorkspaceSetup settings});
typedef SetupMember = ({String name, HouseholdRole role});

final personalizationDraftProvider = ChangeNotifierProvider.autoDispose
    .family<PersonalizationDraft, PersonalizationInput>(
      (ref, input) => PersonalizationDraft(input.name),
    );

class PersonalizationDraft extends ChangeNotifier {
  PersonalizationDraft(this.name);
  String name, occasion = '';
  int crest = 0;
  DateTime? date;
  IndividualOccupation job = IndividualOccupation.designer;
  bool clients = true;
  final members = <SetupMember>[];
  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setOccasion(String value) {
    occasion = value;
    notifyListeners();
  }

  void setDate(DateTime? value) {
    date = value;
    notifyListeners();
  }

  void setJob(IndividualOccupation value) {
    job = value;
    notifyListeners();
  }

  void setClients(bool value) {
    clients = value;
    notifyListeners();
  }

  void nextCrest() {
    crest = (crest + 1) % 4;
    notifyListeners();
  }

  void saveMember(SetupMember member, int? index) {
    if (index == null) {
      members.add(member);
    } else {
      members[index] = member;
    }
    notifyListeners();
  }

  void removeMember(int index) {
    members.removeAt(index);
    notifyListeners();
  }

  PersonalizationResult finish(WorkspaceKind kind) => (
    name: name.trim(),
    settings: WorkspaceSetup(
      occupation: kind == WorkspaceKind.individual ? job : null,
      withClients: clients,
      occasion: occasion.trim(),
      date: date,
      crest: crest,
      members: List.unmodifiable(members),
    ),
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workspace/application/local_workspaces.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';

/// Status tabs on the shopping list, mapped onto workspace record statuses.
enum ShoppingFilter {
  all(null),
  buy(WorkspaceStatus.todo),
  cart(WorkspaceStatus.inProgress),
  got(WorkspaceStatus.done);

  const ShoppingFilter(this.status);
  final WorkspaceStatus? status;

  bool matches(WorkspaceRecord record) =>
      status == null || record.status == status;
}

/// Store codes kept as data; the UI translates them.
const shoppingStores = ['mile12', 'shoprite', 'market', 'anywhere'];
const _storeNames = {
  'mile12': 'Mile 12',
  'shoprite': 'Shoprite',
  'market': 'Market',
};

class ShoppingState {
  const ShoppingState({
    this.filter = ShoppingFilter.all,
    this.store = 'mile12',
  });
  final ShoppingFilter filter;
  final String store;

  ShoppingState copyWith({ShoppingFilter? filter, String? store}) =>
      ShoppingState(filter: filter ?? this.filter, store: store ?? this.store);
}

/// Shopping records for a workspace, newest additions first.
final shoppingItemsProvider = Provider.autoDispose
    .family<List<WorkspaceRecord>, String>((ref, workspaceId) {
      final directory = ref.watch(localWorkspacesProvider).value;
      final space = directory?.workspaces
          .where((w) => w.id == workspaceId)
          .firstOrNull;
      final records = space?.items(WorkspaceSection.shopping) ?? const [];
      final added = records.where((r) => !r.id.startsWith('family-ref-'));
      final seeded = records.where((r) => r.id.startsWith('family-ref-'));
      return [...added.toList().reversed, ...seeded];
    });

final shoppingControllerProvider = NotifierProvider.autoDispose
    .family<ShoppingController, ShoppingState, String>(ShoppingController.new);

class ShoppingController extends Notifier<ShoppingState> {
  ShoppingController(this.workspaceId);
  final String workspaceId;

  @override
  ShoppingState build() => const ShoppingState();

  LocalWorkspaces get _directory => ref.read(localWorkspacesProvider.notifier);

  void filter(ShoppingFilter value) => state = state.copyWith(filter: value);
  void store(String value) => state = state.copyWith(store: value);

  /// Adds an item at the chosen store. Returns false when nothing was saved.
  Future<bool> add(String name) async {
    final title = name.trim();
    if (title.isEmpty) return false;
    try {
      await _directory.saveRecord(
        workspaceId,
        WorkspaceRecord(
          id: '',
          section: WorkspaceSection.shopping,
          title: title,
          points: 0,
          fields: {
            'store': _storeNames[state.store] ?? '',
            'addedByYou': 'true',
          },
        ),
      );
      state = state.copyWith(filter: ShoppingFilter.all);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Toggles bought. Returns true when the item is now bought.
  Future<bool?> toggleBought(WorkspaceRecord item) => _set(
    item,
    item.status == WorkspaceStatus.done
        ? WorkspaceStatus.todo
        : WorkspaceStatus.done,
  );

  Future<bool?> toggleCart(WorkspaceRecord item) => _set(
    item,
    item.status == WorkspaceStatus.inProgress
        ? WorkspaceStatus.todo
        : WorkspaceStatus.inProgress,
  );

  /// Returns whether the new status is done, or null when saving failed.
  Future<bool?> _set(WorkspaceRecord item, WorkspaceStatus status) async {
    try {
      await _directory.updateRecord(
        workspaceId,
        item.id,
        (r) => r.copyWith(status: status),
      );
      return status == WorkspaceStatus.done;
    } catch (_) {
      return null;
    }
  }
}

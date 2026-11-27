import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../router/tms_routes.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/tms_icons.dart';
import '../../workspace/domain/local_workspace.dart';
import '../../workspace/domain/workspace_kind.dart';
import '../../../shared/kit/kit.dart';
import '../../../shared/kit/kit_visuals.dart';
import '../../workspace/presentation/widgets/workspace_ui.dart';
import '../application/shopping_controller.dart';
import 'widgets/shopping_widgets.dart';

class ShoppingScreen extends ConsumerStatefulWidget {
  const ShoppingScreen({super.key, required this.workspace});
  final LocalWorkspace workspace;
  @override
  ConsumerState<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends ConsumerState<ShoppingScreen> {
  final _draft = TextEditingController();
  String get _id => widget.workspace.id;
  ShoppingController get _actions =>
      ref.read(shoppingControllerProvider(_id).notifier);

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  void _toast(String key, [Map<String, String>? args]) =>
      designToast(context, context.tr(key, namedArgs: args));

  Future<void> _add() async {
    final name = _draft.text.trim();
    if (name.isEmpty) return;
    final ok = await _actions.add(name);
    if (!mounted) return;
    if (ok) _draft.clear();
    ok
        ? _toast('shopping.added', {'name': name})
        : _toast('workspaces.try_again');
  }

  Future<void> _bought(WorkspaceRecord item) async {
    final done = await _actions.toggleBought(item);
    if (!mounted) return;
    if (done == null) return _toast('workspaces.try_again');
    if (done) _toast('shopping.bought_toast', {'name': item.title});
  }

  Future<void> _cart(WorkspaceRecord item) async {
    if (await _actions.toggleCart(item) == null && mounted) {
      _toast('workspaces.try_again');
    }
  }

  @override
  Widget build(BuildContext c) {
    final state = ref.watch(shoppingControllerProvider(_id));
    final items = ref.watch(shoppingItemsProvider(_id));
    final visible = items.where(state.filter.matches).toList();
    final demo = items.any((r) => r.id.startsWith('family-ref-'));
    return Scaffold(
      backgroundColor: c.background,
      bottomNavigationBar: const WorkspaceNavigation(
        kind: WorkspaceKind.family,
        active: TmsRoute.home,
        badges: true,
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            KitHeader(
              title: c.tr('shopping.title'),
              subtitle: c.tr('shopping.subtitle'),
              back: c.tr('shopping.back'),
              action: KitIconButton(
                icon: TmsIcons.share,
                tooltip: c.tr('shopping.share'),
                onPressed: () => _toast('shopping.shared'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _AddRow(controller: _draft, onAdd: _add),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final store in shoppingStores)
                    KitChip(
                      compact: true,
                      label: c.tr('shopping.stores.$store'),
                      selected: state.store == store,
                      onTap: () => _actions.store(store),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            KitTabs(
              children: [
                for (final f in ShoppingFilter.values)
                  KitChip(
                    label: c.tr('shopping.filters.${f.name}'),
                    count: items.where(f.matches).length,
                    selected: state.filter == f,
                    onTap: () => _actions.filter(f),
                  ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 30),
                children: [
                  if (visible.isEmpty)
                    KitPop(
                      child: KitCard(
                        padding: const EdgeInsets.all(26),
                        child: Column(
                          children: [
                            Text(
                              c.tr('shopping.empty_title'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.tr('shopping.empty_body'),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    KitList(
                      key: ValueKey(state.filter),
                      children: [
                        for (final item in visible)
                          ShoppingRow(
                            key: ValueKey(item.id),
                            item: item,
                            onBought: () => _bought(item),
                            onCart: () => _cart(item),
                          ),
                      ],
                    ),
                  if (demo) ...[const SizedBox(height: 14), const _LiveCard()],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRow extends StatelessWidget {
  const _AddRow({required this.controller, required this.onAdd});
  final TextEditingController controller;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
    decoration: BoxDecoration(
      color: c.panel,
      border: Border.all(color: c.outline),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      spacing: 8,
      children: [
        Icon(TmsIcons.add, size: 20, color: c.muted),
        Expanded(
          child: Semantics(
            label: c.tr('shopping.new_item'),
            textField: true,
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onAdd(),
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 15.5),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: c.tr('shopping.placeholder'),
                hintStyle: TextStyle(color: c.muted),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 36,
          child: FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: DesignColor.purple,
              foregroundColor: DesignColor.ink,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              c.tr('shopping.add'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );
}

class _LiveCard extends StatelessWidget {
  const _LiveCard();
  @override
  Widget build(BuildContext c) => KitCard(
    padding: const EdgeInsets.all(16),
    child: Row(
      spacing: 12,
      children: [
        DesignAvatar('BO', size: 36, color: KitColor.avatar(7)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.tr('shopping.live_title'),
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                c.tr('shopping.live_body'),
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ),
        ),
        KitStatus(c.tr('shopping.live'), KitColor.progress, dot: true),
      ],
    ),
  );
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/local_workspace.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../../shared/kit/kit.dart';
import '../../../../shared/kit/kit_visuals.dart';

/// One `.sh` line: tick, name and note, store tag and cart toggle.
class ShoppingRow extends StatelessWidget {
  const ShoppingRow({
    super.key,
    required this.item,
    required this.onBought,
    required this.onCart,
  });
  final WorkspaceRecord item;
  final VoidCallback onBought, onCart;
  @override
  Widget build(BuildContext c) {
    final bought = item.status == WorkspaceStatus.done;
    final inCart = item.status == WorkspaceStatus.inProgress;
    final store = item.fields['store'] ?? '';
    final meta = item.fields['addedByYou'] == 'true'
        ? c.tr('shopping.added_meta')
        : item.notes;
    const teal = KitColor.tick;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: DesignMotion.curve,
      constraints: const BoxConstraints(minHeight: 62),
      color: bought ? KitColor.done.withValues(alpha: .08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          KitTick(
            on: bought,
            label: c.tr('shopping.mark_bought'),
            onTap: onBought,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: bought ? .55 : 1,
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: bought ? TextDecoration.lineThrough : null,
                      decorationColor: teal,
                    ),
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(meta, style: TextStyle(fontSize: 12, color: c.muted)),
                ],
              ],
            ),
          ),
          if (store.isNotEmpty)
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.raised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                store,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                ),
              ),
            ),
          Semantics(
            button: true,
            toggled: inCart,
            label: c.tr('shopping.mark_cart'),
            child: GestureDetector(
              onTap: onCart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: DesignMotion.curve,
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: inCart ? const Color(0x262bb3a3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: inCart ? const Color(0x662bb3a3) : c.outline,
                  ),
                ),
                child: Icon(
                  TmsIcons.shoppingCart,
                  size: 16,
                  color: inCart ? teal : c.muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

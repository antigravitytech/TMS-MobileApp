import 'package:easy_localization/easy_localization.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../router/tms_routes.dart';
import 'design_tokens.dart';
import 'tms_icons.dart';

part 'design_components.dart';
part 'design_forms.dart';
part 'design_tabs.dart';

typedef DesignTab = (TmsRoute, String, IconData, int);

class DesignPage extends StatelessWidget {
  const DesignPage({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.navigation,
    this.subtitle,
    this.actions = const [],
    this.tab,
    this.tabs = DesignTabs.companyTabs,
    this.floatingActionButton,
    this.footer,
    this.headerTop,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 30),
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final Widget? leading, navigation;
  final List<Widget> actions;
  final TmsRoute? tab;
  final List<DesignTab> tabs;
  final Widget? floatingActionButton;
  final Widget? footer;
  final EdgeInsets padding;
  final double? headerTop;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.background,
    body: SafeArea(
      bottom: tab == null && footer == null,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  headerTop == null
                      ? 18
                      : (headerTop! - MediaQuery.viewPaddingOf(context).top)
                            .clamp(8, headerTop!),
                  20,
                  10,
                ),
                child: Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 10),
                    ] else if (tab == null) ...[
                      DesignIcon(
                        icon: TmsIcons.chevronBack,
                        label: context.tr('common.back'),
                        onPressed: () => context.router.maybePop(),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.muted,
                              ),
                            ),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: padding,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    for (var i = 0; i < children.length; i++)
                      DesignEntrance(
                        key: ValueKey(children[i].key ?? i),
                        order: i,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: i == children.length - 1 ? 0 : 12,
                          ),
                          child: children[i],
                        ),
                      ),
                  ],
                ),
              ),
              if (footer != null)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: footer!,
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    floatingActionButton: floatingActionButton,
    bottomNavigationBar:
        navigation ??
        (tab == null ? null : DesignTabs(active: tab!, items: tabs)),
  );
}

class DesignEntrance extends StatelessWidget {
  const DesignEntrance({super.key, this.order = 0, required this.child});
  final int order;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 330 + order.clamp(0, 7) * 24),
      curve: DesignMotion.curve,
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 13 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

class DesignIcon extends StatelessWidget {
  const DesignIcon({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: label,
    style: IconButton.styleFrom(
      backgroundColor: context.panel,
      side: BorderSide(color: context.outline),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      minimumSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 21),
  );
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../../shared/kit/kit.dart';
import '../../authentication/application/account_session.dart';
import '../../authentication/domain/account.dart';
import '../../authentication/presentation/widgets/account_action_form.dart';
import '../../workspace/application/workspace_preview.dart';
import '../application/birthdays_controller.dart';
import '../domain/birthday.dart';

part 'widgets/birthday_card_sheet.dart';
part 'widgets/birthday_overview.dart';

class BirthdaysScreen extends ConsumerStatefulWidget {
  const BirthdaysScreen({super.key});
  @override
  ConsumerState<BirthdaysScreen> createState() => _BirthdaysScreenState();
}

class _BirthdaysScreenState extends ConsumerState<BirthdaysScreen> {
  /// Months from today: -2 and -1 are the two before this one.
  int month = 0;

  /// My name, from the signed-in account or the preview profile.
  (String, String) get _me {
    final account = ref.read(accountSessionProvider);
    final preview = ref.read(workspacePreviewProvider);
    return account == null
        ? (preview.firstName, preview.lastName)
        : (account.firstName, account.lastName);
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    try {
      await action();
      if (mounted) designToast(context, done);
    } catch (error) {
      if (!mounted) return;
      designToast(
        context,
        error is AccountFailure
            ? accountErrorMessage(context, error)
            : context.tr('network.errors.unknown'),
      );
    }
  }

  Future<void> compose(BirthdayPerson person) async {
    final card = await _composeCard(context, to: person.name, from: _me.$1);
    if (!mounted || card == null) return;
    final done = context.tr(
      'birthdays.card_sent',
      namedArgs: {'name': person.name.split(' ').first},
    );
    await _run(
      () => ref
          .read(birthdaysProvider.notifier)
          .sendWish(person, message: card.message, style: card.style),
      done,
    );
  }

  Future<void> celebrate(BirthdayEntry entry) => _run(
    () => ref.read(birthdaysProvider.notifier).celebrate(entry),
    context.tr('birthdays.wished_toast', namedArgs: {'name': entry.name}),
  );

  @override
  Widget build(BuildContext context) {
    final calendar = ref.watch(birthdaysProvider);
    final data = calendar.value;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime dateOf(int daysAway) => today.add(Duration(days: daysAway));
    int monthOf(int daysAway) {
      final date = dateOf(daysAway);
      return (date.year - today.year) * 12 + date.month - today.month;
    }

    final people = [
      for (final p in data?.members ?? const <BirthdayPerson>[])
        (p.name, p.daysAway),
      for (final e in data?.entries ?? const <BirthdayEntry>[])
        (e.name, e.daysAway),
    ];
    final counts = <int, int>{};
    for (final (_, away) in people) {
      counts.update(monthOf(away), (n) => n + 1, ifAbsent: () => 1);
    }
    // The two months before this one, this one, then months with birthdays.
    final months = [
      -2,
      -1,
      0,
      for (var m = 1; m < 12; m++)
        if ((counts[m] ?? 0) > 0) m,
    ];
    final inMonth = people.where((p) => monthOf(p.$2) == month).toList()
      ..sort((a, b) => a.$2.compareTo(b.$2));
    final locale = context.locale.toString();

    return DesignPage(
      title: context.tr('common.birthdays'),
      subtitle: data == null
          ? null
          : context.plural('birthdays.to_celebrate', people.length),
      children: [
        if (data == null && !calendar.hasError)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (data == null) ...[
          DesignEmpty(
            context.tr('birthdays.load_failed'),
            calendar.error is AccountFailure
                ? accountErrorMessage(
                    context,
                    calendar.error! as AccountFailure,
                  )
                : context.tr('network.errors.unknown'),
            icon: TmsIcons.birthday,
          ),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(birthdaysProvider),
          ),
        ] else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final m in months)
                  _MonthChip(
                    label: DateFormat.MMM(
                      locale,
                    ).format(DateTime(today.year, today.month + m)),
                    count: counts[m] ?? 0,
                    selected: month == m,
                    onTap: () => setState(() => month = m),
                  ),
              ],
            ),
          ),
          if (month == 0)
            _BirthdayOverview(
              calendar: data,
              me: '${_me.$1} ${_me.$2}',
              dateOf: dateOf,
              onSend: compose,
              onCelebrate: celebrate,
            )
          else if (inMonth.isEmpty)
            DesignEmpty(
              context.tr('birthdays.nothing_to_celebrate_this_month'),
              context.tr('birthdays.choose_another_month'),
              icon: TmsIcons.birthday,
            )
          else ...[
            DesignTitle(context.tr('birthdays.coming_up')),
            for (final (name, away) in inMonth)
              DesignTile(
                title: name,
                subtitle: DateFormat.MMMMd(locale).format(dateOf(away)),
                leading: DesignAvatar(kitPerson(name).$1),
              ),
          ],
        ],
      ],
    );
  }
}

/// A month in the strip: its short name and how many birthdays it has.
class _MonthChip extends StatelessWidget {
  const _MonthChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? DesignColor.purple : context.panel,
          border: Border.all(color: context.outline),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: selected ? DesignColor.ink : context.muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? DesignColor.ink : context.foreground,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

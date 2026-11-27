import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';
import '../../../workspace/domain/workspace_kind.dart';
import '../../../workspace/presentation/widgets/workspace_ui.dart';
import '../../application/workspace_personalization_draft.dart';
import 'personal_setup_controls.dart';
import '../../../../shared/design/hero_gradient.dart';
import 'special_setup_options.dart';

class SpecialPersonalization extends StatelessWidget {
  const SpecialPersonalization({
    super.key,
    required this.kind,
    required this.draft,
  });
  final WorkspaceKind kind;
  final PersonalizationDraft draft;

  @override
  Widget build(BuildContext context) {
    final prefix = 'setup_specials.kinds.${kind.name}';
    final date = draft.date;
    final locale = context.locale.toString();
    final format = context.locale.languageCode == 'en'
        ? DateFormat('d MMM y', locale)
        : DateFormat.yMMMd(locale);
    final formattedDate = date == null ? null : format.format(date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SetupNameInput(
          label: context.tr(
            kind == WorkspaceKind.alumni
                ? 'setup_details.set_name'
                : 'workspaces.name',
          ),
          hint: context.tr('$prefix.name_hint'),
          value: draft.name,
          onChanged: draft.setName,
        ),
        const SizedBox(height: 14),
        SetupNameInput(
          label: context.tr(
            kind == WorkspaceKind.committee
                ? 'setup_specials.milestone'
                : 'setup_specials.event',
          ),
          hint: context.tr('$prefix.event_hint'),
          value: draft.occasion,
          onChanged: draft.setOccasion,
        ),
        const SizedBox(height: 14),
        Text(context.tr('setup_specials.date'), style: setupLabel(context)),
        const SizedBox(height: 8),
        Material(
          color: context.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: context.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final value = await pickWorkspaceDate(context, draft.date);
                    if (context.mounted && value != null) draft.setDate(value);
                  },
                  child: Container(
                    alignment: AlignmentDirectional.centerStart,
                    constraints: const BoxConstraints(minHeight: 54),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      formattedDate ?? context.tr('workspaces.pick_date'),
                      style: TextStyle(
                        fontSize: 16,
                        color: date == null
                            ? context.muted
                            : context.foreground,
                      ),
                    ),
                  ),
                ),
              ),
              if (date != null)
                IconButton(
                  tooltip: context.tr('setup_specials.clear_date'),
                  onPressed: () => draft.setDate(null),
                  icon: Icon(TmsIcons.close, size: 16, color: context.muted),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _CountdownCard(
          kind: kind,
          occasion: draft.occasion,
          date: date,
          dateText: formattedDate,
        ),
      ],
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({
    required this.kind,
    required this.occasion,
    required this.date,
    required this.dateText,
  });
  final WorkspaceKind kind;
  final String occasion;
  final DateTime? date;
  final String? dateText;

  @override
  Widget build(BuildContext context) {
    const foreground = Color(0xfff3f5fe);
    const muted = Color(0xffc9cbe0);
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final target = date;
    final days = target == null
        ? null
        : math.max(
            0,
            DateTime.utc(
              target.year,
              target.month,
              target.day,
            ).difference(today).inDays,
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CustomPaint(
        painter: const DesignHeroGradient(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  if (days != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NumberFormat.decimalPattern(
                            context.locale.toString(),
                          ).format(days),
                          style: const TextStyle(
                            color: foreground,
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            height: .94,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context
                              .plural('setup_specials.days', days)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .75,
                          ),
                        ),
                      ],
                    )
                  else
                    Expanded(
                      child: Text(
                        context.tr('setup_specials.countdown_preview'),
                        style: const TextStyle(
                          color: foreground,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      spacing: 2,
                      children: [
                        Text(
                          occasion.trim().isEmpty
                              ? specialSetupTitle(context, kind)
                              : occasion.trim(),
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: foreground,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (dateText case final date?)
                          Text(
                            date,
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('setup_details.countdown'),
                style: const TextStyle(
                  color: muted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final feature in specialSetupOptions[kind]!.$3)
                    Container(
                      constraints: const BoxConstraints(minHeight: 30),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x14ffffff),
                        border: Border.all(color: const Color(0x1fffffff)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.tr('setup_specials.features.$feature'),
                        style: const TextStyle(
                          color: foreground,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

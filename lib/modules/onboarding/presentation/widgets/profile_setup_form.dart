import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import 'profile_avatar_picker.dart';

class ProfileSetupForm extends StatelessWidget {
  const ProfileSetupForm({
    super.key,
    required this.first,
    required this.last,
    required this.job,
    required this.color,
    required this.photo,
    required this.roles,
    required this.onFirst,
    required this.onLast,
    required this.onJob,
    required this.onPhoto,
    required this.onColor,
    required this.onRole,
  });

  final String first, last, job;
  final int color;
  final Uint8List? photo;
  final Set<String> roles;
  final ValueChanged<String> onFirst, onLast, onJob, onRole;
  final ValueChanged<int> onColor;
  final VoidCallback onPhoto;

  static const roleRows = [
    ['common.member', 'common.line_manager'],
    ['onboarding.project_manager', 'common.team_lead'],
  ];

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.45,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileAvatarPicker(
          first: first,
          last: last,
          color: color,
          photo: photo,
          onPhoto: onPhoto,
          onColor: onColor,
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Expanded(
              child: _ProfileField(
                label: tr('common.first_name'),
                value: first,
                onChanged: onFirst,
                autofillHint: AutofillHints.givenName,
              ),
            ),
            Expanded(
              child: _ProfileField(
                label: tr('common.last_name'),
                value: last,
                onChanged: onLast,
                autofillHint: AutofillHints.familyName,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ProfileField(
          label: tr('common.job_title'),
          value: job,
          onChanged: onJob,
          autofillHint: AutofillHints.jobTitle,
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            text: tr('onboarding.what_do_you_do_here'),
            children: [
              TextSpan(
                text: ' ${tr('onboarding.pick_all_that_apply')}',
                style: TextStyle(color: context.profileSetupDim),
              ),
            ],
          ),
          style: labelStyle.copyWith(color: context.profileSetupMuted),
        ),
        for (final row in roleRows) ...[
          if (row != roleRows.first) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in row)
                ChoiceChip(
                  label: Text(tr(role)),
                  selected: roles.contains(role),
                  showCheckmark: false,
                  backgroundColor: Colors.transparent,
                  selectedColor: context.foreground,
                  surfaceTintColor: Colors.transparent,
                  labelStyle: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: roles.contains(role)
                        ? context.background
                        : context.profileSetupMuted,
                  ),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  visualDensity: VisualDensity.standard,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: roles.contains(role)
                        ? context.foreground
                        : context.outline,
                  ),
                  onSelected: (_) => onRole(role),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.autofillHint,
  });

  final String label, value, autofillHint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      ExcludeSemantics(
        child: Text(
          label,
          style: TextStyle(
            color: context.profileSetupMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      ),
      Semantics(
        label: label,
        child: TextFormField(
          initialValue: value,
          onChanged: onChanged,
          autofillHints: [autofillHint],
          textInputAction: autofillHint == AutofillHints.jobTitle
              ? TextInputAction.done
              : TextInputAction.next,
          style: TextStyle(fontSize: 16, color: context.foreground),
          decoration: InputDecoration(
            filled: true,
            fillColor: context.panel,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            constraints: const BoxConstraints(minHeight: 54),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: context.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: DesignColor.purple),
            ),
          ),
        ),
      ),
    ],
  );
}

import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/tms_icons.dart';

extension ProfileSetupPalette on BuildContext {
  Color get profileSetupMuted => dark ? const Color(0xff9397ab) : muted;
  Color get profileSetupDim =>
      dark ? const Color(0xff75798c) : const Color(0xff73778b);
}

class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.first,
    required this.last,
    required this.color,
    required this.photo,
    this.photoUrl,
    required this.onPhoto,
    required this.onColor,
  });

  final String first, last;
  final int color;
  final Uint8List? photo;
  final String? photoUrl;
  final VoidCallback onPhoto;
  final ValueChanged<int> onColor;

  static const colors = [
    Color(0xffc4bdf6),
    Color(0xff86d6cb),
    Color(0xffeccb84),
    Color(0xffeeabb0),
    Color(0xffa3c8f1),
    Color(0xffbcd995),
  ];

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final initials = [first.trim(), last.trim()]
        .where((name) => name.isNotEmpty)
        .map((name) => name.characters.first)
        .join()
        .toUpperCase();

    final remote = Uri.tryParse(photoUrl ?? '');
    final ImageProvider? image = photo != null
        ? MemoryImage(photo!)
        : remote != null && remote.scheme == 'https' && remote.host.isNotEmpty
        ? NetworkImage(remote.toString())
        : null;
    return Row(
      spacing: 16,
      children: [
        SizedBox.square(
          dimension: 84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: DesignMotion.duration(
                  context,
                  const Duration(milliseconds: 400),
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors[color],
                  shape: BoxShape.circle,
                  image: image == null
                      ? null
                      : DecorationImage(image: image, fit: BoxFit.cover),
                ),
                child: image == null
                    ? Text(
                        initials.isEmpty ? '?' : initials,
                        style: const TextStyle(
                          color: DesignColor.ink,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
              PositionedDirectional(
                end: -6,
                bottom: -6,
                child: SizedBox.square(
                  dimension: 36,
                  child: IconButton(
                    tooltip: tr('onboarding.choose_profile_photo'),
                    onPressed: onPhoto,
                    icon: const Icon(TmsIcons.camera, size: 16),
                    padding: EdgeInsets.zero,
                    style: IconButton.styleFrom(
                      backgroundColor: DesignColor.purple,
                      foregroundColor: DesignColor.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: context.background, width: 3),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('onboarding.add_a_photo_or_pick_your_colour'),
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: context.profileSetupMuted,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 246),
                child: Row(
                  spacing: 6,
                  children: [
                    for (final (index, swatch) in colors.indexed)
                      Flexible(
                        child: Semantics(
                          selected: index == color && photo == null,
                          child: Tooltip(
                            message: tr(
                              'onboarding.avatar_colour',
                              namedArgs: {
                                'number': NumberFormat.decimalPattern(
                                  context.locale.toString(),
                                ).format(index + 1),
                              },
                            ),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onColor(index),
                              child: AnimatedScale(
                                scale: index == color && photo == null
                                    ? 1.12
                                    : 1,
                                duration: DesignMotion.duration(
                                  context,
                                  const Duration(milliseconds: 300),
                                ),
                                curve: Curves.easeOutBack,
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: AnimatedContainer(
                                    duration: DesignMotion.duration(
                                      context,
                                      DesignMotion.fast,
                                    ),
                                    width: 36,
                                    height: 36,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: index == color && photo == null
                                            ? context.foreground
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: swatch,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

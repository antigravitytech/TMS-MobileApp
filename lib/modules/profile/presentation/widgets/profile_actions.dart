part of '../profile_screen.dart';

/// Opens the status sheet and returns the picked status.
Future<Presence?> _pickStatus(
  BuildContext context,
  Presence current,
) => showGeneralDialog<Presence>(
  context: context,
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: Colors.transparent,
  transitionDuration: DesignMotion.duration(context, DesignMotion.page),
  pageBuilder: (sheet, animation, _) => Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () => Navigator.pop(sheet),
          child: FadeTransition(
            opacity: animation,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: const ColoredBox(color: Color(0xa6080910)),
            ),
          ),
        ),
      ),
      Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: DesignMotion.curve),
          ),
          child: BottomSheet(
            backgroundColor: sheet.panel,
            enableDrag: false,
            showDragHandle: false,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            onClosing: () => Navigator.pop(sheet),
            builder: (context) => SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: context.outline,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DesignTitle(context.tr('profile.set_your_status')),
                    const SizedBox(height: 10),
                    for (final status in Presence.values)
                      Semantics(
                        selected: current == status,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(sheet, status),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 4,
                            ),
                            child: Row(
                              spacing: 12,
                              children: [
                                CircleAvatar(
                                  radius: 6,
                                  backgroundColor: _presenceColor(status),
                                ),
                                Expanded(
                                  child: Text(
                                    context.tr(presenceLabelKey(status)),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (current == status)
                                  Icon(
                                    TmsIcons.check,
                                    color: context.lavender,
                                    size: 18,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  ),
  transitionBuilder: (_, _, _, child) => child,
);

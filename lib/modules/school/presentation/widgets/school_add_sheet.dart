import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/design/design_widgets.dart';
import '../../application/school_controller.dart';
import 'school_widgets.dart';

Future<void> showSchoolAdd(BuildContext c, SchoolController controller) =>
    designSheet<void>(
      c,
      title: c.tr('school.add'),
      builder: (_) => _Add(controller: controller),
    );

class _Add extends StatefulWidget {
  const _Add({required this.controller});
  final SchoolController controller;
  @override
  State<_Add> createState() => _AddState();
}

class _AddState extends State<_Add> {
  String type = 'hw', title = '';
  bool busy = false;
  @override
  Widget build(BuildContext c) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var row = 0; row < 2; row++)
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            spacing: 7,
            children: [
              for (var col = 0; col < 3; col++)
                Expanded(
                  child: Builder(
                    builder: (c) {
                      final value = [
                        'hw',
                        'test',
                        'form',
                        'pta',
                        'buy',
                        'fees',
                      ][row * 3 + col];
                      final color = schoolColor(value);
                      return GestureDetector(
                        onTap: () => setState(() => type = value),
                        child: AnimatedContainer(
                          duration: DesignMotion.fast,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: type == value
                                ? DesignColor.purple.withValues(alpha: .17)
                                : c.panel,
                            border: Border.all(
                              color: type == value
                                  ? DesignColor.purple
                                  : c.outline,
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: color.withValues(alpha: .3),
                                  ),
                                ),
                                child: Icon(
                                  schoolIcon(value),
                                  size: 17,
                                  color: color,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                c.tr('school.type_$value'),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      const SizedBox(height: 8),
      TextField(
        onChanged: (v) => title = v,
        decoration: InputDecoration(
          hintText: c.tr('school.add_hint'),
          filled: true,
          fillColor: c.panel,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: c.outline),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        c.tr(
          'school.add_for',
          namedArgs: {
            'name': widget.controller.child.isEmpty
                ? 'Tobi'
                : widget.controller.child,
          },
        ),
        style: TextStyle(color: c.muted, fontSize: 12),
      ),
      const SizedBox(height: 16),
      DesignButton(
        c.tr('school.add_button'),
        onPressed: busy
            ? null
            : () async {
                setState(() => busy = true);
                final ok = await widget.controller.add(
                  type,
                  title.trim().isEmpty ? c.tr('school.default_title') : title,
                );
                if (!c.mounted) return;
                if (ok) {
                  Navigator.pop(c);
                } else {
                  setState(() => busy = false);
                  designToast(c, c.tr('workspaces.try_again'));
                }
              },
      ),
    ],
  );
}

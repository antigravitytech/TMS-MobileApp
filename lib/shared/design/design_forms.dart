part of 'design_widgets.dart';

class DesignButton extends StatelessWidget {
  const DesignButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.secondary = false,
    this.disabledColor,
    this.color,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  final Color? color, disabledColor;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      disabledBackgroundColor: disabledColor,
      disabledForegroundColor: disabledColor == null ? null : DesignColor.ink,
      backgroundColor:
          color ?? (secondary ? context.raised : DesignColor.purple),
      foregroundColor: secondary ? context.foreground : DesignColor.ink,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 7,
      children: [
        if (icon != null) Icon(icon, size: 18),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class DesignField extends StatelessWidget {
  const DesignField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.lines = 1,
    this.obscure = false,
    this.autofocus = false,
    this.keyboardType,
    this.suffix,
  });
  final String label;
  final String? hint, initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final int lines;
  final bool obscure, autofocus;
  final TextInputType? keyboardType;
  final Widget? suffix;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    initialValue: controller == null ? initialValue : null,
    onChanged: onChanged,
    onFieldSubmitted: onSubmitted,
    autofocus: autofocus,
    keyboardType: keyboardType,
    obscureText: obscure,
    maxLines: lines,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      filled: true,
      fillColor: context.panel,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: context.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: DesignColor.purple),
      ),
    ),
  );
}

Future<T?> designSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: context.panel,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
  ),
  sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
      ? AnimationStyle.noAnimation
      : null,
  builder: (context) => SafeArea(
    top: false,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            if (title.trim().isNotEmpty) DesignTitle(title),
            builder(context),
          ],
        ),
      ),
    ),
  ),
);

void designToast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );

class DesignEmpty extends StatelessWidget {
  const DesignEmpty(
    this.title,
    this.subtitle, {
    super.key,
    this.icon = TmsIcons.checkCircle,
  });
  final String title, subtitle;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 12),
    child: Column(
      spacing: 10,
      children: [
        Icon(icon, color: context.lavender, size: 46),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.muted),
        ),
      ],
    ),
  );
}

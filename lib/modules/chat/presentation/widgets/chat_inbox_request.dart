part of '../chat_screens.dart';

extension _InboxRequest on _InboxState {
  Widget _requestCard(ChatRequest request) => DesignCard(
    color: context.background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        _label(context.tr('chat.chat_request')),
        Row(
          spacing: 12,
          children: [
            DesignAvatar(
              request.row.initials,
              color: chatColor(request.row.color),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.row.name} · ${context.tr(request.role)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  DesignLabel(request.detail),
                ],
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            for (final accept in [true, false])
              Expanded(
                child: DesignButton(
                  context.tr(accept ? 'chat.accept' : 'chat.decline'),
                  secondary: !accept,
                  onPressed: () => respond(request, accept: accept),
                ),
              ),
          ],
        ),
        DesignLabel(context.tr(request.note)),
      ],
    ),
  );
}

class _ChatFilter extends StatelessWidget {
  const _ChatFilter(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? context.foreground : Colors.transparent,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: context.outline),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? context.background : context.muted,
          ),
        ),
      ),
    ),
  );
}

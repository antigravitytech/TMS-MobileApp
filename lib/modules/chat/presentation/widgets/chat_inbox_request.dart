part of '../chat_screens.dart';

extension _InboxRequest on _InboxState {
  Widget _requestCard(List<String> request) => DesignCard(
    color: context.background,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        _label(context.tr('chat.chat_request')),
        Row(
          spacing: 12,
          children: [
            DesignAvatar(request[0], color: chatColor(request[1])),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request[2]} · ${context.tr(request[3])}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  DesignLabel(request[4]),
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
                  onPressed: () {
                    controller.resolveRequest(
                      accept
                          ? ChatRow(
                              initials: request[0],
                              color: request[1],
                              name: request[2],
                            )
                          : null,
                    );
                    designToast(
                      context,
                      context.tr(
                        accept ? request[6] : 'chat.chat_request_declined',
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        DesignLabel(context.tr(request[5])),
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

/// The design's six note colours, by their API names. The API's `teal`
/// shows as `slate`.
const noteColors = ['violet', 'lime', 'rose', 'sky', 'amber', 'slate'];

class JournalNote {
  const JournalNote({
    required this.id,
    required this.title,
    required this.body,
    required this.color,
    required this.updatedAt,
    this.pinned = false,
    this.remindAt,
  });
  final String id, title, body;

  /// One of [noteColors].
  final String color;
  final bool pinned;

  /// When the reminder rings, while it isn't done.
  final DateTime? remindAt;
  final DateTime updatedAt;

  JournalNote pin(bool value) => JournalNote(
    id: id,
    title: title,
    body: body,
    color: color,
    updatedAt: DateTime.now(),
    pinned: value,
    remindAt: remindAt,
  );
}

/// A note being written.
typedef NoteDraft = ({
  String title,
  String body,
  String color,
  DateTime? remindAt,
});

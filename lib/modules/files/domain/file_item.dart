/// The library's file kinds.
enum FileKind { pdf, image, video, document }

/// A file attached to a task.
class FileItem {
  const FileItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.size,
    required this.uploader,
    required this.taskId,
    required this.taskTitle,
    required this.createdAt,
    this.project = '',
    this.url = '',
  });
  final String id, name, uploader, project;
  final FileKind kind;

  /// Bytes.
  final int size;
  final String taskId, taskTitle;
  final DateTime createdAt;

  /// A signed link that saves the file under its name.
  final String url;
}

/// A file chosen on the device, ready to upload.
typedef PickedFile = ({String name, String path, int size});

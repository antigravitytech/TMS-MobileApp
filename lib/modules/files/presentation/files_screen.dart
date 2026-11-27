import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart' show FileType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/media_service.dart';
import '../../../router/tms_routes.dart';
import '../../../shared/design/design_tokens.dart';
import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';
import '../../tasks/application/tasks_controller.dart';
import '../../tasks/data/tasks_repository.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/presentation/tasks_screen.dart' show taskErrorMessage;
import '../application/files_controller.dart';
import '../domain/file_item.dart';

part 'widgets/file_list_widgets.dart';

class FilesScreen extends ConsumerStatefulWidget {
  const FilesScreen({super.key});
  @override
  ConsumerState<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends ConsumerState<FilesScreen> {
  /// The type chips; null is "All types".
  static const kinds = [
    null,
    FileKind.pdf,
    FileKind.image,
    FileKind.document,
    FileKind.video,
  ];

  FileKind? kind;
  String? project, owner;

  /// Picks files on the device, then a task to attach them to.
  Future<void> upload() async {
    final choice = await designSheet<FileType>(
      context,
      title: context.tr('files.add_a_file'),
      builder: (sheet) => Column(
        children: [
          DesignLabel(context.tr('files.attach_it_to_a_task_so_it')),
          DesignTile(
            title: context.tr('files.photos'),
            icon: TmsIcons.gallery,
            onTap: () => Navigator.pop(sheet, FileType.image),
          ),
          DesignTile(
            title: context.tr('files.browse'),
            icon: TmsIcons.folderOpen,
            onTap: () => Navigator.pop(sheet, FileType.any),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    final List<PickedFile> picked;
    try {
      picked = [
        for (final f in await MediaService.pickFiles(type: choice) ?? const [])
          if (f.path case final path?) (name: f.name, path: path, size: f.size),
      ];
    } catch (_) {
      if (mounted) {
        designToast(
          context,
          context.tr('files.the_file_picker_could_not_open'),
        );
      }
      return;
    }
    if (!mounted || picked.isEmpty) return;
    final task = await _pickTask();
    if (!mounted || task == null) return;
    try {
      await ref.read(filesProvider.notifier).upload(picked, task);
      if (!mounted) return;
      setState(() => kind = project = owner = null);
      designToast(
        context,
        context.plural(
          'files.uploaded_to',
          picked.length,
          namedArgs: {'task': task.reference},
        ),
      );
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    }
  }

  /// My tasks to attach a file to, loaded when the sheet opens.
  Future<TaskItem?> _pickTask() => designSheet<TaskItem>(
    context,
    title: context.tr('files.choose_task'),
    builder: (sheet) => Consumer(
      builder: (context, ref, _) => switch (ref.watch(
        tasksListProvider(TaskScope.mine),
      )) {
        AsyncValue(value: final list?) => Column(
          children: [
            if (list.tasks.isEmpty) DesignLabel(context.tr('files.no_tasks')),
            for (final t in list.tasks.where((t) => !t.done))
              DesignTile(
                title: t.title,
                subtitle: t.reference,
                icon: TmsIcons.checkSquare,
                onTap: () => Navigator.pop(sheet, t),
              ),
          ],
        ),
        AsyncValue(:final error?) => DesignLabel(
          taskErrorMessage(context, error),
        ),
        _ => const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      },
    ),
  );

  /// The row only knows the task's id, so load it before opening.
  Future<void> openTask(FileItem file) async {
    try {
      final task = await ref.read(tasksRepositoryProvider).byId(file.taskId);
      if (!mounted) return;
      ref.read(openedTaskProvider.notifier).open(task);
      TmsRoute.task.open(context);
    } catch (error) {
      if (mounted) designToast(context, taskErrorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(filesProvider);
    final files = async.value;
    final projects = {
      for (final f in files ?? const <FileItem>[])
        if (f.project.isNotEmpty) f.project,
    }.toList();
    final owners = {
      for (final f in files ?? const <FileItem>[]) f.uploader,
    }.toList();
    T? next<T>(List<T> options, T? current) {
      final i = current == null ? -1 : options.indexOf(current);
      return i + 1 < options.length ? options[i + 1] : null;
    }

    final visible = [
      for (final f in files ?? const <FileItem>[])
        if ((kind == null || f.kind == kind) &&
            (project == null || f.project == project) &&
            (owner == null || f.uploader == owner))
          f,
    ];
    return DesignPage(
      title: context.tr('common.files'),
      actions: [
        DesignButton(
          context.tr('files.upload'),
          icon: TmsIcons.upload,
          onPressed: files == null ? null : upload,
        ),
      ],
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              for (final k in kinds)
                _FileChip(
                  context.tr(
                    k == null ? 'files.all_types' : 'files.kinds.${k.name}',
                  ),
                  selected: kind == k,
                  onTap: () => setState(() => kind = k),
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: [
              _FileChip(
                project ?? context.tr('common.all_projects'),
                icon: TmsIcons.monitor,
                onTap: () => setState(() => project = next(projects, project)),
                dropdown: true,
              ),
              _FileChip(
                owner ?? context.tr('files.anyone'),
                onTap: () => setState(() => owner = next(owners, owner)),
                dropdown: true,
              ),
            ],
          ),
        ),
        if (files == null && !async.hasError)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (files == null) ...[
          DesignLabel(taskErrorMessage(context, async.error)),
          DesignButton(
            context.tr('workspaces.try_again'),
            secondary: true,
            onPressed: () => ref.invalidate(filesProvider),
          ),
        ] else if (visible.isEmpty)
          DesignEmpty(
            context.tr('files.no_files_found'),
            context.tr(
              files.isEmpty
                  ? 'files.attach_it_to_a_task_so_it'
                  : 'files.try_changing_the_file_filters',
            ),
            icon: TmsIcons.folderMissing,
          )
        else
          DesignCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, file) in visible.indexed) ...[
                  if (i > 0) Divider(height: 1, color: context.outline),
                  _FileRow(file: file, onTap: () => openTask(file)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

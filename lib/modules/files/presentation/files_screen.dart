import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../shared/design/design_widgets.dart';
import '../../../shared/design/tms_icons.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});
  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  static const types = [
    'files.all_files',
    'files.documents',
    'files.images',
    'files.other',
  ];
  final files = <(String, String, String, String)>[
    ('Q4 hiring budget.xlsx', 'files.documents', 'common.standalone', 'Chioma'),
    (
      'Usability test findings.pdf',
      'files.documents',
      'Customer Portal Revamp',
      'Sarah',
    ),
    ('Checkout mockup.png', 'files.images', 'Customer Portal Revamp', 'Amaka'),
    ('Webhook test run.zip', 'files.other', 'Customer Portal Revamp', 'Tunde'),
  ];
  int type = 0, project = 0, owner = 0;
  static const projects = [
    'common.all_projects',
    'Customer Portal Revamp',
    'common.standalone',
  ];
  static const owners = ['files.anyone', 'Chioma', 'Sarah', 'Amaka', 'Tunde'];
  String projectLabel(BuildContext context, String project) =>
      switch (project) {
        'common.all_projects' || 'common.standalone' => context.tr(project),
        _ => project,
      };

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
    try {
      final result = await FilePicker.pickFiles(type: choice);
      if (!mounted || result.isEmpty) return;
      setState(() {
        for (final item in result) {
          final extension = item.extension?.toLowerCase();
          final category =
              ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)
              ? 'files.images'
              : ['pdf', 'doc', 'docx', 'xlsx', 'txt'].contains(extension)
              ? 'files.documents'
              : 'files.other';
          files.insert(0, (item.name, category, 'common.standalone', 'Chioma'));
        }
        type = 0;
        owner = 0;
        project = 0;
      });
      designToast(context, context.tr('files.files_added_to_this_preview'));
    } catch (_) {
      if (mounted) {
        designToast(
          context,
          context.tr('files.the_file_picker_could_not_open'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = files.where(
      (f) =>
          (type == 0 || f.$2 == types[type]) &&
          (project == 0 || f.$3 == projects[project]) &&
          (owner == 0 || f.$4 == owners[owner]),
    );
    return DesignPage(
      title: context.tr('common.files'),
      actions: [
        DesignButton(
          context.tr('files.upload'),
          icon: TmsIcons.upload,
          onPressed: upload,
        ),
      ],
      children: [
        DesignChoices(
          items: types.map(context.tr).toList(),
          selected: type,
          onChanged: (i) => setState(() => type = i),
        ),
        Wrap(
          spacing: 8,
          children: [
            DesignPill(
              projectLabel(context, projects[project]),
              icon: TmsIcons.folder,
              onTap: () =>
                  setState(() => project = (project + 1) % projects.length),
            ),
            DesignPill(
              owner == 0 ? context.tr(owners.first) : owners[owner],
              onTap: () => setState(() => owner = (owner + 1) % owners.length),
            ),
          ],
        ),
        if (visible.isEmpty)
          DesignEmpty(
            context.tr('files.no_files_found'),
            context.tr('files.try_changing_the_file_filters'),
            icon: TmsIcons.folderMissing,
          ),
        if (visible.isNotEmpty)
          DesignSection(
            children: [
              for (final (name, type, project, owner) in visible)
                DesignTile(
                  title: name,
                  subtitle: '${projectLabel(context, project)} · $owner',
                  icon: type == 'files.images' ? TmsIcons.image : TmsIcons.file,
                  onTap: () => designSheet<void>(
                    context,
                    title: name,
                    builder: (_) => DesignLabel(
                      context.tr(
                        'files.file_details',
                        namedArgs: {
                          'type': context.tr(type),
                          'project': (projectLabel(
                            context,
                            project,
                          )).toString(),
                          'owner': owner,
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

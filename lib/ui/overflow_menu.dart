import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paintroid/core/app_localizations.dart';
import 'package:paintroid/ui/io_handler.dart';
import 'package:paintroid/workspace/workspace.dart';

import '../data/model/project.dart';
import '../data/project_database.dart';
import '../io/src/ui/save_image_dialog.dart';

enum OverflowMenuOption {
  fullscreen,
  saveImage,
  saveProject,
  loadImage,
  newImage;

  String localizedLabel(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    switch (this) {
      case OverflowMenuOption.fullscreen:
        return localizations.fullscreen;
      case OverflowMenuOption.saveImage:
        return localizations.saveImage;
      case OverflowMenuOption.loadImage:
        return localizations.loadImage;
      case OverflowMenuOption.newImage:
        return localizations.newImage;
      case OverflowMenuOption.saveProject:
        return localizations.saveProject;
    }
  }
}

class OverflowMenu extends ConsumerStatefulWidget {
  const OverflowMenu({Key? key}) : super(key: key);

  @override
  ConsumerState<OverflowMenu> createState() => _OverflowMenuState();
}

class _OverflowMenuState extends ConsumerState<OverflowMenu> {
  IOHandler get ioHandler => ref.read(IOHandler.provider);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OverflowMenuOption>(
      color: Theme.of(context).colorScheme.background,
      icon: const Icon(Icons.more_vert),
      shape: RoundedRectangleBorder(
        side: const BorderSide(),
        borderRadius: BorderRadius.circular(20),
      ),
      onSelected: _handleSelectedOption,
      itemBuilder: (BuildContext context) {
        return OverflowMenuOption.values.map((option) {
          return PopupMenuItem(
            value: option,
            child: Text(option.localizedLabel(context)),
          );
        }).toList();
      },
    );
  }

  void _handleSelectedOption(OverflowMenuOption option) {
    final ioHandler = ref.watch(IOHandler.provider);
    switch (option) {
      case OverflowMenuOption.fullscreen:
        _enterFullscreen();
        break;
      case OverflowMenuOption.saveImage:
        ioHandler.saveImage(context);
        break;
      case OverflowMenuOption.saveProject:
        _saveProject();
        break;
      case OverflowMenuOption.loadImage:
        ioHandler.loadImage(context, this, true);
        break;
      case OverflowMenuOption.newImage:
        ioHandler.newImage(context, this);
        break;
    }
  }

  void _enterFullscreen() =>
      ref.read(WorkspaceState.provider.notifier).toggleFullscreen(true);

  void _saveProject() async {
    File? savedProject;
    final imageData = await showSaveImageDialog(context, true);

    if (imageData != null && mounted) {
      savedProject = await ioHandler.saveProject(imageData);
      if (savedProject != null) {
        String? imagePreview = await ioHandler.getPreviewPath(imageData);
        Project project = Project(
          name: imageData.name,
          path: savedProject.path,
          lastModified: DateTime.now(),
          creationDate: DateTime.now(),
          resolution: "",
          format: imageData.format.name,
          size: await savedProject.length(),
          imagePreviewPath: imagePreview,
        );

        final db = await ref.read(ProjectDatabase.provider.future);
        await db.projectDAO.insertProject(project);
      }
    }
  }
}

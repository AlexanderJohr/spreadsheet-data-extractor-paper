import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/l10n/app_localizations.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/widgets/buttons/language_dropdown_button.dart';

import '../app_state.dart';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/excel_file_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/import_excel_files_task_view_model.dart';
import 'package:spreadsheet_data_extractor/src/utils/clipboard_utils.dart';
import 'package:spreadsheet_data_extractor/src/utils/file_dialog_utils.dart';
import 'package:spreadsheet_data_extractor/src/views/message_dialogs.dart';

import 'package:spreadsheet_data_extractor/src/utils/value_utils.dart';
import 'dart:async';

import 'package:path/path.dart';

import 'shared_widgets/import_excel_sheets_task_list_view_header.dart';
import 'shared_widgets/theme_button.dart';

class TaskOverviewPage extends Page {
  const TaskOverviewPage() : super(key: const ValueKey(TaskOverviewPage));
  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, animation2) {
        final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero);
        final curveTween = CurveTween(curve: Curves.easeInOut);
        return SlideTransition(
          position: animation.drive(curveTween).drive(tween),
          child: TaskOverview(),
        );
      },
    );
  }
}

class TaskOverview extends StatefulWidget {
  const TaskOverview({Key? key}) : super(key: key);

  @override
  State<TaskOverview> createState() => _TaskOverviewState();
}

class _TaskOverviewState extends State<TaskOverview> {
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context)!.importExcelFilesButtonText),
        onPressed: () async {
          final files = await selectExcelFilesWithFileDialog();
          if (files.isNotEmpty) {
            final decodedFiles = importSelectedFiles(files, context);
            final viewModel = InheritedTaskListViewModel.of(context);
            viewModel.addImportExcelFilesTask(
              files:
                  decodedFiles
                      .map((f) => ExcelFileViewModel(excelFile: f))
                      .toList(),
            );
            viewModel.treeChanged();
          }
        },
      ),
      bottomNavigationBar: _DemoBottomAppBar(),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.taskPageTitle),
        actions: const [const ThemeButton(), LanguageDropdownButton()],
      ),
      body: ListenableBuilder(
        listenable: SelectedSheetService.of(context),
        builder: (context, snapshot) {
          return TaskListView();
        },
      ),
    );
  }

  List<PopupMenuEntry<String>> buildConfigurationPopupMenuEntries(
    BuildContext context,
  ) {
    return [
      PopupMenuItem<String>(
        onTap: () async {
          final serialized = serializers.serialize(
            InheritedTaskListViewModel.of(context).taskModel,
          );
          await Clipboard.setData(ClipboardData(text: jsonEncode(serialized)));
        },
        child: ListTile(
          leading: const Icon(Icons.copy, color: Colors.blueAccent),
          title: Text(AppLocalizations.of(context)!.copyConfigButtonText),
        ),
      ),
      PopupMenuItem<String>(
        child: FutureBuilder<TaskList?>(
          future: getConfigurationFromClipboardOrNull(),
          builder:
              (context, taskListSnapshot) => ListTile(
                enabled: taskListSnapshot.data != null,
                title: Text(
                  AppLocalizations.of(context)!.insertConfigButtonText,
                ),
                leading: const Icon(Icons.paste, color: Colors.blueAccent),
                onTap: () async {
                  final taskList = taskListSnapshot.data;
                  if (taskList != null) {
                    final importExcelFilesTaskViewModels =
                        await convertToImportExcelFilesTaskViewModel(
                          taskList: taskList,
                          context: context,
                          parentViewModel: InheritedTaskListViewModel.of(
                            context,
                          ),
                        );
                    InheritedTaskListViewModel.of(
                          context,
                        ).importExcelFilesTasks =
                        importExcelFilesTaskViewModels.toList();
                  }
                },
              ),
        ),
      ),
      PopupMenuItem<String>(
        onTap: () => saveConfigurationToFile(context),
        child: ListTile(
          leading: const Icon(Icons.copy, color: Colors.blueAccent),
          title: Text(AppLocalizations.of(context)!.saveConfigButtonText),
        ),
      ),
      PopupMenuItem<String>(
        child: ListTile(
          title: Text(AppLocalizations.of(context)!.loadConfigButtonText),
          leading: const Icon(Icons.paste, color: Colors.blueAccent),
          onTap: () => _loadConfiguration(context),
        ),
      ),
    ];
  }
}

Future<String?> selectExcelSavePathWithFileDialog() async {
  const typeGroup = XTypeGroup(extensions: ['csv']);
  final file = await getSaveLocation(acceptedTypeGroups: [typeGroup]);
  if (file == null) {
    return null;
  }
  final hasCorrectFileExtension = file.path.endsWith(".csv");

  final csvFilePath = hasCorrectFileExtension ? file.path : "${file.path}.csv";

  return csvFilePath;
}

class InheritedTaskListViewModel extends InheritedWidget {
  const InheritedTaskListViewModel({
    Key? key,
    required Widget child,
    required this.viewModel,
  }) : super(key: key, child: child);

  final TaskListViewModel viewModel;

  static TaskListViewModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InheritedTaskListViewModel>()!
        .viewModel;
  }

  @override
  bool updateShouldNotify(covariant InheritedTaskListViewModel oldWidget) {
    return false;
  }
}

class TaskListView extends StatefulWidget {
  const TaskListView() : super(key: const ValueKey(TaskListView));

  @override
  State<TaskListView> createState() => _TaskListViewState();
}

class _TaskListViewState extends State<TaskListView> {
  FocusNode rawKeyboardListenerFocusNode = FocusNode();
  FocusNode rawKeyboardListenerFocusNode2 = FocusNode();

  @override
  Widget build(BuildContext context) {
    final viewModel = InheritedTaskListViewModel.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, snapshot) {
        List slivers = <Widget>[];

        final excelFileTasks = viewModel.importExcelFilesTasks;
        for (var excelFileTask in excelFileTasks) {
          final excelFilesTaskHeader = Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: ImportExcelFilesTaskListViewHeader(task: excelFileTask),
              ),
              const Divider(),
            ],
          );
          slivers.add(SliverToBoxAdapter(child: excelFilesTaskHeader));

          final excelSheetsTasks = excelFileTask.importExcelSheetsTasks;
          for (var excelSheetsTask in excelSheetsTasks) {
            final excelSheetsTaskHeader = Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: ImportExcelSheetsTaskListViewHeader(
                    importSheetTask: excelSheetsTask,
                  ),
                ),
                const Divider(),
              ],
            );
            slivers.add(SliverToBoxAdapter(child: excelSheetsTaskHeader));

            final topLevelExcelCellsTasks =
                excelSheetsTask.importExcelCellsTasks;
            if (topLevelExcelCellsTasks.isNotEmpty) {
              final stack = <ImportExcelCellsTaskViewModel>[];

              for (var topLevelExcelCellsTask
                  in topLevelExcelCellsTasks.reversed) {
                stack.add(topLevelExcelCellsTask);
              }

              while (stack.isNotEmpty) {
                final current = stack.removeLast();

                final nestedExcelCellsTasks = current.importExcelCellsTasks;
                for (var next in nestedExcelCellsTasks.reversed) {
                  stack.add(next);
                }
              }
            }
          }
        }

        return CustomScrollView(slivers: [...slivers]);
      },
    );
  }
}

class OutputTable extends StatelessWidget {
  const OutputTable({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = InheritedTaskListViewModel.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, snapshot) {
        final cellValues = viewModel.getValues().transposed;

        final maxColumnWidths =
            cellValues.isNotEmpty
                ? cellValues.first
                    .map<BehaviorSubject<double?>>(
                      (cell) => BehaviorSubject.seeded(null),
                    )
                    .toList()
                : <BehaviorSubject<double?>>[];
        final maxColumnHeights =
            cellValues.isNotEmpty
                ? cellValues.first
                    .map<BehaviorSubject<double?>>(
                      (cell) => BehaviorSubject.seeded(null),
                    )
                    .toList()
                : <BehaviorSubject<double?>>[];

        return SliverPrototypeExtentList(
          delegate: SliverChildBuilderDelegate((
            BuildContext context,
            int index,
          ) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int x = 0; x < cellValues[index].length; x++)
                    ResizableTableCell(
                      child: ValueCell(cellValue: cellValues[index][x]),
                      maxColumnWidth: maxColumnWidths[x],
                      maxRowHeight: maxColumnHeights[x],
                    ),
                ],
              ),
            );
          }, childCount: cellValues.length),
          prototypeItem: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int x = 0; x < (cellValues.firstOrNull?.length ?? 0); x++)
                  ResizableTableCell(
                    child: ValueCell(cellValue: cellValues.first[x]),
                    maxColumnWidth: maxColumnWidths[x],
                    maxRowHeight: maxColumnHeights[x],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ResizableTableCell extends StatefulWidget {
  const ResizableTableCell({
    Key? key,
    required this.child,
    required this.maxColumnWidth,
    required this.maxRowHeight,
    this.expandable = true,
  }) : super(key: key);

  final BehaviorSubject<double?> maxColumnWidth;
  final BehaviorSubject<double?> maxRowHeight;
  final Widget child;
  final bool expandable;

  @override
  State<ResizableTableCell> createState() => _ResizableTableCellState();
}

class _ResizableTableCellState extends State<ResizableTableCell> {
  BehaviorSubject<double?> get maxColumnWidthBehavior => widget.maxColumnWidth;
  BehaviorSubject<double?> get maxRowHeightBehavior => widget.maxRowHeight;

  @override
  Widget build(BuildContext context) {
    final widgetsBinding = WidgetsBinding.instance;

    if (mounted) {
      widgetsBinding.addPostFrameCallback((a) {
        if (mounted) {
          final size = this.context.size;
          if (size != null) {
            final renderedWidth = size.width;

            final maxColumnWidth = maxColumnWidthBehavior.value;

            if (maxColumnWidth == null) {
              maxColumnWidthBehavior.value = renderedWidth;
            } else if (widget.expandable && maxColumnWidth < renderedWidth) {
              maxColumnWidthBehavior.value = renderedWidth;
            }

            final maxRowHeight = maxRowHeightBehavior.value;

            final renderedHeight = size.height;

            if (maxRowHeight == null) {
              maxRowHeightBehavior.value = renderedHeight;
            } else if (maxRowHeight < renderedHeight) {
              maxRowHeightBehavior.value = renderedHeight;
            }
          }
        }
      });
    }

    return StreamBuilder<List<double?>>(
      stream: Rx.combineLatestList<double?>([
        maxColumnWidthBehavior,
        maxRowHeightBehavior,
      ]),
      builder: (context, snapshot) {
        return Container(
          constraints:
              widget.expandable
                  ? BoxConstraints(
                    minWidth: maxColumnWidthBehavior.value ?? 0,
                    minHeight: maxRowHeightBehavior.value ?? 0,
                  )
                  : BoxConstraints(
                    maxWidth: maxColumnWidthBehavior.value ?? 0,
                    maxHeight: maxRowHeightBehavior.value ?? 0,
                    minWidth: maxColumnWidthBehavior.value ?? 0,
                    minHeight: maxRowHeightBehavior.value ?? 0,
                  ),
          child: widget.child,
        );
      },
    );
  }
}

class ValueCell extends StatefulWidget {
  const ValueCell({Key? key, required this.cellValue}) : super(key: key);

  final Value cellValue;

  @override
  State<ValueCell> createState() => _ValueCellState();
}

class _ValueCellState extends State<ValueCell> {
  Value get cellValue => widget.cellValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: getColorForCellType(cellValue),
        border: Border.all(color: Colors.black, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          cellValue.value,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

Color getColorForCellType(Value cellValue) {
  switch (cellValue.type) {
    case ValueType.selected:
      return Colors.white;
    case ValueType.typed:
      return Colors.black26;
    case ValueType.filled:
      return Colors.cyan;
    case ValueType.automaticallyGenerated:
      return Colors.greenAccent;
    case ValueType.combined:
      return Colors.blueAccent;
    case ValueType.errorWhenFilled:
      return Colors.purple;
    case ValueType.missingWhenJoined:
      return Colors.redAccent;
    case ValueType.missingWhenTransposed:
      return Colors.orange;
    case ValueType.missingWhenCombined:
      return Colors.deepPurple;

    default:
      return Colors.white;
  }
}

class ImportExcelFilesTaskListViewHeader extends StatelessWidget {
  const ImportExcelFilesTaskListViewHeader({Key? key, required this.task})
    : super(key: key);

  final ImportExcelFilesTaskViewModel task;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: task.excelFilesByPathBehavior,
      builder: (context, snapshot) {
        return ListTile(
          leading: Icon(
            Icons.insert_drive_file_sharp,
            size:
                Theme.of(context).iconTheme.size != null
                    ? Theme.of(context).iconTheme.size! * 1.5
                    : null,
          ),
          title: Text(AppLocalizations.of(context)!.importExcelFilesButtonText),
          subtitle: Wrap(
            spacing: 16.0,
            //  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var file in task.excelFilesByPath.values)
                Wrap(
                  direction: Axis.horizontal,
                  spacing: 8.0,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Icon(
                                  Icons.insert_drive_file,
                                  color: Colors.grey,
                                ),
                              ),
                              TextSpan(text: '${file.name}: '),
                            ],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            task.removeFile(file);
                            task.parent.treeChanged();
                          },
                          child: const Icon(
                            Icons.delete_forever,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_box_rounded,
                              color: Colors.greenAccent,
                            ),
                            Icon(
                              Icons.table_chart_sharp,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.importSheetsButtonText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    final addedImportExcelSheetsTask = task
                        .addImportExcelSheetsTaskViewModel(
                          excelFiles: task.excelFilesByPath.values,
                        );
                    SelectedSheetService.of(context).activeSheetTask =
                        addedImportExcelSheetsTask;
                  },
                ),
              ),
              Card(
                child: InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_box_rounded,
                              color: Colors.greenAccent,
                            ),
                            Icon(
                              Icons.insert_drive_file_sharp,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            AppLocalizations.of(
                              context,
                            )!.importAdditionalFilesButtonText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  onTap: () async {
                    final files = await selectExcelFilesWithFileDialog();
                    if (files.isNotEmpty) {
                      final decodedFiles = importSelectedFiles(files, context);
                      task.updateFiles(
                        decodedFiles
                            .map(
                              (excelFile) =>
                                  ExcelFileViewModel(excelFile: excelFile),
                            )
                            .toList(),
                      );
                      task.parent.treeChanged();
                    }
                  },
                ),
              ),
              Card(
                child: PopupMenuButton<String>(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.adaptive.more),
                  ),
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        onTap: () async {
                          final serialized = serializers.serialize(
                            task.taskModel,
                          );
                          await Clipboard.setData(
                            ClipboardData(text: jsonEncode(serialized)),
                          );
                        },
                        child: ListTile(
                          leading: const Icon(
                            Icons.copy,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            AppLocalizations.of(
                              context,
                            )!.copyExcelFileImportTaskButtonText,
                          ),
                        ),
                      ),
                      PopupMenuItem<String>(
                        child: FutureBuilder<ImportExcelFilesTask?>(
                          future: getImportExcelFileTaskFromClipboardOrNull(),
                          builder:
                              (context, importExcelFilesTask) => ListTile(
                                enabled: importExcelFilesTask.data != null,
                                title: Text(
                                  AppLocalizations.of(
                                    context,
                                  )!.insertExcelFileImportTaskButtonText,
                                ),
                                leading: const Icon(
                                  Icons.paste,
                                  color: Colors.blueAccent,
                                ),
                                onTap: () async {
                                  final importExcelFilesTaskData =
                                      importExcelFilesTask.data;
                                  if (importExcelFilesTaskData != null) {
                                    task.taskModel = importExcelFilesTaskData;
                                  }
                                },
                              ),
                        ),
                      ),
                    ];
                  },
                ),
              ),
              Card(
                child: InkWell(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.delete_forever, color: Colors.redAccent),
                  ),
                  onTap: () {
                    task.remove();
                    task.parent.treeChanged();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future _exportCsv(BuildContext context) async {
  final viewModel = InheritedTaskListViewModel.of(context);

  final selectedSavePath = await selectExcelSavePathWithFileDialog();

  if (selectedSavePath != null) {
    final file = File(selectedSavePath);
    final fileExists = file.existsSync();

    final values = viewModel.getValues().transposed;

    final output = StringBuffer();
    String csvData = const ListToCsvConverter(
      delimitAllFields: true,
    ).convert(values, eol: defaultEol);

    if (fileExists) output.write(defaultEol);
    output.write(csvData);

    file.writeAsStringSync(
      output.toString(),
      mode: fileExists ? FileMode.append : FileMode.write,
    );

    final text =
        fileExists
            ? AppLocalizations.of(
              context,
            )!.fileExistsText(values.length, file.path)
            : AppLocalizations.of(
              context,
            )!.fileDoesNotExistsText(values.length, file.path);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

Future<void> _loadConfiguration(BuildContext context) async {
  final selectedConfigurationFile =
      await selectConfigurationOpenPathWithFileDialog();
  if (selectedConfigurationFile == null) {
    return;
  }

  final fileContent = File(selectedConfigurationFile.path).readAsStringSync();
  try {
    final decodedJson = jsonDecode(fileContent);

    final deserialized = serializers.deserialize(decodedJson);

    if (deserialized is TaskList) {
      getAbsoluteExcelFileFromRelativePath({
        required String relativeExcelFilePath,
        required String configurationFilePath,
      }) {
        final loadConfigurationDirectoryPath = dirname(configurationFilePath);
        final joined = join(
          loadConfigurationDirectoryPath,
          relativeExcelFilePath,
        );
        final normalized = normalize(joined);
        return normalized;
      }

      final newTaskModel = deserialized.rebuild((tm) {
        tm.childTasks.map(
          (excelFilesTask) => excelFilesTask.rebuild(
            (excelFilesTaskBuilder) =>
                excelFilesTaskBuilder
                  ..childTasks.map(
                    (sheetTask) => sheetTask.rebuild((sheetTaskBuilder) {
                      final newSheetNamesByExcelFilePath = {
                        for (final sheetNameByExcelFilePath
                            in sheetTask.sheetNamesByExcelFilePath.entries)
                          getAbsoluteExcelFileFromRelativePath(
                            relativeExcelFilePath: sheetNameByExcelFilePath.key,
                            configurationFilePath:
                                selectedConfigurationFile.path,
                          ): sheetNameByExcelFilePath.value,
                      };
                      sheetTaskBuilder.sheetNamesByExcelFilePath.replace(
                        newSheetNamesByExcelFilePath,
                      );
                    }),
                  )
                  ..excelFilePaths.map((excelFilePath) {
                    return getAbsoluteExcelFileFromRelativePath(
                      relativeExcelFilePath: excelFilePath,
                      configurationFilePath: selectedConfigurationFile.path,
                    );
                  }),
          ),
        );
      });

      final importExcelFilesTaskViewModels =
          await convertToImportExcelFilesTaskViewModel(
            taskList: newTaskModel,
            context: context,
            parentViewModel: InheritedTaskListViewModel.of(context),
          );

      InheritedTaskListViewModel.of(context).importExcelFilesTasks =
          importExcelFilesTaskViewModels.toList();

      InheritedTaskListViewModel.of(context).treeChanged();
    }
  } on ArgumentError {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const ConfigurationInvalidDialog(),
    );
  } on FormatException {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => const InvalidJsonDialog(),
    );
  } catch (e) {
    await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => UnexpectedErrorDialog(exception: e),
    );
  }
}

Future<void> saveConfigurationToFile(BuildContext context) async {
  final selectedConfigurationSavePath =
      await selectConfigurationSavePathWithFileDialog();

  if (selectedConfigurationSavePath != null) {
    final file = File(selectedConfigurationSavePath);

    final taskModel = InheritedTaskListViewModel.of(context).taskModel;

    getRelativeExcelFilePathFromConfigurationFile({
      required String absoluteExcelFilePath,
      required String configurationFilePath,
    }) {
      final configurationDirectoryPath = dirname(configurationFilePath);
      final relativeExcelFilePath = relative(
        absoluteExcelFilePath,
        from: configurationDirectoryPath,
      );
      return relativeExcelFilePath;
    }

    final newTaskModel = taskModel.rebuild((tm) {
      tm.childTasks.map(
        (excelFilesTask) => excelFilesTask.rebuild(
          (excelFilesTaskBuilder) =>
              excelFilesTaskBuilder
                ..childTasks.map(
                  (sheetTask) => sheetTask.rebuild((sheetTaskBuilder) {
                    final newSheetNamesByExcelFilePath = {
                      for (final sheetNameByExcelFilePath
                          in sheetTask.sheetNamesByExcelFilePath.entries)
                        getRelativeExcelFilePathFromConfigurationFile(
                          configurationFilePath: selectedConfigurationSavePath,
                          absoluteExcelFilePath: sheetNameByExcelFilePath.key,
                        ): sheetNameByExcelFilePath.value,
                    };
                    sheetTaskBuilder.sheetNamesByExcelFilePath.replace(
                      newSheetNamesByExcelFilePath,
                    );
                  }),
                )
                ..excelFilePaths.map((excelFilePath) {
                  return getRelativeExcelFilePathFromConfigurationFile(
                    configurationFilePath: selectedConfigurationSavePath,
                    absoluteExcelFilePath: excelFilePath,
                  );
                }),
        ),
      );
    });

    final serialized = serializers.serialize(newTaskModel);

    writeFileToDisc() {
      file
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(serialized));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.configSavedText)),
      );
    }

    final fileExists = file.existsSync();
    final createNewFile = !fileExists;

    if (createNewFile) {
      writeFileToDisc();
    } else if (fileExists) {
      final overwriteFile = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => const OverwriteFileDialog(),
      );

      if (overwriteFile == true) {
        writeFileToDisc();
      }
    }
  }
}

class _DemoBottomAppBar extends StatelessWidget {
  const _DemoBottomAppBar({
    this.fabLocation = FloatingActionButtonLocation.endDocked,
    this.shape = const CircularNotchedRectangle(),
  });

  final FloatingActionButtonLocation fabLocation;
  final NotchedShape? shape;

  static final List<FloatingActionButtonLocation> centerLocations =
      <FloatingActionButtonLocation>[
        FloatingActionButtonLocation.centerDocked,
        FloatingActionButtonLocation.centerFloat,
      ];

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: shape,
      color: Colors.blue,
      child: IconTheme(
        data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
        child: Row(
          children: <Widget>[
            ElevatedButton.icon(
              icon: const Icon(Icons.file_upload),
              label: const Text('Import Configuration'),
              onPressed: () => _loadConfiguration(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.file_download),
              label: const Text('Export Configuration'),
              onPressed: () => saveConfigurationToFile(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.table_view),
              label: const Text('Export CSV'),
              onPressed: () => _exportCsv(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

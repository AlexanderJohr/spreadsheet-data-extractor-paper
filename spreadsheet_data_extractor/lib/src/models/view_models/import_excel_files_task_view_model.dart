import 'package:built_collection/built_collection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/excel_file_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/worksheet.dart';
import 'package:spreadsheet_data_extractor/src/utils/lists_utils.dart';
import 'package:spreadsheet_data_extractor/src/utils/value_utils.dart';

/// View model for managing tasks related to importing Excel files.
///
/// This class provides functionality for managing tasks related to importing Excel files.
/// It allows users to add, remove, and update Excel files, as well as retrieve information
/// about the Excel files and their associated sheets. It also provides methods for creating
/// and modifying tasks associated with importing Excel sheets.
class ImportExcelFilesTaskViewModel {
  final TaskListViewModel parent;

  /// Removes the current import Excel files task from its parent task list.
  void remove() => parent.removeTask(this);

  late BehaviorSubject<BuiltMap<String, ExcelFileViewModel>>
  excelFilesByPathBehavior = BehaviorSubject.seeded(
    BuiltMap<String, ExcelFileViewModel>(),
  );

  BuiltMap<String, ExcelFileViewModel> get excelFilesByPath =>
      excelFilesByPathBehavior.value;

  set excelFilesByPath(BuiltMap<String, ExcelFileViewModel> value) {
    excelFilesByPathBehavior.value = value;
  }

  /// Retrieves the first sheet from the first Excel file.
  ///
  /// Returns: The first modifiable sheet view model.
  String? get firstSheet {
    final excelFiles = excelFilesByPath.values;
    if (excelFiles.isEmpty) {
      return null;
    }
    final sheet = excelFiles.first.excelFile.sheetNamesById[1];

    return sheet;
  }

  /// Retrieves the combined values from all child tasks.
  ///
  /// Returns: A combined column list containing the values of all child tasks.
  Table getValues() {
    final childrenValues = TasksResultList(
      importExcelSheetsTasks.isEmpty
          ? [
            Table([
              Column([
                Vector(
                  excelFilesByPath.values.map(
                    (ExcelFileViewModel excelFile) => Value(
                      excelFile.name,
                      type: ValueType.automaticallyGenerated,
                    ),
                  ),
                ),
              ]),
            ]),
          ]
          : importExcelSheetsTasks.map((task) => task.getValues()),
    );
    final columnList = childrenValues.getCombinedColumnList();
    return columnList;
  }

  final BehaviorSubject<BuiltList<ImportExcelSheetsTaskViewModel>>
  importExcelSheetsTasksBehavior = BehaviorSubject.seeded(
    BuiltList<ImportExcelSheetsTaskViewModel>(),
  );

  BuiltList<ImportExcelSheetsTaskViewModel> get importExcelSheetsTasks =>
      importExcelSheetsTasksBehavior.value;

  set importExcelSheetsTasks(BuiltList<ImportExcelSheetsTaskViewModel> value) {
    importExcelSheetsTasksBehavior.value = value;
  }

  /// Adds a new ImportExcelSheetsTaskViewModel to the list of import Excel sheets tasks.
  ///
  /// [excelFiles]: The Excel files for which to create import tasks.
  /// Returns: The created ImportExcelSheetsTaskViewModel.
  ImportExcelSheetsTaskViewModel addImportExcelSheetsTaskViewModel({
    required Iterable<ExcelFileViewModel> excelFiles,
  }) {
    final viewModel = ImportExcelSheetsTaskViewModel(
      excelFiles: excelFiles,
      parentImportExcelFilesTask: this,
    );
    importExcelSheetsTasks = importExcelSheetsTasks.rebuild(
      (b) => b.add(viewModel),
    );
    return viewModel;
  }

  /// Removes a task from the list of import Excel sheets tasks.
  ///
  /// [task]: The task to be removed.
  removeTask(ImportExcelSheetsTaskViewModel task) {
    final rebuild = importExcelSheetsTasks.rebuild((b) => b.remove(task));
    return importExcelSheetsTasks = rebuild;
  }

  /// Retrieves the number of import Excel sheets tasks.
  int get taskCount => importExcelSheetsTasks.length;

  /// Constructor for the ImportExcelFilesTaskViewModel.
  ///
  /// [files]: The list of Excel files.
  /// [parent]: The parent task list view model.
  ImportExcelFilesTaskViewModel({
    required List<ExcelFileViewModel> files,
    required this.parent,
  }) {
    updateFiles(files);
  }

  /// Updates the list of Excel files.
  ///
  /// [files]: The updated list of Excel files.
  void updateFiles(List<ExcelFileViewModel> files) {
    excelFilesByPath = excelFilesByPath.rebuild((b) {
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final path = file.path;
        b.putIfAbsent(path, () => file);
      }
    });
  }

  /// Removes an Excel file and its associated sheets from the view model.
  ///
  /// [file]: The Excel file view model to be removed.
  void removeFile(ExcelFileViewModel file) {
    excelFilesByPath = excelFilesByPath.rebuild((b) {
      b.remove(file.path);
    });
    for (final taskVm in importExcelSheetsTasks) {
      var builder = taskVm.loadedSheetsByExcelFile.value.toBuilder();
      builder.remove(file);
      taskVm.loadedSheetsByExcelFile.value = builder.build();
    }
  }

  /// Converts the current view model to its corresponding task model.
  ///
  /// Returns: The task model representation of the current view model.
  ImportExcelFilesTask get taskModel {
    return ImportExcelFilesTask(
      (b) =>
          b
            ..childTasks = ListBuilder<ImportExcelSheetsTask>(
              importExcelSheetsTasks.map((vm) => vm.taskModel),
            )
            ..excelFilePaths = SetBuilder(excelFilesByPath.keys),
    );
  }

  /// Sets the current view model based on the provided task model.
  ///
  /// [taskModel]: The task model from which to set the current view model.
  set taskModel(ImportExcelFilesTask taskModel) {
    importExcelSheetsTasks = BuiltList<ImportExcelSheetsTaskViewModel>(
      taskModel.childTasks.map(
        (taskModel) => ImportExcelSheetsTaskViewModel(
          parentImportExcelFilesTask: this,
          excelFiles: excelFilesByPath.values,
        )..taskModel = taskModel,
      ),
    );
  }
}

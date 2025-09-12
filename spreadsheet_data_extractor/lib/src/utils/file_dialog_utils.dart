import 'package:built_collection/built_collection.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/excel_file_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/import_excel_files_task_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';
import 'dart:async';

/// Asynchronously prompts the user to select a save location for a configuration file
/// using a file dialog. The selected file path is returned upon successful selection,
/// or `null` if the user cancels the operation.
///
/// The function first defines a type group for JSON files and then calls `getSaveLocation`
/// to display a file dialog for selecting the save location. If a file is selected by the user,
/// it checks whether the file has a JSON file extension. If not, it appends ".json" to the file path.
///
/// Returns:
/// - The selected file path with a ".json" extension if a file is chosen by the user.
/// - `null` if the user cancels the operation or no file is selected.
Future<String?> selectConfigurationSavePathWithFileDialog() async {
  const typeGroup = XTypeGroup(extensions: ['json']);
  final file = await getSaveLocation(acceptedTypeGroups: [typeGroup]);

  if (file == null) {
    return null;
  }

  final path = file.path;
  final hasJsonFileExtension = path.toLowerCase().endsWith(".json");

  if (hasJsonFileExtension) {
    return path; // Return the path as is if it already ends with .json
  }

  return "$path.json";
}

/// Asynchronously prompts the user to select a configuration file for opening
/// using a file dialog.
///
/// This function initiates a file dialog to allow the user to select a file
/// with a JSON extension. The selected file is returned upon successful selection,
/// or `null` if the user cancels the operation.
///
/// Returns:
/// - The selected configuration file, wrapped in an [XFile] object, if chosen by the user.
/// - `null` if the user cancels the operation or no file is selected.
Future<XFile?> selectConfigurationOpenPathWithFileDialog() async {
  const typeGroup = XTypeGroup(extensions: ['json']);
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  return file;
}

/// Asynchronously converts a list of tasks from a task list into a list of view models
/// for importing Excel files.
///
/// This function takes a [taskList], a [BuildContext], and a [parentViewModel] as parameters.
/// It iterates through the child tasks of the provided task list, creating an
/// [ImportExcelFilesTaskViewModel] for each task model. For each task model, it extracts
/// the file paths from the task model and converts them into [XFile] objects. It then
/// asynchronously imports the selected files using the [importSelectedFiles] function
/// and creates [ExcelFileViewModel] objects for each imported file. These view models
/// are then added to the [ImportExcelFilesTaskViewModel] along with the corresponding task
/// model. Finally, the function returns a [BuiltList] containing all the created
/// [ImportExcelFilesTaskViewModel] instances.
///
/// Parameters:
/// - `taskList`: The task list containing the tasks to be converted.
/// - `context`: The build context to use for importing files.
/// - `parentViewModel`: The parent view model associated with the tasks.
///
/// Returns:
/// - A [BuiltList] of [ImportExcelFilesTaskViewModel] instances representing the converted tasks.
Future<BuiltList<ImportExcelFilesTaskViewModel>>
convertToImportExcelFilesTaskViewModel({
  required TaskList taskList,
  required BuildContext context,
  required TaskListViewModel parentViewModel,
}) async {
  final importExcelFilesTaskViewModels = <ImportExcelFilesTaskViewModel>[];
  for (var taskModel in taskList.childTasks) {
    final importExcelFilesTaskViewModel = ImportExcelFilesTaskViewModel(
      files: [],
      parent: parentViewModel,
    );

    final files = taskModel.excelFilePaths.map((path) => XFile(path)).toList();

    if (files.isNotEmpty) {
      final decodedFiles = importSelectedFiles(files, context);
      importExcelFilesTaskViewModel.updateFiles(
        decodedFiles
            .map((excelFile) => ExcelFileViewModel(excelFile: excelFile))
            .toList(),
      );

      importExcelFilesTaskViewModel.taskModel = taskModel;
    }

    importExcelFilesTaskViewModels.add(importExcelFilesTaskViewModel);
  }

  return BuiltList(importExcelFilesTaskViewModels);
}

/// Opens a file dialog to allow the user to select Excel files with the '.xlsx' extension.
///
/// This function returns a Future that resolves to a List of [XFile] objects representing
/// the selected Excel files. It utilizes the `openFiles` function from the file_picker package,
/// and restricts the file selection to files with the specified '.xlsx' extension.
///
/// Example:
/// ```dart
/// Future<void> exampleUsage() async {
///   List<XFile> selectedFiles = await selectExcelFilesWithFileDialog();
///   // Process the selected Excel files as needed.
/// }
/// ```
///
/// Returns a Future<List<XFile>> representing the selected Excel files.
Future<List<XFile>> selectExcelFilesWithFileDialog() async {
  const typeGroup = XTypeGroup(extensions: ['xlsx']);
  final files = await openFiles(acceptedTypeGroups: [typeGroup]);
  return files;
}

List<Workbook> importSelectedFiles(List<XFile> files, BuildContext context) {
  return files.map((file) => decodeExcelFile(file)).toList();
}

/// Decodes an Excel file represented by an [XFile] into an [ExcelFileModel].
///
/// This function reads the content of the Excel file, extracts sheet information,
/// including cell values and spans, and constructs an [ExcelFileModel] containing
/// the decoded data.
Workbook decodeExcelFile(XFile file) {
  final workbook = Workbook.fromFilePath(file.path);
  return workbook;
}

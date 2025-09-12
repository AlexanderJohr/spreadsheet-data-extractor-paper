import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/excel_file_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/import_excel_files_task_view_model.dart';
import 'package:spreadsheet_data_extractor/src/utils/lists_utils.dart';
import 'package:spreadsheet_data_extractor/src/utils/value_utils.dart';

/// Represents the view model for managing tasks in the application.
class TaskListViewModel extends ChangeNotifier {
  void treeChanged() {
    notifyListeners();
  }

  List<ImportExcelFilesTaskViewModel> _importExcelFilesTasks =
      <ImportExcelFilesTaskViewModel>[];

  List<ImportExcelFilesTaskViewModel> get importExcelFilesTasks =>
      _importExcelFilesTasks;

  set importExcelFilesTasks(List<ImportExcelFilesTaskViewModel> value) {
    _importExcelFilesTasks = value;
  }

  /// Retrieves the number of tasks in the task list.
  int get taskCount => importExcelFilesTasks.length;

  final BehaviorSubject<bool> joinTimestampBehavior = BehaviorSubject.seeded(
    true,
  );

  /// Retrieves the current value of whether to join timestamps with values.
  bool get joinTimestamp => joinTimestampBehavior.value;
  set joinTimestamp(bool newValue) {
    joinTimestampBehavior.value = newValue;
  }

  Iterable<String> getValuesInOffsetGenerator(
    double startOffset,
    double endOffset,
  ) sync* {
    //   final childTaskTables = importExcelFilesTasks.value.map(
    //     (task) => task.importExcelSheetsTasks,
    //   );
    //   final childrenValues = TasksResultList(childTaskTables);
    //   yield childrenValues.getCombinedColumnList();
  }

  /// Gets the tables of all the children tasks
  /// and joins them together into one combined table,
  /// then adds the column of values of this task (the optional timestamp) on top
  /// and duplicates the column
  /// to fit the column count of the underlying combined table
  ///
  Table getValues() {
    final childTaskTables = importExcelFilesTasks.map(
      (task) => task.getValues(),
    );
    final childrenValues = TasksResultList(childTaskTables);
    final columnList = childrenValues.getCombinedColumnList();

    if (joinTimestamp) {
      final DateTime now = DateTime.now();
      final DateFormat formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
      final String formattedTimeStamp = formatter.format(now);

      final timeStampValueList = Vector([
        Value(formattedTimeStamp, type: ValueType.automaticallyGenerated),
      ]);

      final joinedWithTimeStamp = timeStampValueList.joinWithColumnList(
        columnList,
      );
      return joinedWithTimeStamp;
    }

    return columnList;
  }

  /// Adds a new import Excel files task.
  ///
  /// [files]: The list of Excel files associated with the task.
  void addImportExcelFilesTask({required List<ExcelFileViewModel> files}) =>
      importExcelFilesTasks.add(
        ImportExcelFilesTaskViewModel(files: files, parent: this),
      );

  /// Removes the specified task from the task list.
  ///
  /// [task]: The task to be removed.
  removeTask(ImportExcelFilesTaskViewModel task) {
    importExcelFilesTasks.remove(task);
  }

  /// Replaces an old task with a new task in the task list.
  ///
  /// [oldTask]: The old task to be replaced.
  /// [newTask]: The new task to replace the old task.
  replaceTask({
    required ImportExcelFilesTaskViewModel oldTask,
    required ImportExcelFilesTaskViewModel newTask,
  }) {
    final index = importExcelFilesTasks.indexOf(oldTask);
    importExcelFilesTasks[index] = newTask;
  }

  /// Converts the task list view model to its corresponding model.
  ///
  /// Returns: The model representation of the task list view model.
  TaskList get taskModel {
    return TaskList(
      (b) =>
          b
            ..childTasks = ListBuilder<ImportExcelFilesTask>(
              importExcelFilesTasks.map((vm) => vm.taskModel),
            ),
    );
  }

  /// Sets the task list view model based on the provided model.
  ///
  /// [taskModel]: The model from which to set the task list view model.
  set taskModel(TaskList taskModel) {
    importExcelFilesTasks =
        taskModel.childTasks
            .map(
              (taskModel) =>
                  ImportExcelFilesTaskViewModel(files: [], parent: this)
                    ..taskModel = taskModel,
            )
            .toList();
  }
}

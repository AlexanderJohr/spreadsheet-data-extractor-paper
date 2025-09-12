import 'package:flutter/material.dart';
import 'package:rxdart/subjects.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/pages/cell_selection_page.dart';

import 'src/app.dart';
import 'src/app_state.dart';
import 'src/pages/task_overview_page.dart';
import 'src/settings/settings_controller.dart';
import 'src/settings/settings_service.dart';

void main() async {
  final app = MyApp();

  final selectedSheetService = SelectedSheetService(child: app);

  final selectedTaskService = SelectedTaskService(child: selectedSheetService);

  final appState = AppState(child: selectedTaskService);

  final settingsController = ThemeToggle(
    settingsService: SettingsService(),
    child: appState,
  );
  await settingsController.loadSettings();

  final TaskListViewModel taskListViewModel = TaskListViewModel();

  final inheritedTaskListViewModel = InheritedTaskListViewModel(
    viewModel: taskListViewModel,
    child: settingsController,
  );

  runApp(inheritedTaskListViewModel);
}

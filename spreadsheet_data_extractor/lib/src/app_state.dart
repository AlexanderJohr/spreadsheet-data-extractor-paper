import 'package:flutter/widgets.dart';
import 'package:spreadsheet_data_extractor/l10n/app_localizations.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';

class SelectedSheetService extends InheritedWidget with ChangeNotifier {
  ImportExcelSheetsTaskViewModel? _activeSheetTask;

  ImportExcelSheetsTaskViewModel? get activeSheetTask => _activeSheetTask;

  set activeSheetTask(ImportExcelSheetsTaskViewModel? value) {
    if (value == _activeSheetTask) return;
    _activeSheetTask = value;

    notifyListeners();
  }

  SelectedSheetService({Key? super.key, required super.child});

  static SelectedSheetService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectedSheetService>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class AppState extends InheritedWidget {
  AppState({Key? key, required Widget child}) : super(key: key, child: child);

  final BehaviorSubject<Locale> localeSubject = BehaviorSubject.seeded(
    const Locale('en', ''),
  );

  Locale get locale => localeSubject.value;

  set locale(Locale value) {
    localeSubject.value = value;
    AppLocalizations.delegate.load(locale);
  }

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppState>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

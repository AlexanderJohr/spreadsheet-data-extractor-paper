// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Spreadsheet Describer and Data Extractor';

  @override
  String get taskPageTitle => 'Import Excel Files';

  @override
  String get firstAppCallIntroTitle =>
      'Spreadsheet Metadata Hierarchy Describer and Data Extractor 0.12.0 - For internal use only';

  @override
  String get acceptButtonText => 'accept';

  @override
  String get selectedDataIsNotExcelErrorText =>
      'Error: The selected file to attach the data is not an Excel file';

  @override
  String fileExistsText(int linesAppended, String filePath) {
    return 'Successfully appended $linesAppended line(s) to the existing lines in $filePath';
  }

  @override
  String fileDoesNotExistsText(int linesAppended, String filePath) {
    return 'Successfully saved $linesAppended lines to new $filePath file.';
  }

  @override
  String get taskParentHeaderTitle => 'tasks';

  @override
  String get importExcelFilesButtonText => 'import Excel files';

  @override
  String get copyConfigButtonText => 'copy configuration';

  @override
  String get insertConfigButtonText => 'insert configuration';

  @override
  String get configSavedText => 'Configuration saved successfully.';

  @override
  String get saveConfigButtonText => 'save configuration';

  @override
  String get loadConfigButtonText => 'load configuration';

  @override
  String get importSheetsButtonText => 'import Excel sheets';

  @override
  String get importAdditionalFilesButtonText => 'import additional files';

  @override
  String get copyExcelFileImportTaskButtonText => 'copy Excel file import task';

  @override
  String get insertExcelFileImportTaskButtonText =>
      'insert Excel file import task';

  @override
  String get noSheetSelectedText => 'click to select Excel sheet';

  @override
  String get importCellsButtonText => 'import cells';

  @override
  String get copyWorksheetImportTaskButtonText => 'copy worksheet import task';

  @override
  String get insertWorksheetImportTaskButtonText =>
      'insert worksheet import task';

  @override
  String get noCellsSelectedText => 'click to select cells';

  @override
  String get linkCellIndexBoxText => 'link cell index';

  @override
  String get useDefaultValueBoxText => 'use default value';

  @override
  String get copyCellSelectionButtonText => 'copy cell selection';

  @override
  String get copyTaskButtonText => 'copy task';

  @override
  String get duplicateTaskButtonText => 'duplicate task';

  @override
  String get insertCellSelectionButtonText => 'insert cell selection';

  @override
  String get insertTaskButtonText => 'insert task';

  @override
  String get alignCellSelectionButtonText => 'align cell selection';

  @override
  String get moveAllSelectionsButtonText => 'move all selections';

  @override
  String get linkWithCellsButtonText => 'link with cells';

  @override
  String get errNonValidConfigTitle => 'non valid configuration';

  @override
  String get errNonValidConfigText =>
      'The selected file does not contain a valid configuration.';

  @override
  String get errNonValidJSONTitle => 'non valid json';

  @override
  String get errNonValidJSONText =>
      'The selected file does not contain a valid json.';

  @override
  String get errUnexpectedErrorTitle => 'unexpected error';

  @override
  String errUnexpectedErrorText(Object exception) {
    return 'An unexpected error occurred : $exception';
  }

  @override
  String get fileAlreadyExistsTitle => 'file already exists - overwrite it?';

  @override
  String get fileAlreadyExistsText =>
      'The file already exists, should it be overwritten?';

  @override
  String get yesButtonText => 'yes';

  @override
  String get noButtonText => 'no';

  @override
  String get discardChangesTitle => 'discard changes?';

  @override
  String get discardChangesText =>
      'Changes have been made in this view. Discard them?';

  @override
  String get duplicateAndMoveCheckboxText => 'move and duplicate';

  @override
  String get embedLabelText => 'encapsulate';

  @override
  String get useCellSelectionLabelText => 'use cell selection';

  @override
  String get enterValueManuallyLabelText => 'enter value manually';

  @override
  String get repeatLabelText => 'repeat';

  @override
  String get manualValueLabelText => 'manual value';
}

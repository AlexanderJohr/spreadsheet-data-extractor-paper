// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Smedahidesdex';

  @override
  String get taskPageTitle => 'Importiere Excel Dateien';

  @override
  String get firstAppCallIntroTitle =>
      'Spreadsheet Metadata Hierarchy Describer and Data Extractor 0.12.0 - Nur zur internen Verwendung';

  @override
  String get acceptButtonText => 'akzeptieren';

  @override
  String get selectedDataIsNotExcelErrorText =>
      'Fehler: Ausgewählte Datei zum Anhängen der Daten ist keine Excel Datei';

  @override
  String fileExistsText(int linesAppended, String filePath) {
    return 'Erfolgreich $linesAppended Zeilen an die bestehenden Zeilen in $filePath angehängt';
  }

  @override
  String fileDoesNotExistsText(int linesAppended, String filePath) {
    return 'Erfolgreich $linesAppended Zeile(n) in die neue Datei $filePath gespeichert.';
  }

  @override
  String get taskParentHeaderTitle => 'Aufgaben';

  @override
  String get importExcelFilesButtonText => 'Importiere Excel Dateien';

  @override
  String get copyConfigButtonText => 'Kopiere Konfiguration';

  @override
  String get insertConfigButtonText => 'Füge Konfiguration ein';

  @override
  String get configSavedText => 'Konfiguration erfolgreich gespeichert.';

  @override
  String get saveConfigButtonText => 'Speichere Konfiguration';

  @override
  String get loadConfigButtonText => 'Lade Konfiguration';

  @override
  String get importSheetsButtonText => 'Importiere Excel Sheets';

  @override
  String get importAdditionalFilesButtonText =>
      'Importiere zusätzliche Dateien';

  @override
  String get copyExcelFileImportTaskButtonText =>
      'Kopiere Exceldatei-Import Aufgabe';

  @override
  String get insertExcelFileImportTaskButtonText =>
      'Füge Exceldatei-Import Aufgabe ein';

  @override
  String get noSheetSelectedText => 'Klicken um Excel Sheets zu Selektieren';

  @override
  String get importCellsButtonText => 'Importiere Zellen';

  @override
  String get copyWorksheetImportTaskButtonText =>
      'Kopiere Arbeitsblatt-Import Aufgabe';

  @override
  String get insertWorksheetImportTaskButtonText =>
      'Füge Arbeitsbeinlatt-Import Aufgabe ein';

  @override
  String get noCellsSelectedText => 'Klicken um Excel Zellen zu Selektieren';

  @override
  String get linkCellIndexBoxText => 'Verknüpfe Zellenindex';

  @override
  String get useDefaultValueBoxText => 'Verwende vorgegebenen Wert';

  @override
  String get copyCellSelectionButtonText => 'Kopiere Zellen-Selektion';

  @override
  String get copyTaskButtonText => 'Kopiere Aufgabe';

  @override
  String get duplicateTaskButtonText => 'Dupliziere Aufgabe';

  @override
  String get insertCellSelectionButtonText => 'Füge Zellen-Selektion ein';

  @override
  String get insertTaskButtonText => 'Füge Aufgabe ein';

  @override
  String get alignCellSelectionButtonText => 'Zell-Selektion ausrichten';

  @override
  String get moveAllSelectionsButtonText => 'Verschiebe alle Selektionen';

  @override
  String get linkWithCellsButtonText => 'Verknüpfe mit Zellen';

  @override
  String get errNonValidConfigTitle => 'Konfiguration nicht valide';

  @override
  String get errNonValidConfigText =>
      'Die selektierte Datei enthält keine valide Konfiguration.';

  @override
  String get errNonValidJSONTitle => 'Json nicht valide';

  @override
  String get errNonValidJSONText =>
      'Die selektierte Datei enthält kein valides Json.';

  @override
  String get errUnexpectedErrorTitle => 'Unerwarteter Fehler';

  @override
  String errUnexpectedErrorText(Object exception) {
    return 'Ein unerwarteter Fehler ist aufgetreten : $exception';
  }

  @override
  String get fileAlreadyExistsTitle =>
      'Datei existiert bereits - überschreiben?';

  @override
  String get fileAlreadyExistsText =>
      'Die Datei existiert bereits, soll sie überschrieben werden?';

  @override
  String get yesButtonText => 'ja';

  @override
  String get noButtonText => 'nein';

  @override
  String get discardChangesTitle => 'Änderungen verwerfen?';

  @override
  String get discardChangesText =>
      'Es wurden Änderungen in dieser Ansicht vorgenommen. Sollen diese verworfen werden?';

  @override
  String get duplicateAndMoveCheckboxText => 'verschieben und duplizieren';

  @override
  String get embedLabelText => 'verschachteln';

  @override
  String get useCellSelectionLabelText => 'verwende Zellen-Selektion';

  @override
  String get enterValueManuallyLabelText => 'Wert manuell eingeben';

  @override
  String get repeatLabelText => 'wiederhole';

  @override
  String get manualValueLabelText => 'manueller Wert';
}

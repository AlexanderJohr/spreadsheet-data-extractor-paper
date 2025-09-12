// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Descriptor de hoja de cálculo y extractor de datos';

  @override
  String get taskPageTitle => 'Importar archivos de Excel';

  @override
  String get firstAppCallIntroTitle =>
      'Spreadsheet Metadata Hierarchy Describer and Data Extractor 0.12.0 - Sólo para uso interno';

  @override
  String get acceptButtonText => 'aceptar';

  @override
  String get selectedDataIsNotExcelErrorText =>
      'Error: El archivo seleccionado para adjuntar datos no es un archivo de Excel';

  @override
  String fileExistsText(int linesAppended, String filePath) {
    return 'Se han añadido con éxito líneas $linesAppended a las líneas existentes en $filePath.';
  }

  @override
  String fileDoesNotExistsText(int linesAppended, String filePath) {
    return 'Guardadas con éxito las línea(s) $linesAppended en el nuevo archivo $filePath.';
  }

  @override
  String get taskParentHeaderTitle => 'tareas';

  @override
  String get importExcelFilesButtonText => 'importar archivos de Excel';

  @override
  String get copyConfigButtonText => 'copiar configuración';

  @override
  String get insertConfigButtonText => 'insertar configuración';

  @override
  String get configSavedText => 'Configuración guardada correctamente.';

  @override
  String get saveConfigButtonText => 'guardar configuración';

  @override
  String get loadConfigButtonText => 'configuración de carga';

  @override
  String get importSheetsButtonText => 'importar hojas de Excel';

  @override
  String get importAdditionalFilesButtonText => 'importar archivos adicionales';

  @override
  String get copyExcelFileImportTaskButtonText =>
      'copiar tarea de importación de archivos Excel';

  @override
  String get insertExcelFileImportTaskButtonText =>
      'insertar tarea de importación de archivos Excel';

  @override
  String get noSheetSelectedText => 'haga clic para seleccionar hojas de Excel';

  @override
  String get importCellsButtonText => 'importar celdas de tabla';

  @override
  String get copyWorksheetImportTaskButtonText =>
      'copiar tarea de importación de hojas de cálculo';

  @override
  String get insertWorksheetImportTaskButtonText =>
      'insertar tarea de importación de la hoja del tramo de trabajo';

  @override
  String get noCellsSelectedText =>
      'haga clic para seleccionar celdas de Excel';

  @override
  String get linkCellIndexBoxText => 'índice de células de enlace';

  @override
  String get useDefaultValueBoxText => 'utilizar el valor por defecto';

  @override
  String get copyCellSelectionButtonText => 'copiar selección de celdas';

  @override
  String get copyTaskButtonText => 'copiar tarea';

  @override
  String get duplicateTaskButtonText => 'duplicar tarea';

  @override
  String get insertCellSelectionButtonText => 'insertar selección de celdas';

  @override
  String get insertTaskButtonText => 'insertar tarea';

  @override
  String get alignCellSelectionButtonText => 'alinear la selección de celdas';

  @override
  String get moveAllSelectionsButtonText => 'mover todas las selecciones';

  @override
  String get linkWithCellsButtonText => 'vínculo con las células';

  @override
  String get errNonValidConfigTitle => 'configuración no válida';

  @override
  String get errNonValidConfigText =>
      'El fichero seleccionado no contiene una configuración válida.';

  @override
  String get errNonValidJSONTitle => 'json no válido';

  @override
  String get errNonValidJSONText =>
      'El archivo seleccionado no contiene un json válido.';

  @override
  String get errUnexpectedErrorTitle => 'error inesperado';

  @override
  String errUnexpectedErrorText(Object exception) {
    return 'Se ha producido un error inesperado : $exception';
  }

  @override
  String get fileAlreadyExistsTitle =>
      'El archivo ya existe - ¿lo sobrescribo?';

  @override
  String get fileAlreadyExistsText =>
      'El archivo ya existe, ¿hay que sobrescribirlo?';

  @override
  String get yesButtonText => 'sì';

  @override
  String get noButtonText => 'no';

  @override
  String get discardChangesTitle => '¿Descartar cambios?';

  @override
  String get discardChangesText =>
      'Se han realizado cambios en esta vista. ¿Descartarlos?';

  @override
  String get duplicateAndMoveCheckboxText => 'duplicar y mover';

  @override
  String get embedLabelText => 'encapsular';

  @override
  String get useCellSelectionLabelText => 'usar selección de celdas';

  @override
  String get enterValueManuallyLabelText => 'ingresar valor manualmente';

  @override
  String get repeatLabelText => 'repetir';

  @override
  String get manualValueLabelText => 'valor manual';
}

import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';

/// Represents the view model for an Excel file, containing information about the file itself
/// and its sheets.
class ExcelFileViewModel {
  Workbook excelFile;

  String get name => excelFile.name;
  String get path => excelFile.path;

  ExcelFileViewModel({required this.excelFile});
}

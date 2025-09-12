import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';

/// Asynchronously retrieves a CellSelection from the clipboard, or returns `null` if unavailable or invalid.
///
/// This function attempts to retrieve data from the clipboard in plain text format. If successful, it then attempts
/// to deserialize the retrieved text using the `serializers` provided. If the deserialized object is of type `CellSelection`,
/// it is returned. If the clipboard data is unavailable or cannot be deserialized, or if the deserialized object is not
/// a `CellSelection`, `null` is returned.
///
/// Returns:
/// - A [CellSelection] object representing the retrieved CellSelection, if available and valid.
/// - `null` if the clipboard data is unavailable, invalid, or not a CellSelection.
Future<CellSelection?>? getCellSelectionFromClipboardOrNull() async {
  final json = await Clipboard.getData("text/plain");
  if (json == null) {
    return null;
  }

  final jsonString = json.text;
  if (jsonString == null) {
    return null;
  }

  try {
    final deserialized = serializers.deserialize(jsonDecode(jsonString));

    if (deserialized is CellSelection) {
      return deserialized;
    }
  } on FormatException {
    return null;
  }

  return null;
}

/// Asynchronously retrieves an ImportCellsTask from the clipboard, or returns `null` if unavailable or invalid.
///
/// This function attempts to retrieve data from the clipboard in plain text format. If successful, it then attempts
/// to deserialize the retrieved text using the `serializers` provided. If the deserialized object is of type `ImportCellsTask`,
/// it is returned. If the clipboard data is unavailable or cannot be deserialized, or if the deserialized object is not
/// an `ImportCellsTask`, `null` is returned.
///
/// Returns:
/// - An [ImportCellsTask] object representing the retrieved ImportCellsTask, if available and valid.
/// - `null` if the clipboard data is unavailable, invalid, or not an ImportCellsTask.
Future<ImportCellsTask?>? getImportCellTaskFromClipboardOrNull() async {
  final json = await Clipboard.getData("text/plain");
  if (json == null) {
    return null;
  }

  final jsonString = json.text;
  if (jsonString == null) {
    return null;
  }

  try {
    final deserialized = serializers.deserialize(jsonDecode(jsonString));

    if (deserialized is ImportCellsTask) {
      return deserialized;
    }
  } on FormatException {
    return null;
  }

  return null;
}

/// Asynchronously retrieves an ImportExcelSheetsTask from the clipboard, or returns `null` if unavailable or invalid.
///
/// This function attempts to retrieve data from the clipboard in plain text format. If successful, it then attempts
/// to deserialize the retrieved text using the `serializers` provided. If the deserialized object is of type `ImportExcelSheetsTask`,
/// it is returned. If the clipboard data is unavailable or cannot be deserialized, or if the deserialized object is not
/// an `ImportExcelSheetsTask`, `null` is returned.
///
/// Returns:
/// - An [ImportExcelSheetsTask] object representing the retrieved ImportExcelSheetsTask, if available and valid.
/// - `null` if the clipboard data is unavailable, invalid, or not an ImportExcelSheetsTask.
Future<ImportExcelSheetsTask?>? getImportSheetTaskFromClipboardOrNull() async {
  final json = await Clipboard.getData("text/plain");
  if (json == null) {
    return null;
  }

  final jsonString = json.text;
  if (jsonString == null) {
    return null;
  }

  try {
    final deserialized = serializers.deserialize(jsonDecode(jsonString));

    if (deserialized is ImportExcelSheetsTask) {
      return deserialized;
    }
  } on FormatException {
    return null;
  }

  return null;
}

/// Asynchronously retrieves an ImportExcelFilesTask from the clipboard, or returns `null` if unavailable or invalid.
///
/// This function attempts to retrieve data from the clipboard in plain text format. If successful, it then attempts
/// to deserialize the retrieved text using the `serializers` provided. If the deserialized object is of type `ImportExcelFilesTask`,
/// it is returned. If the clipboard data is unavailable or cannot be deserialized, or if the deserialized object is not
/// an `ImportExcelFilesTask`, `null` is returned.
///
/// Returns:
/// - An [ImportExcelFilesTask] object representing the retrieved ImportExcelFilesTask, if available and valid.
/// - `null` if the clipboard data is unavailable, invalid, or not an ImportExcelFilesTask.
Future<ImportExcelFilesTask?>?
getImportExcelFileTaskFromClipboardOrNull() async {
  final json = await Clipboard.getData("text/plain");
  if (json == null) {
    return null;
  }

  final jsonString = json.text;
  if (jsonString == null) {
    return null;
  }

  try {
    final deserialized = serializers.deserialize(jsonDecode(jsonString));

    if (deserialized is ImportExcelFilesTask) {
      return deserialized;
    }
  } on FormatException {
    return null;
  }

  return null;
}

/// Asynchronously retrieves a TaskList configuration from the clipboard, or returns `null` if unavailable or invalid.
///
/// This function attempts to retrieve data from the clipboard in plain text format. If successful, it then attempts
/// to deserialize the retrieved text using the `serializers` provided. If the deserialized object is of type `TaskList`,
/// it is returned. If the clipboard data is unavailable or cannot be deserialized, or if the deserialized object is not
/// a `TaskList`, `null` is returned.
///
/// Returns:
/// - A [TaskList] object representing the retrieved TaskList configuration, if available and valid.
/// - `null` if the clipboard data is unavailable, invalid, or not a TaskList.
Future<TaskList?>? getConfigurationFromClipboardOrNull() async {
  final json = await Clipboard.getData("text/plain");
  if (json == null) {
    return null;
  }

  final jsonString = json.text;
  if (jsonString == null) {
    return null;
  }

  try {
    final deserialized = serializers.deserialize(jsonDecode(jsonString));

    if (deserialized is TaskList) {
      return deserialized;
    }
  } on FormatException {
    return null;
  }

  return null;
}

import 'dart:collection';

import 'package:built_collection/built_collection.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/src/app_state.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/types/cell_coordinate.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:spreadsheet_data_extractor/src/utils/grid_related_utils.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/excel_file_view_model.dart';
import 'package:spreadsheet_data_extractor/src/pages/cell_selection_page.dart';
import 'package:spreadsheet_data_extractor/src/utils/lists_utils.dart'
    as lists_utils;
import 'package:spreadsheet_data_extractor/src/utils/value_utils.dart';

import '../../utils/excel_decoder/worksheet.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/import_excel_files_task_view_model.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';
import 'package:collection/collection.dart';

/// Abstract class representing a list of tasks for importing Excel cells.
///
/// This abstract class provides common functionality for managing tasks related to importing Excel cells.
/// It includes methods for moving, aligning, and adding tasks, as well as retrieving information about the task list.
abstract class ImportExcelCellsTaskList {
  SelectedCellGrids? _selectedCellGridsCache;

  SelectedCellGrids get selectedCellGrids {
    return _selectedCellGridsCache ??= SelectedCellGrids([
      ...importExcelCellsTasks.expand((task) => task.selectedCellGrids),
    ]);
  }

  void invalidateSelectedCellGridsCache() {
    _selectedCellGridsCache = null;
    parentTask?.invalidateSelectedCellGridsCache();
  }

  /// Moves the cells of the child tasks by the specified amount.
  ///
  /// The [deltaX] and [deltaY] parameters specify the amount of movement in the x and y directions, respectively.
  void moveChildrenCells({int deltaX = 0, int deltaY = 0}) {
    final children = importExcelCellsTasks;
    for (var i = 0; i < children.length; i++) {
      final child = children[i];
      child.moveCells(
        deltaX: deltaX,
        deltaY: deltaY,
        includingChildrenTasks: true,
      );
    }
  }

  /// Gets the depth of the task list.
  ///
  /// The depth represents the number of levels of nesting within the task list.
  int get depth {
    int depth = 0;
    var current = this;
    while (current.runtimeType != ImportExcelSheetsTaskViewModel) {
      current = current.parentTask!;
      depth++;
    }

    return depth;
  }

  /// Determines whether the specified task is a parent of the current task list.
  bool isChildOf({required ImportExcelCellsTaskList potentialParent}) {
    ImportExcelCellsTaskList? current = this;
    while (current != null) {
      if (potentialParent == current) {
        return true;
      }

      current = current.parentTask;
    }
    return false;
  }

  bool isNotChildOf({required ImportExcelCellsTaskList potentialParent}) =>
      !isChildOf(potentialParent: potentialParent);

  /// The parent task list of the current task list.
  final ImportExcelCellsTaskList? parentTask;

  /// Gets the top-level view model associated with the task list.
  TaskListViewModel get topViewModel =>
      importSheetTask.parentImportExcelFilesTask.parent;

  /// Gets the import sheet task associated with the task list.
  ImportExcelSheetsTaskViewModel get importSheetTask {
    var current = this;
    while (current.runtimeType != ImportExcelSheetsTaskViewModel) {
      current = current.parentTask!;
    }
    return current as ImportExcelSheetsTaskViewModel;
  }

  /// Gets the root task list associated with the task list.
  TaskListViewModel get rootTaskList =>
      importSheetTask.parentImportExcelFilesTask.parent;

  /// The subject containing the list of import Excel cells tasks.
  List<ImportExcelCellsTaskViewModel> _importExcelCellsTasks = [];

  List<ImportExcelCellsTaskViewModel> get importExcelCellsTasks =>
      _importExcelCellsTasks;

  set importExcelCellsTasks(List<ImportExcelCellsTaskViewModel> value) {
    _importExcelCellsTasks = value;
    _selectedCellGridsCache = null;
  }

  /// Gets the number of tasks in the task list.
  int get taskCount => importExcelCellsTasks.length;

  /// Constructs an [ImportExcelCellsTaskList] with the specified [parentTask].
  ImportExcelCellsTaskList({required this.parentTask});

  /// Gets the number of import Excel cells tasks in the task list.
  int get importExcelCellsTasksCount => importExcelCellsTasks.length;

  /// Adds a new import Excel cells task view model to the task list.
  ///
  /// Returns the created [ImportExcelCellsTaskViewModel].
  ImportExcelCellsTaskViewModel addImportExcelCellsTaskViewModel() {
    final viewModel = ImportExcelCellsTaskViewModel(parent: this);

    importExcelCellsTasks.add(viewModel);

    //rootTaskList.allImportExcelCellsTasks.value = rootTaskList.allImportExcelCellsTasks.value.rebuild((b) => b.add(viewModel));

    return viewModel;
  }

  /// Replaces an existing import Excel cells task view model with a list of new view models.
  ///
  /// The [oldViewModel] parameter specifies the view model to replace,
  /// and the [newViewModels] parameter contains the list of new view models to insert.
  replaceImportExcelCellsTaskViewModel({
    required ImportExcelCellsTaskViewModel oldViewModel,
    required List<ImportExcelCellsTaskViewModel> newViewModels,
  }) {
    final indexOfOld = importExcelCellsTasks.indexOf(oldViewModel);

    importExcelCellsTasks
      ..remove(oldViewModel)
      ..insertAll(indexOfOld, newViewModels);
    invalidateSelectedCellGridsCache();
    //rootTaskList.allImportExcelCellsTasks.value = rootTaskList.allImportExcelCellsTasks.value.rebuild((b) => b.add(viewModel));
  }

  /// Removes the specified task from the task list.
  ///
  /// The [task] parameter specifies the task to remove.
  removeTask(ImportExcelCellsTaskViewModel task) {
    importExcelCellsTasks.remove(task);
    invalidateSelectedCellGridsCache();
    //rootTaskList.allImportExcelCellsTasks.value = rootTaskList.allImportExcelCellsTasks.value.rebuild((b) => b.remove(task));

    return importExcelCellsTasks;
  }

  /// Duplicates the specified task in the task list.
  ///
  /// The [oldSibling] parameter specifies the task to duplicate.
  duplicate(ImportExcelCellsTaskViewModel oldSibling) {
    final newSibling = ImportExcelCellsTaskViewModel(parent: this);
    final indexOfOld = importExcelCellsTasks.indexOf(oldSibling);
    newSibling.taskModel = oldSibling.taskModel;

    importExcelCellsTasks.insert(indexOfOld, newSibling);
  }

  /// Moves the specified task upward in the task list.
  ///
  /// The [importExcelCellsTask] parameter specifies the task to move upward.
  void moveUpward(ImportExcelCellsTaskViewModel importExcelCellsTask) {
    final oldIndex = importExcelCellsTasks.indexOf(importExcelCellsTask);
    final newIndex = oldIndex - 1;
    if (newIndex >= 0) {
      importExcelCellsTasks
        ..removeAt(oldIndex)
        ..insert(newIndex, importExcelCellsTask);
    }
  }

  /// Moves the specified task downward in the task list.
  ///
  /// The [importExcelCellsTask] parameter specifies the task to move downward.
  void moveDownward(ImportExcelCellsTaskViewModel importExcelCellsTask) {
    final oldIndex = importExcelCellsTasks.indexOf(importExcelCellsTask);
    final newIndex = oldIndex + 1;
    if (newIndex < importExcelCellsTasks.length) {
      importExcelCellsTasks
        ..removeAt(oldIndex)
        ..insert(newIndex, importExcelCellsTask);
    }
  }

  /// Returns **all** ImportExcelCellsTaskViewModels in this subtree whose
  /// SelectedCellGrid contains the cell at [x],[y].
  ///
  /// The returned list is empty if no task matches.
  List<ImportExcelCellsTaskViewModel> findAllTasksByCell(int x, int y) {
    final matches = <ImportExcelCellsTaskViewModel>[];

    for (final child in importExcelCellsTasks) {
      // 1️⃣  Does the child itself contain the cell?
      if (child.cellIsSelected(x, y)) {
        matches.add(child);
      }

      // 2️⃣  Look inside the child's descendants as well.
      matches.addAll(child.findAllTasksByCell(x, y));
    }

    return matches;
  }

  /// Returns every task that contains at least one of [coords].
  List<ImportExcelCellsTaskViewModel> findAllTasksByCells(
    Iterable<CellCoordinate> coords,
  ) {
    if (coords.isEmpty) return const [];

    final found = <ImportExcelCellsTaskViewModel>{};

    for (final child in importExcelCellsTasks) {
      final ownsOne = coords.any((c) => child.cellIsSelected(c.x, c.y));
      if (ownsOne) found.add(child);

      found.addAll(child.findAllTasksByCells(coords));
    }

    return found.toList();
  }
}

class InheritedCellsTask extends InheritedWidget {
  const InheritedCellsTask({
    Key? key,
    required Widget child,
    required this.taskViewModel,
  }) : super(key: key, child: child);

  final ImportExcelCellsTaskViewModel taskViewModel;

  static ImportExcelCellsTaskViewModel of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<InheritedCellsTask>()!
          .taskViewModel;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class SortedSelectedCellsList extends UnmodifiableListView<CellBase> {
  SortedSelectedCellsList(Iterable<CellBase> cells)
    : super(List.from(cells, growable: false));

  CellBase? elementAtOrNull(int index) {
    if (length == 1) {
      return super[0];
    }
    if (index < 0 || index >= length) {
      return null;
    }
    return super[index];
  }
}

class LazyImportExcelCellsTaskViewModelCopy
    extends ImportExcelCellsTaskViewModel {
  final ImportExcelCellsTaskViewModel original;
  final int deltaX;
  final int deltaY;

  TaskCellSelection? _cachedShiftedSelectedCellsGrid;

  @override
  TaskCellSelection get selection =>
      _cachedShiftedSelectedCellsGrid ??= original.selection!.copyWithDelta(
        deltaX: deltaX,
        deltaY: deltaY,
      );

  LazyImportExcelCellsTaskViewModelCopy({
    required this.original,
    required this.deltaX,
    required this.deltaY,
  }) : super(parent: original.parentTask);

  factory LazyImportExcelCellsTaskViewModelCopy.copyWithDelta({
    required ImportExcelCellsTaskViewModel from,
    required int deltaX,
    required int deltaY,
  }) {
    return LazyImportExcelCellsTaskViewModelCopy(
        original: from,
        deltaX: deltaX,
        deltaY: deltaY,
      )
      ..boundingBox = Rectangle<int>(
        from.boundingBox.left + deltaX,
        from.boundingBox.top + deltaY,
        from.boundingBox.width,
        from.boundingBox.height,
      )
      ..shiftingLocked = from.shiftingLocked
      ..useTypedValue = from.useTypedValue
      ..typedValue = from.typedValue
      ..importExcelCellsTasks = [
        for (final child in from.importExcelCellsTasks)
          LazyImportExcelCellsTaskViewModelCopy.copyWithDelta(
            from: child,
            deltaX: deltaX,
            deltaY: deltaY,
          ),
      ];
  }
}

/// A view model representing an import task for Excel cells.
///
/// This class extends [ImportExcelCellsTaskList] and provides additional functionality
/// and state management for individual cell import tasks.
class ImportExcelCellsTaskViewModel extends ImportExcelCellsTaskList
    implements SelectionBase {
  bool _expanded = true;

  bool get expanded => _expanded;
  set expanded(bool value) {
    if (value == _expanded) return;
    _expanded = value;
    topViewModel.treeChanged();
  }

  bool toggleExpanded() => expanded = !expanded;

  bool _shiftingLocked = false;
  bool get shiftingLocked => _shiftingLocked;
  set shiftingLocked(bool value) => _shiftingLocked = value;

  String? _typedValue = null;
  String? get typedValue => _useTypedValue ? _typedValue : null;

  set typedValue(String? newValue) {
    _typedValue = newValue;
  }

  bool _useTypedValue = false;
  bool get useTypedValue => _useTypedValue;
  set useTypedValue(bool newValue) {
    _useTypedValue = newValue;
  }

  set selectedCellGrids(SelectedCellGrids newValue) {
    _selectedCellGridsCache = newValue;
  }

  /// Retrieves the selected cell grids.
  @override
  SelectedCellGrids get selectedCellGrids =>
      _selectedCellGridsCache ??= SelectedCellGrids([
        this,
        ...importExcelCellsTasks.map((task) => task.selectedCellGrids),
      ]);

  TaskCellSelection? _selectedCellsGrid;

  TaskCellSelection? get selection => _selectedCellsGrid;

  set selection(TaskCellSelection? value) {
    invalidateSortedCellsCache();
    invalidateSelectedCellGridsCache();
    invalidateBoundingBoxCache();
    _selectedCellsGrid = value;
  }

  void invalidateSortedCellsCache() => _sortedSelectedCells = null;
  void invalidateBoundingBoxCache() => _boundingBox = null;

  SortedSelectedCellsList? _sortedSelectedCells;

  SortedSelectedCellsList get sortedSelectedCells =>
      _sortedSelectedCells ??=
          selection?.toSortedSelectedCellsList() ??
          SortedSelectedCellsList(const []);

  CellSelectionState cellSelected({
    required int columnIndex,
    required int rowIndex,
  }) {
    final cellIsSelected = this.cellIsSelected(columnIndex, rowIndex);
    final cellIsMerged = this.cellIsMerged(columnIndex, rowIndex);

    if (cellIsSelected) {
      if (cellIsMerged) {
        return CellSelectionState.cellIsMerged;
      }
      return CellSelectionState.cellIsSelected;
    } else {
      return CellSelectionState.cellIsNotSelected;
    }
  }

  bool cellIsSelected(int x, int y) => selection?.cellIsSelected(x, y) ?? false;

  bool cellIsMerged(int x, int y) => selection?.cellIsMerged(x, y) ?? false;

  /// Moves the selected cells by a specified delta.
  void moveCells({
    int deltaX = 0,
    int deltaY = 0,
    bool includingChildrenTasks = false,
  }) {
    if (includingChildrenTasks) {
      moveChildrenCells(deltaX: deltaX, deltaY: deltaY);
    }

    if (shiftingLocked) {
      return;
    }

    selection = selection?..moveCells(deltaX: deltaX, deltaY: deltaY);
  }

  /// Retrieves the Excel file view model of the first file.
  ExcelFileViewModel? get firstFile => importSheetTask.firstFile;

  /// Retrieves the first sheet view model.
  ByteParsedWorksheet? get firstSheet => importSheetTask.firstSheet;

  /// Retrieves the cell IDs of the first sheet.
  List<String> getCellIdsOfFirstSheet({int amount = 3}) {
    final cells = cellSelectionModel.cells;
    return cells.take(amount).map((c) => c.getExcelCellId()).toList();
  }

  /// Retrieves the cell IDs. If all cells are in one row and no cell is missing, the range is returned. If all cells are in one column and no cell is missing, the range is returned. If the cells are in a rectangle and no cell is missing, the range is returned. Otherwise, the cell IDs are returned.
  String getCellIds() {
    if (selection?.isEmpty ?? true) {
      return "";
    }
    final first = sortedSelectedCells.first.getExcelCellId();
    final last = sortedSelectedCells.last.getExcelCellId();

    return first == last ? first : '$first : $last';
  }

  /// Retrieves the cell values of the first sheet.
  List<String> getCellValuesOfFirstSheet({int amount = 3}) {
    final firstSheet = this.firstSheet;
    if (firstSheet != null) {
      return sortedSelectedCells
          .take(amount)
          .map((c) => c.getValue(firstSheet))
          .toList();
    } else {
      return [];
    }
  }

  /// Retrieves the values of cells in a sheet.
  lists_utils.Table getValues(ByteParsedWorksheet sheet) {
    final cells = sortedSelectedCells;

    final childrenValues = lists_utils.TasksResultList(
      importExcelCellsTasks.map((task) => task.getValues(sheet)),
    );
    final combinedList = childrenValues.getCombinedColumnList();

    final typedValue = this.typedValue;
    if (useTypedValue && typedValue != null) {
      final typedValueList = lists_utils.Vector([
        Value(typedValue, type: ValueType.typed),
      ]);
      final joined = typedValueList.joinWithColumnList(combinedList);
      return joined;
    }

    final valuesOfSheet = lists_utils.Vector(
      cells
          .map(
            (cell) => Value(
              cell.getValue(sheet),
              type:
                  cell is CombinedCell
                      ? ValueType.combined
                      : ValueType.selected,
            ),
          )
          .toList(),
    );
    // [1,2,3]

    //final a = childrenValues[0][0][0];

    // [ [4,5,6],
    //   [7,8,9] ]
    final joined = valuesOfSheet.joinWithColumnList(combinedList);

    if (importExcelCellsTasks.isEmpty) {
      final cellIndices = lists_utils.Vector(
        cells
            .map(
              (cell) => Value(
                cell.getExcelCellId(),
                type: ValueType.automaticallyGenerated,
              ),
            )
            .toList(),
      );
      final joinedWithCellIndices = cellIndices.joinWithColumnList(joined);
      return joinedWithCellIndices;
    }

    return joined;

    //  final duplicatedValuesForJoin = ValueListColumn(List.filled(combinedList.first.length, valuesOfSheet));
    // [ [1,2,3][1,2,3] ]
    //    final flattenedValuesForJoin = duplicatedValuesForJoin.expand((innerList) => innerList).toList();
    //=> [ 1,2,3,1,2,3 ]

    //   final flattenedChildrenValues = childrenValues.expand((innerList) => innerList).toList();
    // [ 4,5,6,7,8,9 ]

    //  final joinedValues = ColumnList([duplicatedValuesForJoin, ...combinedList]);
    // [ [ 1,2,3,1,2,3 ]
    // , [ 4,5,6,7,8,9 ] ]

    // [ [A,B,C] ]
    // -> [ [4,5,6] ]
    // -> [ [7,8,9] ]
    //    -> [ [10,11,12] ]
    //   -> [ [13,14,15] ]

    // [ [7,8,9] ]

    //   [ [10,11,12] ]
    //   [ [13,14,15] ]

    // [ [4,5,6] ,
    //   [7,8,9] ,
    //   [10,11,12] ]

    // return joinedValues;
  }

  final stopwatchSelectedCells = Stopwatch();

  /// Converts the task model to a task view model.
  set taskModel(ImportCellsTask taskModel) {
    shiftingLocked = taskModel.shiftingLocked == true;
    useTypedValue = taskModel.typedValue != null;
    typedValue = taskModel.typedValue;
    cellSelectionModel = taskModel.cellSelection;
    importExcelCellsTasks =
        taskModel.childTasks
            .map(
              (taskModel) =>
                  ImportExcelCellsTaskViewModel(parent: this)
                    ..taskModel = taskModel,
            )
            .toList();
  }

  /// Retrieves the task model associated with this view model.
  ImportCellsTask get taskModel => ImportCellsTask(
    (b) =>
        b
          ..shiftingLocked = shiftingLocked == true ? true : null
          ..typedValue = typedValue
          ..cellSelection.replace(cellSelectionModel)
          ..childTasks = ListBuilder<ImportCellsTask>(
            importExcelCellsTasks.map((vm) => vm.taskModel),
          ),
  );

  /// Sets the cell selection model.
  set cellSelectionModel(CellSelection cellSelection) {
    selection = cellSelection.toViewModel();
  }

  /// Retrieves the cell selection model.
  CellSelection get cellSelectionModel {
    final cellsToConvert = Queue.from(sortedSelectedCells);

    final allCells = <CellBase>{};

    while (cellsToConvert.isNotEmpty) {
      final cell = cellsToConvert.removeFirst();

      if (cell.hasNeighbors) {
        final cellsToVisit = Queue<SelectedCell>();
        final visitedCells = <SelectedCell>{};
        cellsToVisit.add(cell);
        do {
          final currentlyVisitedCell = cellsToVisit.removeFirst();
          cellsToConvert.remove(currentlyVisitedCell);

          final rightNeighbor = currentlyVisitedCell.rightNeighbor;
          if (rightNeighbor != null && !visitedCells.contains(rightNeighbor)) {
            cellsToVisit.add(rightNeighbor);
          }
          final bottomNeighbor = currentlyVisitedCell.bottomNeighbor;
          if (bottomNeighbor != null &&
              !visitedCells.contains(bottomNeighbor)) {
            cellsToVisit.add(bottomNeighbor);
          }

          final leftNeighbor = currentlyVisitedCell.leftNeighbor;
          if (leftNeighbor != null && !visitedCells.contains(leftNeighbor)) {
            cellsToVisit.add(leftNeighbor);
          }

          final topNeighbor = currentlyVisitedCell.topNeighbor;
          if (topNeighbor != null && !visitedCells.contains(topNeighbor)) {
            cellsToVisit.add(topNeighbor);
          }
          visitedCells.add(currentlyVisitedCell);
        } while (cellsToVisit.isNotEmpty);

        final combinedCell = CombinedCell((b) {
          b.cells = SetBuilder(
            visitedCells.map(
              (c) => SingleCell(
                (b) =>
                    b
                      ..x = c.x
                      ..y = c.y,
              ),
            ),
          );
        });

        allCells.add(combinedCell);
      } else {
        final singleCell = SingleCell(
          (b) =>
              b
                ..x = cell.x
                ..y = cell.y,
        );

        allCells.add(singleCell);
      }
    }

    return CellSelection((b) => b.cells.replace(allCells));
  }

  /// Constructs an [ImportExcelCellsTaskViewModel] with the given parent.
  ImportExcelCellsTaskViewModel({required ImportExcelCellsTaskList? parent})
    : super(parentTask: parent); //{
  //selectedCellsGrid = buildSelectedCellTable(importSheetTask.sheetsByExcelFile.value.values.expand((sheet) => sheet).toList());
  //}

  factory ImportExcelCellsTaskViewModel.copy(
    ImportExcelCellsTaskViewModel other,
    ImportExcelCellsTaskList newParent,
  ) {
    final copy = ImportExcelCellsTaskViewModel(parent: newParent);

    copy.shiftingLocked = other.shiftingLocked;
    copy.useTypedValue = other.useTypedValue;
    copy.typedValue = other.typedValue;
    copy.cellSelectionModel = other.cellSelectionModel;
    copy.importExcelCellsTasks =
        other.importExcelCellsTasks
            .map((child) => ImportExcelCellsTaskViewModel.copy(child, copy))
            .toList();
    return copy;
  }

  /// Removes the task.
  void remove() => parentTask!.removeTask(this);

  bool insertAbove(ImportCellsTask droppedTaskModel) {
    final parent = parentTask!;

    final indexOfDropped = parent.importExcelCellsTasks.indexOf(this);

    if (indexOfDropped >= 0) {
      parent.importExcelCellsTasks.insert(
        indexOfDropped,
        ImportExcelCellsTaskViewModel(parent: parentTask!)
          ..taskModel = droppedTaskModel,
      );
      return true;
    }
    return false;
  }

  bool insertInside(ImportCellsTask droppedTaskModel) {
    importExcelCellsTasks.add(
      ImportExcelCellsTaskViewModel(parent: this)..taskModel = droppedTaskModel,
    );

    return true;
  }

  bool insertBelow(ImportCellsTask droppedTaskModel) {
    final parent = parentTask!;

    final indexOfDropped = parent.importExcelCellsTasks.indexOf(this);

    if (indexOfDropped >= 0) {
      parent.importExcelCellsTasks.insert(
        indexOfDropped + 1,
        ImportExcelCellsTaskViewModel(parent: parentTask!)
          ..taskModel = droppedTaskModel,
      );
      return true;
    }
    return false;
  }

  Rectangle<int>? _boundingBox;

  set boundingBox(Rectangle<int>? value) {
    _boundingBox = value;
  }

  @override
  Rectangle<int> get boundingBox {
    if (_boundingBox != null) {
      return _boundingBox!;
    }
    return _boundingBox ??=
        selection?.boundingBox ?? Rectangle<int>(0, 0, 0, 0);
  }

  Rectangle<int> get boundingBoxOfSelfAndChildren {
    if (importExcelCellsTasks.isEmpty) {
      return boundingBox;
    }

    int minX = boundingBox.left;
    int minY = boundingBox.top;
    int maxX = boundingBox.right - 1;
    int maxY = boundingBox.bottom - 1;

    for (var child in importExcelCellsTasks) {
      final childBoundingBox = child.boundingBoxOfSelfAndChildren;
      if (childBoundingBox.left < minX) {
        minX = childBoundingBox.left;
      }
      if (childBoundingBox.right - 1 > maxX) {
        maxX = childBoundingBox.right - 1;
      }
      if (childBoundingBox.top < minY) {
        minY = childBoundingBox.top;
      }
      if (childBoundingBox.bottom - 1 > maxY) {
        maxY = childBoundingBox.bottom - 1;
      }
    }

    return Rectangle<int>(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  @override
  FoundCellInGrid? findCell({required int y, required int x}) {
    final boundingBox = this.boundingBox;
    final containsPoint = boundingBox.containsPoint(Point(x, y));

    if (!containsPoint) {
      return null;
    }

    final cell = selection?.findCell(x, y);

    if (cell == null) {
      return null;
    }

    return FoundCellInGrid(indexOfTask: -1, cell: cell);
  }
}

class SelectedCellsInHierarchyService extends InheritedWidget {
  final SelectedSheetService selectedSheetService;

  SelectedCellsInHierarchyService({
    Key? super.key,
    required super.child,
    required this.selectedSheetService,
  }) {}

  FoundCellInGrid? findCell({required int y, required int x}) {
    return selectedSheetService.activeSheetTask!.selectedCellGrids.findCell(
      y: y,
      x: x,
    );
  }

  static SelectedCellsInHierarchyService of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            SelectedCellsInHierarchyService
          >()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

/// Represents a view model for tasks related to importing Excel sheets.
///
/// This class extends [ImportExcelCellsTaskList] and provides additional functionality specific to managing tasks
/// for importing Excel sheets. It includes methods for adding and removing sheets, as well as retrieving various
/// properties related to the sheets and associated files.
class ImportExcelSheetsTaskViewModel extends ImportExcelCellsTaskList {
  final ImportExcelFilesTaskViewModel parentImportExcelFilesTask;
  Iterable<ExcelFileViewModel> get excelFiles =>
      parentImportExcelFilesTask.excelFilesByPath.values;

  /// Removes the current task from its parent task.
  void remove() => parentImportExcelFilesTask.removeTask(this);

  final ValueNotifier<ByteParsedWorksheet?> selectedWorksheetNotifier =
      ValueNotifier<ByteParsedWorksheet?>(null);
  bool sheetIsOpen(String sheet) =>
      sheet == selectedWorksheetNotifier.value?.name;
  openSheet(ByteParsedWorksheet sheet) =>
      selectedWorksheetNotifier.value = sheet;

  final ValueNotifier<
    BuiltMap<ExcelFileViewModel, BuiltSet<ByteParsedWorksheet>>
  >
  loadedSheetsByExcelFile = ValueNotifier(BuiltMap());

  Iterable<(Workbook, ByteParsedWorksheet)> get sheets =>
      loadedSheetsByExcelFile.value.entries.expand((entry) {
        final file = entry.key;
        final sheetSet = entry.value;

        return sheetSet.map((sheet) => (file.excelFile, sheet));
      });

  bool allSheetsOfFileSelected(ExcelFileViewModel file) =>
      const SetEquality().equals(
        loadedSheetsByExcelFile.value[file]?.map((s) => s.name).toSet(),
        file.excelFile.sheetNamesById.values.toSet(),
      );

  addAllSheetsForFile(ExcelFileViewModel file) {
    final alreadyLoadedSheetNames =
        loadedSheetsByExcelFile.value[file]!.map((s) => s.name).toSet();
    final allSheetNames = file.excelFile.sheetNamesById.values.toSet();
    final newSheets = allSheetNames.difference(alreadyLoadedSheetNames);

    addSheetsForFile(file, newSheets);
  }

  addSheetsForFile(ExcelFileViewModel file, Set<String> sheetNames) {
    final builder = loadedSheetsByExcelFile.value.toBuilder();
    var setBuilder = builder.putIfAbsent(file, () => BuiltSet()).toBuilder();

    for (final sheetName in sheetNames) {
      setBuilder.add(file.excelFile[sheetName]);
    }
    builder[file] = setBuilder.build();
    loadedSheetsByExcelFile.value = builder.build();
  }

  clearSheetsForFile(ExcelFileViewModel file) {
    var builder = loadedSheetsByExcelFile.value.toBuilder();
    var setBuilder = builder[file]!.toBuilder();
    setBuilder.clear();
    builder[file] = setBuilder.build();
    loadedSheetsByExcelFile.value = builder.build();
  }

  bool get atLeastOnSheetSelected => loadedSheetsByExcelFile.value.values.any(
    (sheetSet) => sheetSet.isNotEmpty,
  );
  bool get noSheetSelected => !atLeastOnSheetSelected;

  /// Indicates whether there are sheets associated with the task.
  bool get hasSheets =>
      loadedSheetsByExcelFile.value.values
          .expand((sheetSet) => sheetSet)
          .isNotEmpty;
  ExcelFileViewModel? get firstFile =>
      loadedSheetsByExcelFile.value.keys.isNotEmpty
          ? loadedSheetsByExcelFile.value.keys.first
          : null;

  ByteParsedWorksheet? get firstSheet =>
      loadedSheetsByExcelFile.value.values.firstOrNull?.firstOrNull;

  /// Retrieves the sheet names by Excel file path as a model for serialization.
  BuiltMap<String, BuiltSet<String>> get sheetsByExcelFilePathModel {
    return BuiltMap(
      loadedSheetsByExcelFile.value.map(
        (key, value) => MapEntry<String, BuiltSet<String>>(
          key.path,
          BuiltSet(value.map((e) => e.name)),
        ),
      ),
    );
  }

  /// Sets the sheet names by Excel file path using the provided model.
  set sheetsByExcelFilePathModel(BuiltMap<String, BuiltSet<String>> model) {
    for (final excelFilePath in model.keys) {
      final sheetsToLoad = model[excelFilePath]!;
      final excelFileVm =
          parentImportExcelFilesTask.excelFilesByPath[excelFilePath]!;
      addSheetsForFile(excelFileVm, sheetsToLoad.toSet());
    }
  }

  /// Retrieves the task model associated with the task.
  ImportExcelSheetsTask get taskModel {
    return ImportExcelSheetsTask((b) {
      b
        ..sheetNamesByExcelFilePath = sheetsByExcelFilePathModel.toBuilder()
        ..childTasks = ListBuilder<ImportCellsTask>(
          importExcelCellsTasks.map((vm) => vm.taskModel),
        );
    });
  }

  /// Sets the task model using the provided task model.
  set taskModel(ImportExcelSheetsTask taskModel) {
    sheetsByExcelFilePathModel = taskModel.sheetNamesByExcelFilePath;

    importExcelCellsTasks =
        taskModel.childTasks
            .map(
              (taskModel) =>
                  ImportExcelCellsTaskViewModel(parent: this)
                    ..taskModel = taskModel,
            )
            .toList();
  }

  /// Retrieves the column list representing the values of the task.
  lists_utils.Table getValues() {
    final filesTasksResultList = lists_utils.TasksResultList(
      loadedSheetsByExcelFile.value.entries.map((entry) {
        final file = entry.key;
        final sheetset = entry.value;

        final fileNameValueList = lists_utils.Vector([
          Value(file.name, type: ValueType.automaticallyGenerated),
        ]);

        final sheetSetTasksResultList = lists_utils.TasksResultList(
          sheetset.map((sheet) {
            final childrenValues = lists_utils.TasksResultList(
              importExcelCellsTasks.map((task) => task.getValues(sheet)),
            );
            final columnList = childrenValues.getCombinedColumnList();

            final sheetNameValueList = lists_utils.Vector([
              Value(sheet.name, type: ValueType.automaticallyGenerated),
            ]);
            final joined = sheetNameValueList.joinWithColumnList(columnList);
            return joined;
          }),
        );

        final combinedSheetSetColumnList =
            sheetSetTasksResultList.getCombinedColumnList();
        final joined = fileNameValueList.joinWithColumnList(
          combinedSheetSetColumnList,
        );

        return joined;
      }),
    );

    return filesTasksResultList.getCombinedColumnList();
  }

  ImportExcelSheetsTaskViewModel({
    required Iterable<ExcelFileViewModel> excelFiles,
    required this.parentImportExcelFilesTask,
  }) : super(parentTask: null) {
    loadedSheetsByExcelFile.value =
        {
          for (final excelFile in excelFiles)
            excelFile: BuiltSet<ByteParsedWorksheet>(),
        }.build();
  }

  ImportExcelSheetsTaskViewModel.copy({
    required ImportExcelSheetsTaskViewModel from,
  }) : parentImportExcelFilesTask = from.parentImportExcelFilesTask,
       super(parentTask: null) {
    taskModel = from.taskModel;
  }

  /// Indicates whether the specified sheet is selected.
  bool sheetIsSelected(ExcelFileViewModel spreadsheetFile, String sheet) {
    final sheetIsSelected =
        loadedSheetsByExcelFile.value[spreadsheetFile]?.any(
          (s) => s.name == sheet,
        ) ==
        true;
    return sheetIsSelected;
  }

  /// Removes the specified sheet from the task.
  void removeSheet({required ExcelFileViewModel file, required String sheet}) {
    var builder = loadedSheetsByExcelFile.value.toBuilder();
    var setBuilder = builder[file]!.toBuilder();
    setBuilder.removeWhere((s) => s.name == sheet);
    builder[file] = setBuilder.build();
    loadedSheetsByExcelFile.value = builder.build();
  }

  /// Adds the specified sheet to the task.
  void addSheet({required ExcelFileViewModel file, required String sheet}) {
    var builder = loadedSheetsByExcelFile.value.toBuilder();
    var setBuilder = builder.putIfAbsent(file, () => BuiltSet()).toBuilder();

    setBuilder.add(file.excelFile[sheet]);
    builder[file] = setBuilder.build();
    loadedSheetsByExcelFile.value = builder.build();
  }
}

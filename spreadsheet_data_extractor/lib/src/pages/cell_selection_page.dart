import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/excel_file_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/import_excel_files_task_view_model.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/pages/task_overview_page.dart';
import 'package:spreadsheet_data_extractor/src/utils/clipboard_utils.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/output_grid_view.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/two_dimensional_grid_view.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';
import 'package:spreadsheet_data_extractor/src/utils/grid_related_utils.dart';
import 'package:multi_split_view/multi_split_view.dart';

import '../app_state.dart';
import '../utils/excel_decoder/worksheet.dart';
import 'shared_widgets/import_excel_sheets_task_list_view_header.dart';
import 'shared_widgets/theme_button.dart';
import 'package:spreadsheet_data_extractor/l10n/app_localizations.dart';

enum CellSelectionState {
  noCellSelectionTaskSelected,
  cellIsSelected,
  cellIsNotSelected,
  cellIsMerged,
}

class SelectedTaskService extends InheritedWidget with ChangeNotifier {
  SelectedTaskService({super.key, required super.child});

  ImportExcelCellsTaskList? _selectedTask;

  ImportExcelCellsTaskList? get selectedTask => _selectedTask;

  set selectedTask(ImportExcelCellsTaskList? task) {
    if (_selectedTask == task) return;
    final selectedTask = _selectedTask;
    if (selectedTask is ImportExcelCellsTaskViewModel) {
      selectedTask.selection = selectedTask.selection?.simplify();
    }

    _selectedTask = task;
    notifyListeners();
  }

  final BehaviorSubject<bool> shiftingLockedBehavior = BehaviorSubject.seeded(
    false,
  );
  bool get shiftingLocked => shiftingLockedBehavior.value;
  set shiftingLocked(bool value) => shiftingLockedBehavior.value = value;

  CellSelectionState cellSelected({
    required int columnIndex,
    required int rowIndex,
  }) {
    final task = selectedTask;
    if (task == null) {
      return CellSelectionState.noCellSelectionTaskSelected;
    }
    if (task is! ImportExcelCellsTaskViewModel) {
      return CellSelectionState.noCellSelectionTaskSelected;
    }
    return task.cellSelected(columnIndex: columnIndex, rowIndex: rowIndex);
  }

  ImportExcelCellsTaskViewModel? get selectCellsTask {
    final selectedTask = this.selectedTask;

    if (selectedTask is ImportExcelCellsTaskViewModel) {
      return selectedTask;
    }
    return null;
  }

  SelectedCellGrid? get selectedCellsGrid {
    final selectedTask = this.selectedTask;

    if (selectedTask is ImportExcelCellsTaskViewModel) {
      return selectedTask.selection?.toSelectedCellGrid() ?? SelectedCellGrid();
    }
    return null;
  }

  set selectedCellsGrid(SelectedCellGrid? grid) {
    final selectedTask = this.selectedTask;

    if (selectedTask is ImportExcelCellsTaskViewModel) {
      selectedTask.selection = grid?.simplify() ?? SelectedCellGrid();
      notifyListeners();
    }
  }

  static SelectedTaskService of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectedTaskService>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class SelectExcelSheetsPage extends Page {
  const SelectExcelSheetsPage() : super();

  @override
  Route createRoute(BuildContext context) {
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (context, animation, animation2) {
        final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero);
        final curveTween = CurveTween(curve: Curves.easeInOut);
        return SlideTransition(
          position: animation.drive(curveTween).drive(tween),
          child: OpenedFile(
            child: SheetScrollController(
              child: OutputScrollController(
                child: const SelectExcelSheetsScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class SheetScrollController extends InheritedWidget {
  SheetScrollController({Key? key, required Widget child})
    : horizontalController = ScrollController(),
      verticalController = ScrollController(),
      super(key: key, child: child) {
    horizontalDetails = ScrollableDetails.horizontal(
      controller: horizontalController,
    );
    verticalDetails = ScrollableDetails.vertical(
      controller: verticalController,
    );
  }

  final ScrollController horizontalController;
  final ScrollController verticalController;
  late final ScrollableDetails horizontalDetails;
  late final ScrollableDetails verticalDetails;

  void reset() {
    if (horizontalController.hasClients && verticalController.hasClients) {
      horizontalController.jumpTo(0);
      verticalController.jumpTo(0);
    }
  }

  static SheetScrollController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SheetScrollController>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class OutputScrollController extends InheritedWidget {
  OutputScrollController({Key? key, required Widget child})
    : horizontalController = ScrollController(),
      verticalController = ScrollController(),
      super(key: key, child: child) {
    horizontalDetails = ScrollableDetails.horizontal(
      controller: horizontalController,
    );
    verticalDetails = ScrollableDetails.vertical(
      controller: verticalController,
    );
  }

  final ScrollController horizontalController;
  final ScrollController verticalController;
  late final ScrollableDetails horizontalDetails;
  late final ScrollableDetails verticalDetails;

  void reset() {
    if (horizontalController.hasClients && verticalController.hasClients) {
      horizontalController.jumpTo(0);
      verticalController.jumpTo(0);
    }
  }

  static OutputScrollController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OutputScrollController>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class ShiftCellsController extends InheritedWidget with ChangeNotifier {
  ShiftCellsController({
    super.key,
    required super.child,
    required this.selectedTaskService,
    required this.selectedCellsService,
  }) {
    selectedTaskService.addListener(() {
      isActive = false;
    });
  }

  final SelectedCellsInHierarchyService selectedCellsService;

  final SelectedTaskService selectedTaskService;

  bool _active = false;

  bool get isActive => _active;

  bool get isInActive => !_active;

  set isActive(bool value) {
    if (_active == value) return;
    _active = value;
    notifyListeners();
  }

  bool toggleActive() => isActive = !isActive;

  SelectedCellGrids? _shiftedCellGridsCache;

  SelectedCellGrids get shiftedCellGrids {
    final shiftedCellGridsCache = _shiftedCellGridsCache;
    if (shiftedCellGridsCache != null) {
      return shiftedCellGridsCache;
    }

    final selectedTask = selectedTaskService.selectedTask;
    if (selectedTask == null) {
      return _shiftedCellGridsCache = SelectedCellGrids([]);
    }

    if (noShiftApplied) {
      return _shiftedCellGridsCache = SelectedCellGrids([]);
    }

    final newShiftedVms = this.newShiftedVms!;
    final firstBoundingBox = newShiftedVms.first.boundingBoxOfSelfAndChildren;
    final lastBoundingBox = newShiftedVms.last.boundingBoxOfSelfAndChildren;
    final combinedBoundingBox = Rectangle<int>(
      min(firstBoundingBox.left, lastBoundingBox.left),
      min(firstBoundingBox.top, lastBoundingBox.top),
      max(firstBoundingBox.right, lastBoundingBox.right) -
          min(firstBoundingBox.left, lastBoundingBox.left),
      max(firstBoundingBox.bottom, lastBoundingBox.bottom) -
          min(firstBoundingBox.top, lastBoundingBox.top),
    );

    return _shiftedCellGridsCache = SelectedCellGrids([
      //if (copy) selectedTask.selectedCellGrids,
      ...newShiftedVms.map((e) => e.selectedCellGrids),
    ])..boundingBox = combinedBoundingBox;
  }

  int _deltaYNotifier = 0;

  int get deltaY => _deltaYNotifier;

  set deltaY(int deltaY) {
    if (_deltaYNotifier == deltaY) return;
    _deltaYNotifier = deltaY;
    invalidateCache();
    notifyListeners();
  }

  int _deltaX = 0;

  int get deltaX => _deltaX;

  set deltaX(int deltaX) {
    if (_deltaX == deltaX) return;
    _deltaX = deltaX;
    invalidateCache();
    notifyListeners();
  }

  bool _copy = false;

  bool get copy => _copy;

  set copy(bool value) {
    if (_copy == value) return;
    _copy = value;
    invalidateCache();
    notifyListeners();
  }

  bool _repeat = false;

  bool get repeat => _repeat;

  set repeat(bool value) {
    if (_repeat == value) return;
    _repeat = value;
    invalidateCache();
    notifyListeners();
  }

  int _repetitions = 1;

  int get repetitions => _repetitions;

  set repetitions(int value) {
    if (_repetitions == value) return;
    _repetitions = value;

    if (repetitionsController.text != value.toString()) {
      repetitionsController.text = value.toString();
    }

    _updateNewShiftedVmsCount(value);
    invalidateShiftedCellGridsCache();
    notifyListeners();
  }

  final TextEditingController repetitionsController = TextEditingController();

  TextEditingValue get repetitionsText => repetitionsController.value;

  set repetitionsText(TextEditingValue value) {
    if (repetitionsController.value == value) return;
    repetitionsController.value = value;
  }

  void invalidateCache() {
    _newShiftedVms = null;
    _shiftedCellGridsCache = null;
  }

  void invalidateShiftedCellGridsCache() {
    _shiftedCellGridsCache = null;
  }

  List<ImportExcelCellsTaskViewModel>? _newShiftedVms;

  List<ImportExcelCellsTaskViewModel>? get newShiftedVms =>
      _newShiftedVms ??= _generateNewShiftedVms();

  List<ImportExcelCellsTaskViewModel> _generateNewShiftedVms() {
    final selectedTask = selectedTaskService.selectedTask;

    if (selectedTask is! ImportExcelCellsTaskViewModel) {
      return [];
    }
    final parent = selectedTask.parentTask;
    if (parent == null) {
      return [];
    }

    if (copy) {
      return [
        for (var i = 0; i < repetitions; i++)
          LazyImportExcelCellsTaskViewModelCopy.copyWithDelta(
            from: selectedTask,
            deltaX: deltaX * (i + 1),
            deltaY: deltaY * (i + 1),
          ),
      ];
    }

    return [
      LazyImportExcelCellsTaskViewModelCopy.copyWithDelta(
        from: selectedTask,
        deltaX: deltaX,
        deltaY: deltaY,
      ),
    ];
  }

  List<ImportExcelCellsTaskViewModel> _updateNewShiftedVmsCount(int newCount) {
    final selectedTask = selectedTaskService.selectedTask;

    if (selectedTask is! ImportExcelCellsTaskViewModel) {
      return [];
    }
    final parent = selectedTask.parentTask;
    if (parent == null) {
      return [];
    }

    final currentNewShiftedVms = newShiftedVms!;

    if (currentNewShiftedVms.length >= newCount) {
      _newShiftedVms = currentNewShiftedVms.sublist(0, newCount);
      return _newShiftedVms!;
    }

    final additionalVms = [
      for (var i = currentNewShiftedVms.length; i < newCount; i++)
        LazyImportExcelCellsTaskViewModelCopy.copyWithDelta(
          from: selectedTask,
          deltaX: deltaX * (i + 1),
          deltaY: deltaY * (i + 1),
        ),
    ];

    _newShiftedVms = [...currentNewShiftedVms, ...additionalVms];
    return additionalVms;
  }

  void apply() {
    final selectCellsTask = selectedTaskService.selectCellsTask;
    if (selectCellsTask == null) {
      return;
    }

    final newAndOldVms = [if (copy) selectCellsTask, ..._newShiftedVms!];
    selectCellsTask.parentTask?.replaceImportExcelCellsTaskViewModel(
      oldViewModel: selectCellsTask,
      newViewModels: newAndOldVms,
    );

    reset();

    selectCellsTask.topViewModel.treeChanged();
  }

  void reset() {
    deltaX = 0;
    deltaY = 0;
    copy = false;
    repeat = false;
    repetitions = 1;
    notifyListeners();
  }

  bool get hasChanges => deltaX != 0 || deltaY != 0 || copy || repeat;
  bool get noShiftApplied => !hasChanges;

  FoundCellInGrid? findCell({required int y, required int x}) {
    return shiftedCellGrids.findCell(y: y, x: x);
  }

  static ShiftCellsController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShiftCellsController>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class _Frame {
  final ImportExcelCellsTaskViewModel task;
  final List<ImportExcelCellsTaskViewModel> path;
  _Frame(this.task, this.path);
}

class SelectExcelSheetsScreen extends StatelessWidget {
  const SelectExcelSheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedSheetService = SelectedSheetService.of(context);

    final scaffold = Scaffold(
      appBar: AppBar(actions: [ShiftCellsWidget(), ThemeButton()]),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check_sharp),
        backgroundColor: Colors.greenAccent,
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      body: ListenableBuilder(
        listenable: selectedSheetService,
        builder: (context, snapshot) {
          final vm = selectedSheetService.activeSheetTask;

          if (vm == null) {
            return const SizedBox.shrink();
          }

          final splitView = MultiSplitView(
            axis: Axis.vertical,
            initialAreas: [
              Area(
                builder:
                    (context, area) => MultiSplitView(
                      initialAreas: [
                        Area(
                          builder: (context, area) => SelectCellsTaskListView(),
                        ),
                        Area(
                          builder:
                              (context, area) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(child: SheetView(vm: vm)),
                                  SheetSelectionList(vm: vm),
                                  FileSelectionList(vm: vm),
                                ],
                              ),
                        ),
                      ],
                    ),
              ),
              Area(
                builder:
                    (context, area) => ListenableBuilder(
                      listenable: Listenable.merge([
                        vm.selectedWorksheetNotifier,
                        vm.topViewModel,
                      ]),
                      builder: (context, child) {
                        return Container(
                          color: Colors.white,
                          child: RawScrollbar(
                            controller:
                                OutputScrollController.of(
                                  context,
                                ).horizontalController,
                            thumbVisibility: true,
                            thickness: 12.0,
                            radius: const Radius.circular(6.0),
                            padding: const EdgeInsets.only(bottom: 1.0),
                            scrollbarOrientation: ScrollbarOrientation.bottom,
                            thumbColor: Colors.grey.shade600.withOpacity(0.8),
                            child: RawScrollbar(
                              controller:
                                  OutputScrollController.of(
                                    context,
                                  ).verticalController,
                              thumbVisibility: true,
                              thickness: 12.0,
                              radius: const Radius.circular(6.0),
                              padding: const EdgeInsets.only(right: 1.0),
                              scrollbarOrientation: ScrollbarOrientation.right,
                              thumbColor: Colors.grey.shade600.withOpacity(0.8),
                              child: OutputGridView(
                                horizontalDetails:
                                    OutputScrollController.of(
                                      context,
                                    ).horizontalDetails,
                                verticalDetails:
                                    OutputScrollController.of(
                                      context,
                                    ).verticalDetails,
                                lazyRowLocator: LazyRowLocator.of(context),

                                diagonalDragBehavior: DiagonalDragBehavior.free,
                                delegate: TwoDimensionalChildBuilderDelegate(
                                  maxXIndex: 16384,
                                  maxYIndex: 1048576,
                                  builder: (
                                    BuildContext context,
                                    ChildVicinity vicinity,
                                  ) {
                                    final rowIndex = vicinity.yIndex;
                                    final columnIndex = vicinity.xIndex;

                                    final hit = LazyRowLocator.of(
                                      context,
                                    ).locateRow(rowIndex);
                                    if (hit == null)
                                      return const SizedBox.shrink();
                                    final (block, local) = hit;
                                    Widget? widget;
                                    if (columnIndex == 0)
                                      widget = Text(block.workbook.path);
                                    if (columnIndex == 1)
                                      widget = Text(block.sheet.name);

                                    final pathLen = block.path.length;
                                    final segCol = columnIndex - 2;
                                    if (segCol >= 0 && segCol < pathLen) {
                                      final seg = block.path[segCol];
                                      final segCells =
                                          seg.sortedSelectedCells; // List for O(1)
                                      final segCell =
                                          (local < segCells.length)
                                              ? segCells[local]
                                              : null;
                                      widget = Text(
                                        segCell
                                                ?.getValue(block.sheet)
                                                .toString() ??
                                            '',
                                      );
                                    }

                                    final cells = block.cells;
                                    final cell =
                                        (local < cells.length)
                                            ? cells[local]
                                            : null;
                                    if (cell == null)
                                      return const SizedBox.shrink();

                                    if (columnIndex == pathLen + 2)
                                      widget = Text(cell.getExcelCellId());
                                    if (columnIndex == pathLen + 3)
                                      widget = Text(cell.getValue(block.sheet));

                                    if (widget == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: widget,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );

          final locator = LazyRowLocator(
            taskListViewModel: InheritedTaskListViewModel.of(context),
            child: splitView,
          );
          return locator;
        },
      ),
    );

    final selectedCellsService = SelectedCellsInHierarchyService(
      selectedSheetService: selectedSheetService,
      child: scaffold,
    );

    final widget = ShiftCellsController(
      selectedTaskService: SelectedTaskService.of(context),
      selectedCellsService: selectedCellsService,
      child: selectedCellsService,
    );

    return widget;
  }
}

class LazyRowLocator extends InheritedWidget {
  final TaskListViewModel taskListViewModel;

  // --- traversal state (resumable) ---
  int _fi = 0; // file idx
  int _sti = 0; // sheet-task idx in current file
  int _si = 0; // sheet pair idx in current sheet-task
  ImportExcelFilesTaskViewModel? _curFile;
  ImportExcelSheetsTaskViewModel? _curSheetsTask;
  List<(Workbook, ByteParsedWorksheet)> _curSheets = const [];
  Queue<_Frame> _q = Queue<_Frame>();
  Workbook? _activeWb;
  ByteParsedWorksheet? _activeSheet;

  // --- cache (growing, sliding window) ---
  final List<RowBlock> _blocks = <RowBlock>[];
  final List<int> _starts = <int>[]; // startRow of each block (absolute)

  void reset() {
    _fi = 0;
    _sti = 0;
    _si = 0;
    _curFile = null;
    _curSheetsTask = null;
    _curSheets = const [];
    _q = Queue<_Frame>();
    _activeWb = null;
    _activeSheet = null;
    _blocks.clear();
    _starts.clear();
  }

  int get _builtRows =>
      _blocks.isEmpty ? 0 : _blocks.last.startRow + _blocks.last.len;

  final int? maxCachedBlocks; // optional cap
  final int? maxCachedRows; // optional cap

  LazyRowLocator({
    required this.taskListViewModel,
    super.key,
    this.maxCachedBlocks,
    this.maxCachedRows,
    required super.child,
  }) {
    taskListViewModel.addListener(() {
      reset();
    });
  }

  // Public: ensure we have indexed through 'rowIndex'
  void ensureBuiltThroughRow(int rowIndex) {
    while (_builtRows <= rowIndex) {
      final rb = _nextBlock();
      if (rb == null) break; // no more data
      _blocks.add(rb);
      _starts.add(rb.startRow);
      _pruneHeadIfNeeded();
    }
  }

  // Public: locate a row -> (block, localRow) if cached/available
  (RowBlock, int)? locateRow(int rowIndex) {
    ensureBuiltThroughRow(rowIndex);
    if (_blocks.isEmpty) return null;
    // binary search last start <= rowIndex
    int lo = 0, hi = _starts.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_starts[mid] <= rowIndex) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final idx = lo - 1;
    if (idx < 0) return null; // pruned earlier rows
    final b = _blocks[idx];
    final local = rowIndex - b.startRow;
    if (local >= 0 && local < b.len) return (b, local);
    return null;
  }

  // Optional: prefetch forward
  void prefetchThroughRow(int rowIndexPlusLookahead) =>
      ensureBuiltThroughRow(rowIndexPlusLookahead);

  // --- internals ---

  RowBlock? _nextBlock() {
    // Fill queue with next sheet’s root tasks if empty; advance across files/sheets lazily.
    if (!_fillQueueIfEmpty()) return null;

    while (true) {
      if (_q.isEmpty) {
        if (!_fillQueueIfEmpty()) return null;
        continue;
      }
      final f = _q.removeFirst();
      final children = f.task.importExcelCellsTasks;

      if (children.isEmpty) {
        // Leaf -> block of rows
        final SortedSelectedCellsList cells =
            f.task.sortedSelectedCells; // ensure List
        if (cells.isEmpty) continue;
        final start = _builtRows;
        return RowBlock(
          workbook: _activeWb!,
          sheet: _activeSheet!,
          path: List.unmodifiable(f.path),
          cells: cells,
          startRow: start,
          len: cells.length,
        );
      } else {
        final nextPath = List<ImportExcelCellsTaskViewModel>.of(f.path)
          ..add(f.task);
        for (final child in children) {
          _q.add(_Frame(child, nextPath));
        }
      }
    }
  }

  bool _fillQueueIfEmpty() {
    while (_q.isEmpty) {
      // Move to next sheet pair; if none, next sheet-task; if none, next file; if none, done.
      if (_curSheetsTask == null) {
        if (_fi >= taskListViewModel.importExcelFilesTasks.length) return false;
        _curFile = taskListViewModel.importExcelFilesTasks[_fi++];
        _sti = 0;
      }
      if (_sti >= _curFile!.importExcelSheetsTasks.length) {
        _curSheetsTask = null;
        continue;
      }
      _curSheetsTask = _curFile!.importExcelSheetsTasks[_sti++];
      _curSheets = _curSheetsTask!.sheets.toList(); // materialize pairs
      _si = 0;

      while (_si < _curSheets.length && _q.isEmpty) {
        final (wb, sh) = _curSheets[_si++];
        final roots = _curSheetsTask!.importExcelCellsTasks;
        if (roots.isEmpty) continue;
        _q = Queue.of(roots.map((r) => _Frame(r, const [])));
        _activeWb = wb;
        _activeSheet = sh;
      }
      if (_q.isNotEmpty) return true;
      // otherwise loop to next sheet-task/file
    }
    return true;
  }

  void _pruneHeadIfNeeded() {
    if (maxCachedBlocks == null && maxCachedRows == null) return;

    int removeCount = 0;
    if (maxCachedBlocks != null && _blocks.length > maxCachedBlocks!) {
      removeCount = _blocks.length - maxCachedBlocks!;
    }
    if (maxCachedRows != null) {
      // drop head until cached span fits in 'maxCachedRows'
      while (removeCount < _blocks.length) {
        final cachedRows =
            _blocks.last.startRow + _blocks.last.len - _blocks.first.startRow;
        if (cachedRows <= maxCachedRows!) break;
        removeCount++;
      }
    }
    if (removeCount > 0) {
      _blocks.removeRange(0, removeCount);
      _starts.removeRange(0, removeCount);
      // Note: startRow in remaining blocks stays absolute; that's fine.
    }
  }

  static LazyRowLocator of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LazyRowLocator>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class RowBlock {
  final Workbook workbook;
  final ByteParsedWorksheet sheet;
  final List<ImportExcelCellsTaskViewModel> path;
  final SortedSelectedCellsList cells;
  final int startRow;
  final int len;
  const RowBlock({
    required this.workbook,
    required this.sheet,
    required this.path,
    required this.cells,
    required this.startRow,
    required this.len,
  });
}

class ShiftCellsWidget extends StatelessWidget {
  ShiftCellsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = ShiftCellsController.of(context);

    shiftCellsWidgetBuilder(context, snapshot) {
      if (ctrl.isInActive) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(right: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
              child: InkWell(
                onTap: () async {
                  ctrl.deltaX -= 1;
                },
                child: const Icon(
                  Icons.keyboard_arrow_left_sharp,
                  color: Colors.blueAccent,
                  size: 16,
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 1,
                  ),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: InkWell(
                    onTap: () async {
                      ctrl.deltaY -= 1;
                    },
                    child: const Icon(
                      Icons.keyboard_arrow_up_sharp,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 1,
                    vertical: 1,
                  ),
                  shape: BeveledRectangleBorder(
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: InkWell(
                    onTap: () async {
                      ctrl.deltaY += 1;
                    },
                    child: const Icon(
                      Icons.keyboard_arrow_down_sharp,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              shape: BeveledRectangleBorder(
                borderRadius: BorderRadius.circular(0.0),
              ),
              child: InkWell(
                onTap: () async {
                  ctrl.deltaX += 1;
                },
                child: const Icon(
                  Icons.keyboard_arrow_right_sharp,
                  color: Colors.blueAccent,
                  size: 16,
                ),
              ),
            ),
            IntrinsicWidth(
              stepWidth: 100,
              child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                title: Row(
                  children: [
                    Text(
                      AppLocalizations.of(
                        context,
                      )!.duplicateAndMoveCheckboxText,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    if (ctrl.copy)
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.repeatLabelText,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 0, 4, 0),
                              child: IntrinsicWidth(
                                stepWidth: 1,
                                child: TextFormField(
                                  decoration: InputDecoration(
                                    isDense:
                                        true, // Reduces the height by tightening the vertical space
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                      horizontal: 8.0,
                                    ),
                                    border:
                                        OutlineInputBorder(), // Optional: Adds a border to match the reduced size
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  controller: ctrl.repetitionsController,
                                  style:
                                      Theme.of(context)
                                          .textTheme
                                          .titleMedium, // Optional: Reduce font size if needed
                                  onChanged: (value) {
                                    ctrl.repetitions = int.parse(value);
                                  },
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Card(
                                  margin: const EdgeInsets.only(top: 1),
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.circular(0.0),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      ctrl.repetitions += 1;
                                    },
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.blueAccent,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                Card(
                                  margin: const EdgeInsets.only(top: 1),
                                  shape: BeveledRectangleBorder(
                                    borderRadius: BorderRadius.circular(0.0),
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      ctrl.repetitions -= 1;
                                    },
                                    child: const Icon(
                                      Icons.remove,
                                      color: Colors.blueAccent,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                value: ctrl.copy,
                onChanged: (value) => ctrl.copy = value == true,
              ),
            ),
            Row(children: [AcceptShiftButton(), CancelShiftButton()]),
          ],
        ),
      );
    }

    ListenableBuilder listenableBuilder = ListenableBuilder(
      listenable: ctrl,
      builder: shiftCellsWidgetBuilder,
    );
    return listenableBuilder;
  }
}

class CancelShiftButton extends StatelessWidget {
  const CancelShiftButton({super.key});

  Widget _generateCancelShiftButton(VoidCallback onTab) => Card(
    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
    child: IconButton(
      onPressed: onTab,
      icon: const Icon(Icons.highlight_remove, color: Colors.redAccent),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ctrl = ShiftCellsController.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, snapshot) {
        acceptButtonTab() async {
          ctrl.reset();
          ctrl.isActive = false;
        }

        final onTab = acceptButtonTab;

        final button = _generateCancelShiftButton(onTab);

        return button;
      },
    );
  }
}

class AcceptShiftButton extends StatelessWidget {
  const AcceptShiftButton({super.key});

  Widget _generateAcceptShiftButton(VoidCallback? onTab, Color buttonColor) =>
      Card(
        margin: const EdgeInsets.all(8),
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(0.0)),
        child: IconButton(
          onPressed: onTab,
          icon: Icon(Icons.check_sharp, color: buttonColor),
        ),
      );

  VoidCallback? onTabFunction(ShiftCellsController ctrl) {
    if (!ctrl.hasChanges) {
      return null;
    }

    return () async {
      ctrl.apply();
      ctrl.isActive = false;
    };
  }

  Color buttonColorFunction(ShiftCellsController ctrl) {
    final enabledColor = Colors.greenAccent;
    final disabledColor = Colors.grey.shade300;

    if (ctrl.hasChanges) {
      return enabledColor;
    } else {
      return disabledColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ShiftCellsController.of(context);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, snapshot) {
        final VoidCallback? onTab = onTabFunction(ctrl);
        final Color buttonColor = buttonColorFunction(ctrl);

        final button = _generateAcceptShiftButton(onTab, buttonColor);

        return button;
      },
    );
  }
}

class SheetView extends StatelessWidget {
  SheetView({super.key, required this.vm});
  final ImportExcelSheetsTaskViewModel vm;
  Widget? _sheetViewWidget;

  int? startRowIndex;
  int? startColumnIndex;

  void _handleCellTap(
    ImportExcelCellsTaskViewModel vm,
    SelectedCellGrid cells,
    int columnIndex,
    int rowIndex,
  ) {
    if (startRowIndex == null || startColumnIndex == null) {
      // No initial selection, set the current cell as the start
      startRowIndex = rowIndex;
      startColumnIndex = columnIndex;
      cells.toggleCell(columnIndex, rowIndex);
    } else if (HardwareKeyboard.instance.isShiftPressed) {
      // Shift is pressed, select the range of cells
      int startRow = min(startRowIndex!, rowIndex);
      int endRow = max(startRowIndex!, rowIndex);
      int startCol = min(startColumnIndex!, columnIndex);
      int endCol = max(startColumnIndex!, columnIndex);

      cells.toggleCells([
        for (int y = startRow; y <= endRow; y++)
          for (int x = startCol; x <= endCol; x++)
            if ((x, y) != (startColumnIndex, startRowIndex)) (x, y),
      ]);

      startRowIndex = rowIndex;
      startColumnIndex = columnIndex;
    } else if (HardwareKeyboard.instance.isAltPressed) {
      // Alt is pressed, select the range of cells
      int startRow = min(startRowIndex!, rowIndex);
      int endRow = max(startRowIndex!, rowIndex);
      int startCol = min(startColumnIndex!, columnIndex);
      int endCol = max(startColumnIndex!, columnIndex);

      SelectedCell? previousSelectedCell;

      // Select all cells in the range except for the starting cell
      for (int y = startRow; y <= endRow; y++) {
        for (int x = startCol; x <= endCol; x++) {
          final selectedCell = cells
              .putIfAbsent(y, () => SelectedCellRow())
              .putIfAbsent(x, () => SelectedCell(x: x, y: y));

          if (previousSelectedCell != null) {
            selectedCell.updateNeigborsFromGrid(cells);
          }

          previousSelectedCell = selectedCell;
        }
      }
      startRowIndex = rowIndex;
      startColumnIndex = columnIndex;
    } else {
      // Just a normal click, clear the previous selection
      startRowIndex = rowIndex;
      startColumnIndex = columnIndex;
      cells.toggleCell(columnIndex, rowIndex);
    }

    // Update the selection state
    vm.topViewModel.treeChanged();
  }

  @override
  Widget build(BuildContext context) {
    return _sheetViewWidget ??= _buildSheetViewWidget(context);
  }

  Widget _buildSheetViewWidget(BuildContext context) {
    final shiftCellsController = ShiftCellsController.of(context);

    final widget = ListenableBuilder(
      listenable: Listenable.merge([
        vm.selectedWorksheetNotifier,
        vm.topViewModel,
        shiftCellsController,
        SelectedTaskService.of(context),
      ]),
      builder: (context, child) {
        if (vm.selectedWorksheetNotifier.value == null) {
          return const SizedBox.shrink();
        }

        return Container(
          color: Colors.white,
          child: RawScrollbar(
            controller: SheetScrollController.of(context).horizontalController,
            thumbVisibility: true,
            thickness: 12.0,
            radius: const Radius.circular(6.0),
            padding: const EdgeInsets.only(bottom: 1.0),
            scrollbarOrientation: ScrollbarOrientation.bottom,
            thumbColor: Colors.grey.shade600.withOpacity(0.8),
            child: RawScrollbar(
              controller: SheetScrollController.of(context).verticalController,
              thumbVisibility: true,
              thickness: 12.0,
              radius: const Radius.circular(6.0),
              padding: const EdgeInsets.only(right: 1.0),
              scrollbarOrientation: ScrollbarOrientation.right,
              thumbColor: Colors.grey.shade600.withOpacity(0.8),
              child: TwoDimensionalGridView(
                cacheExtent: 0,
                horizontalDetails:
                    SheetScrollController.of(context).horizontalDetails,
                verticalDetails:
                    SheetScrollController.of(context).verticalDetails,
                sheetVm: vm,
                diagonalDragBehavior: DiagonalDragBehavior.free,
                delegate: TwoDimensionalChildBuilderDelegate(
                  maxXIndex: 16384,
                  maxYIndex: 1048576,
                  builder: (BuildContext context, ChildVicinity vicinity) {
                    final y = vicinity.yIndex;
                    final x = vicinity.xIndex;
                    var selectedSheet = vm.selectedWorksheetNotifier.value!;

                    final cell = selectedSheet.cell(
                      columnIndex: x,
                      rowIndex: y,
                    );
                    final styles = selectedSheet.workbook.styles;

                    final columnDefinitions = selectedSheet.columnDefinitions;

                    // Apply styles
                    final textStyle = _getTextStyle(cell);
                    final cellBackgroundColor = _getCellBackgroundColor(cell);

                    // Calculate cell width and height
                    double cellWidth;
                    double cellHeight;

                    if (cell != null &&
                        cell.isMergedCellOrigin &&
                        cell.cellSpan != null) {
                      // Sum the widths of the spanned columns
                      cellWidth = 0;
                      for (
                        int col = cell.cellSpan!.start.columnIndex;
                        col <= cell.cellSpan!.end.columnIndex;
                        col++
                      ) {
                        cellWidth += columnDefinitions.getColumnWidth(col);
                      }

                      // Sum the heights of the spanned rows
                      cellHeight = 0;
                      for (
                        int row = cell.cellSpan!.start.rowIndex;
                        row <= cell.cellSpan!.end.rowIndex;
                        row++
                      ) {
                        cellHeight += selectedSheet.row(row)?.height ?? 20.0;
                      }
                    } else {
                      // Regular cell dimensions
                      cellWidth = columnDefinitions.getColumnWidth(x);
                      cellHeight = selectedSheet.row(y)?.height ?? 20.0;
                    }

                    // Determine if the next cell to the right has a value
                    final valueToTheRight = selectedSheet.cell(
                      columnIndex: x + 1,
                      rowIndex: y,
                    );

                    final isSpan = selectedSheet.cellSpans.containsRC(y, x);

                    // Build the cell widget
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Background container with cell dimensions and border

                        // Background container with cell dimensions
                        if (!isSpan || cell?.isMergedCellOrigin == true)
                          IgnorePointer(
                            child: Container(
                              width: cellWidth,
                              height: cellHeight,
                              decoration:
                                  _getCellBorder(cell, styles)?.copyWith(
                                    color: cellBackgroundColor?.withOpacity(
                                      0.6,
                                    ),
                                  ) ??
                                  BoxDecoration(color: cellBackgroundColor),
                            ),
                          ),

                        // Cell content (text)
                        if (!isSpan || cell?.isMergedCellOrigin == true)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: IgnorePointer(
                              child: Container(
                                width: cellWidth,
                                height: cellHeight,
                                alignment: _getCellAlignment(cell),
                                child: Text(
                                  cell?.value?.toString() ?? "",
                                  style: textStyle,
                                  softWrap: cell?.alignment?.wrapText ?? false,
                                  overflow:
                                      cell?.alignment?.wrapText ?? false
                                          ? TextOverflow.clip
                                          : (valueToTheRight?.value != null
                                              ? TextOverflow.fade
                                              : TextOverflow.visible),
                                ),
                              ),
                            ),
                          ),

                        // Semi-transparent yellow overlay for selected cells
                        Builder(
                          builder: (context) {
                            final selectedTask = SelectedTaskService.of(
                              context,
                            );
                            final selectedCellsService =
                                SelectedCellsInHierarchyService.of(context);
                            final selectedCellsGrid =
                                selectedTask.selectedCellsGrid;

                            final cellSelectionStatus = selectedTask
                                .cellSelected(columnIndex: x, rowIndex: y);

                            final shiftCellsController =
                                ShiftCellsController.of(context);

                            final cellInSelectionHierarchy =
                                selectedCellsService.findCell(y: y, x: x);

                            final cellInShiftCellsHierarchy =
                                shiftCellsController.findCell(y: y, x: x);

                            Color? getCellBackgroundColor() {
                              if (cellInShiftCellsHierarchy == null &&
                                  cellInSelectionHierarchy == null) {
                                return null;
                              }

                              Color? backgroundColor;

                              if (cellSelectionStatus ==
                                  CellSelectionState.cellIsMerged) {
                                backgroundColor = Colors.blue;
                              } else if (cellSelectionStatus ==
                                  CellSelectionState.cellIsSelected) {
                                backgroundColor = Colors.yellow;
                              } else if (shiftCellsController.hasChanges) {
                                if (cellInShiftCellsHierarchy != null) {
                                  backgroundColor =
                                      Colors
                                          .primaries[cellInShiftCellsHierarchy
                                                  .indexOfTask %
                                              Colors.primaries.length]
                                          .shade300;
                                }
                                if (cellInSelectionHierarchy != null) {
                                  backgroundColor =
                                      Colors
                                          .primaries[cellInSelectionHierarchy
                                                  .indexOfTask %
                                              Colors.primaries.length]
                                          .shade100;
                                }
                              } else if (cellInSelectionHierarchy != null) {
                                backgroundColor =
                                    Colors
                                        .primaries[cellInSelectionHierarchy
                                                .indexOfTask %
                                            Colors.primaries.length]
                                        .shade300;
                              }
                              return backgroundColor;
                            }

                            Border? getCellBorder({bool inner = false}) {
                              if (cellInShiftCellsHierarchy == null &&
                                  cellInSelectionHierarchy == null) {
                                return null;
                              }

                              Color? borderColor;

                              final selectedCells =
                                  selectedTask.selectedCellsGrid;
                              if (selectedCells == null) {
                                return null;
                              }

                              if (cellSelectionStatus ==
                                  CellSelectionState.cellIsMerged) {
                                borderColor = Colors.cyanAccent;
                              } else if (cellSelectionStatus ==
                                  CellSelectionState.cellIsSelected) {
                                borderColor = Colors.deepOrange;
                              } else if (shiftCellsController.hasChanges) {
                                if (cellInShiftCellsHierarchy != null) {
                                  borderColor =
                                      Colors
                                          .primaries[cellInShiftCellsHierarchy
                                                  .indexOfTask %
                                              Colors.primaries.length]
                                          .shade900;
                                }
                                if (cellInSelectionHierarchy != null) {
                                  borderColor =
                                      Colors
                                          .primaries[cellInSelectionHierarchy
                                                  .indexOfTask %
                                              Colors.primaries.length]
                                          .shade500;
                                }
                              } else if (cellInSelectionHierarchy != null) {
                                borderColor =
                                    Colors
                                        .primaries[cellInSelectionHierarchy
                                                .indexOfTask %
                                            Colors.primaries.length]
                                        .shade900;
                              }

                              final selectedCell =
                                  cellInShiftCellsHierarchy?.cell ??
                                  cellInSelectionHierarchy?.cell ??
                                  selectedCells[y]?[x];

                              if (selectedCell == null) {
                                return null;
                              }

                              if (selectedCell.hasNoNeighbors) {
                                return Border.all(
                                  width: 1,
                                  color: borderColor!,
                                );
                              }

                              return Border(
                                top:
                                    selectedCell.topNeighbor != null
                                        ? BorderSide.none
                                        : BorderSide(
                                          width: 1,
                                          color: borderColor!,
                                        ),
                                right:
                                    selectedCell.rightNeighbor != null
                                        ? BorderSide.none
                                        : BorderSide(
                                          width: 1,
                                          color: borderColor!,
                                        ),
                                bottom:
                                    selectedCell.bottomNeighbor != null
                                        ? BorderSide.none
                                        : BorderSide(
                                          width: 1,
                                          color: borderColor!,
                                        ),
                                left:
                                    selectedCell.leftNeighbor != null
                                        ? BorderSide.none
                                        : BorderSide(
                                          width: 1,
                                          color: borderColor!,
                                        ),
                              );
                            }

                            double selectionCellWidth = columnDefinitions
                                .getColumnWidth(x);
                            double selectionCellHeight =
                                selectedSheet.row(y)?.height ?? 20.0;

                            if (selectedCellsGrid == null) {
                              return Container(
                                width: selectionCellWidth,
                                height: selectionCellHeight,
                                decoration: BoxDecoration(
                                  color: getCellBackgroundColor()?.withOpacity(
                                    0.3,
                                  ),
                                  border: getCellBorder(),
                                ),
                              );
                            }

                            return InkWell(
                              child: Container(
                                width: selectionCellWidth,
                                height: selectionCellHeight,
                                decoration: BoxDecoration(
                                  color: getCellBackgroundColor()?.withOpacity(
                                    0.3,
                                  ),
                                  border: getCellBorder(),
                                ),
                              ),
                              onTap: () {
                                _handleCellTap(
                                  selectedTask.selectCellsTask!,
                                  selectedCellsGrid,
                                  x,
                                  y,
                                );
                                selectedTask.selectedCellsGrid =
                                    selectedCellsGrid;
                              },
                            );
                          },
                        ),
                        _LockToggleOverlay(
                          rootTaskList: vm.importSheetTask,
                          columnIndex: x,
                          rowIndex: y,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    return widget;
  }

  TextStyle? _getTextStyle(Cell? cell) {
    if (cell == null) {
      return null;
    }

    TextStyle textStyle = const TextStyle();

    if (cell.font != null) {
      final font = cell.font!;
      // Combine underline and strikethrough decorations
      final decorations = <TextDecoration>[];
      if (font.underline) decorations.add(TextDecoration.underline);
      if (font.strike) decorations.add(TextDecoration.lineThrough);

      textStyle = textStyle.copyWith(
        fontSize: font.size,
        fontWeight: font.bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: font.italic ? FontStyle.italic : FontStyle.normal,
        decoration:
            decorations.isNotEmpty
                ? TextDecoration.combine(decorations)
                : TextDecoration.none,
        fontFamily: font.name,
        color: _getFontColor(font),
      );
    }

    return textStyle;
  }

  Color? _getFontColor(Font font) {
    if (font.colorRgb != null) {
      String colorStr = font.colorRgb!;
      if (colorStr.length == 8) {
        // Color is in ARGB format
        final argb = int.tryParse(colorStr, radix: 16);
        if (argb != null) {
          return Color(argb);
        }
      } else if (colorStr.length == 6) {
        // Color is in RGB format, add opaque alpha
        final rgb = int.tryParse(colorStr, radix: 16);
        if (rgb != null) {
          return Color(0xFF000000 | rgb);
        }
      }
    }
    // Handle color themes if necessary
    return null; // Return null to use default color
  }

  Color? _getCellBackgroundColor(Cell? cell) {
    if (cell == null) {
      return null;
    }

    if (cell.fill != null) {
      final fill = cell.fill!;
      if (fill.bgColorRgb != null) {
        final argb = int.tryParse(fill.bgColorRgb!, radix: 16);
        if (argb != null) {
          return Color(argb);
        }
      } else if (fill.fgColorRgb != null) {
        final argb = int.tryParse(fill.fgColorRgb!, radix: 16);
        if (argb != null) {
          return Color(argb);
        }
      }
    }
    return null; // Return null to use default background color
  }

  Alignment? _getCellAlignment(Cell? cell) {
    if (cell == null) {
      return null;
    }

    if (cell.alignment != null) {
      final horizontal = cell.alignment!.horizontal;
      final vertical = cell.alignment!.vertical;

      double x;
      double y;

      // Determine horizontal alignment
      switch (horizontal) {
        case 'left':
          x = -1.0;
          break;
        case 'center':
          x = 0.0;
          break;
        case 'right':
          x = 1.0;
          break;
        default:
          x = -1.0; // Default to left
      }

      // Determine vertical alignment
      switch (vertical) {
        case 'top':
          y = -1.0;
          break;
        case 'center':
          y = 0.0;
          break;
        case 'bottom':
          y = 1.0;
          break;
        default:
          y = -1.0; // Default to top
      }

      return Alignment(x, y);
    }
    return const Alignment(-1.0, -1.0); // Default to top-left
  }

  BoxDecoration? _getCellBorder(Cell? cell, Styles styles) {
    if (cell == null) {
      return null;
    }

    if (cell.border == null) return null;

    BorderSide getBorderSide(BorderSideStyle? sideStyle) {
      if (sideStyle == null || sideStyle.style == null) {
        return BorderSide.none;
      }

      // Map Excel border styles to Flutter BorderSide
      double width;
      BorderStyle style;

      switch (sideStyle.style) {
        case 'thin':
          width = 1.0;
          style = BorderStyle.solid;
          break;
        case 'medium':
          width = 2.0;
          style = BorderStyle.solid;
          break;
        case 'thick':
          width = 3.0;
          style = BorderStyle.solid;
          break;
        case 'dashed':
          width = 1.0;
          style = BorderStyle.solid; // Flutter doesn't support dashed directly
          break;
        case 'dotted':
          width = 1.0;
          style = BorderStyle.solid; // Flutter doesn't support dotted directly
          break;
        default:
          width = 1.0;
          style = BorderStyle.solid;
      }

      // Parse color
      Color color = _parseColor(sideStyle, styles);

      return BorderSide(color: color, width: width, style: style);
    }

    return BoxDecoration(
      border: Border(
        left: getBorderSide(cell.border!.left),
        right: getBorderSide(cell.border!.right),
        top: getBorderSide(cell.border!.top),
        bottom: getBorderSide(cell.border!.bottom),
      ),
    );
  }

  Color _parseColor(BorderSideStyle sideStyle, Styles styles) {
    if (sideStyle.colorRgb != null) {
      // Parse RGB color
      final color = _colorFromARGBString(sideStyle.colorRgb!);
      if (color != null) {
        return color;
      }
    } else if (sideStyle.colorTheme != null) {
      // Get color from theme
      final themeIndex = sideStyle.colorTheme!;
      if (themeIndex >= 0 &&
          themeIndex < styles.colorMapping.themeColors.length) {
        return _colorFromARGBString(
              styles.colorMapping.themeColors[themeIndex],
            ) ??
            Colors.black; // Fallback to black if parsing fails
      }
    } else if (sideStyle.colorAuto == true) {
      // Auto color is usually black
      return Colors.black;
    }

    // Default color
    return Colors.black;
  }

  Color? _colorFromARGBString(String colorStr) {
    if (colorStr.length == 8) {
      final argb = int.tryParse(colorStr, radix: 16);
      if (argb != null) {
        return Color(int.parse(colorStr, radix: 16));
      }
    } else if (colorStr.length == 6) {
      final rgb = int.tryParse(colorStr, radix: 16);
      if (rgb != null) {
        return Color(0xFF000000 | rgb);
      }
    }
    return null;
  }
}

class OpenedFile extends InheritedWidget {
  OpenedFile({Key? key, required Widget child}) : super(key: key, child: child);

  final ValueNotifier<ExcelFileViewModel?> openedFileNotifier =
      ValueNotifier<ExcelFileViewModel?>(null);

  ExcelFileViewModel? get openedFile => openedFileNotifier.value;

  bool fileIsSelected(ExcelFileViewModel file) =>
      openedFileNotifier.value == file;
  openFile(ExcelFileViewModel file) => openedFileNotifier.value = file;

  static OpenedFile of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OpenedFile>()!;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

class SheetSelectionList extends StatelessWidget {
  final _sheetsScrollController = ScrollController();

  SheetSelectionList({super.key, required this.vm});

  final ImportExcelSheetsTaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final openedFile = OpenedFile.of(context);

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final newOffset =
              _sheetsScrollController.offset + event.scrollDelta.dy;
          if (event.scrollDelta.dy.isNegative) {
            _sheetsScrollController.jumpTo(max(0, newOffset));
          } else {
            _sheetsScrollController.jumpTo(
              min(_sheetsScrollController.position.maxScrollExtent, newOffset),
            );
          }
        }
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _sheetsScrollController,
        child: AnimatedBuilder(
          animation: openedFile.openedFileNotifier,
          builder: (BuildContext context, Widget? child) {
            if (openedFile.openedFileNotifier.value == null) {
              return const SizedBox.shrink();
            }
            final file = openedFile.openedFile!;
            final worksheets = file.excelFile.sheetNames;
            return Row(
              children: [
                for (var worksheet in worksheets)
                  SheetSelectionTile(vm: vm, file: file, worksheet: worksheet),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SheetSelectionTile extends StatelessWidget {
  const SheetSelectionTile({
    super.key,
    required this.vm,
    required this.file,
    required this.worksheet,
  });

  final ImportExcelSheetsTaskViewModel vm;
  final String worksheet;
  final ExcelFileViewModel file;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm.selectedWorksheetNotifier,
      builder:
          (context, child) => Container(
            decoration: ShapeDecoration(
              color: vm.sheetIsOpen(worksheet) ? Colors.white : Colors.white24,
              shape:
                  vm.sheetIsOpen(worksheet)
                      ? const Border(
                            bottom: BorderSide(color: Colors.green, width: 3),
                          ) +
                          const Border.symmetric(
                            vertical: BorderSide(
                              color: Colors.black54,
                              width: 1,
                            ),
                          )
                      : const Border.symmetric(
                        vertical: BorderSide(color: Colors.black54, width: 1),
                        horizontal: BorderSide(color: Colors.black12, width: 1),
                      ),
            ),
            child: InkWell(
              onTap: () {
                SheetScrollController.of(context).reset();
                vm.openSheet(file.excelFile[worksheet]);
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                child: Row(
                  children: [
                    SheetSelectionCheckbox(
                      vm: vm,
                      file: file,
                      worksheet: worksheet,
                    ),
                    Text(
                      worksheet,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class SheetSelectionCheckbox extends StatelessWidget {
  const SheetSelectionCheckbox({
    super.key,
    required this.vm,
    required this.file,
    required this.worksheet,
  });
  final ImportExcelSheetsTaskViewModel vm;
  final String worksheet;
  final ExcelFileViewModel file;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm.loadedSheetsByExcelFile,
      builder:
          (BuildContext context, Widget? child) => Checkbox(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity(horizontal: -3.5, vertical: -3.5),
            value: vm.sheetIsSelected(file, worksheet),
            onChanged: (value) {
              if (vm.sheetIsSelected(file, worksheet)) {
                vm.removeSheet(file: file, sheet: worksheet);
              } else {
                vm.addSheet(file: file, sheet: worksheet);
              }
            },
          ),
    );
  }
}

class FileSelectionList extends StatelessWidget {
  final _filesScrollController = ScrollController();

  FileSelectionList({super.key, required this.vm});

  final ImportExcelSheetsTaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    final excelFiles =
        SelectedTaskService.of(
          context,
        ).selectedTask?.importSheetTask.excelFiles ??
        [];

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final newOffset =
              _filesScrollController.offset + event.scrollDelta.dy;
          if (event.scrollDelta.dy.isNegative) {
            _filesScrollController.jumpTo(max(0, newOffset));
          } else {
            _filesScrollController.jumpTo(
              min(_filesScrollController.position.maxScrollExtent, newOffset),
            );
          }
        }
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _filesScrollController,
        child: Row(
          children: [
            for (var file in vm.excelFiles)
              FileSelectionTile(file: file, vm: vm),
          ],
        ),
      ),
    );
  }
}

class FileSelectionTile extends StatelessWidget {
  const FileSelectionTile({super.key, required this.file, required this.vm});

  final ImportExcelSheetsTaskViewModel vm;

  final ExcelFileViewModel file;

  @override
  Widget build(BuildContext context) {
    final openedFile = OpenedFile.of(context);
    return AnimatedBuilder(
      animation: OpenedFile.of(context).openedFileNotifier,
      builder:
          (context, child) => Container(
            decoration: ShapeDecoration(
              color:
                  openedFile.fileIsSelected(file)
                      ? Colors.white
                      : Colors.white24,
              shape:
                  openedFile.fileIsSelected(file)
                      ? const Border(
                            bottom: BorderSide(color: Colors.green, width: 3),
                          ) +
                          const Border.symmetric(
                            vertical: BorderSide(
                              color: Colors.black54,
                              width: 1,
                            ),
                          )
                      : const Border.symmetric(
                        vertical: BorderSide(color: Colors.black54, width: 1),
                        horizontal: BorderSide(color: Colors.black12, width: 1),
                      ),
            ),
            child: InkWell(
              onTap: () {
                openedFile.openFile(file);
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  children: [
                    FileSelectionCheckbox(file: file, vm: vm),
                    Text(
                      file.name,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class FileSelectionCheckbox extends StatelessWidget {
  const FileSelectionCheckbox({
    super.key,
    required this.file,
    required this.vm,
  });

  final ExcelFileViewModel file;
  final ImportExcelSheetsTaskViewModel vm;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm.loadedSheetsByExcelFile,
      builder:
          (BuildContext context, Widget? child) => Checkbox(
            visualDensity: VisualDensity(horizontal: -3.5, vertical: -3.5),
            value: vm.allSheetsOfFileSelected(file),
            onChanged: (value) {
              if (vm.allSheetsOfFileSelected(file)) {
                vm.clearSheetsForFile(file);
              } else {
                vm.addAllSheetsForFile(file);
              }
            },
          ),
    );
  }
}

class SelectCellsTaskListView extends StatefulWidget {
  const SelectCellsTaskListView({super.key});

  @override
  State<SelectCellsTaskListView> createState() =>
      _SelectCellsTaskListViewState();
}

class _SelectCellsTaskListViewState extends State<SelectCellsTaskListView> {
  Widget? selectCellsTaskListViewWidget;

  @override
  Widget build(BuildContext context) {
    return selectCellsTaskListViewWidget ??= buildSelectCellsTaskListView(
      context,
    );
  }

  Widget buildSelectCellsTaskListView(BuildContext context) {
    final selectedSheetService = SelectedSheetService.of(context);
    final excelSheetsTask = selectedSheetService.activeSheetTask!;

    taskListWidgetBuilder(context, snapshot) {
      List slivers = <Widget>[];

      final excelSheetsTaskHeader = Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: ImportExcelSheetsTaskListViewHeader(
              importSheetTask: excelSheetsTask,
            ),
          ),
          const Divider(),
        ],
      );
      slivers.add(SliverToBoxAdapter(child: excelSheetsTaskHeader));

      final topLevelExcelCellsTasks = excelSheetsTask.importExcelCellsTasks;
      if (topLevelExcelCellsTasks.isNotEmpty) {
        final stack = <ImportExcelCellsTaskViewModel>[];

        for (var topLevelExcelCellsTask in topLevelExcelCellsTasks.reversed) {
          stack.add(topLevelExcelCellsTask);
        }

        List cellTaskSlivers = <Widget>[];

        while (stack.isNotEmpty) {
          final current = stack.removeLast();

          final expanded = current.expanded;

          final nestedExcelCellsTaskHeader = Column(
            children: [
              Padding(
                padding: EdgeInsets.only(left: 20.0 * (2 + current.depth)),
                child: InheritedCellsTask(
                  child: ImportCellsTaskListViewHeader(),
                  taskViewModel: current,
                ),
              ),
              const Divider(height: 1),
            ],
          );
          cellTaskSlivers.add(nestedExcelCellsTaskHeader);
          if (expanded) {
            final nestedExcelCellsTasks = current.importExcelCellsTasks;
            for (var next in nestedExcelCellsTasks.reversed) {
              stack.add(next);
            }
          }
        }

        slivers.add(
          SliverPrototypeExtentList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => cellTaskSlivers[i],
              childCount: cellTaskSlivers.length,
            ),
            prototypeItem: cellTaskSlivers.first,
          ),
        );
      }

      return CustomScrollView(slivers: [...slivers]);
    }

    final treeChangedListenableBuilder = ListenableBuilder(
      listenable: excelSheetsTask.topViewModel,
      builder: taskListWidgetBuilder,
    );

    final sheetListenableBuilder = ListenableBuilder(
      listenable: selectedSheetService,
      builder: (context, child) => treeChangedListenableBuilder,
    );

    return sheetListenableBuilder;
  }
}

class ImportCellsTaskListViewHeader extends StatelessWidget {
  const ImportCellsTaskListViewHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    ValueNotifier<bool> aboveDragTargetHovered = ValueNotifier(false);

    ValueNotifier<bool> belowDragTargetHovered = ValueNotifier(false);

    return Listener(
      onPointerDown: (event) {
        if (event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(
              event.position.dx,
              event.position.dy,
              event.position.dx,
              event.position.dy,
            ),
            items: <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                onTap: () async {
                  final oldModel = importExcelCellsTask.taskModel;
                  importExcelCellsTask.remove();
                  final newTask =
                      importExcelCellsTask.parentTask
                          ?.addImportExcelCellsTaskViewModel();
                  newTask!.insertInside(oldModel);

                  importExcelCellsTask.topViewModel.treeChanged();
                },
                child: ListTile(
                  leading: Icon(Icons.account_tree, color: Colors.blueAccent),
                  title: Text(
                    AppLocalizations.of(context)!.embedLabelText,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                onTap: () async {
                  importExcelCellsTask.useTypedValue =
                      !importExcelCellsTask.useTypedValue;
                  importExcelCellsTask.topViewModel.treeChanged();
                },
                child: ListTile(
                  leading: const Icon(
                    Icons.text_fields,
                    color: Colors.blueAccent,
                  ),
                  title:
                      importExcelCellsTask.useTypedValue
                          ? Text(
                            AppLocalizations.of(
                              context,
                            )!.useCellSelectionLabelText,
                            style: Theme.of(context).textTheme.labelSmall,
                          )
                          : Text(
                            AppLocalizations.of(
                              context,
                            )!.enterValueManuallyLabelText,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                onTap: () async {
                  ShiftCellsController.of(context).toggleActive();
                },
                child: ListTile(
                  leading: Icon(Icons.open_with, color: Colors.blueAccent),
                  title: Text(
                    AppLocalizations.of(context)!.duplicateAndMoveCheckboxText,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                onTap: () async {
                  final serialized = serializers.serialize(
                    importExcelCellsTask.cellSelectionModel,
                  );
                  await Clipboard.setData(
                    ClipboardData(text: jsonEncode(serialized)),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blueAccent),
                  title: Text(
                    AppLocalizations.of(context)!.copyCellSelectionButtonText,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                onTap: () async {
                  final serialized = serializers.serialize(
                    importExcelCellsTask.taskModel,
                  );
                  await Clipboard.setData(
                    ClipboardData(text: jsonEncode(serialized)),
                  );
                },
                child: ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blueAccent),
                  title: Text(
                    AppLocalizations.of(context)!.copyTaskButtonText,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              PopupMenuItem<String>(
                child: ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blueAccent),
                  title: Text(
                    AppLocalizations.of(context)!.duplicateTaskButtonText,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                onTap: () async {
                  final parent = importExcelCellsTask.parentTask;
                  if (parent != null) {
                    parent.duplicate(importExcelCellsTask);
                    importExcelCellsTask.topViewModel.treeChanged();
                  } else {
                    assert(false);
                  }
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                child: FutureBuilder<CellSelection?>(
                  future: getCellSelectionFromClipboardOrNull(),
                  builder:
                      (context, cellSelection) => ListTile(
                        enabled: cellSelection.data != null,
                        title: Text(
                          AppLocalizations.of(
                            context,
                          )!.insertCellSelectionButtonText,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        leading: const Icon(
                          Icons.paste,
                          color: Colors.blueAccent,
                        ),
                        onTap: () async {
                          final cellSelectionData = cellSelection.data;
                          if (cellSelectionData != null) {
                            importExcelCellsTask.cellSelectionModel =
                                cellSelectionData;
                            importExcelCellsTask.topViewModel.treeChanged();
                          }
                        },
                      ),
                ),
              ),
              PopupMenuItem<String>(
                child: FutureBuilder<ImportCellsTask?>(
                  future: getImportCellTaskFromClipboardOrNull(),
                  builder:
                      (context, importCellsTaskModel) => ListTile(
                        enabled: importCellsTaskModel.data != null,
                        title: Text(
                          AppLocalizations.of(context)!.insertTaskButtonText,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        leading: const Icon(
                          Icons.paste,
                          color: Colors.blueAccent,
                        ),
                        onTap: () async {
                          final importCellsTaskModelData =
                              importCellsTaskModel.data;
                          if (importCellsTaskModelData != null) {
                            importExcelCellsTask.taskModel =
                                importCellsTaskModelData;
                            importExcelCellsTask.topViewModel.treeChanged();
                          }
                        },
                      ),
                ),
              ),
            ],
          );
        }
      },
      child: Draggable<ImportExcelCellsTaskViewModel>(
        data: importExcelCellsTask,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: aboveDragTargetHovered,
              builder:
                  (context, child) => DragTarget<ImportExcelCellsTaskViewModel>(
                    // DragTarget is not needed here
                    builder:
                        (context, candidateData, rejectedData) => Container(
                          color:
                              aboveDragTargetHovered.value
                                  ? Theme.of(context).hoverColor
                                  : null,
                          child: const SizedBox(
                            height: 5,
                            width: double.infinity,
                          ),
                        ),
                    onLeave: (data) => aboveDragTargetHovered.value = false,
                    onWillAcceptWithDetails: (DragTargetDetails details) {
                      var dropped = details.data;

                      final onWillAcceptWithDetails =
                          dropped != importExcelCellsTask &&
                          importExcelCellsTask.isNotChildOf(
                            potentialParent: dropped,
                          );

                      aboveDragTargetHovered.value = onWillAcceptWithDetails;
                      return onWillAcceptWithDetails;
                    },
                    onAcceptWithDetails: (DragTargetDetails details) {
                      final dropped =
                          details.data as ImportExcelCellsTaskViewModel;
                      final droppedTaskModel = dropped.taskModel;
                      dropped.remove();
                      importExcelCellsTask.insertAbove(droppedTaskModel);
                      importExcelCellsTask.topViewModel.treeChanged();
                    },
                  ),
            ),
            DragTarget<ImportExcelCellsTaskViewModel>(
              builder:
                  (context, candidateData, rejectedData) => InkWell(
                    child: Row(
                      children: [
                        ExpandToggle(),
                        Expanded(
                          child: Row(
                            children: [
                              SelectCellsTaskLabel(),
                              UseTypedValueWidget(),
                            ],
                          ),
                        ),
                        JoinWithCellsButton(),
                        LockShiftingButton(),
                        DeleteButton(),
                      ],
                    ),
                    onHover: (value) {},
                    onTap: () {
                      SelectedTaskService.of(context).selectedTask =
                          importExcelCellsTask;
                    },
                  ),
              onLeave: (data) => belowDragTargetHovered.value = false,
              onWillAcceptWithDetails: (
                DragTargetDetails<ImportExcelCellsTaskViewModel> details,
              ) {
                var dropped = details.data;

                return dropped != importExcelCellsTask &&
                    importExcelCellsTask.isNotChildOf(potentialParent: dropped);
              },
              onAcceptWithDetails: (
                DragTargetDetails<ImportExcelCellsTaskViewModel> details,
              ) {
                final dropped = details.data;
                final droppedTaskModel = dropped.taskModel;
                dropped.remove();
                importExcelCellsTask.insertInside(droppedTaskModel);
                importExcelCellsTask.topViewModel.treeChanged();
              },
            ),
            AnimatedBuilder(
              animation: belowDragTargetHovered,
              builder:
                  (context, child) => DragTarget<ImportExcelCellsTaskViewModel>(
                    // DragTarget is not needed here
                    builder:
                        (context, candidateData, rejectedData) => Container(
                          color:
                              belowDragTargetHovered.value
                                  ? Theme.of(context).hoverColor
                                  : null,
                          child: const SizedBox(
                            height: 5,
                            width: double.infinity,
                          ),
                        ),
                    onWillAcceptWithDetails: (
                      DragTargetDetails<ImportExcelCellsTaskViewModel> details,
                    ) {
                      var dropped = details.data;

                      final onWillAcceptWithDetails =
                          dropped != importExcelCellsTask &&
                          importExcelCellsTask.isNotChildOf(
                            potentialParent: dropped,
                          );
                      belowDragTargetHovered.value = onWillAcceptWithDetails;
                      return onWillAcceptWithDetails;
                    },
                    onAcceptWithDetails: (
                      DragTargetDetails<ImportExcelCellsTaskViewModel> details,
                    ) {
                      final dropped = details.data;
                      final droppedTaskModel = dropped.taskModel;
                      dropped.remove();
                      importExcelCellsTask.insertBelow(droppedTaskModel);
                      importExcelCellsTask.topViewModel.treeChanged();
                    },
                  ),
            ),
          ],
        ),
        feedback: Material(
          child: InheritedCellsTask(
            child: Row(
              children: [SelectCellsTaskLabel(), UseTypedValueWidget()],
            ),
            taskViewModel: importExcelCellsTask,
          ),
        ),
      ),
    );
  }
}

class ExpandToggle extends StatelessWidget {
  const ExpandToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    return InkWell(
      onTap: () {
        importExcelCellsTask.toggleExpanded();
      },
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(
          importExcelCellsTask.expanded ? Icons.expand_more : Icons.expand_less,
        ),
      ),
    );
  }
}

class UseTypedValueWidget extends StatelessWidget {
  const UseTypedValueWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    return Row(
      children: [
        if (importExcelCellsTask.useTypedValue)
          IntrinsicWidth(
            stepWidth: 150,
            child: Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.manualValueLabelText,
                ),
                focusNode: FocusNode(
                  onKeyEvent: (node, event) {
                    if (event.logicalKey == LogicalKeyboardKey.space) {
                      return KeyEventResult.skipRemainingHandlers;
                    } else {
                      return KeyEventResult.ignored;
                    }
                  },
                ),
                initialValue: importExcelCellsTask.typedValue,
                onChanged: (value) {
                  importExcelCellsTask.typedValue = value;
                  importExcelCellsTask.topViewModel.treeChanged();
                },
              ),
            ),
          ),
      ],
    );
  }
}

class SelectCellsTaskLabel extends StatelessWidget {
  const SelectCellsTaskLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    final cellIds = importExcelCellsTask.getCellIds();
    final cellValues = importExcelCellsTask.getCellValuesOfFirstSheet(
      amount: 3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!importExcelCellsTask.useTypedValue)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(children: <InlineSpan>[TextSpan(text: cellIds)]),
                style: Theme.of(context).textTheme.labelSmall,
              ),
              for (int i = 0; i < cellValues.length; i++)
                Flexible(
                  flex: 1,
                  child: Text.rich(
                    TextSpan(
                      children: <InlineSpan>[
                        TextSpan(
                          text: cellValues.length > i ? cellValues[i] : "???",
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (i < cellIds.length - 1) const TextSpan(text: ", "),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class DeleteButton extends StatelessWidget {
  const DeleteButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    return InkWell(
      child: const Padding(
        padding: EdgeInsets.all(5.0),
        child: Icon(Icons.delete_forever, color: Colors.redAccent),
      ),
      onTap: () {
        importExcelCellsTask.remove();
        importExcelCellsTask.topViewModel.treeChanged();
      },
    );
  }
}

class LockShiftingButton extends StatelessWidget {
  const LockShiftingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    return InkWell(
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Icon(
          importExcelCellsTask.shiftingLocked
              ? Icons.lock_sharp
              : Icons.lock_open_sharp,
          color:
              importExcelCellsTask.shiftingLocked
                  ? Colors.redAccent
                  : Colors.blueAccent,
        ),
      ),
      onTap: () async {
        importExcelCellsTask.shiftingLocked =
            !importExcelCellsTask.shiftingLocked;
      },
    );
  }
}

class JoinWithCellsButton extends StatelessWidget {
  const JoinWithCellsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ImportExcelCellsTaskViewModel importExcelCellsTask =
        InheritedCellsTask.of(context);

    return InkWell(
      child: const Padding(
        padding: EdgeInsets.all(5.0),
        child: Icon(Icons.add_link_sharp, color: Colors.greenAccent),
      ),
      onTap: () {
        final task = importExcelCellsTask.addImportExcelCellsTaskViewModel();

        SelectedTaskService.of(context).selectedTask = task;

        importExcelCellsTask.topViewModel.treeChanged();
      },
    );
  }
}

/// Little lock that appears in the top-left corner of a cell
/// while the *Shift-Cells* tool is active.
///
/// – It is shown **only** when the cell belongs to the current
///   Shift-Cells hierarchy.
/// – A single click toggles `shiftingLocked` for **all** tasks that
///   own that cell (stacked tasks are handled automatically).
class _LockToggleOverlay extends StatelessWidget {
  const _LockToggleOverlay({
    required this.rootTaskList,
    required this.columnIndex,
    required this.rowIndex,
    super.key,
  });

  final ImportExcelCellsTaskList rootTaskList; // usually vm.importSheetTask
  final int columnIndex;
  final int rowIndex;

  Set<ImportExcelCellsTaskViewModel> get tasks =>
      rootTaskList.findAllTasksByCell(columnIndex, rowIndex).toSet();
  bool get allLocked => tasks.every((t) => t.shiftingLocked);

  @override
  Widget build(BuildContext context) {
    if (ShiftCellsController.of(context).isInActive) {
      return const SizedBox.shrink();
    }

    // Every ImportExcelCellsTask that contains this cell
    final cellInSelectionHierarchy = rootTaskList.selectedCellGrids.findCell(
      y: rowIndex,
      x: columnIndex,
    );

    if (cellInSelectionHierarchy == null) {
      return const SizedBox.shrink();
    }

    final tasksHere =
        rootTaskList.findAllTasksByCell(columnIndex, rowIndex).toSet();

    // If every task is already locked ➜ show closed-lock icon

    return Positioned(
      top: 0,
      left: 0,
      child: InkWell(
        splashFactory: NoSplash.splashFactory,
        onTap: () {
          final newState = !allLocked; // toggle for *all* tasks
          for (final t in tasksHere) {
            t.shiftingLocked = newState;
          }

          rootTaskList.topViewModel.treeChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(
            allLocked ? Icons.lock : Icons.lock_open,
            size: 13,
            color: allLocked ? Colors.redAccent : Colors.blueAccent,
          ),
        ),
      ),
    );
  }
}

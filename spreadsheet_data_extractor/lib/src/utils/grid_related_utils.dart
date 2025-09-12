import 'dart:collection';
import 'dart:math';

import 'package:built_collection/built_collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:spreadsheet_data_extractor/src/models/models.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/worksheet.dart';

abstract class TaskCellSelection {
  bool get isEmpty;

  Rectangle<int> get boundingBox;

  TaskCellSelection copyWithDelta({required int deltaX, required int deltaY});

  SelectedCellGrid? toSelectedCellGrid();

  moveCells({required int deltaX, required int deltaY});

  SortedSelectedCellsList toSortedSelectedCellsList();

  bool cellIsSelected(int x, int y);

  SelectedCell? findCell(int x, int y);

  bool cellIsMerged(int x, int y);

  TaskCellSelection simplify();
}

class SingleCellSelection extends TaskCellSelection {
  final SelectedCell cell;

  SingleCellSelection(this.cell);

  @override
  TaskCellSelection copyWithDelta({required int deltaX, required int deltaY}) {
    return SingleCellSelection(
      SelectedCell(x: cell.x + deltaX, y: cell.y + deltaY),
    );
  }

  @override
  SelectedCellGrid? toSelectedCellGrid() {
    final grid = SelectedCellGrid();
    final row = grid.putIfAbsent(cell.y, () => SelectedCellRow());
    row[cell.x] = cell;
    return grid;
  }

  @override
  void moveCells({required int deltaX, required int deltaY}) {
    cell.x += deltaX;
    cell.y += deltaY;
  }

  @override
  SortedSelectedCellsList toSortedSelectedCellsList() {
    return SortedSelectedCellsList([cell]);
  }

  @override
  bool cellIsSelected(int x, int y) {
    return cell.x == x && cell.y == y;
  }

  @override
  bool cellIsMerged(int x, int y) {
    return false;
  }

  @override
  bool get isEmpty => false;

  @override
  Rectangle<int> get boundingBox => Rectangle<int>(cell.x, cell.y, 1, 1);

  @override
  SelectedCell? findCell(int x, int y) {
    if (cell.x == x && cell.y == y) {
      return cell;
    }
    return null;
  }

  @override
  TaskCellSelection simplify() {
    return this;
  }
}

class SelectedCellRow extends MapView<int, SelectedCell> {
  SelectedCellRow() : super(SplayTreeMap<int, SelectedCell>());
}

/// Represents a grid of selected cells.
///
/// This class extends [MapView] and provides functionality for managing a grid of selected cells.
/// It includes methods for moving cells within the grid, sorting selected cells, and converting the grid to a model.
class SelectedCellGrid extends MapView<int, SelectedCellRow>
    implements TaskCellSelection {
  SelectedCellGrid() : super(SplayTreeMap<int, SelectedCellRow>());

  factory SelectedCellGrid.copyWithDelta({
    required SelectedCellGrid from,
    required int deltaX,
    required int deltaY,
  }) {
    final newGrid = SelectedCellGrid();

    // Map original cell objects to their shifted copies
    final Map<SelectedCell, SelectedCell> map = {};

    // ---- Pass 1: create shifted cells and place them in the new grid
    for (final row in from.values) {
      for (final src in row.values) {
        final dst = SelectedCell(x: src.x + deltaX, y: src.y + deltaY);
        map[src] = dst;

        final newRow = newGrid.putIfAbsent(dst.y, () => SelectedCellRow());
        newRow[dst.x] = dst;
      }
    }

    // ---- Pass 2: replicate the links that existed in the source
    // Link right and bottom to avoid duplicating work.
    for (final row in from.values) {
      for (final src in row.values) {
        final dst = map[src]!;

        final r = src.rightNeighbor;
        if (r != null) {
          final dr = map[r];
          if (dr != null) {
            dst.rightNeighbor = dr;
            dr.leftNeighbor = dst;
          }
        }

        final b = src.bottomNeighbor;
        if (b != null) {
          final db = map[b];
          if (db != null) {
            dst.bottomNeighbor = db;
            db.topNeighbor = dst;
          }
        }
      }
    }

    return newGrid;
  }

  /// Constructs a [SelectedCellGrid] from a collection of selected cells.
  factory SelectedCellGrid.fromCells(Iterable<SelectedCell> cells) {
    final cellsMap = SelectedCellGrid();
    for (var cell in cells) {
      final row = cellsMap.putIfAbsent(cell.y, () => SelectedCellRow());
      row[cell.x] = cell;
    }

    return cellsMap;
  }

  void toggleCell(int x, int y) {
    final row = putIfAbsent(y, () => SelectedCellRow());

    final cell = row[x];
    if (cell == null) {
      row[x] = SelectedCell(x: x, y: y);
    } else {
      cell.informNeighborsOfRemoval();
      row.remove(x);
      if (row.isEmpty) {
        remove(y);
      }
    }
  }

  void toggleCells(Iterable<(int x, int y)> cellsToToggle) {
    for (final (int x, int y) in cellsToToggle) {
      toggleCell(x, y);
    }
  }

  /// Moves all cells within the grid by the specified delta values.
  @override
  void moveCells({int deltaX = 0, int deltaY = 0}) {
    final cells = values.expand((row) => row.values).toList();
    for (var cell in cells) {
      if (deltaX != 0) {
        cell.x += deltaX;
        //if (cell.x < 0) {
        //return;
        //}
      }
      if (deltaY != 0) {
        cell.y += deltaY;
        //if (cell.y < 0) {
        //return;
        //}
      }
    }
    clear();
    for (var cell in cells) {
      final row = putIfAbsent(cell.y, () => SelectedCellRow());
      row[cell.x] = cell;
    }
  }

  @override
  TaskCellSelection copyWithDelta({required int deltaX, required int deltaY}) {
    return SelectedCellGrid.copyWithDelta(
      from: this,
      deltaX: deltaX,
      deltaY: deltaY,
    );
  }

  @override
  SelectedCellGrid? toSelectedCellGrid() {
    return this;
  }

  @override
  SortedSelectedCellsList toSortedSelectedCellsList() {
    final all = <SelectedCell>[];
    for (final row in values) {
      all.addAll(row.values);
    }

    final toVisit = Queue<SelectedCell>.from(all);
    final seen = <SelectedCell>{};
    final grouped = <CellBase>{};

    while (toVisit.isNotEmpty) {
      final start = toVisit.removeFirst();
      if (!seen.add(start)) continue;

      final comp = <SelectedCell>{start};
      final q = Queue<SelectedCell>()..add(start);

      while (q.isNotEmpty) {
        final c = q.removeFirst();

        final nbs = <SelectedCell?>[
          c.rightNeighbor,
          c.leftNeighbor,
          c.topNeighbor,
          c.bottomNeighbor,
        ];

        for (final nb in nbs) {
          if (nb != null && !seen.contains(nb)) {
            seen.add(nb);
            comp.add(nb);
            q.add(nb);
            toVisit.remove(nb);
          }
        }
      }

      if (comp.length == 1) {
        final only = comp.first;
        grouped.add(SelectedCell(x: only.x, y: only.y));
      } else {
        grouped.add(MergedSelectedCell(cells: comp.toList()));
      }
    }

    return SortedSelectedCellsList(grouped);
  }

  String concatCombinedCellText(
    CombinedCell combined,
    String Function(int x, int y) textAt, {
    String sep = ' ',
  }) {
    final cells =
        combined.cells.toList()..sort(
          (a, b) => a.y != b.y ? a.y.compareTo(b.y) : a.x.compareTo(b.x),
        );
    return cells
        .map((c) => textAt(c.x, c.y))
        .where((s) => s.isNotEmpty)
        .join(sep);
  }

  @override
  bool cellIsSelected(int x, int y) {
    return this[y]?[x] != null;
  }

  @override
  bool cellIsMerged(int x, int y) {
    return this[y]?[x]?.hasNeighbors == true;
  }

  @override
  Rectangle<int> get boundingBox {
    int minX = double.maxFinite.toInt();
    int minY = double.maxFinite.toInt();
    int maxX = double.minPositive.toInt();
    int maxY = double.minPositive.toInt();

    for (final row in values) {
      for (final cell in row.values) {
        if (cell.x < minX) {
          minX = cell.x;
        }
        if (cell.x > maxX) {
          maxX = cell.x;
        }
        if (cell.y < minY) {
          minY = cell.y;
        }
        if (cell.y > maxY) {
          maxY = cell.y;
        }
      }
    }

    return Rectangle<int>(minX, minY, maxX - minX + 1, maxY - minY + 1);
  }

  @override
  SelectedCell? findCell(int x, int y) {
    final row = this[y];
    if (row == null) {
      return null;
    }
    final cell = row[x];
    if (cell == null) {
      return null;
    }
    return cell;
  }

  @override
  TaskCellSelection simplify() {
    if (length == 1) {
      return SingleCellSelection(values.first.values.first);
    }
    return this;
  }
}

abstract class SelectionBase {
  FoundCellInGrid? findCell({required int y, required int x});
  Rectangle<int> get boundingBox;
}

/// Represents a collection of selected cell grids.
///
/// This class extends [UnmodifiableListView] and provides functionality for managing a collection of grids
/// of selected cells. It includes methods for finding a cell with a specific value within the collection.
class SelectedCellGrids extends UnmodifiableListView<SelectionBase>
    implements SelectionBase {
  SelectedCellGrids(Iterable<SelectionBase> src)
    : super(List<SelectionBase>.unmodifiable(src));

  Rectangle<int>? _boundingBox;
  // Spatial index (lazy)
  List<int>? _r1, _c1, _r2, _c2, _pm, _order;
  bool _indexValid = false;

  void _invalidateAll() {
    _boundingBox = null;
    _indexValid = false;
    _r1 = _c1 = _r2 = _c2 = _pm = _order = null;
  }

  set boundingBox(Rectangle<int> value) {
    _boundingBox = value;
  }

  @override
  Rectangle<int> get boundingBox {
    if (_boundingBox != null) {
      return _boundingBox!;
    }

    int minX = double.maxFinite.toInt();
    int minY = double.maxFinite.toInt();
    int maxX = double.minPositive.toInt();
    int maxY = double.minPositive.toInt();
    for (var grid in this) {
      final childBoundingBox = grid.boundingBox;

      if (childBoundingBox.left < minX) {
        minX = childBoundingBox.left;
      }
      if (childBoundingBox.right > maxX) {
        maxX = childBoundingBox.right;
      }
      if (childBoundingBox.top < minY) {
        minY = childBoundingBox.top;
      }
      if (childBoundingBox.bottom > maxY) {
        maxY = childBoundingBox.bottom;
      }
    }

    _boundingBox = Rectangle(minX, minY, maxX - minX + 1, maxY - minY + 1);
    return _boundingBox!;
  }

  void _ensureIndex() {
    if (_indexValid) return;
    final m = length;
    final r1 = List<int>.filled(m, 0);
    final c1 = List<int>.filled(m, 0);
    final r2 = List<int>.filled(m, 0);
    final c2 = List<int>.filled(m, 0);
    final ord = List<int>.generate(m, (i) => i);

    for (var i = 0; i < m; i++) {
      final b = this[i].boundingBox;
      // Rectangle<int>(left, top, width, height)
      r1[i] = b.top;
      c1[i] = b.left;
      r2[i] = b.top + b.height - 1;
      c2[i] = b.left + b.width - 1;
    }
    // sort by (r1, c1), permuting arrays consistently
    ord.sort((a, b) {
      final dr = r1[a] - r1[b];
      return dr != 0 ? dr : (c1[a] - c1[b]);
    });
    final R1 = <int>[], C1 = <int>[], R2 = <int>[], C2 = <int>[];
    for (final i in ord) {
      R1.add(r1[i]);
      C1.add(c1[i]);
      R2.add(r2[i]);
      C2.add(c2[i]);
    }
    // prefix max of R2
    final PM = List<int>.filled(m, 0);
    var mx = -0x7fffffff;
    for (var i = 0; i < m; i++) {
      if (R2[i] > mx) mx = R2[i];
      PM[i] = mx;
    }

    _r1 = R1;
    _c1 = C1;
    _r2 = R2;
    _c2 = C2;
    _pm = PM;
    _order = ord;
    _indexValid = true;
  }

  int _upperBound(List<int> a, int x) {
    var lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] <= x)
        lo = mid + 1;
      else
        hi = mid;
    }
    return lo;
  }

  int _lowerBoundOnPrefixMax(List<int> pm, int x, int lo, int hi) {
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (pm[mid] >= x)
        hi = mid;
      else
        lo = mid + 1;
    }
    return lo;
  }

  int _upperBoundRange(List<int> a, int x, int lo, int hi) {
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] <= x)
        lo = mid + 1;
      else
        hi = mid;
    }
    return lo;
  }

  @override
  FoundCellInGrid? findCell({required int y, required int x}) {
    final bb = boundingBox;
    if (!bb.containsPoint(Point(x, y))) return null;

    // Fast path: small lists
    if (length <= 32) {
      for (var i = 0; i < length; i++) {
        final found = this[i].findCell(y: y, x: x);
        if (found != null) {
          final idx = found.indexOfTask > i ? found.indexOfTask : i;
          return FoundCellInGrid(indexOfTask: idx, cell: found.cell);
        }
      }
      return null;
    }

    // Indexed path
    _ensureIndex();
    final R1 = _r1!, C1 = _c1!, R2 = _r2!, C2 = _c2!, PM = _pm!, ORD = _order!;
    var hi = _upperBound(R1, y);
    if (hi == 0) return null;
    var lo = _lowerBoundOnPrefixMax(PM, y, 0, hi);
    if (lo >= hi) return null;
    var k = _upperBoundRange(C1, x, lo, hi) - 1;
    if (k < lo) return null;

    for (var i = k; i >= lo; i--) {
      if (C1[i] > x) break;
      if (y <= R2[i] && x <= C2[i]) {
        final childIdx = ORD[i];
        final found = this[childIdx].findCell(y: y, x: x);
        if (found != null) {
          final idx =
              found.indexOfTask > childIdx ? found.indexOfTask : childIdx;
          return FoundCellInGrid(indexOfTask: idx, cell: found.cell);
        }
      }
    }
    return null;
  }
}

class FoundCellInGrid {
  final int indexOfTask;

  SelectedCell cell;

  FoundCellInGrid({required this.indexOfTask, required this.cell});
}

class FoundCellInRepetitionProperties {
  final int indexOfRepetition;
  final int indexOfTask;
  SelectedCell cell;

  FoundCellInRepetitionProperties({
    required this.indexOfRepetition,
    required this.indexOfTask,
    required this.cell,
  });
}

enum CellAlignment { top, right, bottom, left }

class SheetDimensions {
  final int height;
  final int width;

  const SheetDimensions({required this.height, required this.width});
}

class Neighbors {
  SelectedCell? topNeighbor;
  SelectedCell? bottomNeighbor;
  SelectedCell? leftNeighbor;
  SelectedCell? rightNeighbor;

  Neighbors({
    this.topNeighbor,
    this.bottomNeighbor,
    this.leftNeighbor,
    this.rightNeighbor,
  });
}

class MergedSelectedCell extends CellBase {
  List<SelectedCell> cells;

  MergedSelectedCell({required this.cells});

  @override
  List<CellIndex> getCellIndex() {
    return cells
        .map((c) => CellIndex(rowIndex: c.y, columnIndex: c.x))
        .toList();
  }

  @override
  String getExcelCellId() {
    if (cells.isEmpty) {
      return "";
    }
    if (cells.length == 1) {
      final c = cells.first;
      return CellIndex(rowIndex: c.y, columnIndex: c.x).cellId;
    }
    final first = cells.first;
    final last = cells.last;
    final start = CellIndex(rowIndex: first.y, columnIndex: first.x).cellId;
    final end = CellIndex(rowIndex: last.y, columnIndex: last.x).cellId;
    return "$start:$end";
  }

  @override
  String getValue(ByteParsedWorksheet sheet) {
    return cells.map((c) => c.getValue(sheet)).join(" ");
  }
}

/// Represents a selected cell in a grid.
///
/// This class is used to model a cell with coordinates (x, y) in a grid,
/// along with its neighboring cells. It provides methods to update neighbors,
/// check neighbor validity, and inform neighbors of removal.
class SelectedCell extends CellBase {
  Neighbors? neighbors;

  SelectedCell? get topNeighbor => neighbors?.topNeighbor;
  SelectedCell? get bottomNeighbor => neighbors?.bottomNeighbor;
  SelectedCell? get leftNeighbor => neighbors?.leftNeighbor;
  SelectedCell? get rightNeighbor => neighbors?.rightNeighbor;

  set topNeighbor(SelectedCell? value) {
    neighbors ??= Neighbors();
    neighbors!.topNeighbor = value;
  }

  set bottomNeighbor(SelectedCell? value) {
    neighbors ??= Neighbors();
    neighbors!.bottomNeighbor = value;
  }

  set leftNeighbor(SelectedCell? value) {
    neighbors ??= Neighbors();
    neighbors!.leftNeighbor = value;
  }

  set rightNeighbor(SelectedCell? value) {
    neighbors ??= Neighbors();
    neighbors!.rightNeighbor = value;
  }

  int x;
  int y;

  /// Constructs a [SelectedCell] with the specified coordinates.
  SelectedCell({required this.x, required this.y});

  /// Constructs a [SelectedCell] from a [SingleCell].
  SelectedCell.fromSingleCell(SingleCell cell) : x = cell.x, y = cell.y;

  /// Indicates whether the cell has any neighbors.
  bool get hasNeighbors =>
      topNeighbor != null ||
      bottomNeighbor != null ||
      leftNeighbor != null ||
      rightNeighbor != null;

  bool get hasNoNeighbors => !hasNeighbors;

  /// Updates the neighboring cells of this cell.
  void updateNeighbors(SelectedCell neighbor) {
    if (neighbor.x == x - 1 && y == neighbor.y) {
      leftNeighbor = neighbor;
      neighbor.rightNeighbor = this;
    }
    if (neighbor.x == x + 1 && y == neighbor.y) {
      rightNeighbor = neighbor;
      neighbor.leftNeighbor = this;
    }
    if (x == neighbor.x && y - 1 == neighbor.y) {
      topNeighbor = neighbor;
      neighbor.bottomNeighbor = this;
    }
    if (x == neighbor.x && y + 1 == neighbor.y) {
      bottomNeighbor = neighbor;
      neighbor.topNeighbor = this;
    }
  }

  void updateNeigborsFromGrid(SelectedCellGrid grid) {
    final topCell = grid[y - 1]?[x];
    final rightCell = grid[y]?[x + 1];
    final bottomCell = grid[y + 1]?[x];
    final leftCell = grid[y]?[x - 1];

    if (x == topCell?.x && y - 1 == topCell?.y) {
      topNeighbor = topCell;
      topCell?.bottomNeighbor = this;
    }
    if (rightCell?.x == x + 1 && y == rightCell?.y) {
      rightNeighbor = rightCell;
      rightCell?.leftNeighbor = this;
    }

    if (x == bottomCell?.x && y + 1 == bottomCell?.y) {
      bottomNeighbor = bottomCell;
      bottomCell?.topNeighbor = this;
    }
    if (y == leftCell?.y && leftCell?.x == x - 1) {
      leftNeighbor = leftCell;
      leftCell?.rightNeighbor = this;
    }
  }

  /// Checks the validity of neighboring cells and updates them if needed.
  checkNeighborsValidity() {
    final topNeighbor = this.topNeighbor;
    if (topNeighbor != null && topNeighbor.y != y - 1) {
      topNeighbor.bottomNeighbor = null;
      this.topNeighbor = null;
    }
    final rightNeighbor = this.rightNeighbor;
    if (rightNeighbor != null && rightNeighbor.x != x + 1) {
      rightNeighbor.leftNeighbor = null;
      this.rightNeighbor = null;
    }
    final bottomNeighbor = this.bottomNeighbor;
    if (bottomNeighbor != null && bottomNeighbor.y != y + 1) {
      bottomNeighbor.topNeighbor = null;
      this.bottomNeighbor = null;
    }
    final leftNeighbor = this.leftNeighbor;
    if (leftNeighbor != null && leftNeighbor.x != x - 1) {
      leftNeighbor.rightNeighbor = null;
      this.leftNeighbor = null;
    }
  }

  /// Informs neighboring cells of the removal of this cell.
  ///
  /// Returns a list of cells that have been informed of the removal.
  void informNeighborsOfRemoval() {
    if (topNeighbor != null) {
      if (topNeighbor!.bottomNeighbor == this) {
        topNeighbor!.bottomNeighbor = null;
      }
    }
    if (bottomNeighbor != null) {
      if (bottomNeighbor!.topNeighbor == this) {
        bottomNeighbor!.topNeighbor = null;
      }
    }
    if (leftNeighbor != null) {
      if (leftNeighbor!.rightNeighbor == this) {
        leftNeighbor!.rightNeighbor = null;
      }
    }
    if (rightNeighbor != null) {
      if (rightNeighbor!.leftNeighbor == this) {
        rightNeighbor!.leftNeighbor = null;
      }
    }
  }

  @override
  String getValue(ByteParsedWorksheet sheet, {bool trim = true}) {
    final cell = sheet.cell(columnIndex: x, rowIndex: y);

    if (cell == null) {
      return "";
    }

    final cellSpan = cell.cellSpan;
    final dynamic cellValue;
    if (cellSpan != null) {
      cellValue =
          sheet
              .cell(
                columnIndex: cellSpan.start.columnIndex,
                rowIndex: cellSpan.start.rowIndex,
              )!
              .value;
    } else {
      cellValue = cell.value;
    }

    final text = cellValue.toString();

    if (trim) {
      final withoutLinebreaks = text.split("\n").fold<String>("", (
        previousValue,
        text,
      ) {
        final trimmedText = text.trim();
        if (previousValue.endsWith("-")) {
          return "$previousValue$trimmedText";
        } else {
          return "$previousValue $trimmedText";
        }
      });
      return withoutLinebreaks;
    } else {
      return text;
    }
  }

  @override
  String getExcelCellId() => CellIndex(rowIndex: y, columnIndex: x).cellId;
  @override
  List<CellIndex> getCellIndex() => [CellIndex(rowIndex: y, columnIndex: x)];
}

abstract class ImportCellsBase {
  List<String> getValues(ByteParsedWorksheet sheet);

  List<String> getCellIds(ByteParsedWorksheet sheet);

  const ImportCellsBase();
}

/// Represents a collection of cells imported from a sheet.
///
/// This class extends [ImportCellsBase] and provides implementations for
/// retrieving values and cell IDs from the imported cells.
class ImportCells extends ImportCellsBase {
  final List<CellBase> cells;

  /// Retrieves the values of all cells from the specified [sheet].
  ///
  /// Returns a list of strings representing the values of the cells.
  @override
  List<String> getValues(ByteParsedWorksheet sheet) {
    final values = <String>[];

    for (var cell in cells) {
      values.add(cell.getValue(sheet));
    }

    return values;
  }

  /// Retrieves the Excel cell IDs of all cells from the specified [sheet].
  ///
  /// Returns a list of strings representing the Excel cell IDs of the cells.
  @override
  List<String> getCellIds(ByteParsedWorksheet sheet) {
    final cellIds = <String>[];

    for (var cell in cells) {
      cellIds.add(cell.getExcelCellId());
    }

    return cellIds;
  }

  const ImportCells(this.cells);
}

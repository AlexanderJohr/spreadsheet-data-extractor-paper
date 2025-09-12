import 'dart:collection';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';

/// Represents a collection of [ColumnDefinition] objects.
///
/// Provides methods for managing column definitions and calculating column offsets.
class ColumnDefinitions extends UnmodifiableListView<ColumnDefinition> {
  @override
  final int length;
  final double defaultColWidth;

  // Band-level arrays (sorted by columnStart)
  late final List<int> _starts; // band start col (min)
  late final List<int> _ends; // band end col (max)
  late final List<double> _wEach; // width per col in band
  late final List<double> _bandStartOff; // absolute pixel offset at band start

  // Piecewise-constant “segments” for inverse lookup (offset -> col)
  // Each segment has constant column width, covers a contiguous col range.
  late final List<int> _segStartCol; // start column (1-based)
  late final List<double> _segStartOff; // offset at start (pixels)
  late final List<double> _segEndOff; // offset at end (pixels), last = +inf
  late final List<double> _segColWidth; // width per column in this segment

  ColumnDefinitions(List<ColumnDefinition> source, this.defaultColWidth)
    : length = source.length,
      super(
        List<ColumnDefinition>.from(source)
          ..sort((a, b) => a.columnStart.compareTo(b.columnStart)),
      ) {
    // Normalize band arrays
    _starts = List<int>.generate(length, (i) => this[i].columnStart);
    _ends = List<int>.generate(length, (i) => this[i].columnEnd);
    _wEach = List<double>.generate(length, (i) => this[i].widthOfEachColumn);

    // Precompute absolute offsets for each band start, and build segments (gaps + bands).
    _bandStartOff = List<double>.filled(length, 0);
    final segStartCol = <int>[];
    final segStartOff = <double>[];
    final segEndOff = <double>[];
    final segColWidth = <double>[];

    int nextCol = 1; // first column not yet covered
    double off = 0.0; // running pixel offset

    for (int i = 0; i < length; i++) {
      final start = _starts[i], end = _ends[i], w = _wEach[i];
      // Default-width gap before this band?
      if (nextCol < start) {
        segStartCol.add(nextCol);
        segStartOff.add(off);
        final gapLen = start - nextCol;
        off += gapLen * defaultColWidth;
        segEndOff.add(off);
        segColWidth.add(defaultColWidth);
        nextCol = start;
      }
      // This band segment
      _bandStartOff[i] = off;
      segStartCol.add(start);
      segStartOff.add(off);
      final bandLen = end - start + 1;
      off += bandLen * w;
      segEndOff.add(off);
      segColWidth.add(w);
      nextCol = end + 1;
    }
    // Trailing default segment (unbounded to the right)
    segStartCol.add(nextCol);
    segStartOff.add(off);
    segEndOff.add(double.infinity);
    segColWidth.add(defaultColWidth);

    _segStartCol = segStartCol;
    _segStartOff = segStartOff;
    _segEndOff = segEndOff;
    _segColWidth = segColWidth;
  }

  // ---------- Queries ----------

  // Width at a given column (A=1)
  double getColumnWidth(int columnIndex) {
    final i = _upperBoundInt(_starts, columnIndex) - 1;
    if (i >= 0 && columnIndex <= _ends[i]) return _wEach[i];
    return defaultColWidth;
  }

  // Absolute pixel offset of the left edge of columnIndex
  double getColumnOffset(int columnIndex) {
    final i = _upperBoundInt(_starts, columnIndex) - 1;
    if (i >= 0 && columnIndex <= _ends[i]) {
      // Inside band i
      return _bandStartOff[i] + (columnIndex - _starts[i]) * _wEach[i];
    }
    if (i >= 0) {
      // In default gap after band i
      final afterBand =
          _bandStartOff[i] + (_ends[i] - _starts[i] + 1) * _wEach[i];
      final gapCols = columnIndex - _ends[i] - 1;
      return afterBand + gapCols * defaultColWidth;
    }
    // Before first band: prefix default columns
    return (columnIndex - 1) * defaultColWidth;
  }

  // Inverse: given a horizontal pixel offset, return 1-based column index
  int getColumnIndexByOffset(double horizontalOffset) {
    if (horizontalOffset <= 0) return 1;

    // Find first segment whose endOffset > x (last segEnd is +inf, so found)
    final seg = _upperBoundDouble(_segEndOff, horizontalOffset);
    final startOff = _segStartOff[seg];
    final w = _segColWidth[seg];
    final startCol = _segStartCol[seg];

    final localCols = ((horizontalOffset - startOff) / w).floor();
    final col = startCol + localCols;
    return (col < 1) ? 1 : col;
  }

  // ---------- Helpers ----------

  static int _upperBoundInt(List<int> a, int x) {
    int lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] <= x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  static int _upperBoundDouble(List<double> a, double x) {
    int lo = 0, hi = a.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (a[mid] <= x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo; // index of first element > x
  }
}

class WorksheetColumn {
  final int index;
  final double offset;
  final double width;

  WorksheetColumn({
    required this.index,
    required this.offset,
    required this.width,
  });
}

const double columnWidthFactor = 7.00;
const double rowHeightFactor = 4 / 3;

/// Represents the definition of a single column or a set of columns.
/// Starting index of the column.
class ColumnDefinition {
  final int columnStart;

  final double startOffset;

  /// Ending index of the column.
  final int columnEnd;

  /// Number of columns.
  final int columnCount;

  /// Width of each column.
  final double widthOfEachColumn;

  /// Total width of all columns.
  final double widthOfAllColumns;

  WorksheetColumn get lastColumn => WorksheetColumn(
    index: columnEnd,
    offset: startOffset + getLocalColumnOffset(columnEnd),
    width: widthOfEachColumn,
  );

  /// Constructs a [ColumnDefinition] object.
  const ColumnDefinition({
    required this.columnStart,
    required this.columnEnd,
    required this.widthOfEachColumn,
    required this.widthOfAllColumns,
    required this.columnCount,
    required this.startOffset,
  });

  factory ColumnDefinition.fromParsedValues({
    required int parsedColumnStart,
    required int parsedColumnEnd,
    required double parsedWidth,
    double offset = 0,
  }) {
    final columnCount = parsedColumnEnd - parsedColumnStart + 1;

    final widthOfEachColumn = parsedWidth * columnWidthFactor;
    final widthOfAllColumns = widthOfEachColumn * columnCount;

    return ColumnDefinition(
      columnStart: parsedColumnStart,
      columnEnd: parsedColumnEnd,
      widthOfEachColumn: widthOfEachColumn,
      widthOfAllColumns: widthOfAllColumns,
      columnCount: columnCount,
      startOffset: offset,
    );
  }
  factory ColumnDefinition.fromString(
    String colXmlString, {
    double offset = 0,
    double baseColWidth = 64.0,
  }) {
    final minMatch = RegExp(r'\bmin="(\d+)"').firstMatch(colXmlString);
    final maxMatch = RegExp(r'\bmax="(\d+)"').firstMatch(colXmlString);
    final widthMatch = RegExp(r'\bwidth="([\d.]+)"').firstMatch(colXmlString);

    if (minMatch == null || maxMatch == null || widthMatch == null) {
      throw ArgumentError('Invalid <col> XML string: $colXmlString');
    }

    final columnStart = int.parse(minMatch.group(1)!);
    final columnEnd = int.parse(maxMatch.group(1)!);
    final columnCount = columnEnd - columnStart + 1;

    var parsedWidth = double.parse(widthMatch.group(1)!);
    if (parsedWidth == 0) {
      parsedWidth = baseColWidth;
    }

    final widthOfEachColumn = parsedWidth * columnWidthFactor;
    final widthOfAllColumns = widthOfEachColumn * columnCount;

    return ColumnDefinition(
      columnStart: columnStart,
      columnEnd: columnEnd,
      widthOfEachColumn: widthOfEachColumn,
      widthOfAllColumns: widthOfAllColumns,
      columnCount: columnCount,
      startOffset: offset,
    );
  }

  /// Calculates the local column offset for the given column index.
  ///
  /// The [columnIndex] parameter specifies the column index within the column definition.
  ///
  /// Returns the local column offset for the given column index.
  double getLocalColumnOffset(int columnIndex) {
    if (columnIndex < columnStart) {
      throw ArgumentError('Invalid column index.');
    }

    if (columnIndex > columnEnd) {
      return widthOfAllColumns;
    } else {
      final inclusiveCountOfColumns = columnIndex - columnStart;
      final localColumnOffset = inclusiveCountOfColumns * widthOfEachColumn;
      return localColumnOffset;
    }
  }

  /// Retrieves the leading column index for the given local horizontal offset.
  int getLeadingColumnIndex(double localHorizontalOffset) {
    if (localHorizontalOffset < 0) {
      throw ArgumentError('Invalid local horizontal offset.');
    }

    if (localHorizontalOffset > widthOfAllColumns) {
      throw ArgumentError('Invalid local horizontal offset.');
    }

    int leadingColumnIndex = localHorizontalOffset ~/ widthOfEachColumn;
    return leadingColumnIndex;
  }
}

abstract class Cell {
  dynamic get value;

  Font? get font;

  Fill? get fill;

  String? get numberFormat;

  BorderDefinition? get border;

  AlignmentDefinition? get alignment;

  CellSpan? get cellSpan;

  bool get hasFill;
  bool get hasNoFill;
  bool get hasBorder;
  bool get hasNoBorder;
  bool get isMergedCell;
  bool get isMergedCellOrigin;
  bool get hasValue;
  bool get hasNoValue;
}

/// Minimal value types (same as you had)
class CellIndex {
  final int rowIndex;
  final int columnIndex;
  const CellIndex({required this.rowIndex, required this.columnIndex});
  @override
  bool operator ==(Object o) =>
      o is CellIndex && o.rowIndex == rowIndex && o.columnIndex == columnIndex;
  @override
  int get hashCode => rowIndex ^ columnIndex;
  @override
  String toString() => 'R$rowIndex:C$columnIndex';

  String get cellId => '${_numericToLetters(columnIndex)}$rowIndex';

  String _numericToLetters(int number) {
    final letters = <String>[];

    while (number > 0) {
      var remainder = (number - 1) % 26;
      letters.add(String.fromCharCode(65 + remainder));
      number = (number - 1) ~/ 26;
    }

    return letters.reversed.join();
  }
}

class CellSpan {
  final CellIndex start; // top-left (normalized)
  final CellIndex end; // bottom-right (normalized)
  const CellSpan({required this.start, required this.end});
}

class CellSpans {
  // sorted by (r1, c1)
  final List<CellSpan> _cellSpans;

  // parallel arrays for speed
  final List<int> _r1;
  final List<int> _c1;
  final List<int> _r2;
  final List<int> _c2;

  // prefix max of r2 to quickly bound the left edge of the candidate window
  final List<int> _prefixMaxR2;

  // top-left origin map -> O(1) origin checks
  final Map<CellIndex, CellSpan> _origins;

  factory CellSpans(Iterable<CellSpan> spans) {
    final Map<CellIndex, CellSpan> cellSpanOrigins = <CellIndex, CellSpan>{};

    // normalize (defensive) and sort by (r1,c1)
    final cellSpans = List.of(
      spans.map((s) {
        int r1 = s.start.rowIndex, c1 = s.start.columnIndex;
        int r2 = s.end.rowIndex, c2 = s.end.columnIndex;
        if (r2 < r1) {
          final t = r1;
          r1 = r2;
          r2 = t;
        }
        if (c2 < c1) {
          final t = c1;
          c1 = c2;
          c2 = t;
        }
        return CellSpan(
          start: CellIndex(rowIndex: r1, columnIndex: c1),
          end: CellIndex(rowIndex: r2, columnIndex: c2),
        );
      }),
    );

    cellSpans.sort((a, b) {
      final dr = a.start.rowIndex - b.start.rowIndex;
      return (dr != 0) ? dr : (a.start.columnIndex - b.start.columnIndex);
    });

    final m = cellSpans.length;
    final rowStartIndices = List.filled(m, 0);
    final columnStartIndexes = List.filled(m, 0);
    final rowEndIndices = List.filled(m, 0);
    final columnEndIndices = List.filled(m, 0);
    final prefixMaxRowEndIndexes = List.filled(m, 0);

    int mx = -0x7fffffff;
    for (int i = 0; i < m; i++) {
      final s = cellSpans[i];
      final rowStartIndex = s.start.rowIndex;
      final columnStartIndex = s.start.columnIndex;
      final endRowIndex = s.end.rowIndex;
      final columnEndIndex = s.end.columnIndex;
      rowStartIndices[i] = rowStartIndex;
      columnStartIndexes[i] = columnStartIndex;
      rowEndIndices[i] = endRowIndex;
      columnEndIndices[i] = columnEndIndex;
      if (endRowIndex > mx) mx = endRowIndex;
      prefixMaxRowEndIndexes[i] = mx;
      cellSpanOrigins.putIfAbsent(s.start, () => s);
    }
    return CellSpans._(
      cellSpans,
      rowStartIndices,
      columnStartIndexes,
      rowEndIndices,
      columnEndIndices,
      prefixMaxRowEndIndexes,
      cellSpanOrigins,
    );
  }
  CellSpans._(
    this._cellSpans,
    this._r1,
    this._c1,
    this._r2,
    this._c2,
    this._prefixMaxR2,
    this._origins,
  );

  bool containsRC(int row, int col) => spanAtRC(row, col) != null;

  bool isOriginRC(int row, int col) =>
      _origins.containsKey(CellIndex(rowIndex: row, columnIndex: col));

  CellSpan? spanAtRC(int row, int col) {
    if (_cellSpans.isEmpty) return null;

    final int hi = _upperBound(_r1, row);
    if (hi == 0) return null;

    final int lo = _lowerBoundOnPrefixMax(_prefixMaxR2, row, 0, hi);
    if (lo >= hi) return null;

    int idx = _upperBoundRange(_c1, col, lo, hi) - 1; // last with c1 <= col
    if (idx < lo) return null;

    // 3) scan left while c1 <= col (usually 0..1 items in practice)
    for (int i = idx; i >= lo; i--) {
      if (_c1[i] > col) break;
      if (row <= _r2[i] && col <= _c2[i]) {
        return _cellSpans[i];
      }
      // if col > c2[i], earlier items have even smaller c2 expectation; keep going just in case
    }

    return null;
  }

  bool contains(CellIndex ci) => containsRC(ci.rowIndex, ci.columnIndex);
  bool isOrigin(CellIndex ci) => isOriginRC(ci.rowIndex, ci.columnIndex);
  CellSpan? spanAt(CellIndex ci) => spanAtRC(ci.rowIndex, ci.columnIndex);

  static int _upperBound(List<int> arr, int x) {
    int lo = 0, hi = arr.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (arr[mid] <= x)
        lo = mid + 1;
      else
        hi = mid;
    }
    return lo;
  }

  static int _lowerBoundOnPrefixMax(
    List<int> prefixMax,
    int x,
    int lo,
    int hi,
  ) {
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (prefixMax[mid] >= x)
        hi = mid;
      else
        lo = mid + 1;
    }
    return lo;
  }

  static int _upperBoundRange(List<int> arr, int x, int lo, int hi) {
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (arr[mid] <= x)
        lo = mid + 1;
      else
        hi = mid;
    }
    return lo;
  }
}

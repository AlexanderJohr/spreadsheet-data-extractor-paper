// Ultra-fast, no-decode worksheet scanner with lazy row/cell indexing.
// - ByteWorksheetParser locates <sheetData>, parses <mergeCells> after it, and
//   parses <sheetFormatPr> / <cols> before it (widths optional).
// - cell(columnIndex, rowIndex) lazily finds the row via a sync* generator,
//   which also extracts ht="..." (row height) if present and returns a ByteRow.
// - ByteRow lazily scans <c ...> cells via a sync* generator and caches ByteCell by column.
// - ByteCell exposes getters for s="...", t="...", <v>...</v>, and inline <is>...</is>.

import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/workbook.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/worksheet.dart';
import 'package:test/test.dart';

// ASCII sentinels
const int _lt = 60; // '<'
const int _gt = 62; // '>'
const int _sp = 32;
const int _tab = 9;
const int _lf = 10;
const int _cr = 13;
const int _dq = 34; // '"'
const int _sq = 39; // '\''
const int _slash = 47; // '/'
const int _eq = 61; // '='
const int _dash = 45; // '-'
const int _dot = 46; // '.'
const int _zero = 48; // '0'
const int _nine = 57; // '9'
const int _A = 65, _Z = 90, _a = 97, _z = 122;

// ASCII letters used in fixed tags/attr names
const int _r = 114, _o = 111, _w = 119; // row
const int _c = 99; // c
const int _s = 115; // s
const int _t = 116; // t
const int _h = 104; // h
const int _m = 109; // m
const int _n = 110; // n
const int _e = 101; // e
const int _f = 102; // f
const int _g = 103; // g
const int _l = 108; // l
const int _d = 100; // d
const int _i = 105; // i
const int _v = 118; // v
const int _x = 120; // x

// Fixed byte patterns
const List<int> _sheetDataOpenPat = <int>[
  60,
  115,
  104,
  101,
  101,
  116,
  68,
  97,
  116,
  97,
]; // "<sheetData"
const List<int> _sheetDataClosePat = <int>[
  60,
  47,
  115,
  104,
  101,
  101,
  116,
  68,
  97,
  116,
  97,
  62,
]; // "</sheetData>"
const List<int> _mergeCellsOpenPat = <int>[
  60,
  109,
  101,
  114,
  103,
  101,
  67,
  101,
  108,
  108,
  115,
]; // "<mergeCells"

const List<int> _mergeCellOpenPat = <int>[
  60,
  109,
  101,
  114,
  103,
  101,
  67,
  101,
  108,
  108,
]; // "<mergeCell"

const List<int> _mergeCellsClosePat = <int>[
  60,
  47,
  109,
  101,
  114,
  103,
  101,
  67,
  101,
  108,
  108,
  115,
  62,
]; // "</mergeCells>"
const List<int> _colsOpenPat = <int>[60, 99, 111, 108, 115]; // "<cols"
const List<int> _colsClosePat = <int>[
  60,
  47,
  99,
  111,
  108,
  115,
  62,
]; // "</cols>"
const List<int> _colOpenPat = <int>[60, 99, 111, 108]; // "<col"
const List<int> _sheetFormatPrPat = <int>[
  60,
  115,
  104,
  101,
  101,
  116,
  70,
  111,
  114,
  109,
  97,
  116,
  80,
  114,
]; // "<sheetFormatPr"

const List<int> _rowOpenPat = <int>[60, 114, 111, 119]; // "<row"

final List<int> _defaultRowHeightPat = const AsciiEncoder().convert(
  'defaultRowHeight',
);
final List<int> _defaultColWidthPat = const AsciiEncoder().convert(
  'defaultColWidth',
);

@pragma('vm:prefer-inline')
bool _isSpace(int b) => b == _sp || b == _tab || b == _lf || b == _cr;

@pragma('vm:prefer-inline')
int _findNextGt(Uint8List data, int from, int end) {
  for (int j = from; j < end; j++) {
    if (data[j] == _gt) return j;
  }
  return -1;
}

@pragma('vm:prefer-inline')
int _indexOfForward(Uint8List data, List<int> pat, int from, int end) {
  final int m = pat.length;
  final int last = end - m;
  final int p0 = pat[0];
  for (int i = from; i <= last; i++) {
    if (data[i] != p0) continue;
    int k = 1;
    while (k < m && data[i + k] == pat[k]) k++;
    if (k == m) return i;
  }
  return -1;
}

@pragma('vm:prefer-inline')
int _lastIndexOfBackward(
  Uint8List data,
  List<int> pat,
  int start /*inclusive*/,
  int end /*exclusive*/,
) {
  final int m = pat.length;
  final int lastStart = (end - m);
  for (int i = lastStart; i >= start; i--) {
    int k = 0;
    while (k < m && data[i + k] == pat[k]) k++;
    if (k == m) return i;
  }
  return -1;
}

@pragma('vm:prefer-inline')
(int, int)? getInnerAttrInterval(int i, int n, final Uint8List data) {
  while (i < n && _isSpace(data[i])) {
    i++;
  }
  if (i < n && data[i] == _eq) {
    i++;
    while (i < n && _isSpace(data[i])) {
      i++;
    }
    if (i < n && (data[i] == _dq || data[i] == _sq)) {
      final q = data[i++];
      final start = i;
      while (i < n && data[i] != q) {
        i++;
      }
      return (start, i);
    }
  }
  return null;
}

@pragma('vm:prefer-inline')
int _parseAsciiInt(Uint8List data, int from, int end) {
  int i = from;
  int sign = 1;
  if (i < end && data[i] == _dash) {
    sign = -1;
    i++;
  }
  int v = 0, d = 0;
  while (i < end) {
    final b = data[i];
    if (b >= _zero && b <= _nine) {
      v = v * 10 + (b - _zero);
      d++;
      i++;
      continue;
    }
    break;
  }
  return d == 0 ? 0 : sign * v;
}

@pragma('vm:prefer-inline')
double? _parseAsciiDouble(Uint8List data, int from, int end) {
  int i = from;
  int sign = 1;
  if (i < end && data[i] == _dash) {
    sign = -1;
    i++;
  }
  int intPart = 0;
  int digits = 0;
  while (i < end) {
    final b = data[i];
    if (b >= _zero && b <= _nine) {
      intPart = intPart * 10 + (b - _zero);
      digits++;
      i++;
      continue;
    }
    break;
  }
  double v = intPart.toDouble();
  if (i < end && data[i] == _dot) {
    i++;
    double frac = 0.0;
    double div = 1.0;
    int fracDigits = 0;
    while (i < end) {
      final b = data[i];
      if (b >= _zero && b <= _nine) {
        frac = frac * 10.0 + (b - _zero);
        div *= 10.0;
        i++;
        fracDigits++;
        continue;
      }
      break;
    }
    if (fracDigits > 0) v += frac / div;
  }
  if (digits == 0) return null;
  return sign < 0 ? -v : v;
}

@pragma('vm:prefer-inline')
int _colLettersToIndex(Uint8List data, int from, int to) {
  int sum = 0;
  for (int i = from; i < to; i++) {
    final b = data[i];
    if (b >= _A && b <= _Z) {
      sum = sum * 26 + (b - _A + 1);
    } else if (b >= _a && b <= _z) {
      sum = sum * 26 + (b - _a + 1);
    } else {
      break;
    }
  }
  return sum;
}

/// No-decode worksheet scanner with lazy row/cell indexing.
/// - ByteWorksheetParser locates <sheetData>, parses <mergeCells> after it, and
///   parses <sheetFormatPr> / <cols> before it.
/// - cell(columnIndex, rowIndex) lazily finds the row via a sync* generator,
///   which also extracts ht="..." (row height) if present and returns a ByteRow.
/// - ByteRow lazily scans <c ...> cells via a sync* generator and caches ByteCell by column.
/// - ByteCell exposes getters for s="...", t="...", <v>...</v>, and inline <is>...</is>.
class ByteParsedWorksheet {
  final Workbook workbook;
  final String name;
  ArchiveFile sheetArchiveFile;
  final Uint8List bytes;

  int sheetDataOpenByte = -1;
  int afterSheetDataOpenGtByte = -1;
  int sheetDataCloseByte = -1;
  int afterSheetDataCloseByte = -1;
  int colsOpenByte = -1;
  int colsCloseByte = -1;

  // From <sheetFormatPr>
  double defaultRowHeight = 15.0;
  double defaultColWidth = 8.43;

  late CellSpans cellSpans;
  late ColumnDefinitions columnDefinitions;
  int maxColumnIndex = 0;
  int maxRowIndex = 0;
  double verticalExtent = 0.0;

  double sumOfRowHeights = 0;
  double countOfRowHeights = 0;

  final Map<int, ByteRow> rowCache = HashMap<int, ByteRow>();
  final List<int> _cachedRowIdxs = <int>[];

  late Iterator<ByteRow> rowIter;

  ByteParsedWorksheet({
    required this.sheetArchiveFile,
    required this.workbook,
    required this.name,
  }) : bytes = sheetArchiveFile.content {
    rowIter = rowsGenerator().iterator;
    _locateSheetData();

    cellSpans = _scanMergeCellsAfterAsSpans();

    final columnDefinitions = _scanColsAndSheetFormatBefore();
    this.columnDefinitions = ColumnDefinitions(
      columnDefinitions,
      defaultColWidth,
    );

    sumRowHeightsHtOnly();
    maxRowIndex = findLastRowNumberBackward()!;
    final rowsCountWithoutHeight = maxRowIndex - countOfRowHeights;
    verticalExtent =
        (sumOfRowHeights + rowsCountWithoutHeight * defaultRowHeight) *
        rowHeightFactor;
  }

  ByteCell? cell({required int columnIndex, required int rowIndex}) {
    final r = row(rowIndex);
    if (r == null) return null;
    return r.cell(columnIndex);
  }

  String value({required int columnIndex, required int rowIndex}) {
    final r = row(rowIndex);
    if (r == null) return "";
    final c = r.cell(columnIndex);
    if (c == null) return "";
    return c.value.toString();
  }

  // Public: get a cached row or scan until found; caches as it goes.
  ByteRow? row(int rowIndex) {
    final cached = rowCache[rowIndex];
    if (cached != null) return cached;

    while (rowIter.moveNext()) {
      final row = rowIter.current;
      rowCache.putIfAbsent(row.rowIndex, () => row);
      if (row.rowIndex == rowIndex) return row;
      if (row.rowIndex > rowIndex) break;
    }
    return rowCache[rowIndex];
  }

  void _cacheRow(ByteRow row) {
    if (rowCache.putIfAbsent(row.rowIndex, () => row) == row) {
      if (_cachedRowIdxs.isEmpty || _cachedRowIdxs.last != row.rowIndex) {
        _cachedRowIdxs.add(row.rowIndex);
      }
    }
  }

  double _bottomForIndex(int rowIndex) {
    final row = rowCache[rowIndex]!;
    final h = row.height ?? defaultRowHeight;
    return row.offset + h;
  }

  int _firstCachedGreaterThan(double target) {
    int lo = 0, hi = _cachedRowIdxs.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final bottom = _bottomForIndex(_cachedRowIdxs[mid]);
      if (target < bottom) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }

  int getRowIndexByOffset(double verticalOffset) {
    if (verticalOffset < 0) {
      throw ArgumentError('Vertical offset must be ≥ 0');
    }

    if (_cachedRowIdxs.isNotEmpty) {
      final lastIdx = _cachedRowIdxs.last;
      if (verticalOffset < _bottomForIndex(lastIdx)) {
        final i = _firstCachedGreaterThan(verticalOffset);
        if (i < _cachedRowIdxs.length) return _cachedRowIdxs[i];
      }
    }

    // 2) Else advance the iterator until we cross the offset or exhaust rows.
    int lastRowIndex = _cachedRowIdxs.isNotEmpty ? _cachedRowIdxs.last : 0;

    while (rowIter.moveNext()) {
      final row = rowIter.current;
      _cacheRow(row);
      lastRowIndex = row.rowIndex;

      final h = row.height ?? defaultRowHeight;
      final bottom = row.offset + h;
      if (verticalOffset < bottom) {
        return row.rowIndex;
      }
    }

    return lastRowIndex;
  }

  // ===== locate <sheetData> ... </sheetData> =====
  void _locateSheetData() {
    final int close = _lastIndexOfBackward(
      bytes,
      _sheetDataClosePat,
      0,
      bytes.length,
    );
    if (close < 0) return;
    sheetDataCloseByte = close;
    afterSheetDataCloseByte = close + _sheetDataClosePat.length;

    final int open = _indexOfForward(bytes, _sheetDataOpenPat, 0, bytes.length);
    if (open < 0) return;
    sheetDataOpenByte = open;
    final gt = _findNextGt(
      bytes,
      open + _sheetDataOpenPat.length,
      bytes.length,
    );
    afterSheetDataOpenGtByte = (gt >= 0) ? (gt + 1) : -1;
  }

  List<String> _scanMergeCellsAfter() {
    final List<String> mergeRefs = <String>[];

    if (afterSheetDataCloseByte <= 0) return mergeRefs;
    final tailStart = afterSheetDataCloseByte;
    final mcOpen = _indexOfForward(
      bytes,
      _mergeCellsOpenPat,
      tailStart,
      bytes.length,
    );
    if (mcOpen < 0) return mergeRefs;
    final mcOpenGt = _findNextGt(
      bytes,
      mcOpen + _mergeCellsOpenPat.length,
      bytes.length,
    );
    if (mcOpenGt < 0) return mergeRefs;
    final mcClose = _indexOfForward(
      bytes,
      _mergeCellsClosePat,
      mcOpenGt + 1,
      bytes.length,
    );
    final int blockEnd =
        (mcClose >= 0) ? mcClose + _mergeCellsClosePat.length : bytes.length;

    // Extract <mergeCell ref="A1:B3"/>
    int i = mcOpen;
    while (true) {
      final tag = _indexOfForward(
        bytes,
        const [60, 109, 101, 114, 103, 101, 67, 101, 108, 108],
        i,
        blockEnd,
      ); // "<mergeCell"
      if (tag < 0) break;
      final gt = _findNextGt(bytes, tag + 10, blockEnd);
      if (gt < 0) break;

      // find ref="...":
      int j = tag + 10;
      String? ref;
      while (j < gt) {
        // scan for r e f = "..."
        if (bytes[j] == _r &&
            (j + 2) < gt &&
            bytes[j + 1] == _e &&
            bytes[j + 2] == _f) {
          int k = j + 3;
          while (k < gt && _isSpace(bytes[k])) k++;
          if (k < gt && bytes[k] == _eq) {
            k++;
            while (k < gt && _isSpace(bytes[k])) k++;
            if (k < gt && (bytes[k] == _dq || bytes[k] == _sq)) {
              final q = bytes[k++];
              final start = k;
              while (k < gt && bytes[k] != q) k++;
              if (k <= gt) {
                ref = utf8Decoder.convert(bytes, start, k);
                break;
              }
            }
          }
        }
        j++;
      }
      if (ref != null) mergeRefs.add(ref);
      i = gt + 1;
    }
    return mergeRefs;
  }

  CellSpans _scanMergeCellsAfterAsSpans() {
    final spans = <CellSpan>[];
    if (afterSheetDataCloseByte <= 0) return CellSpans(spans);

    final tailStart = afterSheetDataCloseByte;
    final mcOpen = _indexOfForward(
      bytes,
      _mergeCellsOpenPat,
      tailStart,
      bytes.length,
    );
    if (mcOpen < 0) return CellSpans(spans);

    final mcOpenGt = _findNextGt(
      bytes,
      mcOpen + _mergeCellsOpenPat.length,
      bytes.length,
    );
    if (mcOpenGt < 0) return CellSpans(spans);

    final mcClose = _indexOfForward(
      bytes,
      _mergeCellsClosePat,
      mcOpenGt + 1,
      bytes.length,
    );
    final int blockEnd =
        (mcClose >= 0) ? mcClose + _mergeCellsClosePat.length : bytes.length;

    int i = mcOpen;
    while (true) {
      // "<mergeCell"
      final tag = _indexOfForward(bytes, _mergeCellOpenPat, i, blockEnd);
      if (tag < 0) break;
      final gt = _findNextGt(bytes, tag + _mergeCellOpenPat.length, blockEnd);
      if (gt < 0) break;

      // find ref="..."/'...'
      int j = tag + _mergeCellOpenPat.length;
      while (j < gt) {
        // r e f
        if (bytes[j] == _r &&
            j + 2 < gt &&
            bytes[j + 1] == _e &&
            bytes[j + 2] == _f) {
          int k = j + 3;
          while (k < gt && _isSpace(bytes[k])) {
            k++;
          }
          if (k < gt && bytes[k] == _eq) {
            k++;
            while (k < gt && _isSpace(bytes[k])) {
              k++;
            }
            if (k < gt && (bytes[k] == _dq || bytes[k] == _sq)) {
              final q = bytes[k++];
              final refStart = k;
              while (k < gt && bytes[k] != q) {
                k++;
              }
              final refEnd = k; // exclusive
              if (refEnd > refStart) {
                spans.add(_parseSpanRefBytes(bytes, refStart, refEnd));
              }
              break;
            }
          }
        }
        j++;
      }

      i = gt + 1;
    }
    return CellSpans(spans);
  }

  // ========== sheetFormatPr + cols before <sheetData> ==========
  List<ColumnDefinition> _scanColsAndSheetFormatBefore() {
    List<ColumnDefinition> columnDefinitions = [];

    if (sheetDataOpenByte <= 0) return columnDefinitions;
    final limit = sheetDataOpenByte;

    // --- sheetFormatPr: parse defaultRowHeight, defaultColWidth ---
    final sfp = _indexOfForward(bytes, _sheetFormatPrPat, 0, limit);
    if (sfp >= 0) {
      final tagEndGt = _findNextGt(
        bytes,
        sfp + _sheetFormatPrPat.length,
        limit,
      );
      if (tagEndGt >= 0) {
        final val1 = _parseAttrDouble(
          bytes,
          sfp,
          tagEndGt,
          _defaultRowHeightPat,
        );
        if (val1 != null) defaultRowHeight = val1;
        final val2 = _parseAttrDouble(
          bytes,
          sfp,
          tagEndGt,
          _defaultColWidthPat,
        );
        if (val2 != null && val2 > 0) defaultColWidth = val2;
      }
    }

    // cols/col (optional): parse width
    colsOpenByte = _indexOfForward(bytes, _colsOpenPat, 0, limit);
    if (colsOpenByte >= 0) {
      final colsOpenGt = _findNextGt(
        bytes,
        colsOpenByte + _colsOpenPat.length,
        limit,
      );
      if (colsOpenGt >= 0) {
        colsCloseByte = _indexOfForward(
          bytes,
          _colsClosePat,
          colsOpenGt + 1,
          limit,
        );
        final int blockEnd =
            (colsCloseByte >= 0) ? colsCloseByte + _colsClosePat.length : limit;
        int i = colsOpenByte;
        while (true) {
          final colOpen = _indexOfForward(bytes, _colOpenPat, i, blockEnd);
          if (colOpen < 0) break;
          final colGt = _findNextGt(
            bytes,
            colOpen + _colOpenPat.length,
            blockEnd,
          );
          if (colGt < 0) break;

          int? minIdx, maxIdx;
          double? width;

          // scan attributes until '>'
          int j = colOpen + 4;
          while (j < colGt) {
            // min=".."
            if (bytes[j] == _m &&
                j + 2 < colGt &&
                bytes[j + 1] == _i &&
                bytes[j + 2] == _n) {
              int k = j + 3;
              while (k < colGt && _isSpace(bytes[k])) k++;
              if (k < colGt && bytes[k] == _eq) {
                k++;
                while (k < colGt && _isSpace(bytes[k])) k++;
                if (k < colGt && (bytes[k] == _dq || bytes[k] == _sq)) {
                  final q = bytes[k++], start = k;
                  while (k < colGt && bytes[k] != q) k++;
                  minIdx = _parseAsciiInt(bytes, start, k);
                }
              }
            }
            // max=".."
            else if (bytes[j] == _m &&
                j + 2 < colGt &&
                bytes[j + 1] == _a &&
                bytes[j + 2] == _x) {
              int k = j + 3;
              while (k < colGt && _isSpace(bytes[k])) k++;
              if (k < colGt && bytes[k] == _eq) {
                k++;
                while (k < colGt && _isSpace(bytes[k])) k++;
                if (k < colGt && (bytes[k] == _dq || bytes[k] == _sq)) {
                  final q = bytes[k++], start = k;
                  while (k < colGt && bytes[k] != q) k++;
                  maxIdx = _parseAsciiInt(bytes, start, k);
                }
              }
            }
            // width=".."
            else if (bytes[j] == _w &&
                j + 4 < colGt &&
                bytes[j + 1] == _i &&
                bytes[j + 2] == _d &&
                bytes[j + 3] == _t &&
                bytes[j + 4] == _h) {
              int k = j + 5;
              while (k < colGt && _isSpace(bytes[k])) k++;
              if (k < colGt && bytes[k] == _eq) {
                k++;
                while (k < colGt && _isSpace(bytes[k])) k++;
                if (k < colGt && (bytes[k] == _dq || bytes[k] == _sq)) {
                  final q = bytes[k++], start = k;
                  while (k < colGt && bytes[k] != q) k++;
                  width = _parseAsciiDouble(bytes, start, k);
                }
              }
            }

            j++;
          }

          if (minIdx != null && maxIdx != null) {
            if (width == null || width == 0) {
              width = defaultColWidth;
            }

            final columnDefinition = ColumnDefinition.fromParsedValues(
              parsedColumnStart: minIdx,
              parsedColumnEnd: maxIdx,
              parsedWidth: width,
            );
            columnDefinitions.add(columnDefinition);
          }

          i = colGt + 1;
        }
      }
    }

    return columnDefinitions;
  }

  @pragma('vm:prefer-inline')
  double? _parseAttrDouble(
    Uint8List data,
    int tagStart,
    int tagGt,
    List<int> namePat,
  ) {
    final nameAt = _indexOfForward(data, namePat, tagStart, tagGt);
    if (nameAt < 0) return null;
    int k = nameAt + namePat.length;
    while (k < tagGt && _isSpace(data[k])) k++;
    if (k >= tagGt || data[k] != _eq) return null;
    k++;
    while (k < tagGt && _isSpace(data[k])) k++;
    if (k >= tagGt || (data[k] != _dq && data[k] != _sq)) return null;
    final q = data[k++];
    final start = k;
    while (k < tagGt && data[k] != q) k++;
    return _parseAsciiDouble(data, start, k);
  }

  Iterable<ByteRow> rowsGenerator() sync* {
    final data = bytes;
    final int n = sheetDataCloseByte;
    if (afterSheetDataOpenGtByte < 0 || sheetDataCloseByte < 0) return;

    int? prevRowNum;
    int? prevRowStart;
    double? prevRowHt;
    double prevRowOffsetTop = 0.0;

    int i = afterSheetDataOpenGtByte;
    while (i <= n - 4) {
      if (data[i] == _lt &&
          data[i + 1] == _r &&
          data[i + 2] == _o &&
          data[i + 3] == _w &&
          data[i + 4] == _sp) {
        final int rowStart = i;

        int j = i + 5;
        int? currRowNum;
        double? currHt;
        while (j < n) {
          final int bj = data[j];
          if (bj == _gt) {
            j++;
            break;
          }
          final int pv = data[j - 1];

          // r="123"
          if (bj == _r && _isSpace(pv)) {
            int k = j + 1;
            final innerAttributeInterval = getInnerAttrInterval(k, n, data);
            if (innerAttributeInterval != null) {
              final (attrStart, attrEnd) = innerAttributeInterval;
              currRowNum = _parseAsciiInt(data, attrStart, attrEnd);
            }
          }
          // ht="nn.nn"
          else if (bj == _h &&
              (j + 1) < n &&
              data[j + 1] == _t &&
              _isSpace(pv)) {
            int k = j + 2;
            final innerAttributeInterval = getInnerAttrInterval(k, n, data);
            if (innerAttributeInterval != null) {
              final (attrStart, attrEnd) = innerAttributeInterval;
              currHt = _parseAsciiDouble(data, attrStart, attrEnd);
            }
          }
          j++;
        }
        if (j > n) break; // malformed at end

        // Compute the offset for the CURRENT row (top of this row),
        // using previous row info + gaps
        double currentOffsetTop;
        if (prevRowNum == null) {
          // rows before the first encountered row
          final int before = (currRowNum ?? 1) - 1;
          currentOffsetTop = (before > 0) ? before * defaultRowHeight : 0.0;
        } else {
          final int gap = (currRowNum ?? (prevRowNum + 1)) - prevRowNum - 1;
          final double prevHeightUsed = (prevRowHt ?? defaultRowHeight);
          currentOffsetTop =
              prevRowOffsetTop +
              prevHeightUsed * rowHeightFactor +
              (gap > 0 ? gap * defaultRowHeight : 0.0) * rowHeightFactor;
        }

        // We can now finalize and emit the PREVIOUS row (its end is current rowStart)
        if (prevRowNum != null && prevRowStart != null) {
          final prev = ByteRow._(
            this,
            prevRowNum!,
            prevRowStart!,
            rowStart,
            height: (prevRowHt ?? defaultRowHeight) * rowHeightFactor,
            offset: prevRowOffsetTop,
          );
          _cacheRow(prev);
          yield prev;
        }

        // Shift window: current -> previous
        prevRowNum = currRowNum;
        prevRowStart = rowStart;
        prevRowHt = currHt;
        prevRowOffsetTop = currentOffsetTop;

        // continue scanning after this row's open tag
        i = j;
        continue;
      }
      i++;
    }

    // Flush last row (ends at </sheetData>)
    if (prevRowNum != null && prevRowStart != null) {
      final last = ByteRow._(
        this,
        prevRowNum!,
        prevRowStart!,
        sheetDataCloseByte,
        height: prevRowHt,
        offset: prevRowOffsetTop,
      );
      _cacheRow(last);
      yield last;
    }
  }

  /// Scans once through <sheetData> and sums all row `ht="..."` values (as doubles).
  sumRowHeightsHtOnly() {
    if (afterSheetDataOpenGtByte < 0 || sheetDataCloseByte < 0) return 0.0;
    final b = bytes;
    final int end = sheetDataCloseByte;
    int i = afterSheetDataOpenGtByte;
    sumOfRowHeights = 0.0;
    countOfRowHeights = 0.0;

    while (i <= end - 2) {
      // fast check: attribute name must be exactly 'ht' starting at a boundary
      if (b[i] == _h && b[i + 1] == _t) {
        final int prev = (i > 0) ? b[i - 1] : _sp;
        final bool atBoundary = _isSpace(prev) || prev == _lt;
        if (atBoundary) {
          int k = i + 2;
          // optional spaces
          while (k < end && _isSpace(b[k])) k++;
          // '='
          if (k < end && b[k] == _eq) {
            k++;
            while (k < end && _isSpace(b[k])) k++;
            if (k < end && (b[k] == _dq || b[k] == _sq)) {
              final int q = b[k++];
              final int valStart = k;
              while (k < end && b[k] != q) k++;
              // parse double between quotes
              final double? v = _parseAsciiDouble(b, valStart, k);
              if (v != null) {
                sumOfRowHeights += v;
                countOfRowHeights++;
              }
              // jump past closing quote (or end)
              i = (k < end) ? (k + 1) : end;
              continue; // keep scanning
            }
          }
        }
      }
      i++;
    }
  }

  // Inside WorksheetParser:
  int? findLastRowNumberBackward() {
    if (afterSheetDataOpenGtByte < 0 || sheetDataCloseByte < 0) return null;

    // Search the last "<row" within the sheetData range.
    final int rowTag = _lastIndexOfBackward(
      bytes,
      _rowOpenPat,
      afterSheetDataOpenGtByte, // start (inclusive)
      sheetDataCloseByte, // end   (exclusive)
    );
    if (rowTag < 0) return null;

    // Find end of the opening tag '>'
    final int gt = _findNextGt(
      bytes,
      rowTag + _rowOpenPat.length,
      sheetDataCloseByte,
    );
    if (gt < 0) return null;

    // Scan attributes in <row ...> to get r="123"
    final b = bytes;
    final int attrStart = rowTag + _rowOpenPat.length;
    int j = attrStart;
    while (j < gt) {
      final int bj = b[j];

      // Attribute name must be exactly 'r' at a boundary (space or '<')
      if (bj == _r) {
        final int prev = (j > attrStart) ? b[j - 1] : _sp;
        final bool atBoundary = _isSpace(prev) || prev == _lt;
        if (atBoundary) {
          int k = j + 1;
          while (k < gt && _isSpace(b[k])) k++;
          if (k < gt && b[k] == _eq) {
            k++;
            while (k < gt && _isSpace(b[k])) k++;
            if (k < gt && (b[k] == _dq || b[k] == _sq)) {
              final int q = b[k++];
              // parse digits
              final int numStart = k;
              while (k < gt && b[k] >= _zero && b[k] <= _nine) k++;
              final int rowNum = _parseAsciiInt(b, numStart, k);
              // ensure closing quote present (best effort)
              if (k < gt && b[k] == q) return rowNum;
              return rowNum; // still return even if quote missing; up to you
            }
          }
        }
      }
      j++;
    }

    return null; // r= not found on that row tag
  }

  @override
  String toString() {
    return name;
  }
}

class ByteRow {
  final ByteParsedWorksheet _ws;
  final int rowIndex;
  final int start; // byte position of '<' in <row
  final int end; // byte position of next <row or </sheetData> (exclusive)
  final double? height; // ht attribute if present
  final double offset; // cumulative height BEFORE this row
  late Iterator<ByteCell> cellIter;

  ByteRow._(
    this._ws,
    this.rowIndex,
    this.start,
    this.end, {
    this.height,
    required this.offset,
  }) {
    cellIter = cellsSync().iterator;
    final lastColumnIndex = lastCellColumnIndexBackward();
    if (lastColumnIndex != null && lastColumnIndex > _ws.maxColumnIndex) {
      _ws.maxColumnIndex = lastColumnIndex;
    }
  }

  final Map<int, ByteCell> _cellCache = <int, ByteCell>{};

  ByteCell? cell(int columnIndex) {
    final cached = _cellCache[columnIndex];
    if (cached != null) return cached;

    while (cellIter.moveNext()) {
      final bc = cellIter.current;

      if (bc.hasValue || bc.hasFill || bc.hasBorder) {
        _cellCache[bc.colIndex] = bc;
        if (bc.colIndex == columnIndex) return bc;
      }
      if (bc.colIndex > columnIndex) break;
    }
    return null;
  }

  ByteCell? operator [](int columnIndex) {
    return cell(columnIndex);
  }

  /// Scans backward from `end` to find the last `<c ...>` in this row
  /// and returns its column index (A=1, B=2, ...). Returns null if none.
  int? lastCellColumnIndexBackward() {
    final b = _ws.bytes;
    // we need to look at [i-1]=='<' and [i]=='c'
    int i = end - 1;

    while (i >= start + 1) {
      if (b[i - 1] == _lt && b[i] == _c) {
        final int cStart = i - 1;

        // Find the '>' that closes the opening <c ...> (could be "/>")
        final int gt = _findNextGt(b, cStart + 2, end);
        if (gt < 0) return null; // malformed tail

        // Parse attributes inside <c ...> looking for r="A123"
        int j = cStart + 2;
        while (j < gt) {
          final int bj = b[j];

          // r="A123" at an attribute boundary
          if (bj == _r) {
            final int prev = (j > cStart + 2) ? b[j - 1] : _sp;
            final bool atBoundary = _isSpace(prev);
            if (atBoundary) {
              int k = j + 1;
              while (k < gt && _isSpace(b[k])) k++;
              if (k < gt && b[k] == _eq) {
                k++;
                while (k < gt && _isSpace(b[k])) k++;
                if (k < gt && (b[k] == _dq || b[k] == _sq)) {
                  final int q = b[k++];
                  // letters = column
                  final int lettersStart = k;
                  while (k < gt) {
                    final int ch = b[k];
                    final bool isLetter =
                        (ch >= _A && ch <= _Z) || (ch >= _a && ch <= _z);
                    if (!isLetter) break;
                    k++;
                  }
                  final int colIdx = _colLettersToIndex(b, lettersStart, k);
                  // skip numeric row part to closing quote
                  while (k < gt && b[k] >= _zero && b[k] <= _nine) k++;
                  // we’ve got the column either way
                  return colIdx > 0 ? colIdx : null;
                }
              }
            }
          }
          j++;
        }

        // If this <c ...> didn't have r="...", keep searching earlier cells
        i = cStart - 1;
        continue;
      }

      i--;
    }

    return null; // no <c found in this row
  }

  /// Ultra-fast generator for <c ...> cells in this row. Yields (colIndex, start, endExclusive).
  Iterable<ByteCell> cellsSync() sync* {
    final data = _ws.bytes;
    final int n = end;
    int i = start;

    while (i <= n - 2) {
      // look for "<c"
      if (data[i] == _lt && data[i + 1] == _c) {
        final int cStart = i;
        // parse attributes until '>'
        int j = i + 2;
        int? colIdx;

        while (j < n) {
          final int bj = data[j];
          if (bj == _gt) {
            j++;
            break;
          }

          // r="A123"
          if (bj == _r) {
            final int prev = (j > i + 2) ? data[j - 1] : _sp;
            if (_isSpace(prev)) {
              int k = j + 1;
              while (k < n && _isSpace(data[k])) k++;
              if (k < n && data[k] == _eq) {
                k++;
                while (k < n && _isSpace(data[k])) k++;
                if (k < n && (data[k] == _dq || data[k] == _sq)) {
                  final q = data[k++];
                  final lettersStart = k;
                  while (k < n) {
                    final b = data[k];
                    final isLetter =
                        (b >= _A && b <= _Z) || (b >= _a && b <= _z);
                    if (!isLetter) break;
                    k++;
                  }
                  colIdx = _colLettersToIndex(data, lettersStart, k);
                  // skip numeric row part to closing quote
                  while (k < n && data[k] >= _zero && data[k] <= _nine) k++;
                  if (k < n && data[k] == q) {
                    // good; continue to '>'
                  }
                }
              }
            }
          }
          j++;
        }
        if (j > n) break;

        // end of this cell = next "<c" start or row end
        int k = j;
        int nextC = -1;
        while (k <= n - 2) {
          if (data[k] == _lt && data[k + 1] == _c) {
            nextC = k;
            break;
          }
          k++;
        }
        final int cEnd = (nextC >= 0) ? nextC : n;

        if (colIdx != null) {
          var byteCell = ByteCell(_ws, cStart, cEnd, rowIndex, colIdx);
          _cellCache[colIdx] = byteCell;
          yield byteCell;
        }

        i = cEnd;
        continue;
      }

      i++;
    }
  }
}

class ByteCell extends Cell {
  final ByteParsedWorksheet _ws;
  Uint8List get bytes => _ws.bytes;
  final int start;
  final int end;
  final int rowIndex;
  final int colIndex;

  ByteCell(this._ws, this.start, this.end, this.rowIndex, this.colIndex);

  int? _styleIndex;
  String? _typeAttr;
  Object? _vCached; // int (shared string index) or String
  String? _isCached;

  int? get styleIndex {
    if (_styleIndex != null) return _styleIndex;
    final b = bytes;
    final int gt = _findNextGt(b, start + 2, end);
    if (gt < 0) return null;

    int j = start + 2;
    while (j < gt) {
      if (b[j] == _s) {
        // s="int"
        int k = j + 1;
        while (k < gt && _isSpace(b[k])) k++;
        if (k < gt && b[k] == _eq) {
          k++;
          while (k < gt && _isSpace(b[k])) k++;
          if (k < gt && (b[k] == _dq || b[k] == _sq)) {
            final q = b[k++];
            final startNum = k;
            while (k < gt && b[k] >= _zero && b[k] <= _nine) k++;
            _styleIndex = _parseAsciiInt(b, startNum, k);
          }
        }
      }
      j++;
    }
    return _styleIndex;
  }

  String? get typeAttr {
    if (_typeAttr != null) return _typeAttr;
    final b = bytes;
    final int gt = _findNextGt(b, start + 2, end);
    if (gt < 0) return null;

    int j = start + 2;
    while (j < gt) {
      if (b[j] == _t) {
        // t="str"
        int k = j + 1;
        while (k < gt && _isSpace(b[k])) k++;
        if (k < gt && b[k] == _eq) {
          k++;
          while (k < gt && _isSpace(b[k])) k++;
          if (k < gt && (b[k] == _dq || b[k] == _sq)) {
            final q = b[k++];
            final startStr = k;
            while (k < gt && b[k] != q) k++;
            _typeAttr = utf8Decoder.convert(b, startStr, k);
            return _typeAttr;
          }
        }
      }
      j++;
    }
    return null;
  }

  /// Content of <v>...</v>
  /// - If t=="s": returns int (shared string index)
  /// - Else: returns decoded String
  Object? get v {
    if (_vCached != null) return _vCached;
    final b = bytes;
    // find "<v>"
    int i = start;
    // '<' 'v' '>'
    while (i <= end - 3) {
      if (b[i] == _lt && b[i + 1] == _v && b[i + 2] == _gt) {
        final vStart = i + 3;
        // find "</v>"
        int k = vStart;
        while (k <= end - 4) {
          if (b[k] == _lt &&
              b[k + 1] == _slash &&
              b[k + 2] == _v &&
              b[k + 3] == _gt) {
            final vEnd = k;
            final t = typeAttr;
            if (t == 's') {
              _vCached = _parseAsciiInt(b, vStart, vEnd);
            } else {
              var convert = utf8Decoder.convert(b, vStart, vEnd);
              _vCached = convert;
            }
            return _vCached;
          }
          k++;
        }
        break;
      }
      i++;
    }
    return null;
  }

  /// Inline string inside <is> ... <t> ... </t> ... </is>
  String? get inlineString {
    if (_isCached != null) return _isCached;
    final b = bytes;

    // Find "<is"
    int i = start;
    while (i <= end - 3) {
      if (b[i] == _lt && b[i + 1] == _i && b[i + 2] == _s) {
        final gt = _findNextGt(b, i + 3, end);
        if (gt < 0) break;
        final isStart = gt + 1;
        // Find "</is>"
        final isClose = _indexOfForward(
          b,
          const [60, 47, 105, 115, 62],
          isStart,
          end,
        ); // </is>
        final int blockEnd = (isClose >= 0) ? isClose : end;

        // Collect all <t>...</t>
        final sb = StringBuffer();
        int j = isStart;
        while (j <= blockEnd - 3) {
          if (b[j] == _lt && b[j + 1] == _t) {
            final tGt = _findNextGt(b, j + 2, blockEnd);
            if (tGt < 0) break;
            final txtStart = tGt + 1;
            final tClose = _indexOfForward(
              b,
              const [60, 47, 116, 62],
              txtStart,
              blockEnd,
            ); // </t>
            if (tClose < 0) break;
            sb.write(utf8Decoder.convert(b, txtStart, tClose));
            j = tClose + 4;
            continue;
          }
          j++;
        }
        _isCached = sb.isEmpty ? null : sb.toString();
        return _isCached;
      }
      i++;
    }
    return null;
  }

  @override
  AlignmentDefinition? get alignment {
    final styleIndex = this.styleIndex;
    if (styleIndex == null) return null;
    return _ws.workbook.styles.cellXfs[styleIndex].alignment;
  }

  @override
  BorderDefinition? get border {
    final styleIndex = this.styleIndex;
    if (styleIndex == null) return null;
    final borderId = _ws.workbook.styles.cellXfs[styleIndex].borderId;
    if (borderId == null) return null;
    return _ws.workbook.styles.borders[borderId];
  }

  @override
  bool get hasBorder {
    return border != null;
  }

  @override
  bool get hasNoBorder {
    return !hasBorder;
  }

  @override
  CellSpan? get cellSpan => _ws.cellSpans.spanAtRC(rowIndex, colIndex);

  @override
  Fill? get fill {
    final styleIndex = this.styleIndex;
    if (styleIndex == null) return null;
    final fillId = _ws.workbook.styles.cellXfs[styleIndex].fillId;
    if (fillId == null) return null;
    return _ws.workbook.styles.fills[fillId];
  }

  @override
  String? get numberFormat {
    final styleIndex = this.styleIndex;
    if (styleIndex == null) return null;
    final numFmtId = _ws.workbook.styles.cellXfs[styleIndex].numFmtId;
    if (numFmtId == null) return null;
    return _ws.workbook.styles.numberFormats[numFmtId];
  }

  @override
  Font? get font {
    final styleIndex = this.styleIndex;
    if (styleIndex == null) return null;
    final fontId = _ws.workbook.styles.cellXfs[styleIndex].fontId;
    if (fontId == null) return null;
    return _ws.workbook.styles.fonts[fontId];
  }

  @override
  bool get hasFill {
    return fill != null;
  }

  @override
  bool get hasNoFill {
    return !hasFill;
  }

  @override
  bool get hasValue {
    return value != null;
  }

  @override
  bool get hasNoValue {
    return !hasValue;
  }

  @override
  bool get isMergedCell => _ws.cellSpans.containsRC(rowIndex, colIndex);

  @override
  bool get isMergedCellOrigin => _ws.cellSpans.isOriginRC(rowIndex, colIndex);

  @override
  get value {
    if (typeAttr == 'inlineStr') {
      return inlineString!;
    }

    if (typeAttr == 's') {
      v as int;

      final ss = _ws.workbook.sharedStrings[v];
      if (ss == null) throw ArgumentError('Shared string $v not found');
      return ss;
    }
    return v;
  }
}

// Byte helpers (you likely already have _parseAsciiInt)
int _lettersToColBytes(Uint8List b, int from, int to) {
  int col = 0;
  for (int i = from; i < to; i++) {
    int c = b[i];
    if (c >= 97 && c <= 122) c -= 32; // a..z -> A..Z
    if (c < 65 || c > 90) break; // stop at first non-letter
    col = col * 26 + (c - 65 + 1);
  }
  return col;
}

CellIndex _parseCellIndexBytes(Uint8List b, int from, int to) {
  // letters
  int i = from;
  while (i < to) {
    final c = b[i];
    final isAZ = (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
    if (!isAZ) break;
    i++;
  }
  if (i == from) throw ArgumentError('Bad cell ref: no letters');
  final col = _lettersToColBytes(b, from, i);

  // digits
  if (i >= to) throw ArgumentError('Bad cell ref: no digits');
  final row = _parseAsciiInt(b, i, to);
  return CellIndex(rowIndex: row, columnIndex: col);
}

CellSpan _parseSpanRefBytes(Uint8List b, int from, int to) {
  // ref value looks like: A1:B3
  int sep = -1;
  for (int i = from; i < to; i++) {
    if (b[i] == 58) {
      sep = i;
      break;
    } // ':'
  }
  if (sep <= from || sep >= to - 1) {
    throw ArgumentError('Bad merge ref bytes (missing :)');
  }
  final a = _parseCellIndexBytes(b, from, sep);
  final c = _parseCellIndexBytes(b, sep + 1, to);

  int r1 = a.rowIndex, c1 = a.columnIndex;
  int r2 = c.rowIndex, c2 = c.columnIndex;
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
}

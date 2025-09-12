import 'dart:collection';
import 'dart:math';

import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:spreadsheet_data_extractor/src/utils/value_utils.dart';

abstract class IVector implements UnmodifiableListView<Value> {
  Value operator [](int index);
  int get length;
  IVector expanded(int newLength);
}

mixin ExpandVectorMixin implements UnmodifiableListView<Value> {
  /// Expands the [Vector] to the new length.
  ///
  /// If the current length of the list is 1, this method fills the list with values
  /// by repeating the first value to match the new length. Otherwise, it fills the
  /// list with "😕" values to match the new length.
  ///
  /// Returns a new [Vector] with the expanded length.
  IVector expanded(int newLength) {
    if (length == 1) {
      return _BroadcastVector(first, newLength);
    } else {
      return Vector([
        // insert old values first
        for (int i = 0; i < length; i++) this[i],
        // insert missing values
        for (int i = length; i < newLength; i++)
          const Value("😕", type: ValueType.errorWhenFilled),
      ]);
    }
  }
}

class _BroadcastVector extends UnmodifiableListView<Value>
    with ExpandVectorMixin
    implements IVector {
  final Value v;
  final int _len;
  _BroadcastVector(this.v, this._len) : super([v]);
  @override
  int get length => _len;
  @override
  Value operator [](int i) => v;
}

/// A list of [Value] objects directly extracted from Excel cells.
///
/// This class extends [UnmodifiableListView] and provides functionality for managing a list
/// of [Value] objects. It is used to store values extracted from Excel cells.
class Vector extends UnmodifiableListView<Value>
    with ExpandVectorMixin
    implements IVector {
  Vector(Iterable<Value> source) : super(source.toList());
  Vector.fromStringList(List<dynamic> dynamicList)
    : super(
        dynamicList.map((entry) {
          if (entry is Value) {
            return entry;
          }
          return Value(entry.valueToString());
        }).toList(),
      );

  /// Joins the [Vector] with a [Table].
  ///
  /// If the [Table] is empty, it creates a new [Table] with a single column
  /// containing the [Vector]. Otherwise, it duplicates the [Vector] and adds it
  /// as the first column to match the number of columns in the provided [Table].
  ///
  /// Returns a new [Table] representing the joined values.
  Table joinWithColumnList(Table columnList) {
    if (columnList.isEmpty) {
      return Table([
        Column([Vector(this)]),
      ]);
    }
    final duplicatedValuesForJoin = _BroadcastColumn(
      this,
      columnList.first.length,
    );

    final joinedValues = Table([duplicatedValuesForJoin, ...columnList]);

    return joinedValues;
  }
}

abstract class IColumn implements UnmodifiableListView<IVector> {
  IVector operator [](int index);
  int get length;
}

class _BroadcastColumn extends UnmodifiableListView<IVector>
    implements IColumn {
  final IVector v;
  final int _len;
  _BroadcastColumn(this.v, this._len) : super([v]);
  @override
  int get length => _len;
  @override
  IVector operator [](int i) => v;
}

/// A list of lists of values of Excel cells
/// It is used to  maintain the inner lists to ease joining
class Column extends UnmodifiableListView<IVector> implements IColumn {
  Column(Iterable<IVector> source) : super(source.toList());

  Column.fromNestedStringList(List<dynamic> dynamicList)
    : super(dynamicList.map((entry) => Vector.fromStringList(entry)).toList());
}

// A horizontal list of columns,
// each containing a list of tasks with their Lists of cell vlaues
class Table extends UnmodifiableListView<IColumn> {
  Table(Iterable<IColumn> source) : super(source.toList());

  Table.fromNestedStringList(List<dynamic> dynamicList)
    : super(
        dynamicList.map((entry) => Column.fromNestedStringList(entry)).toList(),
      );

  /// Gets the maximum length of the [Vector] objects in each column.
  ///
  /// Returns a list containing the maximum length of the [Vector] objects in each column.
  List<int> get maxValueListLengts {
    if (isNotEmpty) {
      final transponedLengthTable = [
        for (int y = 0; y < first.length; y++)
          [
            for (int x = 0; x < length; x++)
              y < this[x].length ? this[x][y].length : 0,
          ],
      ];
      final maxValueListLengts =
          transponedLengthTable
              .map(
                (row) => row.fold<int>(
                  0,
                  (previousValue, element) => max(previousValue, element),
                ),
              )
              .toList();
      return maxValueListLengts;
    } else {
      return [];
    }
  }

  /// Fills the innermost lists evenly with values to match the maximum length.
  ///
  /// Returns a new [Table] with the innermost lists filled evenly with values
  /// to match the maximum length of all lists in each column.
  Table get innermostsListsFilledEvenly {
    final maxValueListLengts = this.maxValueListLengts;

    final innermostsListsFilledEvenly = Table([
      for (int iSpalte = 0; iSpalte < length; iSpalte++)
        Column([
          for (int iList = 0; iList < this[iSpalte].length; iList++)
            this[iSpalte][iList].expanded(maxValueListLengts[iList]),
        ]),
    ]);

    return innermostsListsFilledEvenly;
  }

  /// Unpacks the innermost lists to a flat list of values.
  ///
  /// Returns a list of lists of [Value] objects representing the unpacked innermost lists.
  List<List<Value>> get innermostsListsUnpacked {
    final innermostsListsFilledEvenly = this.innermostsListsFilledEvenly;

    final innermostsListsUnpacked = [
      for (int iSpalte = 0; iSpalte < length; iSpalte++)
        [
          for (int iList = 0; iList < this[iSpalte].length; iList++)
            ...innermostsListsFilledEvenly[iSpalte][iList],
        ],
    ];

    return innermostsListsUnpacked;
  }

  /// Transposes the column list to switch rows and columns.
  ///
  /// Returns a new [Table] with rows and columns transposed.
  List<List<Value>> get transposed {
    final innermostsListsUnpacked = this.innermostsListsUnpacked;

    final transposed = [
      if (innermostsListsUnpacked.isNotEmpty)
        for (int y = 0; y < innermostsListsUnpacked.first.length; y++)
          [
            for (int x = 0; x < innermostsListsUnpacked.length; x++)
              if (innermostsListsUnpacked[x].isNotEmpty)
                y < innermostsListsUnpacked[x].length
                    ? innermostsListsUnpacked[x][y]
                    : const Value("😕", type: ValueType.missingWhenTransposed),
          ],
      // innermostsListsUnpacked.map((listOfValues) => y < listOfValues.length ? listOfValues[y] : "YYY").toList(),
    ];

    return transposed;
  }
}

// A List of Tables (List of Columns)
class TasksResultList extends UnmodifiableListView<Table> {
  TasksResultList(Iterable<Table> source) : super(source.toList());

  TasksResultList.fromNestedStringList(List<dynamic> dynamicList)
    : super(
        dynamicList.map((entry) => Table.fromNestedStringList(entry)).toList(),
      );

  /// Get the tables of all the children tasks
  ///
  /// Join the data of all child tasks and their children
  Table getCombinedColumnList() {
    if (isEmpty) {
      return Table([]);
    }

    final maxColumnListLength = map(
      (table) => table.length,
    ).fold<int>(0, (previousLength, length) => max(previousLength, length));
    final combinedList = Table([
      for (
        int iFlattenedColumn = 0;
        iFlattenedColumn < maxColumnListLength;
        iFlattenedColumn++
      )
        Column([
          for (int iTask = 0; iTask < length; iTask++)
            // for (int iSpalte = 0; iSpalte < childrenValues[iTask].length; iSpalte++)
            if (iFlattenedColumn < this[iTask].length)
              for (
                int iList = 0;
                iList < this[iTask][iFlattenedColumn].length;
                iList++
              )
                this[iTask][iFlattenedColumn][iList]
            else
              for (int iList = 0; iList < this[iTask].last.length; iList++)
                Vector([const Value.missingWhenCombined()]),
        ]),
    ]);
    return combinedList;
  }
}

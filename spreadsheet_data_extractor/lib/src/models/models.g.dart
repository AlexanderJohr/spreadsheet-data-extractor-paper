// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers =
    (new Serializers().toBuilder()
          ..add(CellIndexModel.serializer)
          ..add(CellSelection.serializer)
          ..add(CombinedCell.serializer)
          ..add(ExcelFileModel.serializer)
          ..add(ExcelSheet.serializer)
          ..add(ImportCellsTask.serializer)
          ..add(ImportExcelFilesTask.serializer)
          ..add(ImportExcelSheetsTask.serializer)
          ..add(ModifiedRow.serializer)
          ..add(SingleCell.serializer)
          ..add(TaskList.serializer)
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ImportCellsTask)]),
            () => new ListBuilder<ImportCellsTask>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [const FullType(ImportCellsTask)]),
            () => new ListBuilder<ImportCellsTask>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(BuiltSet, const [const FullType(String)]),
            ]),
            () => new MapBuilder<String, BuiltSet<String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ImportExcelFilesTask),
            ]),
            () => new ListBuilder<ImportExcelFilesTask>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(String),
              const FullType(ExcelSheet),
            ]),
            () => new MapBuilder<String, ExcelSheet>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(int),
              const FullType(BuiltMap, const [
                const FullType(int),
                const FullType(String),
              ]),
            ]),
            () => new MapBuilder<int, BuiltMap<int, String>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(int),
              const FullType(BuiltMap, const [
                const FullType(int),
                const FullType(CellIndexModel),
              ]),
            ]),
            () => new MapBuilder<int, BuiltMap<int, CellIndexModel>>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltMap, const [
              const FullType(int),
              const FullType(String),
            ]),
            () => new MapBuilder<int, String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(CellBase)]),
            () => new SetBuilder<CellBase>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(SingleCell)]),
            () => new SetBuilder<SingleCell>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltSet, const [const FullType(String)]),
            () => new SetBuilder<String>(),
          )
          ..addBuilderFactory(
            const FullType(BuiltList, const [
              const FullType(ImportExcelSheetsTask),
            ]),
            () => new ListBuilder<ImportExcelSheetsTask>(),
          ))
        .build();
Serializer<CellIndexModel> _$cellIndexModelSerializer =
    new _$CellIndexModelSerializer();
Serializer<ExcelSheet> _$excelSheetSerializer = new _$ExcelSheetSerializer();
Serializer<ExcelFileModel> _$excelFileModelSerializer =
    new _$ExcelFileModelSerializer();
Serializer<TaskList> _$taskListSerializer = new _$TaskListSerializer();
Serializer<ImportExcelFilesTask> _$importExcelFilesTaskSerializer =
    new _$ImportExcelFilesTaskSerializer();
Serializer<ModifiedRow> _$modifiedRowSerializer = new _$ModifiedRowSerializer();
Serializer<ImportExcelSheetsTask> _$importExcelSheetsTaskSerializer =
    new _$ImportExcelSheetsTaskSerializer();
Serializer<ImportCellsTask> _$importCellsTaskSerializer =
    new _$ImportCellsTaskSerializer();
Serializer<CellSelection> _$cellSelectionSerializer =
    new _$CellSelectionSerializer();
Serializer<SingleCell> _$singleCellSerializer = new _$SingleCellSerializer();
Serializer<CombinedCell> _$combinedCellSerializer =
    new _$CombinedCellSerializer();

class _$CellIndexModelSerializer
    implements StructuredSerializer<CellIndexModel> {
  @override
  final Iterable<Type> types = const [CellIndexModel, _$CellIndexModel];
  @override
  final String wireName = 'CellIndexModel';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    CellIndexModel object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'y',
      serializers.serialize(object.y, specifiedType: const FullType(int)),
      'x',
      serializers.serialize(object.x, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  CellIndexModel deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new CellIndexModelBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'y':
          result.y =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
        case 'x':
          result.x =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
      }
    }

    return result.build();
  }
}

class _$ExcelSheetSerializer implements StructuredSerializer<ExcelSheet> {
  @override
  final Iterable<Type> types = const [ExcelSheet, _$ExcelSheet];
  @override
  final String wireName = 'ExcelSheet';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ExcelSheet object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'maxRows',
      serializers.serialize(object.maxRows, specifiedType: const FullType(int)),
      'maxCols',
      serializers.serialize(object.maxCols, specifiedType: const FullType(int)),
      'sheetName',
      serializers.serialize(
        object.sheetName,
        specifiedType: const FullType(String),
      ),
      'data',
      serializers.serialize(
        object.data,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(int),
          const FullType(BuiltMap, const [
            const FullType(int),
            const FullType(String),
          ]),
        ]),
      ),
      'spanCells',
      serializers.serialize(
        object.spanCells,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(int),
          const FullType(BuiltMap, const [
            const FullType(int),
            const FullType(CellIndexModel),
          ]),
        ]),
      ),
    ];

    return result;
  }

  @override
  ExcelSheet deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ExcelSheetBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'maxRows':
          result.maxRows =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
        case 'maxCols':
          result.maxCols =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
        case 'sheetName':
          result.sheetName =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'data':
          result.data.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(int),
                const FullType(BuiltMap, const [
                  const FullType(int),
                  const FullType(String),
                ]),
              ]),
            )!,
          );
          break;
        case 'spanCells':
          result.spanCells.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(int),
                const FullType(BuiltMap, const [
                  const FullType(int),
                  const FullType(CellIndexModel),
                ]),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$ExcelFileModelSerializer
    implements StructuredSerializer<ExcelFileModel> {
  @override
  final Iterable<Type> types = const [ExcelFileModel, _$ExcelFileModel];
  @override
  final String wireName = 'ExcelFileModel';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ExcelFileModel object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'name',
      serializers.serialize(object.name, specifiedType: const FullType(String)),
      'path',
      serializers.serialize(object.path, specifiedType: const FullType(String)),
      'sheets',
      serializers.serialize(
        object.sheets,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(String),
          const FullType(ExcelSheet),
        ]),
      ),
    ];

    return result;
  }

  @override
  ExcelFileModel deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ExcelFileModelBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'name':
          result.name =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'path':
          result.path =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'sheets':
          result.sheets.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(ExcelSheet),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$TaskListSerializer implements StructuredSerializer<TaskList> {
  @override
  final Iterable<Type> types = const [TaskList, _$TaskList];
  @override
  final String wireName = 'TaskList';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    TaskList object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'childTasks',
      serializers.serialize(
        object.childTasks,
        specifiedType: const FullType(BuiltList, const [
          const FullType(ImportExcelFilesTask),
        ]),
      ),
    ];

    return result;
  }

  @override
  TaskList deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new TaskListBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'childTasks':
          result.childTasks.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(ImportExcelFilesTask),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$ImportExcelFilesTaskSerializer
    implements StructuredSerializer<ImportExcelFilesTask> {
  @override
  final Iterable<Type> types = const [
    ImportExcelFilesTask,
    _$ImportExcelFilesTask,
  ];
  @override
  final String wireName = 'ImportExcelFilesTask';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ImportExcelFilesTask object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'excelFilePaths',
      serializers.serialize(
        object.excelFilePaths,
        specifiedType: const FullType(BuiltSet, const [const FullType(String)]),
      ),
      'childTasks',
      serializers.serialize(
        object.childTasks,
        specifiedType: const FullType(BuiltList, const [
          const FullType(ImportExcelSheetsTask),
        ]),
      ),
    ];

    return result;
  }

  @override
  ImportExcelFilesTask deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ImportExcelFilesTaskBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'excelFilePaths':
          result.excelFilePaths.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(String),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'childTasks':
          result.childTasks.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(ImportExcelSheetsTask),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$ModifiedRowSerializer implements StructuredSerializer<ModifiedRow> {
  @override
  final Iterable<Type> types = const [ModifiedRow, _$ModifiedRow];
  @override
  final String wireName = 'ModifiedRow';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ModifiedRow object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'modifiedCells',
      serializers.serialize(
        object.modifiedCells,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(int),
          const FullType(String),
        ]),
      ),
    ];

    return result;
  }

  @override
  ModifiedRow deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ModifiedRowBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'modifiedCells':
          result.modifiedCells.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(int),
                const FullType(String),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$ImportExcelSheetsTaskSerializer
    implements StructuredSerializer<ImportExcelSheetsTask> {
  @override
  final Iterable<Type> types = const [
    ImportExcelSheetsTask,
    _$ImportExcelSheetsTask,
  ];
  @override
  final String wireName = 'ImportExcelSheetsTask';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ImportExcelSheetsTask object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'childTasks',
      serializers.serialize(
        object.childTasks,
        specifiedType: const FullType(BuiltList, const [
          const FullType(ImportCellsTask),
        ]),
      ),
      'sheetNamesByExcelFilePath',
      serializers.serialize(
        object.sheetNamesByExcelFilePath,
        specifiedType: const FullType(BuiltMap, const [
          const FullType(String),
          const FullType(BuiltSet, const [const FullType(String)]),
        ]),
      ),
    ];

    return result;
  }

  @override
  ImportExcelSheetsTask deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ImportExcelSheetsTaskBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'childTasks':
          result.childTasks.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(ImportCellsTask),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
        case 'sheetNamesByExcelFilePath':
          result.sheetNamesByExcelFilePath.replace(
            serializers.deserialize(
              value,
              specifiedType: const FullType(BuiltMap, const [
                const FullType(String),
                const FullType(BuiltSet, const [const FullType(String)]),
              ]),
            )!,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$ImportCellsTaskSerializer
    implements StructuredSerializer<ImportCellsTask> {
  @override
  final Iterable<Type> types = const [ImportCellsTask, _$ImportCellsTask];
  @override
  final String wireName = 'ImportCellsTask';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    ImportCellsTask object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'childTasks',
      serializers.serialize(
        object.childTasks,
        specifiedType: const FullType(BuiltList, const [
          const FullType(ImportCellsTask),
        ]),
      ),
      'cellSelection',
      serializers.serialize(
        object.cellSelection,
        specifiedType: const FullType(CellSelection),
      ),
    ];
    Object? value;
    value = object.typedValue;
    if (value != null) {
      result
        ..add('typedValue')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(String)),
        );
    }
    value = object.shiftingLocked;
    if (value != null) {
      result
        ..add('shiftingLocked')
        ..add(
          serializers.serialize(value, specifiedType: const FullType(bool)),
        );
    }
    return result;
  }

  @override
  ImportCellsTask deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new ImportCellsTaskBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'childTasks':
          result.childTasks.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltList, const [
                    const FullType(ImportCellsTask),
                  ]),
                )!
                as BuiltList<Object?>,
          );
          break;
        case 'typedValue':
          result.typedValue =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String?;
          break;
        case 'shiftingLocked':
          result.shiftingLocked =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )
                  as bool?;
          break;
        case 'cellSelection':
          result.cellSelection.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(CellSelection),
                )!
                as CellSelection,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$CellSelectionSerializer implements StructuredSerializer<CellSelection> {
  @override
  final Iterable<Type> types = const [CellSelection, _$CellSelection];
  @override
  final String wireName = 'CellSelection';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    CellSelection object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'cells',
      serializers.serialize(
        object.cells,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(CellBase),
        ]),
      ),
    ];

    return result;
  }

  @override
  CellSelection deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new CellSelectionBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'cells':
          result.cells.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(CellBase),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
      }
    }

    return result.build();
  }
}

class _$SingleCellSerializer implements StructuredSerializer<SingleCell> {
  @override
  final Iterable<Type> types = const [SingleCell, _$SingleCell];
  @override
  final String wireName = 'SingleCell';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    SingleCell object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'x',
      serializers.serialize(object.x, specifiedType: const FullType(int)),
      'y',
      serializers.serialize(object.y, specifiedType: const FullType(int)),
    ];

    return result;
  }

  @override
  SingleCell deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new SingleCellBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'x':
          result.x =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
        case 'y':
          result.y =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(int),
                  )!
                  as int;
          break;
      }
    }

    return result.build();
  }
}

class _$CombinedCellSerializer implements StructuredSerializer<CombinedCell> {
  @override
  final Iterable<Type> types = const [CombinedCell, _$CombinedCell];
  @override
  final String wireName = 'CombinedCell';

  @override
  Iterable<Object?> serialize(
    Serializers serializers,
    CombinedCell object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = <Object?>[
      'cells',
      serializers.serialize(
        object.cells,
        specifiedType: const FullType(BuiltSet, const [
          const FullType(SingleCell),
        ]),
      ),
      'separator',
      serializers.serialize(
        object.separator,
        specifiedType: const FullType(String),
      ),
      'trimValues',
      serializers.serialize(
        object.trimValues,
        specifiedType: const FullType(bool),
      ),
    ];

    return result;
  }

  @override
  CombinedCell deserialize(
    Serializers serializers,
    Iterable<Object?> serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = new CombinedCellBuilder();

    final iterator = serialized.iterator;
    while (iterator.moveNext()) {
      final key = iterator.current! as String;
      iterator.moveNext();
      final Object? value = iterator.current;
      switch (key) {
        case 'cells':
          result.cells.replace(
            serializers.deserialize(
                  value,
                  specifiedType: const FullType(BuiltSet, const [
                    const FullType(SingleCell),
                  ]),
                )!
                as BuiltSet<Object?>,
          );
          break;
        case 'separator':
          result.separator =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )!
                  as String;
          break;
        case 'trimValues':
          result.trimValues =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(bool),
                  )!
                  as bool;
          break;
      }
    }

    return result.build();
  }
}

class _$CellIndexModel extends CellIndexModel {
  @override
  final int y;
  @override
  final int x;

  factory _$CellIndexModel([void Function(CellIndexModelBuilder)? updates]) =>
      (new CellIndexModelBuilder()..update(updates))._build();

  _$CellIndexModel._({required this.y, required this.x}) : super._() {
    BuiltValueNullFieldError.checkNotNull(y, r'CellIndexModel', 'y');
    BuiltValueNullFieldError.checkNotNull(x, r'CellIndexModel', 'x');
  }

  @override
  CellIndexModel rebuild(void Function(CellIndexModelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CellIndexModelBuilder toBuilder() =>
      new CellIndexModelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CellIndexModel && y == other.y && x == other.x;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, y.hashCode);
    _$hash = $jc(_$hash, x.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CellIndexModel')
          ..add('y', y)
          ..add('x', x))
        .toString();
  }
}

class CellIndexModelBuilder
    implements Builder<CellIndexModel, CellIndexModelBuilder> {
  _$CellIndexModel? _$v;

  int? _y;
  int? get y => _$this._y;
  set y(int? y) => _$this._y = y;

  int? _x;
  int? get x => _$this._x;
  set x(int? x) => _$this._x = x;

  CellIndexModelBuilder();

  CellIndexModelBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _y = $v.y;
      _x = $v.x;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CellIndexModel other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CellIndexModel;
  }

  @override
  void update(void Function(CellIndexModelBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CellIndexModel build() => _build();

  _$CellIndexModel _build() {
    final _$result =
        _$v ??
        new _$CellIndexModel._(
          y: BuiltValueNullFieldError.checkNotNull(y, r'CellIndexModel', 'y'),
          x: BuiltValueNullFieldError.checkNotNull(x, r'CellIndexModel', 'x'),
        );
    replace(_$result);
    return _$result;
  }
}

class _$ExcelSheet extends ExcelSheet {
  @override
  final int maxRows;
  @override
  final int maxCols;
  @override
  final String sheetName;
  @override
  final BuiltMap<int, BuiltMap<int, String>> data;
  @override
  final BuiltMap<int, BuiltMap<int, CellIndexModel>> spanCells;

  factory _$ExcelSheet([void Function(ExcelSheetBuilder)? updates]) =>
      (new ExcelSheetBuilder()..update(updates))._build();

  _$ExcelSheet._({
    required this.maxRows,
    required this.maxCols,
    required this.sheetName,
    required this.data,
    required this.spanCells,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(maxRows, r'ExcelSheet', 'maxRows');
    BuiltValueNullFieldError.checkNotNull(maxCols, r'ExcelSheet', 'maxCols');
    BuiltValueNullFieldError.checkNotNull(
      sheetName,
      r'ExcelSheet',
      'sheetName',
    );
    BuiltValueNullFieldError.checkNotNull(data, r'ExcelSheet', 'data');
    BuiltValueNullFieldError.checkNotNull(
      spanCells,
      r'ExcelSheet',
      'spanCells',
    );
  }

  @override
  ExcelSheet rebuild(void Function(ExcelSheetBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExcelSheetBuilder toBuilder() => new ExcelSheetBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExcelSheet &&
        maxRows == other.maxRows &&
        maxCols == other.maxCols &&
        sheetName == other.sheetName &&
        data == other.data &&
        spanCells == other.spanCells;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, maxRows.hashCode);
    _$hash = $jc(_$hash, maxCols.hashCode);
    _$hash = $jc(_$hash, sheetName.hashCode);
    _$hash = $jc(_$hash, data.hashCode);
    _$hash = $jc(_$hash, spanCells.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExcelSheet')
          ..add('maxRows', maxRows)
          ..add('maxCols', maxCols)
          ..add('sheetName', sheetName)
          ..add('data', data)
          ..add('spanCells', spanCells))
        .toString();
  }
}

class ExcelSheetBuilder implements Builder<ExcelSheet, ExcelSheetBuilder> {
  _$ExcelSheet? _$v;

  int? _maxRows;
  int? get maxRows => _$this._maxRows;
  set maxRows(int? maxRows) => _$this._maxRows = maxRows;

  int? _maxCols;
  int? get maxCols => _$this._maxCols;
  set maxCols(int? maxCols) => _$this._maxCols = maxCols;

  String? _sheetName;
  String? get sheetName => _$this._sheetName;
  set sheetName(String? sheetName) => _$this._sheetName = sheetName;

  MapBuilder<int, BuiltMap<int, String>>? _data;
  MapBuilder<int, BuiltMap<int, String>> get data =>
      _$this._data ??= new MapBuilder<int, BuiltMap<int, String>>();
  set data(MapBuilder<int, BuiltMap<int, String>>? data) => _$this._data = data;

  MapBuilder<int, BuiltMap<int, CellIndexModel>>? _spanCells;
  MapBuilder<int, BuiltMap<int, CellIndexModel>> get spanCells =>
      _$this._spanCells ??=
          new MapBuilder<int, BuiltMap<int, CellIndexModel>>();
  set spanCells(MapBuilder<int, BuiltMap<int, CellIndexModel>>? spanCells) =>
      _$this._spanCells = spanCells;

  ExcelSheetBuilder();

  ExcelSheetBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _maxRows = $v.maxRows;
      _maxCols = $v.maxCols;
      _sheetName = $v.sheetName;
      _data = $v.data.toBuilder();
      _spanCells = $v.spanCells.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExcelSheet other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExcelSheet;
  }

  @override
  void update(void Function(ExcelSheetBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExcelSheet build() => _build();

  _$ExcelSheet _build() {
    _$ExcelSheet _$result;
    try {
      _$result =
          _$v ??
          new _$ExcelSheet._(
            maxRows: BuiltValueNullFieldError.checkNotNull(
              maxRows,
              r'ExcelSheet',
              'maxRows',
            ),
            maxCols: BuiltValueNullFieldError.checkNotNull(
              maxCols,
              r'ExcelSheet',
              'maxCols',
            ),
            sheetName: BuiltValueNullFieldError.checkNotNull(
              sheetName,
              r'ExcelSheet',
              'sheetName',
            ),
            data: data.build(),
            spanCells: spanCells.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'data';
        data.build();
        _$failedField = 'spanCells';
        spanCells.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'ExcelSheet',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$ExcelFileModel extends ExcelFileModel {
  @override
  final String name;
  @override
  final String path;
  @override
  final BuiltMap<String, ExcelSheet> sheets;

  factory _$ExcelFileModel([void Function(ExcelFileModelBuilder)? updates]) =>
      (new ExcelFileModelBuilder()..update(updates))._build();

  _$ExcelFileModel._({
    required this.name,
    required this.path,
    required this.sheets,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(name, r'ExcelFileModel', 'name');
    BuiltValueNullFieldError.checkNotNull(path, r'ExcelFileModel', 'path');
    BuiltValueNullFieldError.checkNotNull(sheets, r'ExcelFileModel', 'sheets');
  }

  @override
  ExcelFileModel rebuild(void Function(ExcelFileModelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExcelFileModelBuilder toBuilder() =>
      new ExcelFileModelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExcelFileModel &&
        name == other.name &&
        path == other.path &&
        sheets == other.sheets;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, path.hashCode);
    _$hash = $jc(_$hash, sheets.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExcelFileModel')
          ..add('name', name)
          ..add('path', path)
          ..add('sheets', sheets))
        .toString();
  }
}

class ExcelFileModelBuilder
    implements Builder<ExcelFileModel, ExcelFileModelBuilder> {
  _$ExcelFileModel? _$v;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _path;
  String? get path => _$this._path;
  set path(String? path) => _$this._path = path;

  MapBuilder<String, ExcelSheet>? _sheets;
  MapBuilder<String, ExcelSheet> get sheets =>
      _$this._sheets ??= new MapBuilder<String, ExcelSheet>();
  set sheets(MapBuilder<String, ExcelSheet>? sheets) => _$this._sheets = sheets;

  ExcelFileModelBuilder();

  ExcelFileModelBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _path = $v.path;
      _sheets = $v.sheets.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExcelFileModel other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ExcelFileModel;
  }

  @override
  void update(void Function(ExcelFileModelBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExcelFileModel build() => _build();

  _$ExcelFileModel _build() {
    _$ExcelFileModel _$result;
    try {
      _$result =
          _$v ??
          new _$ExcelFileModel._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ExcelFileModel',
              'name',
            ),
            path: BuiltValueNullFieldError.checkNotNull(
              path,
              r'ExcelFileModel',
              'path',
            ),
            sheets: sheets.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'sheets';
        sheets.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'ExcelFileModel',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$TaskList extends TaskList {
  @override
  final BuiltList<ImportExcelFilesTask> childTasks;

  factory _$TaskList([void Function(TaskListBuilder)? updates]) =>
      (new TaskListBuilder()..update(updates))._build();

  _$TaskList._({required this.childTasks}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      childTasks,
      r'TaskList',
      'childTasks',
    );
  }

  @override
  TaskList rebuild(void Function(TaskListBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  TaskListBuilder toBuilder() => new TaskListBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is TaskList && childTasks == other.childTasks;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, childTasks.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'TaskList')
      ..add('childTasks', childTasks)).toString();
  }
}

class TaskListBuilder implements Builder<TaskList, TaskListBuilder> {
  _$TaskList? _$v;

  ListBuilder<ImportExcelFilesTask>? _childTasks;
  ListBuilder<ImportExcelFilesTask> get childTasks =>
      _$this._childTasks ??= new ListBuilder<ImportExcelFilesTask>();
  set childTasks(ListBuilder<ImportExcelFilesTask>? childTasks) =>
      _$this._childTasks = childTasks;

  TaskListBuilder();

  TaskListBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _childTasks = $v.childTasks.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(TaskList other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$TaskList;
  }

  @override
  void update(void Function(TaskListBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  TaskList build() => _build();

  _$TaskList _build() {
    _$TaskList _$result;
    try {
      _$result = _$v ?? new _$TaskList._(childTasks: childTasks.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'childTasks';
        childTasks.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'TaskList',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$ImportExcelFilesTask extends ImportExcelFilesTask {
  @override
  final BuiltSet<String> excelFilePaths;
  @override
  final BuiltList<ImportExcelSheetsTask> childTasks;

  factory _$ImportExcelFilesTask([
    void Function(ImportExcelFilesTaskBuilder)? updates,
  ]) => (new ImportExcelFilesTaskBuilder()..update(updates))._build();

  _$ImportExcelFilesTask._({
    required this.excelFilePaths,
    required this.childTasks,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      excelFilePaths,
      r'ImportExcelFilesTask',
      'excelFilePaths',
    );
    BuiltValueNullFieldError.checkNotNull(
      childTasks,
      r'ImportExcelFilesTask',
      'childTasks',
    );
  }

  @override
  ImportExcelFilesTask rebuild(
    void Function(ImportExcelFilesTaskBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ImportExcelFilesTaskBuilder toBuilder() =>
      new ImportExcelFilesTaskBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportExcelFilesTask &&
        excelFilePaths == other.excelFilePaths &&
        childTasks == other.childTasks;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, excelFilePaths.hashCode);
    _$hash = $jc(_$hash, childTasks.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportExcelFilesTask')
          ..add('excelFilePaths', excelFilePaths)
          ..add('childTasks', childTasks))
        .toString();
  }
}

class ImportExcelFilesTaskBuilder
    implements Builder<ImportExcelFilesTask, ImportExcelFilesTaskBuilder> {
  _$ImportExcelFilesTask? _$v;

  SetBuilder<String>? _excelFilePaths;
  SetBuilder<String> get excelFilePaths =>
      _$this._excelFilePaths ??= new SetBuilder<String>();
  set excelFilePaths(SetBuilder<String>? excelFilePaths) =>
      _$this._excelFilePaths = excelFilePaths;

  ListBuilder<ImportExcelSheetsTask>? _childTasks;
  ListBuilder<ImportExcelSheetsTask> get childTasks =>
      _$this._childTasks ??= new ListBuilder<ImportExcelSheetsTask>();
  set childTasks(ListBuilder<ImportExcelSheetsTask>? childTasks) =>
      _$this._childTasks = childTasks;

  ImportExcelFilesTaskBuilder();

  ImportExcelFilesTaskBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _excelFilePaths = $v.excelFilePaths.toBuilder();
      _childTasks = $v.childTasks.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportExcelFilesTask other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ImportExcelFilesTask;
  }

  @override
  void update(void Function(ImportExcelFilesTaskBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportExcelFilesTask build() => _build();

  _$ImportExcelFilesTask _build() {
    _$ImportExcelFilesTask _$result;
    try {
      _$result =
          _$v ??
          new _$ImportExcelFilesTask._(
            excelFilePaths: excelFilePaths.build(),
            childTasks: childTasks.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'excelFilePaths';
        excelFilePaths.build();
        _$failedField = 'childTasks';
        childTasks.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'ImportExcelFilesTask',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$ModifiedRow extends ModifiedRow {
  @override
  final BuiltMap<int, String> modifiedCells;

  factory _$ModifiedRow([void Function(ModifiedRowBuilder)? updates]) =>
      (new ModifiedRowBuilder()..update(updates))._build();

  _$ModifiedRow._({required this.modifiedCells}) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      modifiedCells,
      r'ModifiedRow',
      'modifiedCells',
    );
  }

  @override
  ModifiedRow rebuild(void Function(ModifiedRowBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ModifiedRowBuilder toBuilder() => new ModifiedRowBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ModifiedRow && modifiedCells == other.modifiedCells;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, modifiedCells.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ModifiedRow')
      ..add('modifiedCells', modifiedCells)).toString();
  }
}

class ModifiedRowBuilder implements Builder<ModifiedRow, ModifiedRowBuilder> {
  _$ModifiedRow? _$v;

  MapBuilder<int, String>? _modifiedCells;
  MapBuilder<int, String> get modifiedCells =>
      _$this._modifiedCells ??= new MapBuilder<int, String>();
  set modifiedCells(MapBuilder<int, String>? modifiedCells) =>
      _$this._modifiedCells = modifiedCells;

  ModifiedRowBuilder();

  ModifiedRowBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _modifiedCells = $v.modifiedCells.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ModifiedRow other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ModifiedRow;
  }

  @override
  void update(void Function(ModifiedRowBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ModifiedRow build() => _build();

  _$ModifiedRow _build() {
    _$ModifiedRow _$result;
    try {
      _$result =
          _$v ?? new _$ModifiedRow._(modifiedCells: modifiedCells.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'modifiedCells';
        modifiedCells.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'ModifiedRow',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$ImportExcelSheetsTask extends ImportExcelSheetsTask {
  @override
  final BuiltList<ImportCellsTask> childTasks;
  @override
  final BuiltMap<String, BuiltSet<String>> sheetNamesByExcelFilePath;

  factory _$ImportExcelSheetsTask([
    void Function(ImportExcelSheetsTaskBuilder)? updates,
  ]) => (new ImportExcelSheetsTaskBuilder()..update(updates))._build();

  _$ImportExcelSheetsTask._({
    required this.childTasks,
    required this.sheetNamesByExcelFilePath,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      childTasks,
      r'ImportExcelSheetsTask',
      'childTasks',
    );
    BuiltValueNullFieldError.checkNotNull(
      sheetNamesByExcelFilePath,
      r'ImportExcelSheetsTask',
      'sheetNamesByExcelFilePath',
    );
  }

  @override
  ImportExcelSheetsTask rebuild(
    void Function(ImportExcelSheetsTaskBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ImportExcelSheetsTaskBuilder toBuilder() =>
      new ImportExcelSheetsTaskBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportExcelSheetsTask &&
        childTasks == other.childTasks &&
        sheetNamesByExcelFilePath == other.sheetNamesByExcelFilePath;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, childTasks.hashCode);
    _$hash = $jc(_$hash, sheetNamesByExcelFilePath.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportExcelSheetsTask')
          ..add('childTasks', childTasks)
          ..add('sheetNamesByExcelFilePath', sheetNamesByExcelFilePath))
        .toString();
  }
}

class ImportExcelSheetsTaskBuilder
    implements Builder<ImportExcelSheetsTask, ImportExcelSheetsTaskBuilder> {
  _$ImportExcelSheetsTask? _$v;

  ListBuilder<ImportCellsTask>? _childTasks;
  ListBuilder<ImportCellsTask> get childTasks =>
      _$this._childTasks ??= new ListBuilder<ImportCellsTask>();
  set childTasks(ListBuilder<ImportCellsTask>? childTasks) =>
      _$this._childTasks = childTasks;

  MapBuilder<String, BuiltSet<String>>? _sheetNamesByExcelFilePath;
  MapBuilder<String, BuiltSet<String>> get sheetNamesByExcelFilePath =>
      _$this._sheetNamesByExcelFilePath ??=
          new MapBuilder<String, BuiltSet<String>>();
  set sheetNamesByExcelFilePath(
    MapBuilder<String, BuiltSet<String>>? sheetNamesByExcelFilePath,
  ) => _$this._sheetNamesByExcelFilePath = sheetNamesByExcelFilePath;

  ImportExcelSheetsTaskBuilder();

  ImportExcelSheetsTaskBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _childTasks = $v.childTasks.toBuilder();
      _sheetNamesByExcelFilePath = $v.sheetNamesByExcelFilePath.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportExcelSheetsTask other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ImportExcelSheetsTask;
  }

  @override
  void update(void Function(ImportExcelSheetsTaskBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportExcelSheetsTask build() => _build();

  _$ImportExcelSheetsTask _build() {
    _$ImportExcelSheetsTask _$result;
    try {
      _$result =
          _$v ??
          new _$ImportExcelSheetsTask._(
            childTasks: childTasks.build(),
            sheetNamesByExcelFilePath: sheetNamesByExcelFilePath.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'childTasks';
        childTasks.build();
        _$failedField = 'sheetNamesByExcelFilePath';
        sheetNamesByExcelFilePath.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'ImportExcelSheetsTask',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$ImportCellsTask extends ImportCellsTask {
  @override
  final BuiltList<ImportCellsTask> childTasks;
  @override
  final String? typedValue;
  @override
  final bool? shiftingLocked;
  @override
  final CellSelection cellSelection;

  factory _$ImportCellsTask([void Function(ImportCellsTaskBuilder)? updates]) =>
      (new ImportCellsTaskBuilder()..update(updates))._build();

  _$ImportCellsTask._({
    required this.childTasks,
    this.typedValue,
    this.shiftingLocked,
    required this.cellSelection,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(
      childTasks,
      r'ImportCellsTask',
      'childTasks',
    );
    BuiltValueNullFieldError.checkNotNull(
      cellSelection,
      r'ImportCellsTask',
      'cellSelection',
    );
  }

  @override
  ImportCellsTask rebuild(void Function(ImportCellsTaskBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ImportCellsTaskBuilder toBuilder() =>
      new ImportCellsTaskBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ImportCellsTask &&
        childTasks == other.childTasks &&
        typedValue == other.typedValue &&
        shiftingLocked == other.shiftingLocked &&
        cellSelection == other.cellSelection;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, childTasks.hashCode);
    _$hash = $jc(_$hash, typedValue.hashCode);
    _$hash = $jc(_$hash, shiftingLocked.hashCode);
    _$hash = $jc(_$hash, cellSelection.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ImportCellsTask')
          ..add('childTasks', childTasks)
          ..add('typedValue', typedValue)
          ..add('shiftingLocked', shiftingLocked)
          ..add('cellSelection', cellSelection))
        .toString();
  }
}

class ImportCellsTaskBuilder
    implements Builder<ImportCellsTask, ImportCellsTaskBuilder> {
  _$ImportCellsTask? _$v;

  ListBuilder<ImportCellsTask>? _childTasks;
  ListBuilder<ImportCellsTask> get childTasks =>
      _$this._childTasks ??= new ListBuilder<ImportCellsTask>();
  set childTasks(ListBuilder<ImportCellsTask>? childTasks) =>
      _$this._childTasks = childTasks;

  String? _typedValue;
  String? get typedValue => _$this._typedValue;
  set typedValue(String? typedValue) => _$this._typedValue = typedValue;

  bool? _shiftingLocked;
  bool? get shiftingLocked => _$this._shiftingLocked;
  set shiftingLocked(bool? shiftingLocked) =>
      _$this._shiftingLocked = shiftingLocked;

  CellSelectionBuilder? _cellSelection;
  CellSelectionBuilder get cellSelection =>
      _$this._cellSelection ??= new CellSelectionBuilder();
  set cellSelection(CellSelectionBuilder? cellSelection) =>
      _$this._cellSelection = cellSelection;

  ImportCellsTaskBuilder();

  ImportCellsTaskBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _childTasks = $v.childTasks.toBuilder();
      _typedValue = $v.typedValue;
      _shiftingLocked = $v.shiftingLocked;
      _cellSelection = $v.cellSelection.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ImportCellsTask other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$ImportCellsTask;
  }

  @override
  void update(void Function(ImportCellsTaskBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ImportCellsTask build() => _build();

  _$ImportCellsTask _build() {
    _$ImportCellsTask _$result;
    try {
      _$result =
          _$v ??
          new _$ImportCellsTask._(
            childTasks: childTasks.build(),
            typedValue: typedValue,
            shiftingLocked: shiftingLocked,
            cellSelection: cellSelection.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'childTasks';
        childTasks.build();

        _$failedField = 'cellSelection';
        cellSelection.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'ImportCellsTask',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

class _$CellSelection extends CellSelection {
  @override
  final BuiltSet<CellBase> cells;

  factory _$CellSelection([void Function(CellSelectionBuilder)? updates]) =>
      (new CellSelectionBuilder()..update(updates))._build();

  _$CellSelection._({required this.cells}) : super._() {
    BuiltValueNullFieldError.checkNotNull(cells, r'CellSelection', 'cells');
  }

  @override
  CellSelection rebuild(void Function(CellSelectionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CellSelectionBuilder toBuilder() => new CellSelectionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CellSelection && cells == other.cells;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cells.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CellSelection')
      ..add('cells', cells)).toString();
  }
}

class CellSelectionBuilder
    implements Builder<CellSelection, CellSelectionBuilder> {
  _$CellSelection? _$v;

  SetBuilder<CellBase>? _cells;
  SetBuilder<CellBase> get cells =>
      _$this._cells ??= new SetBuilder<CellBase>();
  set cells(SetBuilder<CellBase>? cells) => _$this._cells = cells;

  CellSelectionBuilder();

  CellSelectionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cells = $v.cells.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CellSelection other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CellSelection;
  }

  @override
  void update(void Function(CellSelectionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CellSelection build() => _build();

  _$CellSelection _build() {
    _$CellSelection _$result;
    try {
      _$result = _$v ?? new _$CellSelection._(cells: cells.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'cells';
        cells.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'CellSelection',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

abstract mixin class CellBaseBuilder {
  void replace(CellBase other);
  void update(void Function(CellBaseBuilder) updates);
}

class _$SingleCell extends SingleCell {
  @override
  final int x;
  @override
  final int y;

  factory _$SingleCell([void Function(SingleCellBuilder)? updates]) =>
      (new SingleCellBuilder()..update(updates))._build();

  _$SingleCell._({required this.x, required this.y}) : super._() {
    BuiltValueNullFieldError.checkNotNull(x, r'SingleCell', 'x');
    BuiltValueNullFieldError.checkNotNull(y, r'SingleCell', 'y');
  }

  @override
  SingleCell rebuild(void Function(SingleCellBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SingleCellBuilder toBuilder() => new SingleCellBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SingleCell && x == other.x && y == other.y;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, x.hashCode);
    _$hash = $jc(_$hash, y.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SingleCell')
          ..add('x', x)
          ..add('y', y))
        .toString();
  }
}

class SingleCellBuilder
    implements Builder<SingleCell, SingleCellBuilder>, CellBaseBuilder {
  _$SingleCell? _$v;

  int? _x;
  int? get x => _$this._x;
  set x(covariant int? x) => _$this._x = x;

  int? _y;
  int? get y => _$this._y;
  set y(covariant int? y) => _$this._y = y;

  SingleCellBuilder();

  SingleCellBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _x = $v.x;
      _y = $v.y;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant SingleCell other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$SingleCell;
  }

  @override
  void update(void Function(SingleCellBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SingleCell build() => _build();

  _$SingleCell _build() {
    final _$result =
        _$v ??
        new _$SingleCell._(
          x: BuiltValueNullFieldError.checkNotNull(x, r'SingleCell', 'x'),
          y: BuiltValueNullFieldError.checkNotNull(y, r'SingleCell', 'y'),
        );
    replace(_$result);
    return _$result;
  }
}

class _$CombinedCell extends CombinedCell {
  @override
  final BuiltSet<SingleCell> cells;
  @override
  final String separator;
  @override
  final bool trimValues;

  factory _$CombinedCell([void Function(CombinedCellBuilder)? updates]) =>
      (new CombinedCellBuilder()..update(updates))._build();

  _$CombinedCell._({
    required this.cells,
    required this.separator,
    required this.trimValues,
  }) : super._() {
    BuiltValueNullFieldError.checkNotNull(cells, r'CombinedCell', 'cells');
    BuiltValueNullFieldError.checkNotNull(
      separator,
      r'CombinedCell',
      'separator',
    );
    BuiltValueNullFieldError.checkNotNull(
      trimValues,
      r'CombinedCell',
      'trimValues',
    );
  }

  @override
  CombinedCell rebuild(void Function(CombinedCellBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CombinedCellBuilder toBuilder() => new CombinedCellBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CombinedCell &&
        cells == other.cells &&
        separator == other.separator &&
        trimValues == other.trimValues;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cells.hashCode);
    _$hash = $jc(_$hash, separator.hashCode);
    _$hash = $jc(_$hash, trimValues.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CombinedCell')
          ..add('cells', cells)
          ..add('separator', separator)
          ..add('trimValues', trimValues))
        .toString();
  }
}

class CombinedCellBuilder
    implements Builder<CombinedCell, CombinedCellBuilder>, CellBaseBuilder {
  _$CombinedCell? _$v;

  SetBuilder<SingleCell>? _cells;
  SetBuilder<SingleCell> get cells =>
      _$this._cells ??= new SetBuilder<SingleCell>();
  set cells(covariant SetBuilder<SingleCell>? cells) => _$this._cells = cells;

  String? _separator;
  String? get separator => _$this._separator;
  set separator(covariant String? separator) => _$this._separator = separator;

  bool? _trimValues;
  bool? get trimValues => _$this._trimValues;
  set trimValues(covariant bool? trimValues) => _$this._trimValues = trimValues;

  CombinedCellBuilder() {
    CombinedCell._initializeBuilder(this);
  }

  CombinedCellBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cells = $v.cells.toBuilder();
      _separator = $v.separator;
      _trimValues = $v.trimValues;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(covariant CombinedCell other) {
    ArgumentError.checkNotNull(other, 'other');
    _$v = other as _$CombinedCell;
  }

  @override
  void update(void Function(CombinedCellBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CombinedCell build() => _build();

  _$CombinedCell _build() {
    _$CombinedCell _$result;
    try {
      _$result =
          _$v ??
          new _$CombinedCell._(
            cells: cells.build(),
            separator: BuiltValueNullFieldError.checkNotNull(
              separator,
              r'CombinedCell',
              'separator',
            ),
            trimValues: BuiltValueNullFieldError.checkNotNull(
              trimValues,
              r'CombinedCell',
              'trimValues',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'cells';
        cells.build();
      } catch (e) {
        throw new BuiltValueNestedFieldError(
          r'CombinedCell',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/worksheet.dart';
import 'package:flutter/scheduler.dart';

class TwoDimensionalGridView extends TwoDimensionalScrollView {
  final ImportExcelSheetsTaskViewModel sheetVm;

  //  final ByteParsedWorksheet sheet;

  const TwoDimensionalGridView({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    required TwoDimensionalChildBuilderDelegate delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
    required this.sheetVm,
  }) : super(delegate: delegate);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return TwoDimensionalGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      sheetVm: sheetVm,
    );
  }
}

class TwoDimensionalGridViewport extends TwoDimensionalViewport {
  final ImportExcelSheetsTaskViewModel sheetVm;

  const TwoDimensionalGridViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    required this.sheetVm,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    var renderTwoDimensionalGridViewport = RenderTwoDimensionalGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      sheetVm: sheetVm,
    );

    return renderTwoDimensionalGridViewport;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTwoDimensionalGridViewport renderObject,
  ) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior
      ..sheetVm = sheetVm;
  }
}

class RenderTwoDimensionalGridViewport extends RenderTwoDimensionalViewport {
  ImportExcelSheetsTaskViewModel sheetVm;

  RenderTwoDimensionalGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    required this.sheetVm,
  }) : super(delegate: delegate);

  @override
  void layoutChildSequence() {
    final sheet = sheetVm.selectedWorksheetNotifier.value!;
    final columnDefinitions = sheet.columnDefinitions;

    final double viewportWidth = viewportDimension.width + cacheExtent;
    final double viewportHeight = viewportDimension.height + cacheExtent;
    final TwoDimensionalChildBuilderDelegate builderDelegate =
        delegate as TwoDimensionalChildBuilderDelegate;

    final int leadingRowIndex = max(
      (sheet.getRowIndexByOffset(verticalOffset.pixels)).floor(),
      1,
    );
    final int trailingRowIndex =
        sheet
            .getRowIndexByOffset(verticalOffset.pixels + viewportHeight)
            .ceil();

    final int trailingColumnIndex = columnDefinitions.getColumnIndexByOffset(
      horizontalOffset.pixels + viewportWidth,
    );

    final int leadingColumnIndex = max(
      (columnDefinitions.getColumnIndexByOffset(
        horizontalOffset.pixels,
      )).floor(),
      1,
    );

    final leadingColumnOffset = columnDefinitions.getColumnOffset(
      leadingColumnIndex,
    );

    final leadingRowOffset = sheet.row(leadingRowIndex)!.offset;

    double xLayoutOffset = leadingColumnOffset - horizontalOffset.pixels;
    double yLayoutOffset = leadingRowOffset - verticalOffset.pixels;

    Set<CellSpan> burnedCellSpans = {};

    for (
      int columnIndex = leadingColumnIndex;
      columnIndex <= trailingColumnIndex;
      columnIndex++
    ) {
      var spanAtVicinity = sheet.cellSpans.spanAtRC(
        leadingRowIndex,
        columnIndex,
      );
      if (spanAtVicinity == null || burnedCellSpans.contains(spanAtVicinity)) {
        continue;
      }

      if (spanAtVicinity.start.rowIndex == leadingRowIndex &&
          spanAtVicinity.start.columnIndex == columnIndex) {
        continue;
      }
      if (spanAtVicinity.start.rowIndex >= leadingRowIndex) {
        continue;
      }

      final ChildVicinity vicinity = ChildVicinity(
        xIndex: spanAtVicinity.start.columnIndex,
        yIndex: spanAtVicinity.start.rowIndex,
      );

      final RenderBox child = buildOrObtainChildFor(vicinity)!;

      child.layout(
        BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
      );

      parentDataOf(child).layoutOffset = Offset(
        columnDefinitions.getColumnOffset(spanAtVicinity.start.columnIndex) -
            horizontalOffset.pixels,
        sheet.row(spanAtVicinity.start.rowIndex)!.offset -
            verticalOffset.pixels,
      );

      burnedCellSpans.add(spanAtVicinity);

      final double columnWidth = columnDefinitions.getColumnWidth(columnIndex);
      xLayoutOffset += columnWidth;
    }

    xLayoutOffset = leadingColumnOffset - horizontalOffset.pixels;
    yLayoutOffset = leadingRowOffset - verticalOffset.pixels;

    for (
      int rowIndex = leadingRowIndex;
      rowIndex <= trailingRowIndex;
      rowIndex++
    ) {
      var spanAtVicinity = sheet.cellSpans.spanAtRC(
        rowIndex,
        leadingColumnIndex,
      );
      if (spanAtVicinity == null || burnedCellSpans.contains(spanAtVicinity)) {
        continue;
      }
      if (spanAtVicinity.start.rowIndex == rowIndex &&
          spanAtVicinity.start.columnIndex == leadingColumnIndex) {
        continue;
      }
      if (spanAtVicinity.start.columnIndex >= leadingColumnIndex) {
        continue;
      }

      burnedCellSpans.add(spanAtVicinity);

      final ChildVicinity vicinity = ChildVicinity(
        xIndex: spanAtVicinity.start.columnIndex,
        yIndex: spanAtVicinity.start.rowIndex,
      );

      final RenderBox child = buildOrObtainChildFor(vicinity)!;

      child.layout(
        BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
      );

      parentDataOf(child).layoutOffset = Offset(
        columnDefinitions.getColumnOffset(spanAtVicinity.start.columnIndex) -
            horizontalOffset.pixels,
        sheet.row(spanAtVicinity.start.rowIndex)!.offset -
            verticalOffset.pixels,
      );
      final row = sheet.row(rowIndex);
      if (row != null) {
        final num rowHeight = row.height ?? sheet.defaultRowHeight;
        yLayoutOffset += rowHeight;
      } else {
        yLayoutOffset += sheet.defaultRowHeight;
      }
    }

    xLayoutOffset = leadingColumnOffset - horizontalOffset.pixels;
    yLayoutOffset = leadingRowOffset - verticalOffset.pixels;
    for (
      int columnIndex = leadingColumnIndex;
      columnIndex <= trailingColumnIndex;
      columnIndex++
    ) {
      yLayoutOffset = leadingRowOffset - verticalOffset.pixels;

      for (
        int rowIndex = leadingRowIndex;
        rowIndex <= trailingRowIndex;
        rowIndex++
      ) {
        final ChildVicinity vicinity = ChildVicinity(
          xIndex: columnIndex,
          yIndex: rowIndex,
        );

        final RenderBox child = buildOrObtainChildFor(vicinity)!;

        child.layout(
          BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
        );
        parentDataOf(child).layoutOffset = Offset(xLayoutOffset, yLayoutOffset);

        final row = sheet.row(rowIndex);
        if (row != null) {
          final num rowHeight = row.height ?? sheet.defaultRowHeight;
          yLayoutOffset += rowHeight;
        } else {
          yLayoutOffset += sheet.defaultRowHeight;
        }
      }
      final double columnWidth = columnDefinitions.getColumnWidth(columnIndex);

      xLayoutOffset += columnWidth;
    }

    final double verticalExtent = sheet.verticalExtent;

    final lastColumnOffset = columnDefinitions.getColumnOffset(
      sheet.maxColumnIndex,
    );

    final lastColumnWidth =
        columnDefinitions.lastOrNull?.widthOfEachColumn ??
        sheet.defaultColWidth;

    verticalOffset.applyContentDimensions(
      0.0,
      clampDouble(
        verticalExtent - viewportDimension.height,
        0.0,
        double.infinity,
      ),
    );

    final double horizontalExtent = lastColumnOffset + lastColumnWidth + 10;
    horizontalOffset.applyContentDimensions(
      0.0,
      clampDouble(
        horizontalExtent - viewportDimension.width,
        0.0,
        double.infinity,
      ),
    );
  }
}

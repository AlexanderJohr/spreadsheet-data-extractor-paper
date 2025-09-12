import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';
import 'package:spreadsheet_data_extractor/src/models/view_models/task_list_view_model.dart';
import 'package:spreadsheet_data_extractor/src/pages/cell_selection_page.dart';
import 'package:spreadsheet_data_extractor/src/pages/task_overview_page.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/worksheet.dart';
import 'package:flutter/scheduler.dart';

class OutputGridView extends TwoDimensionalScrollView {
  final LazyRowLocator lazyRowLocator;
  const OutputGridView({
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
    required this.lazyRowLocator,
  }) : super(delegate: delegate);

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) {
    return OutputGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      lazyRowLocator: lazyRowLocator,
    );
  }
}

class OutputGridViewport extends TwoDimensionalViewport {
  final LazyRowLocator lazyRowLocator;

  const OutputGridViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    required this.lazyRowLocator,
  });

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    final taskListViewModel = InheritedTaskListViewModel.of(context);

    var renderOutputGridViewport = RenderOutputGridViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      taskListViewModel: taskListViewModel,
      lazyRowLocator: lazyRowLocator,
    );

    return renderOutputGridViewport;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderOutputGridViewport renderObject,
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
      ..taskListViewModel = InheritedTaskListViewModel.of(context)
      ..lazyRowLocator = LazyRowLocator.of(context);
  }
}

class RenderOutputGridViewport extends RenderTwoDimensionalViewport {
  TaskListViewModel taskListViewModel;
  LazyRowLocator lazyRowLocator;

  RenderOutputGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    required this.taskListViewModel,
    required this.lazyRowLocator,
  }) : super(delegate: delegate);

  @override
  void layoutChildSequence() {
    double rowHeight = 20;

    final double viewportWidth = viewportDimension.width + cacheExtent;
    final double viewportHeight = viewportDimension.height + cacheExtent;

    final int leadingRowIndex = verticalOffset.pixels ~/ rowHeight;
    final int trailingRowIndex =
        (verticalOffset.pixels + viewportHeight) ~/ rowHeight;

    lazyRowLocator.prefetchThroughRow(trailingRowIndex + 200);

    final int leadingColumnIndex = 0;

    final leadingColumnOffset = 0;

    final leadingRowOffset = leadingRowIndex * rowHeight;

    double xLayoutOffset = leadingColumnOffset - horizontalOffset.pixels;
    double yLayoutOffset = leadingRowOffset - verticalOffset.pixels;

    int columnIndex = leadingColumnIndex;
    while (xLayoutOffset < viewportWidth) {
      yLayoutOffset = leadingRowOffset - verticalOffset.pixels;

      double maxWidth = 0;
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
          parentUsesSize: true,
        );
        parentDataOf(child).layoutOffset = Offset(xLayoutOffset, yLayoutOffset);
        yLayoutOffset += rowHeight;
        maxWidth = max(maxWidth, child.size.width);
      }
      final double columnWidth = maxWidth;

      if (columnWidth == 0) {
        break;
      }
      xLayoutOffset += columnWidth;
      columnIndex++;
    }

    verticalOffset.applyContentDimensions(0.0, double.infinity);

    horizontalOffset.applyContentDimensions(0, double.infinity);
  }
}

import 'package:flutter/material.dart';

import 'package:spreadsheet_data_extractor/src/app_state.dart';
import 'package:spreadsheet_data_extractor/src/models/task_list/import_excel_cells_task_list.dart';

import 'package:spreadsheet_data_extractor/src/pages/cell_selection_page.dart';
import 'package:spreadsheet_data_extractor/l10n/app_localizations.dart';

class ImportExcelSheetsTaskListViewHeader extends StatelessWidget {
  const ImportExcelSheetsTaskListViewHeader({
    Key? key,
    required this.importSheetTask,
  }) : super(key: key);

  final ImportExcelSheetsTaskViewModel importSheetTask;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: importSheetTask.loadedSheetsByExcelFile,
      builder: (context, snapshot) {
        return ListTile(
          leading: Icon(
            Icons.table_chart_sharp,
            size: Theme.of(context).iconTheme.size,
          ),
          title:
              importSheetTask.noSheetSelected
                  ? Text(
                    AppLocalizations.of(context)!.noSheetSelectedText,
                    style: Theme.of(context).textTheme.labelSmall,
                  )
                  : Text(
                    AppLocalizations.of(context)!.importSheetsButtonText,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var entry in importSheetTask
                  .loadedSheetsByExcelFile
                  .value
                  .entries
                  .where((entry) => entry.value.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Wrap(
                    direction: Axis.horizontal,
                    spacing: 8.0,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Icons.insert_drive_file,
                                color: Colors.grey,
                              ),
                            ),
                            TextSpan(text: '${entry.key.name}: '),
                          ],
                          style: Theme.of(context).textTheme.labelSmall!
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      for (var sheet in entry.value)
                        Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              const WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Padding(
                                  padding: EdgeInsets.all(3.0),
                                  child: Icon(
                                    Icons.table_chart_sharp,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              TextSpan(text: '$sheet '),
                            ],
                            style: Theme.of(context).textTheme.labelSmall!
                                .copyWith(fontWeight: FontWeight.w400),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (importSheetTask.atLeastOnSheetSelected)
                InkWell(
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(
                      Icons.add_link_sharp,
                      color: Colors.greenAccent,
                    ),
                  ),
                  onTap: () {
                    final task =
                        importSheetTask.addImportExcelCellsTaskViewModel();

                    SelectedTaskService.of(context).selectedTask = task;
                    task.topViewModel.treeChanged();
                  },
                ),
            ],
          ),
          onTap: () {
            SelectedTaskService.of(context).selectedTask = importSheetTask;
            SelectedSheetService.of(context).activeSheetTask = importSheetTask;
          },
        );
      },
    );
  }
}

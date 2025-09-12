import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:spreadsheet_data_extractor/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:rxdart/rxdart.dart';
import 'package:spreadsheet_data_extractor/src/pages/cell_selection_page.dart';

import 'app_state.dart';
import 'pages/task_overview_page.dart';
import 'settings/settings_controller.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeToggle = AnimatedBuilder(
      animation: ThemeToggle.of(context),
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: PointerDeviceKind.values.toSet(),
          ),
          home: Builder(
            builder: (context) {
              return ListenableBuilder(
                listenable: SelectedSheetService.of(context),
                builder: (context, child) {
                  final selectedSheet =
                      SelectedSheetService.of(context).activeSheetTask;

                  return Navigator(
                    pages: [
                      TaskOverviewPage(),
                      if (selectedSheet != null) const SelectExcelSheetsPage(),
                    ],
                    onDidRemovePage: (Page page) {
                      if (page.runtimeType == SelectExcelSheetsPage) {
                        SelectedSheetService.of(context).activeSheetTask = null;
                      }
                    },
                  );
                },
              );
            },
          ),
          restorationScopeId: 'app',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''),
            Locale('es', ''),
            Locale('de', ''),
          ],
          onGenerateTitle:
              (BuildContext context) => AppLocalizations.of(context)!.appTitle,
          darkTheme:
              ThemeToggle.of(context).themeMode == ThemeMode.dark
                  ? ThemeData.dark().copyWith()
                  : ThemeData.light().copyWith(),
          themeMode: ThemeToggle.of(context).themeMode,
        );
      },
    );

    return themeToggle;
  }
}

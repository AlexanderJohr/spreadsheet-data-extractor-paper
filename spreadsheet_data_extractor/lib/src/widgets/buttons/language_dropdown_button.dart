import 'package:flutter/material.dart';
import 'package:spreadsheet_data_extractor/src/app_state.dart';

/// A button widget for
class LanguageDropdownButton extends StatelessWidget {
  const LanguageDropdownButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      child: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.language),
      ),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            onTap: () async {
              AppState.of(context).locale = const Locale('en', '');
            },
            child: const ListTile(
              leading: Icon(Icons.flag, color: Colors.blueAccent),
              title: Text("English"),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () async {
              AppState.of(context).locale = const Locale('de', '');
            },
            child: const ListTile(
              leading: Icon(Icons.flag, color: Colors.redAccent),
              title: Text("Deutsch"),
            ),
          ),
          PopupMenuItem<String>(
            onTap: () async {
              AppState.of(context).locale = const Locale('es', '');
            },
            child: const ListTile(
              leading: Icon(Icons.flag, color: Colors.yellowAccent),
              title: Text("Español"),
            ),
          ),
        ];
      },
    );
  }
}

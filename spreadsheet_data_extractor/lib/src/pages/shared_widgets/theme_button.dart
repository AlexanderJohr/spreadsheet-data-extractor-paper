import 'package:flutter/material.dart';

import 'package:spreadsheet_data_extractor/src/settings/settings_controller.dart';

class ThemeButton extends StatelessWidget {
  const ThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: IconButton(
        onPressed: () => ThemeToggle.of(context).toggleTheme(),
        icon: ThemeToggle.of(context).icon,
      ),
    );
  }
}

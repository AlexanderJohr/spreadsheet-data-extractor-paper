import 'package:flutter/material.dart';

/// Displays an error message in a dialog box.
///
/// This function creates and displays an AlertDialog containing the provided error message.
///
/// [context]: The BuildContext in which the dialog should be displayed.
/// [message]: The error message to be displayed.
void displayError(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Ein Fehler ist aufgetreten.'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

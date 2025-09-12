import 'package:flutter/material.dart';
import 'package:spreadsheet_data_extractor/l10n/app_localizations.dart';

class ConfigurationInvalidDialog extends StatelessWidget {
  const ConfigurationInvalidDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.errNonValidConfigTitle),
      content: Text(AppLocalizations.of(context)!.errNonValidConfigText),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('ok 😔'),
        ),
      ],
    );
  }
}

class InvalidJsonDialog extends StatelessWidget {
  const InvalidJsonDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.errNonValidJSONTitle),
      content: Text(AppLocalizations.of(context)!.errNonValidJSONText),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('ok 😔'),
        ),
      ],
    );
  }
}

class UnexpectedErrorDialog extends StatelessWidget {
  final Object exception;

  const UnexpectedErrorDialog({Key? key, required this.exception})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.errUnexpectedErrorTitle),
      content: Text(
        AppLocalizations.of(context)!.errUnexpectedErrorText(exception),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('ok 😔'),
        ),
      ],
    );
  }
}

class OverwriteFileDialog extends StatelessWidget {
  const OverwriteFileDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.fileAlreadyExistsTitle),
      content: Text(AppLocalizations.of(context)!.fileAlreadyExistsText),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.noButtonText),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(AppLocalizations.of(context)!.yesButtonText),
        ),
      ],
    );
  }
}

class IgnoreChangesDialog extends StatelessWidget {
  const IgnoreChangesDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.discardChangesTitle),
      content: Text(AppLocalizations.of(context)!.discardChangesText),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.noButtonText),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(AppLocalizations.of(context)!.yesButtonText),
        ),
      ],
    );
  }
}

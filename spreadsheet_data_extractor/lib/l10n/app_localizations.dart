import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet Describer and Data Extractor'**
  String get appTitle;

  /// No description provided for @taskPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Excel Files'**
  String get taskPageTitle;

  /// No description provided for @firstAppCallIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Spreadsheet Metadata Hierarchy Describer and Data Extractor 0.12.0 - For internal use only'**
  String get firstAppCallIntroTitle;

  /// No description provided for @acceptButtonText.
  ///
  /// In en, this message translates to:
  /// **'accept'**
  String get acceptButtonText;

  /// No description provided for @selectedDataIsNotExcelErrorText.
  ///
  /// In en, this message translates to:
  /// **'Error: The selected file to attach the data is not an Excel file'**
  String get selectedDataIsNotExcelErrorText;

  /// No description provided for @fileExistsText.
  ///
  /// In en, this message translates to:
  /// **'Successfully appended {linesAppended} line(s) to the existing lines in {filePath}'**
  String fileExistsText(int linesAppended, String filePath);

  /// No description provided for @fileDoesNotExistsText.
  ///
  /// In en, this message translates to:
  /// **'Successfully saved {linesAppended} lines to new {filePath} file.'**
  String fileDoesNotExistsText(int linesAppended, String filePath);

  /// No description provided for @taskParentHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'tasks'**
  String get taskParentHeaderTitle;

  /// No description provided for @importExcelFilesButtonText.
  ///
  /// In en, this message translates to:
  /// **'import Excel files'**
  String get importExcelFilesButtonText;

  /// No description provided for @copyConfigButtonText.
  ///
  /// In en, this message translates to:
  /// **'copy configuration'**
  String get copyConfigButtonText;

  /// No description provided for @insertConfigButtonText.
  ///
  /// In en, this message translates to:
  /// **'insert configuration'**
  String get insertConfigButtonText;

  /// No description provided for @configSavedText.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved successfully.'**
  String get configSavedText;

  /// No description provided for @saveConfigButtonText.
  ///
  /// In en, this message translates to:
  /// **'save configuration'**
  String get saveConfigButtonText;

  /// No description provided for @loadConfigButtonText.
  ///
  /// In en, this message translates to:
  /// **'load configuration'**
  String get loadConfigButtonText;

  /// No description provided for @importSheetsButtonText.
  ///
  /// In en, this message translates to:
  /// **'import Excel sheets'**
  String get importSheetsButtonText;

  /// No description provided for @importAdditionalFilesButtonText.
  ///
  /// In en, this message translates to:
  /// **'import additional files'**
  String get importAdditionalFilesButtonText;

  /// No description provided for @copyExcelFileImportTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'copy Excel file import task'**
  String get copyExcelFileImportTaskButtonText;

  /// No description provided for @insertExcelFileImportTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'insert Excel file import task'**
  String get insertExcelFileImportTaskButtonText;

  /// No description provided for @noSheetSelectedText.
  ///
  /// In en, this message translates to:
  /// **'click to select Excel sheet'**
  String get noSheetSelectedText;

  /// No description provided for @importCellsButtonText.
  ///
  /// In en, this message translates to:
  /// **'import cells'**
  String get importCellsButtonText;

  /// No description provided for @copyWorksheetImportTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'copy worksheet import task'**
  String get copyWorksheetImportTaskButtonText;

  /// No description provided for @insertWorksheetImportTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'insert worksheet import task'**
  String get insertWorksheetImportTaskButtonText;

  /// No description provided for @noCellsSelectedText.
  ///
  /// In en, this message translates to:
  /// **'click to select cells'**
  String get noCellsSelectedText;

  /// No description provided for @linkCellIndexBoxText.
  ///
  /// In en, this message translates to:
  /// **'link cell index'**
  String get linkCellIndexBoxText;

  /// No description provided for @useDefaultValueBoxText.
  ///
  /// In en, this message translates to:
  /// **'use default value'**
  String get useDefaultValueBoxText;

  /// No description provided for @copyCellSelectionButtonText.
  ///
  /// In en, this message translates to:
  /// **'copy cell selection'**
  String get copyCellSelectionButtonText;

  /// No description provided for @copyTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'copy task'**
  String get copyTaskButtonText;

  /// No description provided for @duplicateTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'duplicate task'**
  String get duplicateTaskButtonText;

  /// No description provided for @insertCellSelectionButtonText.
  ///
  /// In en, this message translates to:
  /// **'insert cell selection'**
  String get insertCellSelectionButtonText;

  /// No description provided for @insertTaskButtonText.
  ///
  /// In en, this message translates to:
  /// **'insert task'**
  String get insertTaskButtonText;

  /// No description provided for @alignCellSelectionButtonText.
  ///
  /// In en, this message translates to:
  /// **'align cell selection'**
  String get alignCellSelectionButtonText;

  /// No description provided for @moveAllSelectionsButtonText.
  ///
  /// In en, this message translates to:
  /// **'move all selections'**
  String get moveAllSelectionsButtonText;

  /// No description provided for @linkWithCellsButtonText.
  ///
  /// In en, this message translates to:
  /// **'link with cells'**
  String get linkWithCellsButtonText;

  /// No description provided for @errNonValidConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'non valid configuration'**
  String get errNonValidConfigTitle;

  /// No description provided for @errNonValidConfigText.
  ///
  /// In en, this message translates to:
  /// **'The selected file does not contain a valid configuration.'**
  String get errNonValidConfigText;

  /// No description provided for @errNonValidJSONTitle.
  ///
  /// In en, this message translates to:
  /// **'non valid json'**
  String get errNonValidJSONTitle;

  /// No description provided for @errNonValidJSONText.
  ///
  /// In en, this message translates to:
  /// **'The selected file does not contain a valid json.'**
  String get errNonValidJSONText;

  /// No description provided for @errUnexpectedErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'unexpected error'**
  String get errUnexpectedErrorTitle;

  /// No description provided for @errUnexpectedErrorText.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred : {exception}'**
  String errUnexpectedErrorText(Object exception);

  /// No description provided for @fileAlreadyExistsTitle.
  ///
  /// In en, this message translates to:
  /// **'file already exists - overwrite it?'**
  String get fileAlreadyExistsTitle;

  /// No description provided for @fileAlreadyExistsText.
  ///
  /// In en, this message translates to:
  /// **'The file already exists, should it be overwritten?'**
  String get fileAlreadyExistsText;

  /// No description provided for @yesButtonText.
  ///
  /// In en, this message translates to:
  /// **'yes'**
  String get yesButtonText;

  /// No description provided for @noButtonText.
  ///
  /// In en, this message translates to:
  /// **'no'**
  String get noButtonText;

  /// No description provided for @discardChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'discard changes?'**
  String get discardChangesTitle;

  /// No description provided for @discardChangesText.
  ///
  /// In en, this message translates to:
  /// **'Changes have been made in this view. Discard them?'**
  String get discardChangesText;

  /// No description provided for @duplicateAndMoveCheckboxText.
  ///
  /// In en, this message translates to:
  /// **'move and duplicate'**
  String get duplicateAndMoveCheckboxText;

  /// No description provided for @embedLabelText.
  ///
  /// In en, this message translates to:
  /// **'encapsulate'**
  String get embedLabelText;

  /// No description provided for @useCellSelectionLabelText.
  ///
  /// In en, this message translates to:
  /// **'use cell selection'**
  String get useCellSelectionLabelText;

  /// No description provided for @enterValueManuallyLabelText.
  ///
  /// In en, this message translates to:
  /// **'enter value manually'**
  String get enterValueManuallyLabelText;

  /// No description provided for @repeatLabelText.
  ///
  /// In en, this message translates to:
  /// **'repeat'**
  String get repeatLabelText;

  /// No description provided for @manualValueLabelText.
  ///
  /// In en, this message translates to:
  /// **'manual value'**
  String get manualValueLabelText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:spreadsheet_data_extractor/src/utils/excel_decoder/byte_worksheet_parser.dart';
import 'package:xml/xml.dart';

// Extension methods for XmlElements to get the first element or null
extension XmlElementExtension on Iterable<XmlElement> {
  XmlElement? get firstOrNull => isNotEmpty ? first : null;
}

class WorkbookTheme {
  final List<String> themeColors;

  static const Map<int, String> themeColorNames = {
    0: 'lt1',
    1: 'dk1',
    2: 'lt2',
    3: 'dk2',
    4: 'accent1',
    5: 'accent2',
    6: 'accent3',
    7: 'accent4',
    8: 'accent5',
    9: 'accent6',
  };

  WorkbookTheme._({required this.themeColors});

  WorkbookTheme.empty() : themeColors = [];

  static List<String> _parseThemeColors(XmlElement themeElement) {
    final List<String> colors = [];

    final clrSchemeElement = themeElement
        .findAllElements('a:clrScheme')
        .firstWhereOrNull((element) => element.getAttribute('name') != null);

    if (clrSchemeElement == null) return colors;

    for (int i = 0; i < themeColorNames.length; i++) {
      final colorName = themeColorNames[i]!;
      final colorElement =
          clrSchemeElement.getElement(colorName) ??
          clrSchemeElement.getElement('a:$colorName');
      if (colorElement != null) {
        final colorValueElement =
            colorElement.children.whereType<XmlElement>().firstOrNull;
        if (colorValueElement != null) {
          String? colorHex;
          if (colorValueElement.name.local == 'sysClr') {
            colorHex = colorValueElement.getAttribute('lastClr');
          } else if (colorValueElement.name.local == 'srgbClr') {
            colorHex = colorValueElement.getAttribute('val');
          }
          if (colorHex != null) {
            colors.add(colorHex);
          }
        }
      }
    }

    return colors;
  }
}

// Class representing the styles from xl/styles.xml
class Styles {
  final Map<int, String> numberFormats;
  final List<Font> fonts;
  final List<Fill> fills;
  final List<BorderDefinition?> borders;
  final List<CellStyleXf> cellStyleXfs;
  final List<CellXf> cellXfs;
  final List<CellStyle> cellStyles;
  final ColorMapping colorMapping;

  Styles._({
    required this.numberFormats,
    required this.fonts,
    required this.fills,
    required this.borders,
    required this.cellStyleXfs,
    required this.cellXfs,
    required this.cellStyles,
    required this.colorMapping,
  });

  Styles.empty()
    : numberFormats = {},
      fonts = [],
      fills = [],
      borders = [],
      cellStyleXfs = [],
      cellXfs = [],
      cellStyles = [],
      colorMapping = ColorMapping(themeColors: []);

  factory Styles.fromArchiveFile(ArchiveFile file, WorkbookTheme theme) {
    XmlDocument xmlDocument = file.toXmlDocument();

    final stylesElement = xmlDocument.findElements('styleSheet').firstOrNull;
    if (stylesElement == null) {
      return Styles.empty();
    }

    final numberFormats = _parseNumFmts(stylesElement);
    final fonts = _parseFonts(stylesElement, theme);
    final fills = _parseFills(stylesElement, theme);
    final borders = _parseBorders(stylesElement, theme);
    final cellStyleXfs = _parseCellStyleXfs(stylesElement);
    final cellXfs = _parseCellXfs(stylesElement);
    final cellStyles = _parseCellStyles(stylesElement);
    final colorMapping = _parseColorMapping(stylesElement, theme);

    return Styles._(
      numberFormats: numberFormats,
      fonts: fonts,
      fills: fills,
      borders: borders,
      cellStyleXfs: cellStyleXfs,
      cellXfs: cellXfs,
      cellStyles: cellStyles,
      colorMapping: colorMapping,
    );
  }

  // Parsing methods
  static Map<int, String> _parseNumFmts(XmlElement stylesElement) {
    final numFmtsElement = stylesElement.findElements('numFmts').firstOrNull;
    if (numFmtsElement == null) return {};
    final numFmtElements = numFmtsElement.findElements('numFmt');

    final map = <int, String>{
      for (final e in numFmtElements)
        int.parse(e.getAttribute('numFmtId') ?? '0'):
            e.getAttribute('formatCode') ?? '',
    };

    return map;
  }

  static List<Font> _parseFonts(XmlElement stylesElement, WorkbookTheme theme) {
    final fontsElement = stylesElement.findElements('fonts').firstOrNull;
    if (fontsElement == null) return [];
    final fontElements = fontsElement.findElements('font');

    return fontElements.map((fontElement) {
      // Parse font properties
      final nameElement = fontElement.findElements('name').firstOrNull;
      final fontName = nameElement?.getAttribute('val');

      final szElement = fontElement.findElements('sz').firstOrNull;
      final fontSize =
          szElement != null
              ? double.tryParse(szElement.getAttribute('val') ?? '')
              : null;

      final colorElement = fontElement.findElements('color').firstOrNull;
      String? colorRgb = colorElement?.getAttribute('rgb');
      final colorThemeStr = colorElement?.getAttribute('theme');
      int? colorTheme =
          colorThemeStr != null ? int.tryParse(colorThemeStr) : null;

      if (colorTheme != null && theme.themeColors.isNotEmpty) {
        // Map the theme color index to the actual color
        if (colorTheme >= 0 &&
            colorTheme < WorkbookTheme.themeColorNames.length) {
          final themeColor = theme.themeColors[colorTheme];
          colorRgb = themeColor;
        }
      }

      final bold = fontElement.findElements('b').isNotEmpty;
      final italic = fontElement.findElements('i').isNotEmpty;
      final underline = fontElement.findElements('u').isNotEmpty;
      final strike = fontElement.findElements('strike').isNotEmpty;

      return Font(
        name: fontName,
        size: fontSize,
        colorRgb: colorRgb,
        colorTheme: colorTheme,
        bold: bold,
        italic: italic,
        underline: underline,
        strike: strike,
      );
    }).toList();
  }

  static List<Fill> _parseFills(XmlElement stylesElement, WorkbookTheme theme) {
    final fillsElement = stylesElement.findElements('fills').firstOrNull;
    if (fillsElement == null) return [];
    final fillElements = fillsElement.findElements('fill');

    return fillElements.map((fillElement) {
      final patternFillElement =
          fillElement.findElements('patternFill').firstOrNull;
      if (patternFillElement != null) {
        final patternType = patternFillElement.getAttribute('patternType');

        final fgColorElement =
            patternFillElement.findElements('fgColor').firstOrNull;
        String? fgColorRgb = fgColorElement?.getAttribute('rgb');
        final fgColorThemeStr = fgColorElement?.getAttribute('theme');
        int? fgColorTheme =
            fgColorThemeStr != null ? int.tryParse(fgColorThemeStr) : null;

        if (fgColorTheme != null && theme.themeColors.isNotEmpty) {
          // Map the theme color index to the actual color
          if (fgColorTheme >= 0 &&
              fgColorTheme < WorkbookTheme.themeColorNames.length) {
            final themeColor = theme.themeColors[fgColorTheme];
            fgColorRgb = themeColor.padLeft(8, '0').toUpperCase();
          }
        }

        final bgColorElement =
            patternFillElement.findElements('bgColor').firstOrNull;
        String? bgColorRgb = bgColorElement?.getAttribute('rgb');
        final bgColorThemeStr = bgColorElement?.getAttribute('theme');
        int? bgColorTheme =
            bgColorThemeStr != null ? int.tryParse(bgColorThemeStr) : null;

        if (bgColorTheme != null && theme.themeColors.isNotEmpty) {
          // Map the theme color index to the actual color
          if (bgColorTheme >= 0 &&
              bgColorTheme < WorkbookTheme.themeColorNames.length) {
            final themeColor = theme.themeColors[bgColorTheme];
            bgColorRgb = themeColor;
          }
        }

        return Fill(
          patternType: patternType,
          fgColorRgb: fgColorRgb,
          fgColorTheme: fgColorTheme,
          bgColorRgb: bgColorRgb,
          bgColorTheme: bgColorTheme,
        );
      } else {
        // Handle gradient fills if necessary
        return Fill();
      }
    }).toList();
  }

  static List<BorderDefinition?> _parseBorders(
    XmlElement stylesElement,
    WorkbookTheme theme,
  ) {
    final bordersElement = stylesElement.findElements('borders').firstOrNull;
    if (bordersElement == null) return [];
    final borderElements = bordersElement.findElements('border');

    return borderElements
        .map(
          (borderElement) =>
              BorderDefinition.parseBorderDefinition(borderElement, theme),
        )
        .toList();
  }

  static List<CellStyleXf> _parseCellStyleXfs(XmlElement stylesElement) {
    final cellStyleXfsElement =
        stylesElement.findElements('cellStyleXfs').firstOrNull;
    if (cellStyleXfsElement == null) return [];
    final xfElements = cellStyleXfsElement.findElements('xf');

    return xfElements.map((xfElement) {
      final numFmtId = int.tryParse(xfElement.getAttribute('numFmtId') ?? '');
      final fontId = int.tryParse(xfElement.getAttribute('fontId') ?? '');
      final fillId = int.tryParse(xfElement.getAttribute('fillId') ?? '');
      final borderId = int.tryParse(xfElement.getAttribute('borderId') ?? '');
      final applyNumberFormat =
          xfElement.getAttribute('applyNumberFormat') == '1';
      final applyFont = xfElement.getAttribute('applyFont') == '1';
      final applyFill = xfElement.getAttribute('applyFill') == '1';
      final applyBorder = xfElement.getAttribute('applyBorder') == '1';
      final applyAlignment = xfElement.getAttribute('applyAlignment') == '1';
      final applyProtection = xfElement.getAttribute('applyProtection') == '1';

      return CellStyleXf(
        numFmtId: numFmtId,
        fontId: fontId,
        fillId: fillId,
        borderId: borderId,
        applyNumberFormat: applyNumberFormat,
        applyFont: applyFont,
        applyFill: applyFill,
        applyBorder: applyBorder,
        applyAlignment: applyAlignment,
        applyProtection: applyProtection,
      );
    }).toList();
  }

  static List<CellXf> _parseCellXfs(XmlElement stylesElement) {
    final cellXfsElement = stylesElement.findElements('cellXfs').firstOrNull;
    if (cellXfsElement == null) return [];
    final xfElements = cellXfsElement.findElements('xf');

    return xfElements.map((xfElement) {
      final numFmtId = int.tryParse(xfElement.getAttribute('numFmtId') ?? '');
      final fontId = int.tryParse(xfElement.getAttribute('fontId') ?? '');
      final fillId = int.tryParse(xfElement.getAttribute('fillId') ?? '');
      final borderId = int.tryParse(xfElement.getAttribute('borderId') ?? '');
      final xfId = int.tryParse(xfElement.getAttribute('xfId') ?? '');

      final applyNumberFormat =
          xfElement.getAttribute('applyNumberFormat') == '1';
      final applyFont = xfElement.getAttribute('applyFont') == '1';
      final applyFill = xfElement.getAttribute('applyFill') == '1';
      final applyBorder = xfElement.getAttribute('applyBorder') == '1';
      final applyAlignment = xfElement.getAttribute('applyAlignment') == '1';
      final applyProtection = xfElement.getAttribute('applyProtection') == '1';

      AlignmentDefinition? alignment;
      final alignmentElement = xfElement.findElements('alignment').firstOrNull;
      if (alignmentElement != null) {
        alignment = _parseAlignment(alignmentElement);
      }

      return CellXf(
        numFmtId: numFmtId,
        fontId: fontId,
        fillId: fillId,
        borderId: borderId,
        xfId: xfId,
        applyNumberFormat: applyNumberFormat,
        applyFont: applyFont,
        applyFill: applyFill,
        applyBorder: applyBorder,
        applyAlignment: applyAlignment,
        applyProtection: applyProtection,
        alignment: alignment,
      );
    }).toList();
  }

  static AlignmentDefinition _parseAlignment(XmlElement alignmentElement) {
    final horizontal = alignmentElement.getAttribute('horizontal');
    final vertical = alignmentElement.getAttribute('vertical');
    final wrapText = alignmentElement.getAttribute('wrapText') == '1';
    final indent = int.tryParse(alignmentElement.getAttribute('indent') ?? '');
    final textRotation = int.tryParse(
      alignmentElement.getAttribute('textRotation') ?? '',
    );

    return AlignmentDefinition(
      horizontal: horizontal,
      vertical: vertical,
      wrapText: wrapText,
      indent: indent,
      textRotation: textRotation,
    );
  }

  static List<CellStyle> _parseCellStyles(XmlElement stylesElement) {
    final cellStylesElement =
        stylesElement.findElements('cellStyles').firstOrNull;
    if (cellStylesElement == null) return [];
    final cellStyleElements = cellStylesElement.findElements('cellStyle');

    return cellStyleElements.map((cellStyleElement) {
      final name = cellStyleElement.getAttribute('name');
      final xfId = int.tryParse(cellStyleElement.getAttribute('xfId') ?? '');
      final builtinId = int.tryParse(
        cellStyleElement.getAttribute('builtinId') ?? '',
      );

      return CellStyle(name: name, xfId: xfId, builtinId: builtinId);
    }).toList();
  }

  static ColorMapping _parseColorMapping(
    XmlElement stylesElement,
    WorkbookTheme theme,
  ) {
    return ColorMapping(themeColors: theme.themeColors);
  }
}

// Supporting classes for styles components
class NumberFormat {
  final int id;
  final String formatCode;

  NumberFormat(this.id, this.formatCode);
}

class Font {
  final String? name;
  final double? size;
  final String? colorRgb;
  final int? colorTheme;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;

  Font({
    this.name,
    this.size,
    this.colorRgb,
    this.colorTheme,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
  });
}

class Fill {
  final String? patternType;
  final String? fgColorRgb;
  final int? fgColorTheme;
  final String? bgColorRgb;
  final int? bgColorTheme;

  Fill({
    this.patternType,
    this.fgColorRgb,
    this.fgColorTheme,
    this.bgColorRgb,
    this.bgColorTheme,
  });
}

class ColorMapping {
  final List<String> themeColors;

  ColorMapping({required this.themeColors});
}

class BorderSideStyle {
  final String? style;
  final String? colorRgb;
  final int? colorTheme;
  final int? colorIndexed;
  final bool? colorAuto;

  BorderSideStyle({
    this.style,
    this.colorRgb,
    this.colorTheme,
    this.colorIndexed,
    this.colorAuto,
  });
}

class BorderDefinition {
  final BorderSideStyle? left;
  final BorderSideStyle? right;
  final BorderSideStyle? top;
  final BorderSideStyle? bottom;
  final BorderSideStyle? diagonal;

  BorderDefinition({
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.diagonal,
  });

  static BorderSideStyle? parseBorderSide(
    XmlElement xmlElement,
    String side,
    WorkbookTheme theme,
  ) {
    final sideElement = xmlElement.getElement(side);
    if (sideElement != null) {
      final style = sideElement.getAttribute('style');
      final colorElement = sideElement.getElement('color');

      String? colorRgb;
      int? colorTheme;
      int? colorIndexed;
      bool? colorAuto;

      if (colorElement != null) {
        colorRgb = colorElement.getAttribute('rgb');
        final themeStr = colorElement.getAttribute('theme');
        final indexedStr = colorElement.getAttribute('indexed');
        final autoStr = colorElement.getAttribute('auto');

        colorTheme = themeStr != null ? int.tryParse(themeStr) : null;
        colorIndexed = indexedStr != null ? int.tryParse(indexedStr) : null;
        colorAuto = autoStr == '1';

        if (colorTheme != null && theme.themeColors.isNotEmpty) {
          // Map the theme color index to the actual color
          if (colorTheme >= 0 &&
              colorTheme < WorkbookTheme.themeColorNames.length) {
            final themeColor = theme.themeColors[colorTheme];
            colorRgb = themeColor;
          }
        }
      }
      if (style == null &&
          colorRgb == null &&
          colorTheme == null &&
          colorIndexed == null &&
          colorAuto == null) {
        return null;
      }

      return BorderSideStyle(
        style: style,
        colorRgb: colorRgb,
        colorTheme: colorTheme,
        colorIndexed: colorIndexed,
        colorAuto: colorAuto,
      );
    }
    return null;
  }

  static BorderDefinition? parseBorderDefinition(
    XmlElement xmlElement,
    WorkbookTheme theme,
  ) {
    final left = parseBorderSide(xmlElement, 'left', theme);
    final right = parseBorderSide(xmlElement, 'right', theme);
    final top = parseBorderSide(xmlElement, 'top', theme);
    final bottom = parseBorderSide(xmlElement, 'bottom', theme);
    final diagonal = parseBorderSide(xmlElement, 'diagonal', theme);

    if (left == null &&
        right == null &&
        top == null &&
        bottom == null &&
        diagonal == null) {
      return null;
    }

    return BorderDefinition(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      diagonal: diagonal,
    );
  }
}

class CellStyleXf {
  final int? numFmtId;
  final int? fontId;
  final int? fillId;
  final int? borderId;
  final bool applyNumberFormat;
  final bool applyFont;
  final bool applyFill;
  final bool applyBorder;
  final bool applyAlignment;
  final bool applyProtection;

  CellStyleXf({
    this.numFmtId,
    this.fontId,
    this.fillId,
    this.borderId,
    this.applyNumberFormat = false,
    this.applyFont = false,
    this.applyFill = false,
    this.applyBorder = false,
    this.applyAlignment = false,
    this.applyProtection = false,
  });
}

class CellXf {
  final int? numFmtId;
  final int? fontId;
  final int? fillId;
  final int? borderId;
  final int? xfId;
  final bool applyNumberFormat;
  final bool applyFont;
  final bool applyFill;
  final bool applyBorder;
  final bool applyAlignment;
  final bool applyProtection;
  final AlignmentDefinition? alignment;

  CellXf({
    this.numFmtId,
    this.fontId,
    this.fillId,
    this.borderId,
    this.xfId,
    this.applyNumberFormat = false,
    this.applyFont = false,
    this.applyFill = false,
    this.applyBorder = false,
    this.applyAlignment = false,
    this.applyProtection = false,
    this.alignment,
  });
}

class AlignmentDefinition {
  final String? horizontal;
  final String? vertical;
  final bool? _wrapText;

  bool get wrapText {
    if (horizontal == 'centerContinuous') {
      return false;
    }
    return _wrapText ?? false;
  }

  final int? indent;
  final int? textRotation;

  AlignmentDefinition({
    this.horizontal,
    this.vertical,
    bool? wrapText,
    this.indent,
    this.textRotation,
  }) : _wrapText = wrapText;
}

class CellStyle {
  final String? name;
  final int? xfId;
  final int? builtinId;

  CellStyle({this.name, this.xfId, this.builtinId});
}

class Workbook {
  final Styles styles;

  final Map<int, String> _sharedStrings;
  UnmodifiableMapView<int, String> get sharedStrings =>
      UnmodifiableMapView(_sharedStrings);

  final Map<int, String> sheetNamesById = {};
  final Map<String, int> sheetIdsByName = {};
  final Map<int, ArchiveFile> sheetArchiveFileById = {};
  final Map<String, ArchiveFile> sheetArchiveFileByName = {};
  final Map<int, ByteParsedWorksheet> sheetById = {};
  final Map<String, ByteParsedWorksheet> sheetByName = {};
  List<String> get sheetNames {
    final keysSorted = sheetNamesById.keys.toList()..sort();
    return keysSorted.map((key) => sheetNamesById[key]!).toList();
  }

  final String path;
  String get name => p.basename(path);

  factory Workbook.fromFilePath(String filePath) {
    final fileBytes = File(filePath).readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(fileBytes);

    return Workbook(path: filePath, archive: archive);
  }

  Workbook({required this.path, required Archive archive})
    : styles = archive.styles,
      _sharedStrings = archive.sharedStrings {
    final worksheets = archive.worksheets;
    for (final file in worksheets) {
      final sheetId = file.sheetId;
      final sheetName = archive.sheetNames[sheetId]!;
      sheetNamesById[sheetId] = sheetName;
      sheetIdsByName[sheetName] = sheetId;
      sheetArchiveFileById[sheetId] = file;
      sheetArchiveFileByName[sheetName] = file;
    }

    for (final entry in archive.sheetNames.entries) {
      sheetNamesById[entry.key] = entry.value;
      sheetIdsByName[entry.value] = entry.key;
    }
  }

  @override
  ByteParsedWorksheet operator [](Object index) {
    final ArchiveFile? archiveFile;
    final ByteParsedWorksheet? cachedWorksheet;

    if (index is int) {
      cachedWorksheet = sheetById[index];
      archiveFile = sheetArchiveFileById[index];
    } else if (index is String) {
      cachedWorksheet = sheetByName[index];
      archiveFile = sheetArchiveFileByName[index];
    } else {
      throw ArgumentError('Index must be an int or String');
    }

    if (cachedWorksheet != null) {
      return cachedWorksheet;
    }
    if (archiveFile == null) {
      throw ArgumentError('No sheet found for index: $index');
    }

    final name = sheetNamesById[archiveFile.sheetId]!;
    final worksheet = ByteParsedWorksheet(
      name: name,
      sheetArchiveFile: archiveFile,
      workbook: this,
    );

    sheetById[archiveFile.sheetId] = worksheet;
    sheetByName[name] = worksheet;
    sheetArchiveFileById.remove(archiveFile.sheetId);
    sheetArchiveFileByName.remove(name);

    return worksheet;
  }
}

extension _ExcelArchive on Archive {
  ArchiveFile get workbookFile {
    return firstWhere((file) => file.name == 'xl/workbook.xml');
  }

  ArchiveFile? get sharedStringsFile {
    return firstWhereOrNull((file) => file.name == 'xl/sharedStrings.xml');
  }

  Map<int, String> get sharedStrings {
    final xmlDoc = sharedStringsFile?.toXmlDocument();
    var innerTexts = xmlDoc?.findAllElements('si').map((si) => si.innerText);
    return innerTexts?.toList().asMap() ?? {};
  }

  Map<int, String> get sheetNames {
    final xmlDoc = workbookFile.toXmlDocument();
    var sheetNames = xmlDoc
        .findAllElements('sheet')
        .map((sheet) => sheet.getAttribute("name")!);
    return {for (final (index, sheet) in sheetNames.indexed) index + 1: sheet};
  }

  static const String stylesPath = 'xl/styles.xml';

  ArchiveFile get stylesFile => firstWhere((file) => file.name == stylesPath);

  Styles get styles {
    final theme = workbookTheme;

    return Styles.fromArchiveFile(stylesFile, theme);
  }

  static const String themePath = 'xl/theme/theme1.xml';

  ArchiveFile get themeFile => firstWhere((f) => f.name == themePath);

  WorkbookTheme get workbookTheme {
    XmlDocument xmlDocument = themeFile.toXmlDocument();

    final themeElement = xmlDocument.rootElement;

    final themeColors = WorkbookTheme._parseThemeColors(themeElement);

    return WorkbookTheme._(themeColors: themeColors);
  }

  Iterable<ArchiveFile> get worksheets => where((file) => file.isWorksheet);
}

extension ExcelSheetArchiveFile on ArchiveFile {
  int get sheetId {
    final regex = RegExp(r'xl/worksheets/sheet(\d+)\.xml');
    final match = regex.firstMatch(name);
    if (match == null) {
      throw ArgumentError("Invalid file name format: $name");
    }
    return int.parse(match.group(1)!);
  }

  static final RegExp _worksheetFilePattern = RegExp(
    r'xl/worksheets/sheet(\d+)\.xml',
  );

  bool get isWorksheet => _worksheetFilePattern.hasMatch(name);
}

Utf8Decoder utf8Decoder = const Utf8Decoder();

extension XmlArchiveFileExtension on ArchiveFile {
  XmlDocument toXmlDocument() {
    final List<int> data = content as List<int>;
    final stringContent = utf8Decoder.convert(data);
    return XmlDocument.parse(stringContent);
  }
}

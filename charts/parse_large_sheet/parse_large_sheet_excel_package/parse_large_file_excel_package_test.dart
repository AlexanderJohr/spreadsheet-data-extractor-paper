import 'dart:io';
import 'package:test/test.dart';
import 'package:excel/excel.dart';

void main() {
  const xlsxRelativePath =
      '../statistischer-bericht-pflegekraeftevorausberechnung-2070-5124210249005.xlsx';
  const sheetName = '12421-05';
  const firstCsvOutPath =
      'run_times_to_open_worksheet_dart_excel_package_first.csv';
  const lastCsvOutPath =
      'run_times_to_open_worksheet_dart_excel_package_last.csv';

  test('Open workbook 10x, verify cells, write CSV, report median', () {
    final filePath = File(xlsxRelativePath).absolute.path;
    final csvFile = File(firstCsvOutPath).absolute;

    csvFile.writeAsStringSync('Run Number,Time (seconds),DateTime\n');

    final times = <double>[];

    for (var i = 1; i <= 10; i++) {
      final sw = Stopwatch()..start();

      final bytes = File(filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel[sheetName];

      final a3 = sheet.cell(CellIndex.indexByString('A3')).value.toString();
      expect(a3, 'Age from ... to under ... Years');

      final b3 = sheet.cell(CellIndex.indexByString('B3')).value.toString();
      expect(b3, 'Nursing Staff');

      final b4 = sheet.cell(CellIndex.indexByString('B4')).value.toString();
      expect(b4, 'Year');

      final b5 = sheet.cell(CellIndex.indexByString('B5')).value.toString();
      expect(b5, '2024');

      final c5 = sheet.cell(CellIndex.indexByString('C5')).value.toString();
      expect(c5, '2029');

      final d5 = sheet.cell(CellIndex.indexByString('D5')).value.toString();
      expect(d5, '2034');

      final e5 = sheet.cell(CellIndex.indexByString('E5')).value.toString();
      expect(e5, '2039');

      final f5 = sheet.cell(CellIndex.indexByString('F5')).value.toString();
      expect(f5, '2044');

      final g5 = sheet.cell(CellIndex.indexByString('G5')).value.toString();
      expect(g5, '2049');

      final a6 = sheet.cell(CellIndex.indexByString('A6')).value.toString();
      expect(a6, 'Total');

      final b6 = sheet.cell(CellIndex.indexByString('B6')).value.toString();
      expect(b6, '1673');

      final c6 = sheet.cell(CellIndex.indexByString('C6')).value.toString();
      expect(c6, '1710');

      final d6 = sheet.cell(CellIndex.indexByString('D6')).value.toString();
      expect(d6, '1738');

      final e6 = sheet.cell(CellIndex.indexByString('E6')).value.toString();
      expect(e6, '1790');

      final f6 = sheet.cell(CellIndex.indexByString('F6')).value.toString();
      expect(f6, '1839');

      final g6 = sheet.cell(CellIndex.indexByString('G6')).value.toString();
      expect(g6, '1867');

      sw.stop();
      final secs = sw.elapsedMilliseconds / 1000.0;
      times.add(secs);

      csvFile.writeAsStringSync(
        '$i,${secs.toStringAsFixed(4)},${_formatNow()}\n',
        mode: FileMode.append,
      );

      print('Run $i: Time = ${secs.toStringAsFixed(4)} s');
    }

    final median = _median(times);
    print('Median time over 10 runs: ${median.toStringAsFixed(4)} s');
  });

  test(
    'Open workbook 10x (last row), verify cells, write CSV, report median',
    () {
      final filePath = File(xlsxRelativePath).absolute.path;
      final csvFile = File(lastCsvOutPath).absolute;

      csvFile.writeAsStringSync('Run Number,Time (seconds),DateTime\n');

      final times = <double>[];

      for (var i = 1; i <= 10; i++) {
        final sw = Stopwatch()..start();

        final bytes = File(filePath).readAsBytesSync();
        final excel = Excel.decodeBytes(bytes);
        final sheet = excel[sheetName];

        final a1048547 = sheet
            .cell(CellIndex.indexByString('A1048547'))
            .value
            .toString();
        expect(a1048547, '65 - 70');

        final b1048547 = sheet
            .cell(CellIndex.indexByString('B1048547'))
            .value
            .toString();
        expect(b1048547, '23');

        final c1048547 = sheet
            .cell(CellIndex.indexByString('C1048547'))
            .value
            .toString();
        expect(c1048547, '32');

        final d1048547 = sheet
            .cell(CellIndex.indexByString('D1048547'))
            .value
            .toString();
        expect(d1048547, '33');

        final e1048547 = sheet
            .cell(CellIndex.indexByString('E1048547'))
            .value
            .toString();
        expect(e1048547, '26');

        final f1048547 = sheet
            .cell(CellIndex.indexByString('F1048547'))
            .value
            .toString();
        expect(f1048547, '26');

        final g1048547 = sheet
            .cell(CellIndex.indexByString('G1048547'))
            .value
            .toString();
        expect(g1048547, '30');

        sw.stop();
        final secs = sw.elapsedMilliseconds / 1000.0;
        times.add(secs);

        csvFile.writeAsStringSync(
          '$i,${secs.toStringAsFixed(4)},${_formatNow()}\n',
          mode: FileMode.append,
        );

        print('Run $i: Time = ${secs.toStringAsFixed(4)} s');
      }

      final median = _median(times);
      print('Median time over 10 runs: ${median.toStringAsFixed(4)} s');
    },
  );
}

double _median(List<double> values) {
  if (values.isEmpty) return double.nan;
  final copy = [...values]..sort();
  final n = copy.length;
  if (n.isOdd) {
    return copy[n ~/ 2];
  } else {
    final a = copy[n ~/ 2 - 1];
    final b = copy[n ~/ 2];
    return (a + b) / 2.0;
  }
}

String _formatNow() {
  final now = DateTime.now();
  String two(int x) => x.toString().padLeft(2, '0');
  final y = now.year.toString().padLeft(4, '0');
  final m = two(now.month);
  final d = two(now.day);
  final hh = two(now.hour);
  final mm = two(now.minute);
  final ss = two(now.second);
  return '$y-$m-$d $hh:$mm:$ss';
}

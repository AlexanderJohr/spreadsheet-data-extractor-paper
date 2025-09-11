import 'dart:io';
import 'package:test/test.dart';
import 'package:smedahidesdex/src/utils/excel_decoder/workbook.dart';

void main() {
  const xlsxRelativePath =
      '../statistischer-bericht-pflegekraeftevorausberechnung-2070-5124210249005.xlsx';
  const sheetName = '12421-05';
  const firstCsvOutPath = 'run_times_to_open_worksheet_sde_first.csv';
  const lastCsvOutPath = 'run_times_to_open_worksheet_sde_last.csv';

  test('Open workbook 10×, verify cells, write CSV, report median', () {
    final filePath = File(xlsxRelativePath).absolute.path;
    final csvFile = File(firstCsvOutPath).absolute;

    csvFile.writeAsStringSync('Run Number,Time (seconds),DateTime\n');

    final times = <double>[];

    for (var i = 1; i <= 10; i++) {
      final sw = Stopwatch()..start();

      final workbook = Workbook.fromFilePath(filePath);
      final sheet = workbook[sheetName];

      final a3 = sheet.row(3)?.cell(1)?.value;
      expect(a3, 'Age from ... to under ... Years');

      final b3 = sheet.row(3)?.cell(2)?.value;
      expect(b3, 'Nursing Staff');

      final b4 = sheet.row(4)?.cell(2)?.value;
      expect(b4, 'Year');

      final b5 = sheet.row(5)?.cell(2)?.value;
      expect(b5, '2024');

      final c5 = sheet.row(5)?.cell(3)?.value;
      expect(c5, '2029');

      final d5 = sheet.row(5)?.cell(4)?.value;
      expect(d5, '2034');

      final e5 = sheet.row(5)?.cell(5)?.value;
      expect(e5, '2039');

      final f5 = sheet.row(5)?.cell(6)?.value;
      expect(f5, '2044');

      final g5 = sheet.row(5)?.cell(7)?.value;
      expect(g5, '2049');

      final a6 = sheet.row(6)?.cell(1)?.value;
      expect(a6, 'Total');

      final b6 = sheet.row(6)?.cell(2)?.value;
      expect(b6, '1673');

      final c6 = sheet.row(6)?.cell(3)?.value;
      expect(c6, '1710');

      final d6 = sheet.row(6)?.cell(4)?.value;
      expect(d6, '1738');

      final e6 = sheet.row(6)?.cell(5)?.value;
      expect(e6, '1790');

      final f6 = sheet.row(6)?.cell(6)?.value;
      expect(f6, '1839');

      final g6 = sheet.row(6)?.cell(7)?.value;
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
    'Open workbook 10× (last row), verify cells, write CSV, report median',
    () {
      final filePath = File(xlsxRelativePath).absolute.path;
      final csvFile = File(lastCsvOutPath).absolute;

      csvFile.writeAsStringSync('Run Number,Time (seconds),DateTime\n');

      final times = <double>[];

      for (var i = 1; i <= 10; i++) {
        final sw = Stopwatch()..start();

        final workbook = Workbook.fromFilePath(filePath);
        final sheet = workbook[sheetName];

        final a1048547 = sheet.row(1048547)?.cell(1)?.value;
        expect(a1048547, '65 - 70');

        final b1048547 = sheet.row(1048547)?.cell(2)?.value;
        expect(b1048547, '23');

        final c1048547 = sheet.row(1048547)?.cell(3)?.value;
        expect(c1048547, '32');

        final d1048547 = sheet.row(1048547)?.cell(4)?.value;
        expect(d1048547, '33');

        final e1048547 = sheet.row(1048547)?.cell(5)?.value;
        expect(e1048547, '26');

        final f1048547 = sheet.row(1048547)?.cell(6)?.value;
        expect(f1048547, '26');

        final g1048547 = sheet.row(1048547)?.cell(7)?.value;
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

import 'dart:io';
import 'package:test/test.dart';
import 'package:excel/excel.dart';

void main() {
  const xlsxRelativePath =
      '../statistischer-bericht-rechnungsergebnis-kernhaushalt-gemeinden-2140331217005.xlsx';
  const sheetName = '71717-01';
  const csvOutPath = 'run_times_to_open_worksheet_dart.csv';

  test('Open workbook 10×, verify cells, write CSV, report median', () {
    final filePath = File(xlsxRelativePath).absolute.path;
    final csvFile = File(csvOutPath).absolute;

    csvFile.writeAsStringSync('Run Number,Time (seconds),DateTime\n');

    final times = <double>[];
    final errors = <String>[];

    for (var i = 1; i <= 10; i++) {
      final sw = Stopwatch()..start();

      late Excel excel;
      final bytes = File(filePath).readAsBytesSync();
      excel = Excel.decodeBytes(bytes);

      final sheet = excel.sheets[sheetName];
      if (sheet == null) {
        errors.add('Run $i: Arbeitsblatt "$sheetName" nicht gefunden.');
      } else {
        final a3 = sheet.cell(CellIndex.indexByString('A3')).value.toString();
        expect(a3, 'Jahr');

        final b4 = sheet.cell(CellIndex.indexByString('B4')).value.toString();
        expect(b4, 'Insgesamt');

        final a6 = sheet.cell(CellIndex.indexByString('A6')).value.toString();
        expect(a6, '2021');

        final b6 = sheet.cell(CellIndex.indexByString('B6')).value.toString();
        expect(b6, '286710');
      }

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

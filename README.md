# Reproducing the Results

This repository contains:

* **Spreadsheet Data Extractor (SDE)** source (`/spreadsheet_data_extractor`) incl. the optimized byte-level parser used in benchmarks.
* **Benchmarks** and **chart generators** under `/charts`, covering:

  * **Large multi-worksheet workbook** (open one selected sheet).
* **LaTeX sources** for the paper (`main.tex` and supporting `.tex` files), plus all required assets in the `images/` folder.

All benchmark scripts write CSVs and the Python scripts render the box plots used in the paper.

---

## 1) Requirements

### OS / Tools

* **Windows** (Excel COM automation requires Windows + Excel)
* **Microsoft Excel** (version 16.x tested)
* **PowerShell** (Windows built-in; allow script execution or use `-ExecutionPolicy Bypass`)
* **Python** 3.10+ (create a venv and install `requirements.txt`)
* **Dart** SDK (for Dart tests)
* **Flutter** (for SDE UI; `flutter doctor` should pass)
* **VS Code** (optional, but simplifies running everything)

### VS Code extensions (recommended)

* **Dart** (Dart-Code.dart-code)
* **Flutter** (Dart-Code.flutter)
* **Python** (ms-python.python)
* **PowerShell** (ms-vscode.PowerShell)

---

## 2) Quick start (VS Code “Run and Debug”)

We provide **ready-made launch configurations** in `.vscode/launch.json`.
Open the repo in VS Code → **Run and Debug** (Ctrl/Cmd+Shift+D) → pick a config:

### SDE app

* **Spreadsheet Data Extractor (Debug)**
* **Spreadsheet Data Extractor (Release)**
* **Spreadsheet Data Extractor (Profile)**

### Benchmarks — Single worksheet (first vs. last row)

* **Run Tests for Parse Large Sheet with SDE**
* **Run Tests for Parse Large Sheet with Excel Package**
* **Run Microsoft Excel to Parse Single Worksheet (PowerShell)**

### Benchmarks — Large multi-worksheet workbook (open one sheet)

* **Run Tests for Parse Large File with SDE**
* **Run Tests for Parse Large File with Excel Package**
* **Run Microsoft Excel to Parse Large Workbook (PowerShell)**

### Chart generation (after CSVs exist)

* **Generate Boxplot Run Times to Open Large Worksheet**
* **Generate Boxplot Run Times to Open Worksheet from Large Workbook**

> If PowerShell complains about script execution, VS Code runs these with an integrated console and `ExecutionPolicy Bypass`. Otherwise, set in a terminal:
> `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

---

## 3) Command-line (no VS Code)

### 3.1. Python environment

```powershell
# from repo root
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

### 3.2. Dart / Flutter

```powershell
# Verify
dart --version
flutter --version
flutter doctor
```

---

## 4) Running the Benchmarks

### 4.1. Single-worksheet benchmark (first rows vs. last row)

This measures SDE’s **time-to-first-visual** vs. **full-parse** under identical workload.

#### SDE (Dart test)

```powershell
dart test charts/parse_large_sheet/parse_large_sheet_sde/parse_large_sheet_sde_test.dart -r expanded
# Produces:
#   charts/parse_large_sheet/parse_large_sheet_sde/run_times_to_open_worksheet_sde_first.csv
#   charts/parse_large_sheet/parse_large_sheet_sde/run_times_to_open_worksheet_sde_last.csv
```

#### Excel Package (Dart test)

```powershell
dart test charts/parse_large_sheet/parse_large_sheet_excel_package/parse_large_sheet_excel_package_test.dart -r expanded
# Produces:
#   charts/parse_large_sheet/parse_large_sheet_excel_package/run_times_to_open_worksheet_dart_excel_package_first.csv
#   charts/parse_large_sheet/parse_large_sheet_excel_package/run_times_to_open_worksheet_dart_excel_package_last.csv
```

#### Microsoft Excel (PowerShell / COM)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File charts/parse_large_sheet/parse_large_sheet_microsoft_excel/parse_large_file_microsoft_excel.ps1
# Produces:
#   charts/parse_large_sheet/parse_large_sheet_microsoft_excel/run_times_to_open_worksheet_powershell_first.csv
#   charts/parse_large_sheet/parse_large_sheet_microsoft_excel/run_times_to_open_worksheet_powershell_last.csv
```

### 4.2. Large multi-worksheet workbook (open one selected sheet)

This measures **user-centred latency** (open only the selected sheet).

#### SDE (Dart test)

```powershell
dart test charts/parse_large_file/parse_large_file_sde/parse_large_file_sde_test.dart -r expanded
# Produces:
#   charts/parse_large_file/parse_large_file_sde/run_times_to_open_worksheet_sde.csv
```

#### Excel Package (Dart test)

```powershell
dart test charts/parse_large_file/parse_large_file_excel_package/parse_large_file_excel_package_test.dart -r expanded
# Produces (often only first run due to OOM on large file):
#   charts/parse_large_file/parse_large_file_excel_package/run_times_to_open_worksheet_dart.csv
```

#### Microsoft Excel (PowerShell / COM)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass `
  -File charts/parse_large_file/parse_large_file_microsoft_excel/parse_large_file_microsoft_excel_powershell.ps1
# Produces:
#   charts/parse_large_file/parse_large_file_microsoft_excel/run_times_to_open_worksheet_powershell.csv
```

---

## 5) Generating the Charts (after CSVs exist)

### Single-worksheet (first vs. last row)

```powershell
. .venv\Scripts\activate
python charts/parse_large_sheet/generate_boxplot_run_times_to_open_large_sheet.py
# Output PDF:
#   charts/parse_large_sheet/generate_boxplot_run_times_to_open_large_sheet.pdf
```

### Large multi-worksheet (open one sheet)

```powershell
. .venv\Scripts\activate
python charts/parse_large_file/generate_boxplot_run_times_to_open_worksheet_from_large_workbook.py
# Output PDF:
#   charts/parse_large_file/generate_boxplot_run_times_to_open_large_sheet.pdf
#   (or as configured in the script)
```

> The Python scripts expect the CSV files named above to exist in the same directories.

---

## 6) Running the SDE UI

From repo root:

```powershell
flutter run -d windows -t spreadsheet_data_extractor/lib/main.dart   # debug
flutter run -d windows -t spreadsheet_data_extractor/lib/main.dart --release
flutter run -d windows -t spreadsheet_data_extractor/lib/main.dart --profile
```

Or use the VS Code launch configs:

* **Spreadsheet Data Extractor (Debug / Release / Profile)**

---

## 7) Troubleshooting

* **PowerShell cannot run scripts**
  Use the `-ExecutionPolicy Bypass` flag or run:
  `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`

* **Dart `excel` package OOM**
  On the large multi-worksheet scenario, the Dart package often runs out of memory after the first run. This is expected and documented.

* **Python missing packages**
  Activate the venv and run `pip install -r requirements.txt`.

* **Paths**
  All scripts assume the checked-in XLSX files remain in their default locations under `/charts/...`.

---

## 8) Paper build

The LaTeX manuscript is in the repo root (`main.tex`).
It can be build via `latexmk` or `pdflatex`/`lualatex` per your workflow.

---

## 9) Environment reference (used in paper)

* **OS**: Windows 11 Enterprise (build 26100, 64-bit)
* **CPU**: AMD Ryzen 5 PRO 7535U (6-core, 2.9 GHz)
* **RAM**: 31.3 GB
* **Disk**: HDD
* **Excel**: Microsoft Office 16.0

---

If anything is unclear or a path differs on your machine, the VS Code launch configs are the quickest way to run the exact scripts used in the paper.

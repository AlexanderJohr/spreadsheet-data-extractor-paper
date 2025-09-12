# Spreadsheet Data Extractor — Reproducibility Pack

This artifact contains (i) the **Spreadsheet Data Extractor (SDE)** source (including the optimized parser used by the benchmarks), (ii) **benchmark scripts** for SDE, Microsoft Excel (via PowerShell/COM), and a Dart `excel` package, (iii) **CSV outputs** produced by the benchmarks, (iv) **plotting scripts** that generate the box plots shown in the paper, and (v) the **paper sources** (`main.tex`).

> **TL;DR (VS Code users):** Open the folder in VS Code and use the two launch targets in `.vscode/launch.json` to render the two charts *after* you have run the benchmarks to produce the CSVs.


---

## Prerequisites

* **OS**

  * Windows 10/11 **required** for the Microsoft Excel/COM benchmarks.
* **Microsoft Excel** (Desktop 2019/2021/365). The PowerShell scripts launch Excel via COM.
* **PowerShell** 5+ (comes with Windows).
  You may need to temporarily allow script execution:

  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
* **Python** 3.9+ (for plotting) with `pip`.
* **Dart SDK** 3.x (for SDE and `excel` package benchmarks).

  * If you run the SDE app itself, **Flutter** 3.x is needed, but the benchmarks here are pure Dart.
* **TeX** (optional, to build the paper): TeX Live/MiKTeX; build with `latexmk` or `pdflatex`.

---

## Setup (Python for plots)

```powershell
# from the repository root
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

> Linux/macOS:
>
> ```bash
> python3 -m venv .venv
> source .venv/bin/activate
> pip install -r requirements.txt
> ```

---

## Running the benchmarks

> **Tip:** Close any already running Excel instances before starting the Excel/COM benchmarks. If Excel gets stuck, you can kill it with:
>
> ```powershell
> Get-Process EXCEL -ErrorAction SilentlyContinue | Stop-Process -Force
> ```

### A) Single-worksheet benchmark (first rows vs last row)

**1) Microsoft Excel (PowerShell/COM)**

```powershell
cd charts/parse_large_sheet/parse_large_sheet_microsoft_excel
# produces ..._powershell_first.csv and ..._powershell_last.csv
.\parse_large_file_microsoft_excel.ps1
```

**2) SDE (Dart)**

```powershell
cd charts/parse_large_sheet/parse_large_sheet_sde
dart pub get
# Runs both “first rows” and “last row” tests and writes the CSVs
dart test parse_large_sheet_sde_test.dart
# or, if the file is a standalone script:
# dart run parse_large_sheet_sde_test.dart
```

**3) Dart "excel" package**

```powershell
cd charts/parse_large_sheet/parse_large_sheet_excel_package
dart pub get
dart test parse_large_file_excel_package_test.dart
# (On large sheets this package may run out of memory; first/last CSVs are still written if the run completes.)
```

### B) Large multi-worksheet workbook (open one selected sheet)

**1) Microsoft Excel (PowerShell/COM)**

```powershell
cd charts/parse_large_file/parse_large_file_microsoft_excel
.\parse_large_file_microsoft_excel_powershell.ps1
# writes run_times_to_open_worksheet_powershell.csv
```

**2) SDE (Dart)**

```powershell
cd charts/parse_large_file/parse_large_file_sde
dart pub get
dart test parse_large_file_sde_test.dart
# writes run_times_to_open_worksheet_sde.csv
```

**3) Dart "excel" package**

```powershell
cd charts/parse_large_file/parse_large_file_excel_package
dart pub get
dart test parse_large_file_excel_package_test.dart
# writes run_times_to_open_worksheet_dart.csv (may be a single run due to OOM)
```

---

## Generating the plots

After the CSVs exist (from the steps above), run:

```powershell
# 1) Single-worksheet: first vs last row
cd charts/parse_large_sheet
python generate_boxplot_run_times_to_open_large_sheet.py
# -> generates generate_boxplot_run_times_to_open_large_sheet.pdf

# 2) Multi-worksheet workbook: open one selected sheet
cd ..\parse_large_file
python generate_boxplot_run_times_to_open_worksheet_from_large_workbook.py
# -> generates generate_boxplot_run_times_to_open_large_sheet.pdf (in this folder)
```

> **VS Code:** You can also press **Run** on the two launch configurations in `.vscode/launch.json`:
>
> * “Generate Boxplot Run Times to Open Large Worksheet”
> * “Generate Boxplot Run Times to Open Worksheet from Large Workbook”
>   (These launchers only *plot*; they assume the CSVs already exist.)

---

## Building the paper

From the repository root (where `main.tex` lives):

```powershell
latexmk -pdf -interaction=nonstopmode main.tex
# or
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

The generated figures in `charts/.../*.pdf` are referenced by the LaTeX source.

---

## Notes & caveats

* **Excel/COM automation:** Requires desktop Excel on Windows. Scripts open Excel, time the operation, and close it. If Excel stays alive (e.g., a crash), terminate it as shown above.
* **Dart `excel` package:** On very large sheets it may run out of memory; in our runs some measurements produced only a single CSV row. This behavior is expected and documented in the paper.


---

## Contact / questions

If anything is unclear or you encounter issues reproducing the results, please include:

* the script you ran and its full console output,
* your OS + Excel version,
* your Dart/Python versions.

Thanks for taking the time to reproduce the experiments!

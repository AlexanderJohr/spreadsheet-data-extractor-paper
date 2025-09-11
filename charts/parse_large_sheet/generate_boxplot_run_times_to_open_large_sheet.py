import pandas as pd
import matplotlib.pyplot as plt
import os
import sys
from matplotlib.ticker import LogLocator, FixedLocator, FuncFormatter


# ---------- helpers ----------
def read_csv_file(filepath):
    try:
        data = pd.read_csv(filepath)
        print(f"Successfully loaded file '{filepath}'.")
        return data
    except FileNotFoundError:
        print(f"Error: File '{filepath}' not found.")
        sys.exit(1)
    except pd.errors.EmptyDataError:
        print(f"Error: File '{filepath}' is empty.")
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        sys.exit(1)


def format_major(x, pos):
    return f"{x:.1f} s"


def format_minor(x, pos):
    return f"{x:.1f} s" if x >= 0.1 else ""


# ---------- paths ----------
script_dir = os.path.dirname(os.path.abspath(__file__))

# First-rows CSVs
dartpkg_first = os.path.join(
    script_dir,
    "parse_large_sheet_excel_package/run_times_to_open_worksheet_dart_excel_package_first.csv",
)
excel_first = os.path.join(
    script_dir,
    "parse_large_sheet_microsoft_excel/run_times_to_open_worksheet_powershell_first.csv",
)
sde_first = os.path.join(
    script_dir,
    "parse_large_sheet_sde/run_times_to_open_worksheet_sde_first.csv",
)

# Last-row CSVs
sde_last = os.path.join(
    script_dir,
    "parse_large_sheet_sde/run_times_to_open_worksheet_sde_last.csv",
)
excel_last = os.path.join(
    script_dir,
    "parse_large_sheet_microsoft_excel/run_times_to_open_worksheet_powershell_last.csv",
)
dartpkg_last = os.path.join(
    script_dir,
    "parse_large_sheet_excel_package/run_times_to_open_worksheet_dart_excel_package_last.csv",
)

# ---------- load ----------
df_dart_first = read_csv_file(dartpkg_first)
df_excel_first = read_csv_file(excel_first)
df_sde_first = read_csv_file(sde_first)

df_sde_last = read_csv_file(sde_last)
df_excel_last = read_csv_file(excel_last)
df_dart_last = read_csv_file(dartpkg_last)

# ---------- data (order = grouped by program: SDE, Excel, Dart) ----------
epsilon = 1e-6
data_to_plot = [
    # SDE
    df_sde_first["Time (seconds)"].replace(0, epsilon),
    df_sde_last["Time (seconds)"].replace(0, epsilon),
    # Microsoft Excel
    df_excel_first["Time (seconds)"].replace(0, epsilon),
    df_excel_last["Time (seconds)"].replace(0, epsilon),
    # Dart Excel Package
    df_dart_first["Time (seconds)"].replace(0, epsilon),
    df_dart_last["Time (seconds)"].replace(0, epsilon),
]

labels = [
    "Spreadsheet Data Extractor\n(first rows)",
    "Spreadsheet Data Extractor\n(last row)",
    "Microsoft Excel\n(first rows)",
    "Microsoft Excel\n(last row)",
    "Dart Excel Package\n(first rows)",
    "Dart Excel Package\n(last row)",
]

# ---------- plot ----------
plt.figure(figsize=(12, 3.7))

box = plt.boxplot(
    data_to_plot,
    patch_artist=True,
    labels=labels,
    vert=False,
)

# colours (two tints per program for visual grouping)
colors = [
    "lightblue",
    "royalblue",  # SDE: first, last
    "lightgreen",
    "seagreen",  # Excel: first, last
    "lightcoral",
    "indianred",  # Dart: first, last
]
for patch, color in zip(box["boxes"], colors):
    patch.set_facecolor(color)

plt.title(
    "Execution Times: First vs Last Row of Large Worksheet (Grouped by Program)",
    fontsize=18,
)
plt.xlabel("Time (seconds, log$_{10}$ scale)", fontsize=14)
plt.ylabel("Program & case", fontsize=14)

ax = plt.gca()
ax.set_xscale("log")

# major ticks at powers of 10
ax.xaxis.set_major_locator(LogLocator(base=10.0, subs=(1.0,)))

# minor ticks (2,4,6,8 within each decade) across a reasonable range
minor_bases = [0.1, 1, 10, 100, 1000, 10000]
minor_tick_values = []
for base in minor_bases:
    minor_tick_values.extend([base * i for i in (2, 4, 6, 8)])
ax.xaxis.set_minor_locator(FixedLocator(minor_tick_values))

ax.xaxis.set_major_formatter(FuncFormatter(format_major))
ax.xaxis.set_minor_formatter(FuncFormatter(format_minor))

# minor tick line length for visibility
ax.tick_params(which="minor", length=5)

# rotate labels slightly for readability
plt.xticks(rotation=45)

# grid
ax.grid(True, which="major", linestyle="--", linewidth=0.5, alpha=0.7)
ax.grid(True, which="minor", linestyle=":", linewidth=0.5, alpha=0.5)

# visual group separators between programs (after row 2 and row 4)
ax.axhline(2.5, color="gray", linewidth=0.8, alpha=0.5)
ax.axhline(4.5, color="gray", linewidth=0.8, alpha=0.5)

plt.tight_layout()
output_path = os.path.join(
    script_dir,
    "generate_boxplot_run_times_to_open_large_sheet.pdf",
)
plt.savefig(
    output_path,
    bbox_inches="tight",
    dpi=300,
)
plt.show()

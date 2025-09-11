import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os
import sys
import matplotlib.ticker as ticker
from matplotlib.ticker import LogLocator, FixedLocator, FuncFormatter


# Function to read CSV files with error handling
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


# Absolute path to the script directory
script_dir = os.path.dirname(os.path.abspath(__file__))

# Paths to the CSV files using the absolute path
file1 = os.path.join(
    script_dir,
    "parse_large_file_excel_package/run_times_to_open_worksheet_dart.csv",
)
file2 = os.path.join(
    script_dir,
    "parse_large_file_microsoft_excel/run_times_to_open_worksheet_powershell.csv",
)
file3 = os.path.join(
    script_dir,
    "parse_large_file_sde/run_times_to_open_worksheet_sde.csv",
)


# Read the CSV files with error handling
script1 = read_csv_file(file1)
script2 = read_csv_file(file2)
script3 = read_csv_file(file3)

# Replace zero values with a small positive constant to handle log scale
epsilon = 1e-6
data_to_plot = [
    script3["Time (seconds)"].replace(0, epsilon),
    script2["Time (seconds)"].replace(0, epsilon),
    script1["Time (seconds)"].replace(0, epsilon),
]

# Create the horizontal box plot with increased height for better label rotation
plt.figure(figsize=(12, 3))  # Reduced height from 4 to 2

box = plt.boxplot(
    data_to_plot,
    patch_artist=True,
    labels=["Spreadsheet Data Extractor", "Microsoft Excel", "Dart Excel Package"],
    vert=False,
)

# Customize box plot colors
colors = ["lightblue", "lightgreen", "lightcoral"]
for patch, color in zip(box["boxes"], colors):
    patch.set_facecolor(color)

# Add titles and labels with adjusted font sizes for better fit
plt.title("Comparison of Execution Times for Opening One Excel Sheet", fontsize=20)
plt.xlabel("Time (seconds, log$_{10}$ scale)", fontsize=16)
plt.ylabel("Program", fontsize=16)

# Set x-axis to pure logarithmic scale
plt.xscale("log")

# Get the current axis
ax = plt.gca()

# Set major ticks at each power of ten
ax.xaxis.set_major_locator(LogLocator(base=10.0, subs=(1.0,)))

# Define minor ticks only above 0.1, excluding base * 1 to prevent overlap
minor_tick_values = []

# Define the range based on the current x-axis limits
xmin, xmax = ax.get_xlim()

# Generate minor ticks from 0.1 upwards, excluding base * 1
bases = [0.1, 1, 10, 100, 1000]  # Extend this list based on your data's maximum value
for base in bases:
    minor_tick_values.extend(
        [base * i for i in [2, 4, 6, 8]]
    )  # Exclude 1 to prevent overlap

# Set minor ticks using FixedLocator
ax.xaxis.set_minor_locator(FixedLocator(minor_tick_values))


# Define a formatter function for the major ticks
def format_major(x, pos):
    return f"{x:.1f} s"


# Define a formatter function for the minor ticks
def format_minor(x, pos):
    return f"{x:.1f} s" if x >= 0.1 else ""


# Apply the formatter to the x-axis
ax.xaxis.set_major_formatter(FuncFormatter(format_major))
ax.xaxis.set_minor_formatter(FuncFormatter(format_minor))

# Restore minor tick lines by setting their length to 5 points
ax.tick_params(which="minor", length=5)  # Changed from length=0 to length=5

# Rotate major tick labels by 45 degrees
plt.xticks(rotation=45)  # Method 1: Using plt.xticks

# Alternatively, you can use Method 2:
# ax.tick_params(axis='x', labelrotation=45)

# Rotate minor tick labels by 45 degrees
for label in ax.get_xticklabels(which="minor"):
    label.set_rotation(45)

# Add grid lines for major ticks
ax.grid(True, which="major", linestyle="--", linewidth=0.5, alpha=0.7)

# Add grid lines for minor ticks with less prominent style
ax.grid(True, which="minor", linestyle=":", linewidth=0.5, alpha=0.5)

# Ensure layout is tight to prevent clipping of rotated labels
plt.tight_layout()

output_path = os.path.join(
    script_dir,
    "generate_boxplot_run_times_to_open_large_sheet.pdf",
)
# Save the plot as a PDF with higher DPI for better quality (optional)
plt.savefig(output_path, bbox_inches="tight", dpi=300)

# Display the plot
plt.show()

# Spreadsheet Data Extractor (SDE)

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Introduction

The **Spreadsheet Data Extractor (SDE)** is a performance-optimized, user-centric Flutter application designed to transform semi-structured Excel spreadsheets into structured relational data. SDE empowers users to convert complex spreadsheet formats into machine-readable data without requiring any programming knowledge. By leveraging incremental worksheet loading and optimized rendering techniques, SDE ensures efficient handling of large datasets, enhancing both speed and usability.

## Features

- **User-Friendly Interface:** Intuitive graphical interface that allows users to define data hierarchies through simple cell selection.
- **Hierarchy Management:** Easily duplicate and apply hierarchies to similar data structures, streamlining repetitive tasks.
- **Incremental Worksheet Loading:** Efficiently handles large Excel files by loading worksheets incrementally, reducing memory usage and improving performance.
- **Accurate Rendering:** Precisely renders row heights and column widths by parsing Excel's XML content, closely matching the original spreadsheet's appearance.
- **Optimized Performance:** Renders only the visible cells within the viewport, ensuring smooth and responsive interactions even with extensive datasets.

## Installation

### Prerequisites

- **Flutter SDK:** Ensure that you have Flutter installed on your machine. If not, follow the [official Flutter installation guide](https://flutter.dev/docs/get-started/install).
- **Dart SDK:** Flutter includes the Dart SDK, so no separate installation is required.

### Steps

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/yourusername/spreadsheet-data-extractor.git
   cd spreadsheet-data-extractor
   ```

2. **Install Dependencies:**

   Run the following command to fetch all necessary packages:

   ```bash
   flutter pub get
   ```

3. **Run the Application:**

   Launch the app on your desired platform (emulator, simulator, or physical device):

   ```bash
   flutter run lib/main.dart
   ```

## Usage

1. **Launch the Application:**

   After running `flutter run`, the SDE interface will appear.

2. **Load an Excel File:**

   - Click on the "import Excel files" button.
   - Select the `.xlsx` file you wish to process.

3. **Define Data Hierarchies:**

   - **Select Cells:** Click on individual cells or use shift-click for multi-selection to define data and metadata. Use shift-click to
   mege cells.
   - **Hierarchy Panel:** Organize your selections into a hierarchical tree structure in the top-left panel.
   - **Duplicate Hierarchies:** Use the "Move and Duplicate" feature to apply hierarchies to similar data structures efficiently.

4. **Preview and Export:**

   - **Output Preview:** View the extracted relational data in real-time in the bottom panel.
   - **Export Data:** Click on the "Export" button to save the structured data as a CSV file.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).


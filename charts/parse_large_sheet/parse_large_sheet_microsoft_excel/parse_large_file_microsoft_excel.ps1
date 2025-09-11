param(
  # Adjust the default path if needed; kept similar to your Dart relative path.
  [string] $FilePath = (Join-Path (Split-Path -Parent $PSCommandPath) '..\statistischer-bericht-pflegekraeftevorausberechnung-2070-5124210249005.xlsx'),
  [string] $SheetName = '12421-05',
  [ValidateSet('top','last','both')]
  [string] $Case = 'both',
  [int]    $Runs = 10,
  [switch] $ColdStart
)

# ---------------- Helpers ----------------

function New-ExcelApp {
  $excel = New-Object -ComObject Excel.Application
  $excel.Visible = $false
  $excel.DisplayAlerts = $false
  try { $excel.ScreenUpdating = $false } catch {}
  try { $excel.AskToUpdateLinks = $false } catch {}
  return $excel
}

function Close-Workbook([object]$wb) {
  if ($null -ne $wb) {
    try { $wb.Close($false) | Out-Null } catch {}
    try { [Runtime.InteropServices.Marshal]::ReleaseComObject($wb) | Out-Null } catch {}
  }
}

function Release-Com([object]$obj) {
  if ($null -ne $obj) {
    try { [Runtime.InteropServices.Marshal]::ReleaseComObject($obj) | Out-Null } catch {}
  }
}

function Quit-Excel([object]$excel) {
  if ($null -ne $excel) {
    try { $excel.Quit() } catch {}
    Release-Com $excel
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
    [GC]::Collect(); [GC]::WaitForPendingFinalizers()
  }
}

function Now-Stamp { (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }

function Expect-String($errors, [int]$run, $actual, [string]$expected, [string]$cellRef) {
  if ([string]$actual -ne $expected) {
    $errors.Add("Run {0}: {1} != '{2}' (was '{3}')" -f $run, $cellRef, $expected, ($actual -as [string]))
  }
}

function Expect-NumStr($errors, [int]$run, $actual, [int]$expectedNum, [string]$cellRef) {
  if (-not (Equals-NumOrString $actual $expectedNum)) {
    $errors.Add("Run {0}: {1} != {2} (was '{3}')" -f $run, $cellRef, $expectedNum, ($actual -as [string]))
  }
}

function Get-Median([double[]]$vals) {
  if (!$vals -or $vals.Count -eq 0) { return [double]::NaN }
  $sorted = $vals | Sort-Object
  $n = $sorted.Count
  if ($n % 2 -eq 1) { return [double]$sorted[[int][math]::Floor($n/2)] }
  ($sorted[$n/2 - 1] + $sorted[$n/2]) / 2.0
}

function Run-Case([string]$caseName, [string]$csvName, [string]$filePath, [string]$sheetName, [int]$runs, [switch]$coldStart) {
  "Run Number,Time (seconds),DateTime" | Set-Content -Encoding UTF8 $csvName

  $times  = New-Object System.Collections.Generic.List[double]
  $errors = New-Object System.Collections.Generic.List[string]

  $excel = $null
  if (-not $coldStart) { $excel = New-ExcelApp }

  for ($i = 1; $i -le $runs; $i++) {
    if ($coldStart) { $excel = New-ExcelApp }

    $sw = [Diagnostics.Stopwatch]::StartNew()
    $wb = $null
    $ws = $null
    try {
      $wb = $excel.Workbooks.Open($filePath, 0, $true)  # read-only
      $ws = $wb.Worksheets.Item($sheetName)
      if ($null -eq $ws) {
        $errors.Add("Run {0}: Worksheet '{1}' not found." -f $i, $sheetName)
      } else {
        switch ($caseName) {
          'top' {
                $a3 = $ws.Cells.Item(3,1).Value2
                Expect-String   $errors $i $a3 'Age from ... to under ... Years' 'A3'
                $b3 = $ws.Cells.Item(3,2).Value2
                Expect-String   $errors $i $b3 'Nursing Staff' 'B3'
                $b4 = $ws.Cells.Item(4,2).Value2
                Expect-String   $errors $i $b4 'Year' 'B4'
                $b5 = $ws.Cells.Item(5,2).Value2
                Expect-String $errors $i $b5 '2024' 'B5'
                $c5 = $ws.Cells.Item(5,3).Value2
                Expect-String $errors $i $c5 '2029' 'C5'
                $d5 = $ws.Cells.Item(5,4).Value2
                Expect-String $errors $i $d5 '2034' 'D5'
                $e5 = $ws.Cells.Item(5,5).Value2
                Expect-String $errors $i $e5 '2039' 'E5'
                $f5 = $ws.Cells.Item(5,6).Value2
                Expect-String $errors $i $f5 '2044' 'F5'
                $g5 = $ws.Cells.Item(5,7).Value2
                Expect-String $errors $i $g5 '2049' 'G5'
                $a6 = $ws.Cells.Item(6,1).Value2
                Expect-String   $errors $i $a6 'Total' 'A6'
                $b6 = $ws.Cells.Item(6,2).Value2
                Expect-String $errors $i $b6 '1673' 'B6'
                $c6 = $ws.Cells.Item(6,3).Value2
                Expect-String $errors $i $c6 '1710' 'C6'
                $d6 = $ws.Cells.Item(6,4).Value2
                Expect-String $errors $i $d6 '1738' 'D6'
                $e6 = $ws.Cells.Item(6,5).Value2
                Expect-String $errors $i $e6 '1790' 'E6'
                $f6 = $ws.Cells.Item(6,6).Value2
                Expect-String $errors $i $f6 '1839' 'F6'
                $g6 = $ws.Cells.Item(6,7).Value2
                Expect-String $errors $i $g6 '1867' 'G6'
          }
          'last' {
                $r  = 1048547
                $a  = $ws.Cells.Item($r,1).Value2

                Expect-String   $errors $i $a '65 - 70' ("A$($r)")
                $b  = $ws.Cells.Item($r,2).Value2
                Expect-String $errors $i $b '23'      ("B$($r)")
                $c  = $ws.Cells.Item($r,3).Value2
                Expect-String $errors $i $c '32'      ("C$($r)")
                $d  = $ws.Cells.Item($r,4).Value2
                Expect-String $errors $i $d '33'      ("D$($r)")
                $e  = $ws.Cells.Item($r,5).Value2
                Expect-String $errors $i $e '26'      ("E$($r)")
                $f  = $ws.Cells.Item($r,6).Value2
                Expect-String $errors $i $f '26'      ("F$($r)")
                $g  = $ws.Cells.Item($r,7).Value2
                Expect-String $errors $i $g '30'      ("G$($r)")
          }
        }
      }
    }
    catch {
        $errors.Add("Run {0}: Exception:" -f $i)
        Write-Host ($_.Exception.Message)
    }
    finally {
      Close-Workbook $wb
      $sw.Stop()
    }

    $secs = [math]::Round($sw.Elapsed.TotalSeconds, 4)
    $times.Add($secs)

    $secsStr = $secs.ToString('F4', [Globalization.CultureInfo]::InvariantCulture)
    Add-Content -Encoding UTF8 $csvName ("{0},{1},{2}" -f $i, $secsStr, (Now-Stamp))

    Write-Host ("[{0}] Run {1}: Time = {2} s" -f $caseName, $i, $secsStr)

    if ($coldStart) { Quit-Excel $excel; $excel = $null }
  }

  if ($excel) { Quit-Excel $excel }

  $median = Get-Median($times.ToArray())
  $medianStr = $median.ToString('F4', [Globalization.CultureInfo]::InvariantCulture)
  Write-Host ""
  Write-Host ("[{0}] Median over {1} runs: {2} s" -f $caseName, $runs, $medianStr)
  Write-Host ("[{0}] CSV: {1}" -f $caseName, (Resolve-Path $csvName))

  if ($errors.Count -gt 0) {
    Write-Warning ("[{0}] {1} check error(s):" -f $caseName, $errors.Count)
    $errors | ForEach-Object { Write-Warning $_ }
    exit 1
  } else {
    Write-Host ("[{0}] All checks passed." -f $caseName)
  }
}

# ---------------- Main ----------------

if (-not (Test-Path $FilePath)) {
  throw "File not found: $FilePath"
}

switch ($Case) {
  'top'  { Run-Case 'top'  'run_times_to_open_worksheet_powershell_first.csv'  $FilePath $SheetName $Runs $ColdStart }
  'last' { Run-Case 'last' 'run_times_to_open_worksheet_last_powershell_last.csv' $FilePath $SheetName $Runs $ColdStart }
  'both' {
    Run-Case 'top'  'run_times_to_open_worksheet_top_powershell.csv'  $FilePath $SheetName $Runs $ColdStart
    Run-Case 'last' 'run_times_to_open_worksheet_last_powershell.csv' $FilePath $SheetName $Runs $ColdStart
  }
}

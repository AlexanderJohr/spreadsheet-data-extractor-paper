param(
  [string] $FilePath = "$(Split-Path -Parent $PSCommandPath)\..\statistischer-bericht-rechnungsergebnis-kernhaushalt-gemeinden-2140331217005.xlsx",
  [string] $SheetName = "71717-01",
  [int]    $Runs = 10,
  [switch] $ColdStart,                 # if set, start a fresh Excel.exe each run
  [string] $CsvPath = "$(Split-Path -Parent $PSCommandPath)\run_times_to_open_worksheet_powershell.csv"
)

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
    # Encourage COM cleanup
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
  }
}

function Now-Stamp {
  (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
}

function Get-Median([double[]]$vals) {
  if (!$vals -or $vals.Count -eq 0) { return [double]::NaN }
  $sorted = $vals | Sort-Object
  $n = $sorted.Count
  if ($n % 2 -eq 1) { return [double]$sorted[ [int]([math]::Floor($n/2)) ] }
  else {
    $a = [double]$sorted[$n/2 - 1]
    $b = [double]$sorted[$n/2]
    return ($a + $b) / 2.0
  }
}


if (-not (Test-Path $FilePath)) {
  throw "File not found: $FilePath"
}

"Run Number,Time (seconds),DateTime" | Set-Content -Encoding UTF8 $CsvPath

$times  = New-Object System.Collections.Generic.List[double]
$errors = New-Object System.Collections.Generic.List[string]

$excel = $null
if (-not $ColdStart) {
  $excel = New-ExcelApp
}

for ($i = 1; $i -le $Runs; $i++) {
  if ($ColdStart) {
    $excel = New-ExcelApp
  }

  $sw = [Diagnostics.Stopwatch]::StartNew()
  $wb = $null
  $ws = $null
  try {
    $wb = $excel.Workbooks.Open($FilePath, 0, $true)
    $ws = $wb.Worksheets.Item($SheetName)

    $a3 = $ws.Cells.Item(3,1).Value2
    if ([string]$a3 -ne "Jahr") {
      $errors.Add("Run $($i): A3 != 'Jahr' (was '${a3}')")
    }

    $b4 = $ws.Cells.Item(4,2).Value2
    if ([string]$b4 -ne "Insgesamt") {
      $errors.Add("Run $($i): B4 != 'Insgesamt' (was '${b4}')")
    }

    $a6 = $ws.Cells.Item(6,1).Value2
    if ([string]$a6 -ne "2021") {
      $errors.Add("Run $($i): A6 != '2021' (was '${a6}')")
    }

    $b6 = $ws.Cells.Item(6,2).Value2
    if ([string]$b6 -ne "286710") {
      $errors.Add("Run $($i): B6 != 286710 (was '${b6}')")
    }
  }
  catch {
    $errors.Add("Run $($i): Exception: $($_.Exception.Message)")
  }
  finally {
    Close-Workbook $wb
    $sw.Stop()
  }

  $secs = [math]::Round($sw.Elapsed.TotalSeconds, 4)
  $times.Add($secs)

  # Write CSV row (decimal with dot, not comma)
  $secsStr = $secs.ToString("F4", [Globalization.CultureInfo]::InvariantCulture)
  Add-Content -Encoding UTF8 $CsvPath "$i,$secsStr,$(Now-Stamp)"

  Write-Host ("Run {0}: Time = {1} s" -f $i, $secsStr)

  if ($ColdStart) {
    Quit-Excel $excel
    $excel = $null
  }
}

# Cleanup Excel if warm-run mode
if ($excel) { Quit-Excel $excel }

# --- Summary -----------------------------------------------------------------

$median = Get-Median($times.ToArray())
$medianStr = $median.ToString("F4", [Globalization.CultureInfo]::InvariantCulture)

Write-Host ""
Write-Host "Median time over $Runs runs: $medianStr s"
Write-Host "CSV written to: $CsvPath"

if ($errors.Count -gt 0) {
  Write-Warning ("{0} check error(s) occurred:" -f $errors.Count)
  $errors | ForEach-Object { Write-Warning $_ }
  exit 1
}
else {
  Write-Host "All checks passed."
}

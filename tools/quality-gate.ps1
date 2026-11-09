param()

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$mainRoot = Join-Path $root "entry\src\main\ets"
$testRoot = Join-Path $root "entry\src\test"
$failures = 0

function Write-Result([string]$name, [bool]$ok, [string]$detail) {
  if ($ok) {
    Write-Output ("PASS  " + $name)
  } else {
    Write-Output ("FAIL  " + $name + "  " + $detail)
    $script:failures = $script:failures + 1
  }
}

function Get-CodeLines([string]$file) {
  $result = @()
  $lines = Get-Content -LiteralPath $file -Encoding UTF8
  for ($i = 0; $i -lt $lines.Count; $i++) {
    $trim = $lines[$i].Trim()
    if ($trim.StartsWith("//") -or $trim.StartsWith("*") -or $trim.StartsWith("/*")) {
      continue
    }
    $result += [pscustomobject]@{ Line = $lines[$i]; Number = $i + 1 }
  }
  return $result
}

$etsFiles = @()
if (Test-Path -LiteralPath $mainRoot) {
  $etsFiles += Get-ChildItem -LiteralPath $mainRoot -Recurse -Filter *.ets -File
}
if (Test-Path -LiteralPath $testRoot) {
  $etsFiles += Get-ChildItem -LiteralPath $testRoot -Recurse -Filter *.ets -File
}

$v1Pattern = '@(State|Prop|Link|Provide|Consume|Observed|StorageLink|StorageProp)\b'
$v1Hits = @()
$asHits = @()
$anyHits = @()
$colorHits = @()
$entryFiles = @()
$navHits = @()

foreach ($file in $etsFiles) {
  $relative = $file.FullName.Substring($root.Length + 1)
  $code = Get-CodeLines $file.FullName
  foreach ($item in $code) {
    if ($item.Line -cmatch $v1Pattern) {
      $v1Hits += ($relative + ":" + $item.Number + ": " + $item.Line.Trim())
    }
    if ($item.Line -cmatch '\bas\s+[A-Za-z_]') {
      $asHits += ($relative + ":" + $item.Number + ": " + $item.Line.Trim())
    }
    if ($item.Line -cmatch ':\s*(any|unknown)\b') {
      $anyHits += ($relative + ":" + $item.Number + ": " + $item.Line.Trim())
    }
    if ($file.FullName.StartsWith($mainRoot)) {
      if ($item.Line -cmatch '#[0-9A-Fa-f]{6}') {
        if (-not ($file.Name -eq "Palette.ets" -or $file.Name -eq "Theme.ets")) {
          $colorHits += ($relative + ":" + $item.Number + ": " + $item.Line.Trim())
        }
      }
      if ($item.Line -cmatch '@Entry\b') {
        $entryFiles += $relative
      }
      if ($item.Line -cmatch '\.navDestination\(') {
        $navHits += ($relative + ":" + $item.Number)
      }
    }
  }
}

Write-Result "no V1 decorators" ($v1Hits.Count -eq 0) ($v1Hits -join " | ")
Write-Result "no as assertions" ($asHits.Count -eq 0) ($asHits -join " | ")
Write-Result "no any/unknown" ($anyHits.Count -eq 0) ($anyHits -join " | ")
Write-Result "no hardcoded colors outside Palette/Theme" ($colorHits.Count -eq 0) ($colorHits -join " | ")

$entryOk = $entryFiles.Count -eq 1 -and $entryFiles[0].Replace("\", "/") -eq "entry/src/main/ets/pages/Index.ets"
Write-Result "single @Entry in pages/Index.ets" $entryOk ($entryFiles -join " | ")
Write-Result "no navDestination builder" ($navHits.Count -eq 0) ($navHits -join " | ")

$packagePath = Join-Path $root "oh-package.json5"
$packageText = Get-Content -LiteralPath $packagePath -Raw -Encoding UTF8
$depsEmpty = $packageText -match '"dependencies"\s*:\s*\{\s*\}'
Write-Result "no third-party dependencies" $depsEmpty "dependencies is not empty"

if ($failures -gt 0) {
  Write-Output ("QUALITY GATE FAILED: " + $failures + " check(s)")
  exit 1
}
Write-Output "QUALITY GATE PASSED"
exit 0

$ErrorActionPreference = 'SilentlyContinue'
$racine = Split-Path -Parent $MyInvocation.MyCommand.Path
$addons = Join-Path $racine 'Interface\AddOns'
$sv = Get-ChildItem (Join-Path $racine 'WTF\Account') -Directory | ForEach-Object { Join-Path $_.FullName 'SavedVariables' } | Where-Object { Test-Path $_ } | Select-Object -First 1

$liens = @{
  'Leatrix_Plus.lua'      = 'Leatrix_Plus'
  'CraftMyNameScout.lua'  = 'CraftMyNameScout'
  'Auctionator.lua'       = 'Auctionator'
}

function Copier($nom) {
  $dossier = $liens[$nom]
  if (-not $dossier) { return }
  $source = Join-Path $sv $nom
  $cible = Join-Path $addons "$dossier\SavedCopy.lua"
  for ($i = 0; $i -lt 10; $i++) {
    try {
      Copy-Item $source $cible -Force -ErrorAction Stop
      Write-Host "$(Get-Date -Format HH:mm:ss) copie $nom"
      return
    } catch { Start-Sleep -Milliseconds 50 }
  }
}

foreach ($nom in $liens.Keys) { Copier $nom }

$veille = New-Object System.IO.FileSystemWatcher $sv, '*.lua'
$veille.NotifyFilter = [System.IO.NotifyFilters]'LastWrite, FileName'
$veille.EnableRaisingEvents = $true
Write-Host "Pont des SavedVariables actif sur $sv"
while ($true) {
  $e = $veille.WaitForChanged([System.IO.WatcherChangeTypes]::All, 1000)
  if (-not $e.TimedOut) { Copier $e.Name }
}

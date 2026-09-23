$ErrorActionPreference = 'SilentlyContinue'
$racine = Split-Path -Parent $MyInvocation.MyCommand.Path
$addons = Join-Path $racine 'Interface\AddOns'
$compte = Get-ChildItem (Join-Path $racine 'WTF\Account') -Directory | Where-Object { Test-Path (Join-Path $_.FullName 'SavedVariables') } | Select-Object -First 1
$sv = Join-Path $compte.FullName 'SavedVariables'
$pont = Join-Path $addons '!SavedVariablesBridge'

if (-not (Test-Path $pont)) { New-Item -ItemType Directory -Path $pont | Out-Null }

function Horodate { Get-Date -Format 'HH:mm:ss' }

function AddonsInstalles {
  Get-ChildItem $addons -Directory | Where-Object { $_.Name -ne '!SavedVariablesBridge' } | ForEach-Object { $_.Name }
}

function LireAvecReessai($chemin) {
  for ($i = 0; $i -lt 20; $i++) {
    try { return [System.IO.File]::ReadAllText($chemin) } catch { Start-Sleep -Milliseconds 50 }
  }
  Write-Host "$(Horodate)   LECTURE IMPOSSIBLE : $chemin"
  return $null
}

function Synchroniser($raison) {
  $connus = AddonsInstalles
  $fichiers = @()
  Write-Host "$(Horodate) synchronisation ($raison)"

  foreach ($f in Get-ChildItem $sv -Filter '*.lua' -File) {
    if ($f.Name -match '\.bak$') { continue }
    if ($connus -notcontains $f.BaseName) { Write-Host "$(Horodate)   ignore $($f.Name) (aucun addon de ce nom)"; continue }
    $contenu = LireAvecReessai $f.FullName
    if ($null -eq $contenu -or $contenu.Trim().Length -eq 0) { continue }
    $nom = 'SV_' + ($f.BaseName -replace '[^A-Za-z0-9_]', '_') + '.lua'
    [System.IO.File]::WriteAllText((Join-Path $pont $nom), $contenu, [System.Text.UTF8Encoding]::new($false))
    $fichiers += $nom
    Write-Host "$(Horodate)   compte  $($f.Name) -> $nom ($($contenu.Length) caracteres, ecrit $($f.LastWriteTime.ToString('HH:mm:ss')))"
  }

  foreach ($dossier in Get-ChildItem $compte.FullName -Directory -Recurse -Filter 'SavedVariables') {
    if ($dossier.FullName -eq $sv) { continue }
    $perso = (Split-Path -Leaf (Split-Path -Parent $dossier.FullName)) -replace '-.*$', ''
    foreach ($f in Get-ChildItem $dossier.FullName -Filter '*.lua' -File) {
      if ($f.Name -match '\.bak$') { continue }
      if ($connus -notcontains $f.BaseName) { continue }
      $contenu = LireAvecReessai $f.FullName
      if ($null -eq $contenu -or $contenu.Trim().Length -eq 0) { continue }
      $garde = "if UnitName(`"player`") == `"$perso`" then" + [Environment]::NewLine + $contenu + [Environment]::NewLine + 'end' + [Environment]::NewLine
      $nom = 'PERSO_' + ($perso -replace '[^A-Za-z0-9_]', '_') + '_' + ($f.BaseName -replace '[^A-Za-z0-9_]', '_') + '.lua'
      [System.IO.File]::WriteAllText((Join-Path $pont $nom), $garde, [System.Text.UTF8Encoding]::new($false))
      $fichiers += $nom
      Write-Host "$(Horodate)   perso   $perso / $($f.Name) -> $nom ($($contenu.Length) caracteres)"
    }
  }

  foreach ($vieux in Get-ChildItem $pont -Filter '*.lua' -File) {
    if ($fichiers -notcontains $vieux.Name) { Remove-Item $vieux.FullName -Force; Write-Host "$(Horodate)   retire  $($vieux.Name)" }
  }

  $toc = @(
    '## Interface: 16001',
    '## Title: !SavedVariables Bridge',
    '## Notes: Recharge les reglages des addons (bug de la beta Forever)',
    '## Version: 2.0',
    '## Author: CraftMyName',
    ''
  ) + $fichiers
  [System.IO.File]::WriteAllLines((Join-Path $pont '!SavedVariablesBridge.toc'), $toc, [System.Text.UTF8Encoding]::new($false))
  Write-Host "$(Horodate) pont pret : $($fichiers.Count) fichiers charges au prochain demarrage"
}

Synchroniser 'demarrage'

$veille = New-Object System.IO.FileSystemWatcher
$veille.Path = $compte.FullName
$veille.Filter = '*.lua'
$veille.IncludeSubdirectories = $true
$veille.NotifyFilter = [System.IO.NotifyFilters]'LastWrite, FileName'
$veille.EnableRaisingEvents = $true
Write-Host "$(Horodate) veille active sur $($compte.FullName)"

while ($true) {
  $e = $veille.WaitForChanged([System.IO.WatcherChangeTypes]::All, 2000)
  if (-not $e.TimedOut) {
    Write-Host "$(Horodate) WoW a ecrit $($e.Name)"
    Start-Sleep -Milliseconds 250
    Synchroniser "apres ecriture de $($e.Name)"
  }
}

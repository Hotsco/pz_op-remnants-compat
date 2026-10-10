# PZ_op x Project Remnants: locate a subscribed Workshop package and install it.
# No game classes or original mods are downloaded by this script.
[CmdletBinding()]
param([string[]]$SteamRoot,[string]$GameDir,[string]$RuntimeDir,[switch]$LocateOnly)
$ErrorActionPreference='Stop'
# Read-only Steam library discovery. Does not change Steam configuration.
function Get-PZOpSteamRoots {
 $roots=@()
 foreach($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam')) {
  $reg=Get-ItemProperty -LiteralPath $key -ErrorAction SilentlyContinue
  if($reg -and $reg.SteamPath){$roots+=$reg.SteamPath}
  if($reg -and $reg.InstallPath){$roots+=$reg.InstallPath}
 }
 if(${env:ProgramFiles(x86)}){$roots+=Join-Path ${env:ProgramFiles(x86)} 'Steam'}
 return @($roots|Sort-Object -Unique)
}
function Get-PZOpSteamLibraries {
 param([string[]]$SteamRoots=(Get-PZOpSteamRoots))
 $libraries=@($SteamRoots)
 foreach($root in $SteamRoots) {
  if(-not $root){continue}
  $vdf=Join-Path $root 'steamapps\libraryfolders.vdf'
  if(Test-Path -LiteralPath $vdf -PathType Leaf) {
   foreach($match in [regex]::Matches([IO.File]::ReadAllText($vdf),'"path"\s+"([^"]+)"')) {
    $libraries+=$match.Groups[1].Value.Replace('\\','\')
   }
  }
 }
 $found=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($root in $libraries) {
  if($root -and [IO.Path]::IsPathRooted($root)){[void]$found.Add([IO.Path]::GetFullPath($root).TrimEnd('\'))}
 }
 return @($found|Sort-Object)
}
function Test-PZOpGameFolder([string]$Path) {
 if(-not $Path){return $false}
 return (Test-Path -LiteralPath (Join-Path $Path 'projectzomboid.jar') -PathType Leaf) -and
        (Test-Path -LiteralPath (Join-Path $Path 'ProjectZomboid64.json') -PathType Leaf)
}
function Get-PZOpGameCandidates {
 param([string]$StartDir,[string[]]$SteamRoots=(Get-PZOpSteamRoots))
 # Prefer the Steam library that downloaded this Workshop item.
 $parent=[IO.DirectoryInfo]::new([IO.Path]::GetFullPath($StartDir))
 while($null-ne $parent) {
  if($parent.Name-eq 'steamapps') {
   $game=Join-Path $parent.FullName 'common\ProjectZomboid'
   if(Test-PZOpGameFolder $game){return [IO.Path]::GetFullPath($game)}
   break
  }
  $parent=$parent.Parent
 }
 $games=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($root in @(Get-PZOpSteamLibraries -SteamRoots $SteamRoots)) {
  $game=Join-Path $root 'steamapps\common\ProjectZomboid'
  if(Test-PZOpGameFolder $game){[void]$games.Add([IO.Path]::GetFullPath($game))}
 }
 return @($games|Sort-Object)
}
function Find-PZOpGame {
 param([string]$StartDir,[switch]$Interactive)
 $games=@(Get-PZOpGameCandidates -StartDir $StartDir)
 if($games.Count-eq 1){return $games[0]}
 if($Interactive) {
  Write-Host 'Could not select one Project Zomboid installation automatically.'
  foreach($game in $games){Write-Host ('Found: '+$game)}
  Write-Host 'Steam > Project Zomboid > Manage > Browse local files. Copy that folder path.'
  $chosen=(Read-Host 'Game folder path (blank cancels)').Trim().Trim('"')
  if($chosen -and (Test-PZOpGameFolder $chosen)){return [IO.Path]::GetFullPath($chosen)}
 }
 throw 'Specify -GameDir with the folder containing projectzomboid.jar and ProjectZomboid64.json.'
}
$ExpectedManifestHash='B236B5A49EF345FFC598EBAEEDEAC3AC3C64C99FA2B3492692E81F2A38BD6DDA'
function Get-PZOpWorkshopPayloads([string[]]$Libraries) {
 $found=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($library in $Libraries) {
  $content=Join-Path $library 'steamapps\workshop\content\108600'
  if(-not (Test-Path -LiteralPath $content -PathType Container)){continue}
  foreach($item in @(Get-ChildItem -LiteralPath $content -Directory)) {
   if($item.Name -notmatch '^\d+$'){continue}
   $candidate=Join-Path $item.FullName 'mods\PZ_op_Remnants_Compat\42'
   if(Test-Path -LiteralPath (Join-Path $candidate 'runtime.ps1') -PathType Leaf){[void]$found.Add($candidate)}
  }
 }
 return @($found|Sort-Object)
}
function Test-PZOpWorkshopPackage([string]$Path) {
 $manifest=Join-Path $Path 'SHA256SUMS.txt'
 if(-not (Test-Path -LiteralPath $manifest -PathType Leaf)){return $false}
 if((Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash-ne $ExpectedManifestHash){return $false}
 foreach($line in [IO.File]::ReadAllLines($manifest)) {
  if($line -notmatch '^([0-9a-f]{64})  (.+)$'){return $false}
  $hash=$Matches[1];$relative=$Matches[2]
  if($relative.Contains('..') -or [IO.Path]::IsPathRooted($relative)){return $false}
  $file=Join-Path $Path $relative
  if(-not (Test-Path -LiteralPath $file -PathType Leaf)){return $false}
  if((Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash-ne $hash){return $false}
 }
 return $true
}
try {
 if(-not $SteamRoot){$SteamRoot=@(Get-PZOpSteamRoots)}
 $libraries=@(Get-PZOpSteamLibraries -SteamRoots $SteamRoot)
 $candidates=@(Get-PZOpWorkshopPayloads -Libraries $libraries)
 if($candidates.Count-eq 0){throw 'Patch files not found. Subscribe to PZ_op x Project Remnants Compatibility Patch in Steam, wait for the download, then run this command again.'}
 $valid=@($candidates|Where-Object {Test-PZOpWorkshopPackage $_})
 if($valid.Count-eq 0){throw 'The downloaded patch does not match this installer release. Wait for Steam downloads to finish and use the current command from the Workshop page. Nothing was installed.'}
 if($GameDir) {
  if(-not (Test-PZOpGameFolder $GameDir)){throw 'GameDir must contain projectzomboid.jar and ProjectZomboid64.json.'}
  $GameDir=[IO.Path]::GetFullPath($GameDir).TrimEnd('\')
 } else {
  # Do not silently choose between multiple installed copies of the game.
  $games=@(Get-PZOpGameCandidates -StartDir $env:TEMP -SteamRoots $SteamRoot)
  if($games.Count-ne 1){throw 'Could not select one game installation. Run Install.cmd in the subscribed patch folder to select the game folder, or supply -GameDir.'}
  $GameDir=$games[0]
 }
 # All accepted copies have the same pinned manifest and checked file contents.
 $payload=$valid[0]
 Write-Host ('Workshop package: '+$payload)
 Write-Host ('Game folder: '+$GameDir)
 if($LocateOnly){Write-Output 'LOCATE OK: package and game verified; no installation performed';return}
 $argsList=@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $payload 'runtime.ps1'),'-Action','Install','-GameDir',$GameDir)
 if($RuntimeDir){$argsList+=@('-RuntimeDir',$RuntimeDir)}
 & (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @argsList
 if($LASTEXITCODE-ne 0){throw ('Installer stopped with exit code '+$LASTEXITCODE+'. Read the error above.')}
 Write-Output 'Setup complete. Launch the game normally through Steam.'
} catch {
 throw ('PZ_op setup stopped: '+$_.Exception.Message)
}

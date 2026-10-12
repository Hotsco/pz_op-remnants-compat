# PZ_op x Project Remnants 1.0.0: use the verified subscribed Workshop package.
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
$ExpectedManifestHash='0F175B47E69734932D63667002A9C91B65676205836DA71E3AC6223FD88C418E'
function Test-PZOpPayload([string]$root) {
 $manifest=Join-Path $root 'SHA256SUMS.txt'
 if(!(Test-Path -LiteralPath $manifest) -or (Get-FileHash -LiteralPath $manifest).Hash-ne $ExpectedManifestHash){return $false}
 foreach($line in [IO.File]::ReadAllLines($manifest)) {
  if($line -notmatch '^([0-9a-f]{64})  (.+)$'){return $false}
  $hash=$Matches[1];$name=$Matches[2]
  if($name.Contains('..') -or $name.Contains(':') -or [IO.Path]::IsPathRooted($name)){return $false}
  $path=Join-Path $root $name
  if(!(Test-Path -LiteralPath $path) -or (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()-ne $hash){return $false}
 }
 return $true
}
try {
 if(!$SteamRoot){$SteamRoot=@(Get-PZOpSteamRoots)}
 $libraries=@(Get-PZOpSteamLibraries -SteamRoots $SteamRoot)
 $found=@($libraries|ForEach-Object {Join-Path $_ 'steamapps\workshop\content\108600\3816975899\mods\PZ_op_Remnants_Compat\42'}|Where-Object {Test-Path -LiteralPath $_ -PathType Container})
 $valid=@($found|Where-Object {Test-PZOpPayload $_})
 if(!$valid.Count){throw 'Version 1.0.0 patch files not found or do not match. Subscribe to Workshop item 3816975899 and wait for Steam to finish its latest download, then try again.'}
 $payload=$valid[0]
 if(!$GameDir){
  $games=@(Get-PZOpGameCandidates -StartDir $payload -SteamRoots $SteamRoot)
  if($games.Count-ne 1){throw 'Could not select one game installation. Supply -GameDir or use Install.cmd in the subscribed patch folder.'}
  $GameDir=$games[0]
 }
 if(!(Test-PZOpGameFolder $GameDir)){throw 'The selected folder does not contain Project Zomboid.'}
 Write-Host "Workshop package: $payload"
 Write-Host "Game folder: $GameDir"
 if($LocateOnly){Write-Output 'LOCATE OK: 1.0.0 files verified; no installation performed.';return}
 $arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $payload 'runtime.ps1'),'-Action','Install','-GameDir',$GameDir)
 if($RuntimeDir){$arguments+=@('-RuntimeDir',$RuntimeDir)}
 & (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @arguments
 if($LASTEXITCODE-ne 0){throw "Installer stopped with exit code $LASTEXITCODE. Read the error above."}
 Write-Output 'Setup complete. Launch normally through Steam.'
}catch{throw ('PZ_op setup stopped: '+$_.Exception.Message)}

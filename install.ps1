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
$ExpectedManifestHash='DF398240231CD38B28EB59A04DE2794DC52C93D91DCD2B51966BFEF0A1509FED'
$LegacyManifestHash='B236B5A49EF345FFC598EBAEEDEAC3AC3C64C99FA2B3492692E81F2A38BD6DDA'
# Embedded update is generated from the reviewed Workshop installer. This allows
# subscribers on the previous Workshop download to repair startup immediately.
# BEGIN EMBEDDED AOT INSTALLER
$PatchedRuntimeText=@'
[CmdletBinding()]
param(
 [ValidateSet('Install','Check','Uninstall')][string]$Action='Check',
 [string]$GameDir,
 [string]$NpcfwJar,
 [switch]$Interactive,
 [string]$RuntimeDir=(Join-Path $env:LOCALAPPDATA 'PZO-NPCFW-Compat\runtime\0.2.0-local')
)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'FindSteamGame.ps1')
$RuntimeDir=[IO.Path]::GetFullPath($RuntimeDir)
$metadata=Join-Path $RuntimeDir 'install.json'
$utf8=[Text.UTF8Encoding]::new($false)
$aotGuard='-Dpzopt.aotCache=false'
function Test-AotArgument([string]$arg) {
 return $arg -like '-XX:AOTCache*' -or $arg -like '-Xlog:aot=info:file=pzopt/aot/*'
}
function Assert-NoScopedAot($launcherJson) {
 if($launcherJson.windows) {
  foreach($scope in $launcherJson.windows.PSObject.Properties) {
   foreach($arg in @($scope.Value.vmArgs)) {
    if((Test-AotArgument $arg) -or ($arg -like '-Dpzopt.aotCache=*' -and $arg -ne $aotGuard)) {
     throw ('Conflicting AOT option in Windows launcher section '+$scope.Name+'. Remove that AOT override before installing.')
    }
   }
  }
 }
}
function Assert-Stopped([string]$game) {
 $processes=Get-CimInstance Win32_Process -Filter "Name='ProjectZomboid64.exe' OR Name='java.exe' OR Name='javaw.exe'"
 foreach($process in $processes) {
  if(($process.ExecutablePath -and $process.ExecutablePath.StartsWith($game+'\',[StringComparison]::OrdinalIgnoreCase)) -or
     ($process.CommandLine -and $process.CommandLine.IndexOf($game,[StringComparison]::OrdinalIgnoreCase)-ge 0)) {
   throw "Close Project Zomboid and its test Java processes first (PID $($process.ProcessId))."
  }
 }
}
function Write-Atomic([string]$path,[string]$content) {
 $temp=$path+'.pzofix-'+[Guid]::NewGuid().ToString('N')+'.tmp'
 try {
  [IO.File]::WriteAllText($temp,$content,$utf8)
  [IO.File]::Replace($temp,$path,[NullString]::Value)
 } finally {if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}
}
function Verify-Package([string]$root) {
 foreach($line in [IO.File]::ReadAllLines((Join-Path $root 'SHA256SUMS.txt'))) {
  if($line -notmatch '^([0-9a-f]{64})  (.+)$'){throw 'Invalid package checksum file'}
  $expected=$Matches[1];$relative=$Matches[2]
  if($relative.Contains('..') -or [IO.Path]::IsPathRooted($relative)){throw 'Unsafe package path'}
  if((Get-FileHash -LiteralPath (Join-Path $root $relative)).Hash.ToLowerInvariant()-ne $expected){throw "Package checksum failed: $relative"}
 }
}
function Check-Inputs([string]$root,[string]$game) {
 & (Join-Path $game 'jre64\bin\java.exe') -jar (Join-Path $root 'pzo-npcfw-runtime.jar') check (Join-Path $root 'config.properties')
 if($LASTEXITCODE-ne 0){throw "Runtime preflight failed: exit $LASTEXITCODE"}
}
try {
 if(Test-Path -LiteralPath $metadata){$saved=Get-Content -LiteralPath $metadata -Raw -Encoding UTF8|ConvertFrom-Json}
 if(-not $GameDir -and $saved){$GameDir=$saved.game}
 if(-not $GameDir){$GameDir=Find-PZOpGame -StartDir $PSScriptRoot -Interactive:$Interactive}
 $GameDir=(Resolve-Path -LiteralPath $GameDir).Path.TrimEnd('\')
 $launcher=Join-Path $GameDir 'ProjectZomboid64.json'
 $before=[IO.File]::ReadAllText($launcher)
 $json=$before|ConvertFrom-Json
 $agentJar=Join-Path $RuntimeDir 'pzo-npcfw-runtime.jar'
 $configPath=Join-Path $RuntimeDir 'config.properties'
 $ownArg='-javaagent:'+$agentJar.Replace('\','/')+'='+$configPath.Replace('\','/')
 if($Action-eq 'Uninstall') {
  Assert-Stopped $GameDir
  if(-not $saved -or $saved.game-ne $GameDir){throw 'No matching install record'}
  $removeGuard=$saved.aotGuardManaged-eq $true
  if(@($json.vmArgs|Where-Object {$_-eq $saved.argument -or ($removeGuard -and $_-eq $aotGuard)}).Count-eq 0){Write-Output 'Already uninstalled';exit 0}
  $json.vmArgs=@($json.vmArgs|Where-Object {$_-ne $saved.argument -and -not ($removeGuard -and $_-eq $aotGuard)})
  $backup=Join-Path $RuntimeDir ('launcher-before-uninstall-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')
  Copy-Item -LiteralPath $launcher -Destination $backup
  Write-Atomic $launcher ($json|ConvertTo-Json -Depth 20)
  $saved.status='UNINSTALLED'
  [IO.File]::WriteAllText($metadata,($saved|ConvertTo-Json -Depth 10),$utf8)
  Write-Output 'Uninstalled compatibility launch arguments. Existing non-AOT settings preserved. Old AOT cache paths are not restored. Runtime files and backups retained.'
  exit 0
 }
 if($Action-eq 'Check') {
  if(-not $saved -or $saved.game-ne $GameDir){throw 'No matching install record'}
  Verify-Package $RuntimeDir
  $agents=@($json.vmArgs|Where-Object {$_-like '-javaagent:*'})
  if($agents.Count-ne 2 -or $agents[0]-ne $saved.argument -or $agents[1]-ne $saved.npcArgument){throw 'Launcher agent arguments or order changed'}
  if($json.classpath.Count-lt 2 -or $json.classpath[0]-ne '.' -or $json.classpath[1]-ne 'projectzomboid.jar'){throw 'Launcher classpath changed'}
  Assert-NoScopedAot $json
  if(@($json.vmArgs|Where-Object {$_-eq $aotGuard}).Count-ne 1 -or
     @($json.vmArgs|Where-Object {(Test-AotArgument $_) -or ($_-like '-Dpzopt.aotCache=*' -and $_-ne $aotGuard)}).Count-gt 0) {
   throw 'AOT protection is missing or changed. Close the game and rerun the current installation command.'
  }
  Check-Inputs $RuntimeDir $GameDir
  Write-Output ('INSTALLATION CHECK OK; last startup log: '+(Join-Path $RuntimeDir 'runtime.log'))
  exit 0
 }
 Assert-Stopped $GameDir
 Verify-Package $PSScriptRoot
 Assert-NoScopedAot $json
 if($json.classpath.Count-lt 2 -or $json.classpath[1]-ne 'projectzomboid.jar' -or
    @('.','pzopt/aot/pzopt.jar') -notcontains $json.classpath[0]) {
  throw 'Unsupported classpath. Expected loose classes or the PZO AOT jar first, stock jar second.'
 }
 # AOT jars are unsupported by the compatibility agent. Restore PZO's loose-file
 # layout and keep AOT disabled at startup, including after presets/default changes.
 # Do not edit options.ini or replace unrelated launcher settings.
 $json.classpath[0]='.'
 $guardManaged=-not (@($json.vmArgs) -contains $aotGuard)
 if($saved -and $saved.status-eq 'INSTALLED' -and $saved.PSObject.Properties['aotGuardManaged']) {
  $guardManaged=[bool]$saved.aotGuardManaged
 }
 $json.vmArgs=@($json.vmArgs|Where-Object {-not (Test-AotArgument $_) -and -not ($_-like '-Dpzopt.aotCache=*' -and $_-ne $aotGuard)})
 if(@($json.vmArgs|Where-Object {$_-eq $aotGuard}).Count-gt 1){throw 'Duplicate AOT protection argument'}
 if(@($json.vmArgs|Where-Object {$_-eq $aotGuard}).Count-eq 0){$json.vmArgs+= $aotGuard}
 $agents=@($json.vmArgs|Where-Object {$_-like '-javaagent:*' -and $_-ne $ownArg})
 if($agents.Count-ne 1){throw 'Expected one existing NPCFW agent'}
 $npcArgument=$agents[0]
 if($npcArgument -notmatch '^-javaagent:(.+NPCFW\.jar)(?:=.*)?$'){throw 'Existing agent is not NPCFW.jar'}
 $launcherNpc=(Resolve-Path -LiteralPath $Matches[1]).Path
 if($NpcfwJar -and (Resolve-Path -LiteralPath $NpcfwJar).Path-ne $launcherNpc){throw 'Supplied NPCFW path differs from launcher'}
 $NpcfwJar=$launcherNpc
 if($saved -and $saved.game-ne $GameDir){throw 'Runtime directory belongs to another game installation'}
 if(Test-Path -LiteralPath $agentJar) {
  Verify-Package $RuntimeDir
  if((Get-FileHash -LiteralPath $agentJar).Hash-ne (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'pzo-npcfw-runtime.jar')).Hash){throw 'A different runtime build exists; explicit migration required'}
 } else {
  New-Item -ItemType Directory -Force -Path $RuntimeDir,(Join-Path $RuntimeDir 'lib')|Out-Null
  foreach($name in @('pzo-npcfw-runtime.jar','SHA256SUMS.txt','LICENSE-ASM.txt','runtime.ps1','FindSteamGame.ps1','Install.cmd','Check.cmd','Uninstall.cmd')){Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $RuntimeDir}
  Copy-Item -Path (Join-Path $PSScriptRoot 'lib\*.jar') -Destination (Join-Path $RuntimeDir 'lib')
 }
 # Keep management commands available after a Workshop unsubscribe. The agent jar
 # is unchanged for an existing installation; differing engine builds are refused above.
 foreach($name in @('runtime.ps1','FindSteamGame.ps1','Install.cmd','Check.cmd','Uninstall.cmd','LICENSE-ASM.txt','SHA256SUMS.txt')) {
  $src=Join-Path $PSScriptRoot $name
  $dst=Join-Path $RuntimeDir $name
  if([IO.Path]::GetFullPath($src)-ne [IO.Path]::GetFullPath($dst)) {
   if(-not (Test-Path -LiteralPath $dst) -or (Get-FileHash -LiteralPath $src).Hash-ne (Get-FileHash -LiteralPath $dst).Hash) {
    Copy-Item -LiteralPath $src -Destination $dst
   }
  }
 }
 $config=@(('game='+$GameDir.Replace('\','/')),('npcfw='+$NpcfwJar.Replace('\','/')))
 [IO.File]::WriteAllLines($configPath,$config,$utf8)
 Check-Inputs $RuntimeDir $GameDir
 if(@($json.vmArgs|Where-Object {$_-eq $ownArg}).Count-eq 1) {
  if(-not $saved){throw 'Agent argument exists without an installation record'}
  $allAgents=@($json.vmArgs|Where-Object {$_-like '-javaagent:*'})
  if($allAgents.Count-ne 2 -or $allAgents[0]-ne $ownArg -or $allAgents[1]-ne $npcArgument){throw 'Launcher agent order changed; installation was not modified'}
 }
 if(@($json.vmArgs|Where-Object {$_-eq $ownArg}).Count-gt 1){throw 'Duplicate runtime agent argument'}
 $backup=Join-Path $RuntimeDir ('launcher-before-install-'+[DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfff')+'.json')
 Copy-Item -LiteralPath $launcher -Destination $backup
 $record=[ordered]@{version='0.2.0-local';installerRevision='2026-10-12-aot1';game=$GameDir;npcfw=$NpcfwJar;argument=$ownArg;npcArgument=$npcArgument;aotGuardManaged=$guardManaged;backup=$backup;status='PREPARED';installedUtc=[DateTime]::UtcNow.ToString('o')}
 [IO.File]::WriteAllText($metadata,($record|ConvertTo-Json -Depth 10),$utf8)
 if(@($json.vmArgs|Where-Object {$_-eq $ownArg}).Count-eq 0){$json.vmArgs=@($ownArg)+@($json.vmArgs)}
 $newText=$json|ConvertTo-Json -Depth 20
 # Keep an already-correct launcher's exact bytes and formatting on repeat runs.
 if(($json|ConvertTo-Json -Depth 20 -Compress)-eq (($before|ConvertFrom-Json)|ConvertTo-Json -Depth 20 -Compress)){$newText=$before}
 try {
  if([IO.File]::ReadAllText($launcher)-ne $before){throw 'Launcher changed during preparation'}
  Assert-Stopped $GameDir
  if($newText-ne $before){Write-Atomic $launcher $newText}
  $actual=Get-Content -LiteralPath $launcher -Raw -Encoding UTF8|ConvertFrom-Json
  if($actual.vmArgs[0]-ne $ownArg){throw 'Launcher verification failed'}
  $record.status='INSTALLED'
  [IO.File]::WriteAllText($metadata,($record|ConvertTo-Json -Depth 10),$utf8)
 } catch {
  if([IO.File]::ReadAllText($launcher)-eq $newText){Write-Atomic $launcher $before}
  throw
 }
 Write-Output ('INSTALLED: '+$RuntimeDir)
 Write-Output ('Launcher backup: '+$backup)
 Write-Output 'Normal Steam launch will run compatibility before NPCFW. No save-specific mod activation is needed.'
 Write-Output 'AOT startup cache is disabled while this patch is installed. Other PZO settings are unchanged.'
 exit 0
} catch {
 Write-Error $_ -ErrorAction Continue
 exit 4
}
'@
$PatchedManifestText=@'
b3824d4fff4eb2a467bef998f3111993feb2b371dca9f34c4d7175946eafb4dd  pzo-npcfw-runtime.jar
048da3401f440f90946cd5b815063f1b78e72fbfe9cc86dc3a65e3c263e8e677  runtime.ps1
936aaaa442be5e053793f1fb2d8deab782161cbc7057f904ba72f2e5e7f5667a  FindSteamGame.ps1
79ac8cac555ac960c2e253b2e8e1a7c25b14b840ccba13adf3a93d8ef319ce82  Install.cmd
ec90f5611f3cb0591c0ff6204210f159431b91e35d244bef34c87b03248fc80e  Check.cmd
5b040a92a5c961d290e65324741a41ab951b862edca39dd484b68a8c00b69281  Uninstall.cmd
34b8dd2e1b4b5f822ba633602676297fa82328d9438ba4d7336ec7393d212e06  LICENSE-ASM.txt
876eab6a83daecad5ca67eb9fcabb063c97b5aeb8cf1fca7a989ecde17522051  lib/asm-9.8.jar
e640732fbcd3c6271925a504f125e38384688f4dfbbf92c8622dfcee0d09edb9  lib/asm-analysis-9.8.jar
14b7880cb7c85eed101e2710432fc3ffb83275532a6a894dc4c4095d49ad59f1  lib/asm-tree-9.8.jar
8ba0460ecb28fd0e2980e5f3ef3433a513a457bc077f81a53bdc75b587a08d15  lib/asm-util-9.8.jar
'@
# END EMBEDDED AOT INSTALLER
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
 if(@($ExpectedManifestHash,$LegacyManifestHash) -notcontains (Get-FileHash -LiteralPath $manifest -Algorithm SHA256).Hash){return $false}
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
$stageState=@{Path=$null}
function Get-PZOpCurrentPayload([string]$Path) {
 if((Get-FileHash -LiteralPath (Join-Path $Path 'SHA256SUMS.txt')).Hash-eq $ExpectedManifestHash){return $Path}
 $stageState.Path=Join-Path ([IO.Path]::GetTempPath()) ('PZOp-AOT-Installer-'+[Guid]::NewGuid().ToString('N'))
 New-Item -ItemType Directory -Path $stageState.Path|Out-Null
 foreach($line in [IO.File]::ReadAllLines((Join-Path $Path 'SHA256SUMS.txt'))) {
  if($line -notmatch '^([0-9a-f]{64})  (.+)$'){throw 'Invalid verified package manifest'}
  $relative=$Matches[2]
  $destination=Join-Path $stageState.Path $relative
  New-Item -ItemType Directory -Force -Path (Split-Path $destination -Parent)|Out-Null
  Copy-Item -LiteralPath (Join-Path $Path $relative) -Destination $destination
 }
 $encoding=[Text.UTF8Encoding]::new($false)
 [IO.File]::WriteAllText((Join-Path $stageState.Path 'runtime.ps1'),($PatchedRuntimeText.Replace([string][char]13,'').TrimEnd([char]10)+[char]10),$encoding)
 [IO.File]::WriteAllText((Join-Path $stageState.Path 'SHA256SUMS.txt'),($PatchedManifestText.Replace([string][char]13,'').TrimEnd([char]10)+[char]10),$encoding)
 if(-not (Test-PZOpWorkshopPackage $stageState.Path)){throw 'Embedded AOT installer verification failed; nothing was installed'}
 Write-Host 'Applying the verified AOT installer update to the existing Workshop package.'
 return $stageState.Path
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
 $payload=Get-PZOpCurrentPayload $payload
 $argsList=@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $payload 'runtime.ps1'),'-Action','Install','-GameDir',$GameDir)
 if($RuntimeDir){$argsList+=@('-RuntimeDir',$RuntimeDir)}
 & (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') @argsList
 if($LASTEXITCODE-ne 0){throw ('Installer stopped with exit code '+$LASTEXITCODE+'. Read the error above.')}
 Write-Output 'Setup complete. Launch the game normally through Steam.'
} catch {
 throw ('PZ_op setup stopped: '+$_.Exception.Message)
} finally {
 if($stageState.Path -and (Test-Path -LiteralPath $stageState.Path)) {
  $tempBase=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
  $resolved=[IO.Path]::GetFullPath($stageState.Path)
  if($resolved.StartsWith($tempBase,[StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf)-match '^PZOp-AOT-Installer-[0-9a-f]{32}$') {
   Remove-Item -LiteralPath $resolved -Recurse -Force
  }
 }
}

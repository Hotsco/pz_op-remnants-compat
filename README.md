# PZ_op × Project Remnants — Compatibility Patch

Windows / Project Zomboid B42.21. Unofficial compatibility tool for PZ_Optimization and Project Remnants.

Restores NPC/player bump-animation suppression and keeps the original player body visible while controlling an NPC. Normal physical collision remains enabled.

**Steam Workshop release is being prepared.** This repository contains the installer, not the patch payload. Installation requires the matching Workshop subscription files; it will stop if they are missing.

## Installation

Install both original mods first and wait for this patch's Workshop download to finish. Close the game, then run the installation command provided on the Workshop page in Windows PowerShell once. The script finds Steam libraries, verifies the downloaded package, and installs the compatibility agent.

After the Workshop release is available, use this command:

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Hotsco/pz_op-remnants-compat/f33bc4cf7963af56fba0543fbf92857871157385/install.ps1')))
```

Afterward, launch normally through Steam. No save-specific activation is needed. Compatible PZO updates are handled at startup; unsupported game, NPCFW, or target-method changes can block startup. If Steam resets the launcher, run installation again.

## Check or remove

Open `%LOCALAPPDATA%\PZO-NPCFW-Compat\runtime\0.2.0-local` and run `Check.cmd` or `Uninstall.cmd`. Close the game before uninstalling. These files remain available after unsubscribing; unsubscribing alone does not remove the installed patch.

## 한국어

Windows / 좀보이드 B42.21용 PZ_Optimization + Project Remnants 비공식 호환 도구입니다.

NPC/플레이어 접촉 시 충돌 애니메이션 억제와 NPC 조종 중 원래 플레이어 몸이 사라지는 문제를 수정합니다. 일반 물리 충돌은 유지됩니다.

**스팀 워크숍 배포는 준비 중입니다.** 이 저장소에는 설치 스크립트가 있으며 패치 본체는 워크숍에서 받습니다. 해당 구독 파일이 없으면 설치가 중단됩니다.

원본 두 모드를 먼저 설치하고, 이 패치의 워크숍 다운로드가 끝나면 게임을 종료하세요. 워크숍 설명의 설치 명령을 Windows PowerShell에서 한 번 실행하면 경로 탐색과 설치를 진행합니다. 이후에는 스팀에서 평소처럼 실행하면 됩니다. 세이브에 이 패치를 활성화할 필요는 없습니다.

호환되는 PZO 업데이트에는 시작 시 자동 적용됩니다. 지원하지 않는 변경에서는 게임 시작이 중단될 수 있습니다. Steam이 런처를 초기화하면 설치 명령을 다시 실행하세요.

확인·제거 도구는 `%LOCALAPPDATA%\PZO-NPCFW-Compat\runtime\0.2.0-local`의 `Check.cmd`, `Uninstall.cmd`입니다. 제거 전 게임을 종료하세요. 구독 해제만으로 제거되지는 않습니다.

## Credits

- [PZ_Optimization — xD3I](https://steamcommunity.com/sharedfiles/filedetails/?id=3805285544)
- [Project Remnants — Datpat, Klosop1](https://steamcommunity.com/sharedfiles/filedetails/?id=3738362476)

An unofficial community compatibility tool. No game or original mod binaries are included in this repository. ASM notices are included with the Workshop payload.
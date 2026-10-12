# PZ_op × Project Remnants — Compatibility Patch

> **Existing users:** Close the game and run the updated installation command below once again. You do not need to uninstall or unsubscribe first. A Workshop update alone does not update an existing installation.
>
> This update disables PZO's startup cache (AOT) to fix the launch conflict. Other PZO optimizations and the NPC fixes remain enabled.
>
> **기존 설치자도 게임을 종료한 뒤, 아래 설치 명령을 한 번 다시 실행해 주세요.** 삭제나 구독 해제는 필요 없습니다. 워크숍 자동 업데이트만으로는 기존 설치본에 적용되지 않습니다.
>
> 게임 실행을 막을 수 있는 PZO의 시작 캐시(AOT)를 자동으로 끕니다. 다른 최적화 기능과 NPC 수정 기능은 유지됩니다.

Windows / Project Zomboid B42.21. Unofficial compatibility tool for PZ_Optimization and Project Remnants.

Restores NPC/player bump-animation suppression and keeps the original player body visible while controlling an NPC. Normal physical collision remains enabled.

## Installation

Install both original mods, subscribe to this patch on Steam Workshop, and wait for the download to finish. Close the game, then run the following command in Windows PowerShell once. The script finds Steam libraries, verifies the downloaded package, and installs the compatibility agent.

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Hotsco/pz_op-remnants-compat/eebecd7d005a33c08acd556b7821bfe9529b9009/install.ps1')))
```

Afterward, launch normally through Steam. No save-specific activation is needed. Compatible PZO updates are handled at startup; unsupported game, NPCFW, or target-method changes can block startup. If Steam resets the launcher, run installation again.

## Uninstall

1. Close Project Zomboid.
2. Press **Windows + R**, paste the folder path below, and press **Enter**.

   ```text
   %LOCALAPPDATA%\PZO-NPCFW-Compat\runtime\0.2.0-local
   ```

3. In the folder that opens, double-click **Uninstall.cmd**.
4. Once the window confirms removal, close it and unsubscribe from this patch on Steam Workshop.

**Unsubscribing alone does not uninstall the patch.**
To check the installation without removing it, run `Check.cmd` in the same folder.

## 한국어

Windows / 좀보이드 B42.21용 PZ_Optimization + Project Remnants 비공식 호환 도구입니다.

NPC/플레이어 접촉 시 충돌 애니메이션 억제와 NPC 조종 중 원래 플레이어 몸이 사라지는 문제를 수정합니다. 일반 물리 충돌은 유지됩니다.

### 설치 방법

1. **PZ_Optimization과 Project Remnants의 설치를 먼저 마치고**, 이 패치를 스팀 워크숍에서 구독해 다운로드를 기다리세요.
2. 좀보이드를 종료한 뒤, **Windows 키 + R**을 누르고 `powershell`을 입력해 **Enter**를 누르세요.
3. 열린 PowerShell 창에 아래 명령 전체를 붙여넣고 **Enter**를 누르세요. 게임과 구독 폴더를 자동으로 찾아 설치합니다.

   ```powershell
   & ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Hotsco/pz_op-remnants-compat/eebecd7d005a33c08acd556b7821bfe9529b9009/install.ps1')))
   ```

4. 설치 완료 메시지가 나오면 창을 닫고, 스팀에서 평소처럼 게임을 실행하세요.

게임을 켤 때마다 설치 명령을 실행할 필요는 없습니다. 세이브의 모드 목록에서 이 패치를 활성화할 필요는 없습니다.

호환되는 PZO 업데이트에는 시작 시 자동 적용됩니다. 지원하지 않는 변경에서는 게임 시작이 중단될 수 있습니다. Steam이 런처를 초기화하면 설치 명령을 다시 실행하세요.

### 제거 방법

1. 좀보이드를 완전히 종료하세요.
2. **Windows 키 + R**을 누르고, 아래 경로를 붙여넣은 뒤 **Enter**를 누르세요.

   ```text
   %LOCALAPPDATA%\PZO-NPCFW-Compat\runtime\0.2.0-local
   ```

3. 열린 폴더에서 **Uninstall.cmd**를 더블 클릭하세요.
4. 제거 완료 메시지가 나오면 창을 닫고, 스팀 워크숍에서 이 패치를 구독 해제하세요.

**구독 해제만으로는 패치가 제거되지 않습니다.**
설치 상태만 확인하려면 같은 폴더의 `Check.cmd`를 실행하세요.

## Credits

- [PZ_Optimization — xD3I](https://steamcommunity.com/sharedfiles/filedetails/?id=3805285544)
- [Project Remnants — Datpat, Klosop1](https://steamcommunity.com/sharedfiles/filedetails/?id=3738362476)

An unofficial community compatibility tool. No game or original mod binaries are included in this repository. ASM notices are included with the Workshop payload.

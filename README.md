# PZ_op × Project Remnants — Compatibility Patch 1.0.0

**Existing users: wait for the Workshop 1.0.0 download, close the game, and run the new command below once. No uninstall or unsubscribe is needed.** Workshop updates download the package but do not replace the tool already installed on your PC.

Windows / Project Zomboid B42.21. Restores NPC/player bump-animation suppression and keeps the original player body visible while controlling an NPC. Normal physical collision remains.

1.0.0 supports PZO's AOT startup cache. It removes the temporary AOT-off restriction added by 0.3.0, while keeping your current PZO preferences. It does not force AOT on.

## Install / Update

1. Finish installing [PZ_Optimization](https://steamcommunity.com/sharedfiles/filedetails/?id=3805285544) and [Project Remnants](https://steamcommunity.com/sharedfiles/filedetails/?id=3738362476).
2. Subscribe to [this patch](https://steamcommunity.com/sharedfiles/filedetails/?id=3816975899) and wait for its latest download.
3. Close the game. Press **Windows + R**, type `powershell`, and press **Enter**. Paste this entire command and press **Enter**:

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Hotsco/pz_op-remnants-compat/924622fe35bdafd71cd1c5714625edfcac04ce37/install.ps1')))
```

After setup, launch normally through Steam. This step makes the patch start with the game; it is not needed every launch. No save-specific activation is needed. Repeat installation when a patch update asks you to, or if Steam resets the launcher.

When AOT is enabled, allow startup to finish and quit normally during the first launches while PZO prepares the cache. Compatible PZO updates are handled at startup. Unsupported game, NPCFW, target-method, or AOT implementation changes may block startup; future compatibility is not guaranteed.

## Uninstall / Check

Close the game. Press **Windows + R**, paste this folder path, and press **Enter**:

```text
%LOCALAPPDATA%\PZO-NPCFW-Compat\runtime\1.0.0
```

Double-click **Uninstall.cmd**. After removal is confirmed, unsubscribe from the patch. **Unsubscribing alone does not remove its startup setting.** Run **Check.cmd** in the same folder to check installation without removing it.

If you prefer to install from a file, `Install.cmd` is here:

```text
<Steam library>\steamapps\workshop\content\108600\3816975899\mods\PZ_op_Remnants_Compat\42\Install.cmd
```

## 한국어

**기존 설치자도 워크숍 1.0.0 다운로드가 끝나면 게임을 종료하고, 아래 새 명령을 한 번 실행해 주세요. 먼저 삭제하거나 구독을 해제할 필요는 없습니다.** 워크숍 업데이트만으로는 PC에 따로 설치된 도구가 교체되지 않습니다.

Windows / 좀보이드 B42.21용 비공식 호환 패치입니다. NPC/플레이어 접촉 시 충돌 애니메이션 억제와 NPC 조종 중 원래 플레이어 몸이 사라지는 문제를 수정합니다. 일반 물리 충돌은 유지됩니다.

1.0.0부터 PZO의 시작 캐시(AOT)를 함께 사용할 수 있습니다. 0.3.0의 임시 AOT 차단은 해제하며 현재 PZO 옵션은 유지합니다. AOT를 강제로 켜지는 않습니다.

### 설치 / 업데이트

1. PZ_Optimization과 Project Remnants의 설치를 먼저 마치세요.
2. [이 패치](https://steamcommunity.com/sharedfiles/filedetails/?id=3816975899)를 구독하고 최신 파일 다운로드를 기다리세요.
3. 게임을 종료한 뒤 **Windows 키 + R**을 누르고 `powershell`을 입력해 **Enter**를 누르세요. 아래 명령 전체를 붙여넣고 **Enter**를 누르세요.

```powershell
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Hotsco/pz_op-remnants-compat/924622fe35bdafd71cd1c5714625edfcac04ce37/install.ps1')))
```

설치 완료 메시지가 나오면 창을 닫고 스팀에서 평소처럼 실행하세요. 게임 시작과 함께 패치가 작동하도록 연결하는 단계라 매번 실행할 필요는 없습니다. 세이브의 모드 목록에 추가할 필요도 없습니다. 패치 공지에서 요청하거나 스팀이 실행 설정을 초기화했을 때만 다시 설치하면 됩니다.

AOT를 켠 경우 처음 몇 번은 시작을 끝까지 기다린 뒤 정상 종료해 주세요. 캐시 준비에 필요합니다. 호환되는 PZO 업데이트는 시작 시 자동 처리하지만, 지원하지 않는 게임·NPCFW·수정 대상 코드·AOT 변경은 게임 시작을 막을 수 있습니다. 이후 모든 업데이트의 호환성을 보장하지는 않습니다.

### 제거 / 확인

게임을 종료하고 **Windows 키 + R**을 눌러 아래 경로를 붙여넣은 뒤 **Enter**를 누르세요.

```text
%LOCALAPPDATA%\PZO-NPCFW-Compat\runtime\1.0.0
```

열린 폴더에서 **Uninstall.cmd**를 더블 클릭하세요. 제거 완료 메시지가 나오면 이 패치를 구독 해제하세요. **구독 해제만으로는 실행 설정이 제거되지 않습니다.** 설치 상태만 확인하려면 같은 폴더의 **Check.cmd**를 실행하세요.

파일을 직접 찾아 설치할 경우 `Install.cmd`의 위치:

```text
<스팀 라이브러리>\steamapps\workshop\content\108600\3816975899\mods\PZ_op_Remnants_Compat\42\Install.cmd
```

## Credits

- [PZ_Optimization — xD3I](https://steamcommunity.com/sharedfiles/filedetails/?id=3805285544)
- [Project Remnants — Datpat, Klosop1](https://steamcommunity.com/sharedfiles/filedetails/?id=3738362476)

Thank you, J, for helping make this patch available!
해당 패치 배포를 위해 기여해주신 J 감사합니다!

Workshop ID: `3816975899` / Mod ID: `PZ_op_Remnants_Compat`

Unofficial community tool. No game or original mod binaries are distributed here. ASM notices are included with the Workshop package.

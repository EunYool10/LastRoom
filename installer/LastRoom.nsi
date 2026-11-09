; 마지막 방 설치 프로그램 (NSIS 3, Modern UI 2)
Unicode true
!include "MUI2.nsh"
!include "FileFunc.nsh"

!ifndef APPNAME
  !define APPNAME "마지막 방"
!endif
!ifndef APPID
  !define APPID "LastRoom"
!endif
!ifndef VERSION
  !define VERSION "1.4.3"
!endif
!define PUBLISHER "김은율"
!define UNKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}"

Name "${APPNAME}"
OutFile "..\build\LastRoom-Setup-${VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\${APPID}"
InstallDirRegKey HKCU "Software\${APPID}" "InstallDir"
RequestExecutionLevel user
SetCompressor /SOLID lzma
BrandingText "${APPNAME} ${VERSION}"
ShowInstDetails show
ShowUninstDetails show

VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=1042 "ProductName" "${APPNAME}"
VIAddVersionKey /LANG=1042 "FileDescription" "${APPNAME} 설치"
VIAddVersionKey /LANG=1042 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1042 "ProductVersion" "${VERSION}"
VIAddVersionKey /LANG=1042 "CompanyName" "${PUBLISHER}"
VIAddVersionKey /LANG=1042 "LegalCopyright" "${PUBLISHER}"

!define MUI_ICON "icon.ico"
!define MUI_UNICON "icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "welcome.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "header.bmp"
!define MUI_ABORTWARNING

; 첫 화면: 게임 그림과 로고, 설치할 폴더의 전체 경로
!define MUI_WELCOMEPAGE_TITLE "마지막 방 설치"
!define MUI_WELCOMEPAGE_TEXT "고인이 남긴 방을 치우고, 남겨진 물건으로 마지막 이야기를 듣는 1인칭 추리 게임입니다.$\r$\n$\r$\n설치할 폴더:$\r$\n$INSTDIR$\r$\n$\r$\n폴더는 설치하기 전에 바꿀 수 있습니다.$\r$\n$\r$\n다른 프로그램을 닫아 두는 것이 좋습니다. 계속하려면 [다음]을 누르세요."
!insertmacro MUI_PAGE_WELCOME

!define MUI_PAGE_HEADER_TEXT "이용 안내"
!define MUI_PAGE_HEADER_SUBTEXT "설치하기 전에 내용을 확인해 주세요."
!define MUI_LICENSEPAGE_TEXT_TOP "이용 안내를 끝까지 읽어 주세요."
!define MUI_LICENSEPAGE_TEXT_BOTTOM "내용에 동의하면 [동의함]을 눌러 설치를 계속합니다. 동의하지 않으면 설치할 수 없습니다."
!insertmacro MUI_PAGE_LICENSE "license_ko.txt"

!define MUI_PAGE_HEADER_TEXT "설치할 폴더"
!define MUI_PAGE_HEADER_SUBTEXT "게임을 넣을 폴더의 경로를 확인해 주세요."
!define MUI_DIRECTORYPAGE_TEXT_TOP "마지막 방을 아래 폴더에 설치합니다.$\r$\n다른 폴더에 설치하려면 [찾아보기]를 눌러 고르세요. 준비가 되면 [설치]를 누르세요."
!define MUI_DIRECTORYPAGE_TEXT_DESTINATION "설치할 폴더"
!insertmacro MUI_PAGE_DIRECTORY

; 설치 중: 폴더 경로를 머리글에, 파일마다 전체 경로를 목록에 보여 주고, 다 끝나도 목록을 볼 수 있게 멈춘다
!define MUI_PAGE_HEADER_TEXT "설치하고 있습니다"
!define MUI_PAGE_HEADER_SUBTEXT "설치 위치: $INSTDIR"
!define MUI_INSTFILESPAGE_FINISHHEADER_TEXT "설치를 마쳤습니다"
!define MUI_INSTFILESPAGE_FINISHHEADER_SUBTEXT "설치 위치: $INSTDIR"
!define MUI_INSTFILESPAGE_ABORTHEADER_TEXT "설치를 끝내지 못했습니다"
!define MUI_INSTFILESPAGE_ABORTHEADER_SUBTEXT "설치 위치: $INSTDIR"
!define MUI_FINISHPAGE_NOAUTOCLOSE
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE "설치가 끝났습니다"
!define MUI_FINISHPAGE_TEXT_LARGE
!define MUI_FINISHPAGE_TEXT "마지막 방을 아래 폴더에 설치했습니다.$\r$\n$\r$\n$INSTDIR$\r$\n$\r$\n바탕 화면과 시작 메뉴에 바로 가기를 만들었습니다."
!define MUI_FINISHPAGE_RUN "$INSTDIR\LastRoom.exe"
!define MUI_FINISHPAGE_RUN_TEXT "지금 마지막 방 실행하기"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!define MUI_PAGE_HEADER_TEXT "제거하고 있습니다"
!define MUI_PAGE_HEADER_SUBTEXT "제거 위치: $INSTDIR"
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Korean"

; 게임 안에서 받은 업데이트: LastRoom-Setup.exe /S /RUN
;  - 게임이 꺼질 때까지 잠깐 기다렸다가 설치하고, 끝나면 게임을 다시 켠다
Var RunAfter

Function .onInit
  StrCpy $RunAfter "0"
  ${GetParameters} $R0
  ClearErrors
  ${GetOptions} $R0 "/RUN" $R1
  IfErrors +2 0
  StrCpy $RunAfter "1"
  IfSilent 0 +2
  Sleep 1500
FunctionEnd

Function .onInstSuccess
  StrCmp $RunAfter "1" 0 +2
  Exec '"$INSTDIR\LastRoom.exe"'
FunctionEnd

; 전체 경로를 먼저 보여 주고 파일을 넣는다 (기본 문구에는 파일 이름만 나온다)
!macro InstallGameFile NAME
  DetailPrint "파일 설치: $INSTDIR\${NAME}"
  SetDetailsPrint none
  File "..\exe\${NAME}"
  SetDetailsPrint both
!macroend

; 시작 메뉴처럼 긴 경로도 끝까지 볼 수 있게 목록 폭을 가장 긴 줄에 맞춘다 (LVM_SETCOLUMNWIDTH, LVSCW_AUTOSIZE)
!macro FitDetailsList
  IfSilent +4
  FindWindow $R3 "#32770" "" $HWNDPARENT
  GetDlgItem $R3 $R3 1016
  SendMessage $R3 0x101E 0 -1
!macroend

Section "install"
  DetailPrint "설치 폴더: $INSTDIR"
  SetDetailsPrint none
  SetOutPath "$INSTDIR"
  ; 게임이 아직 꺼지는 중이면 파일이 잠겨 있으니 잠시 기다린다
  StrCpy $R2 0
  wait_exe:
  IfFileExists "$INSTDIR\LastRoom.exe" 0 exe_free
  ClearErrors
  Delete "$INSTDIR\LastRoom.exe"
  IfErrors 0 exe_free
  IntOp $R2 $R2 + 1
  IntCmp $R2 30 exe_free 0 exe_free
  Sleep 500
  Goto wait_exe
  exe_free:
  SetDetailsPrint both
  !insertmacro InstallGameFile "LastRoom.exe"
  !insertmacro InstallGameFile "LICENSES.txt"
  !insertmacro InstallGameFile "OFL.txt"
  !insertmacro InstallGameFile "README.txt"
  DetailPrint "제거 프로그램 생성: $INSTDIR\Uninstall.exe"
  SetDetailsPrint none
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  SetDetailsPrint both
  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk" "$INSTDIR\LastRoom.exe"
  CreateShortcut "$SMPROGRAMS\${APPNAME}\${APPNAME} 제거.lnk" "$INSTDIR\Uninstall.exe"
  CreateShortcut "$DESKTOP\${APPNAME}.lnk" "$INSTDIR\LastRoom.exe"
  !insertmacro FitDetailsList
  WriteRegStr HKCU "Software\${APPID}" "InstallDir" "$INSTDIR"
  WriteRegStr HKCU "${UNKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "${UNKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNKEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "${UNKEY}" "DisplayIcon" "$INSTDIR\LastRoom.exe"
  WriteRegStr HKCU "${UNKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNKEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegDWORD HKCU "${UNKEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNKEY}" "NoRepair" 1
  WriteRegDWORD HKCU "${UNKEY}" "EstimatedSize" 130000
SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\LastRoom.exe"
  Delete "$INSTDIR\LICENSES.txt"
  Delete "$INSTDIR\OFL.txt"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\Uninstall.exe"
  RMDir "$INSTDIR"
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  Delete "$SMPROGRAMS\${APPNAME}\${APPNAME} 제거.lnk"
  RMDir "$SMPROGRAMS\${APPNAME}"
  !insertmacro FitDetailsList
  DeleteRegKey HKCU "${UNKEY}"
  DeleteRegKey HKCU "Software\${APPID}"
SectionEnd

; Inno Setup script for the Dhikr Reminder Windows build.
;
; Not invoked directly -- scripts/build_windows.ps1 calls ISCC with the three
; defines below already filled in:
;
;   ISCC.exe /DAppVersion=0.1.0 /DSourceDir=...\build\windows\x64\runner\Release ^
;            /DOutputDir=...\dist scripts\installer.iss
;
; Requires Inno Setup 7 (https://jrsoftware.org/isdl.php). The setup .exe is the
; only thing shipped: it gives a Start-menu entry and an uninstaller, and is
; what the app's own updater downloads and runs (lib/core/update/).

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #error SourceDir must be defined (the staged dist\ folder to package)
#endif
#ifndef OutputDir
  #define OutputDir "..\dist"
#endif

#define AppName "Dhikr Reminder"
#define AppExe "dhikr_reminder.exe"
#define AppPublisher "Gratovo"

[Setup]
; A stable GUID: this is what lets a new version upgrade an existing install
; in place instead of piling up side-by-side entries. Never change it.
AppId={{4C1D8A63-2E57-4B9F-A0D4-7E8C3B1F5260}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={autopf}\Dhikr Reminder
DefaultGroupName=Dhikr Reminder
UninstallDisplayIcon={app}\{#AppExe}
OutputDir={#OutputDir}
OutputBaseFilename=dhikr_reminder-{#AppVersion}-setup
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Per-user install by default, so no admin prompt is needed to hand this to a
; teammate; the wizard still offers an all-users install where allowed.
; `lowest` is what makes per-user the DEFAULT -- without it the setting is
; `admin`, and a silent run that names no scope would raise UAC for something
; that does not need to touch the whole machine.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; The in-app updater (lib/core/update/) runs this same installer silently and
; starts the app again itself, whether or not the install succeeded, so Setup's
; own restart is turned off -- with both, a successful update could leave two
; copies running. It also decides whether a copy is *installed* (and so may
; update itself) by the unins000.exe Setup writes into {app}: keep the default
; uninstaller name, and keep UninstallFilesDir at its default ({app}).
CloseApplications=yes
RestartApplications=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; The whole staged folder: the .exe alone will not run -- it needs data\
; (flutter_assets, icudtl.dat) sitting beside it. recursesubdirs carries it.
;
; Nothing writable is installed here, deliberately: the dhikr list and the
; reminder interval live in %APPDATA%\dhikr_reminder\shared_preferences.json,
; so ignoreversion cannot reset them on an upgrade and an uninstall cannot
; take them with it.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; The "Start with Windows" switch in settings writes this value itself; this
; line only makes the uninstaller remove it, so no login entry is left pointing
; at a deleted exe.
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "DhikrReminder"; ValueType: none; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

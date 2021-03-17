; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "OfflineExpert for [Part 1]"
#define MyAppVersion "1.2"
#define MyAppPublisher "LearnKey, Inc."
#define MyAppURL "https://www.learnkey.com"
#define MyAppExeName "OfflineExpert for [Part 2].exe"
#define MyAppIdentifier "[Part 3]"

[Setup]

AppID={{ABCD1234-5678-EFGH-9012-IJKL3456}

AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\OfflineExpert
DefaultGroupName=OfflineExpert
DisableProgramGroupPage=yes
; Task: check to make sure that .. is the correct relative path. Could be . instead.
LicenseFile=..\text\EULA.rtf
InfoBeforeFile=..\text\INFO.rtf
InfoAfterFile=..\text\SUCCESS.rtf
OutputBaseFilename=offlineexpert-{#MyAppIdentifier}-setup
SetupIconFile=..\images\lk_square_icon.ico
UninstallDisplayIcon=..\images\lk_square_icon.ico
;Password=lk-{#MyAppIdentifier}
Compression=lzma
SolidCompression=yes
WizardSmallImageFile=..\images\lk_square_small.bmp
DisableDirPage=No
AlwaysShowDirOnReadyPage=yes
AllowRootDirectory=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Types]
Name: "full"; Description: "Full installation (standalone)"
Name: "nomedia"; Description: "Client installation (no media)"
Name: "mediaonly"; Description: "Server installation (media only)"; Flags: iscustom

[Components]
Name: "program"; Description: "Program files"; Types: full nomedia; Flags: fixed
Name: "media"; Description: "Media files"; Types: full mediaonly; Flags: fixed
Name: "assets"; Description: "Other course assets"; Types: full mediaonly nomedia; Flags: fixed

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; Components: program
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 0,6.1; Components: program

[Files]
; Common
Source: "..\help\OfflineExpert v1.2.doc"; DestDir: "{app}\help"; Flags: ignoreversion sharedfile isreadme; Components: program media assets
Source: "..\fonts\*"; DestDir: "{app}\fonts"; Flags: ignoreversion sharedfile; Components: program
Source: "..\images\lk*"; DestDir: "{app}\images"; Flags: ignoreversion sharedfile; Components: program
Source: "..\images\bg*"; DestDir: "{app}\images"; Flags: ignoreversion sharedfile; Components: program

; Course
Source: "..\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion; Components: program
Source: "..\{#MyAppIdentifier}*.html"; DestDir: "{app}"; Flags: ignoreversion; Components: program
Source: "..\domains\{#MyAppIdentifier}*.html"; DestDir: "{app}\domains"; Flags: ignoreversion; Components: program
Source: "..\images\{#MyAppIdentifier}*"; DestDir: "{app}\images"; Flags: ignoreversion; Components: program
Source: "..\glossaries\{#MyAppIdentifier}*"; DestDir: "{app}\glossaries"; Flags: ignoreversion; Components: program
Source: "..\outlines\{#MyAppIdentifier}*"; DestDir: "{app}\outlines"; Flags: ignoreversion; Components: program
Source: "..\videos\{#MyAppIdentifier}*"; DestDir: "{app}\videos"; Flags: ignoreversion; Components: media

; Assets
[Part 4]

; Media
[Part 5]

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN"; ValueType: dword; ValueName: iexplore.exe; ValueData: "0"
Root: HKLM; Subkey: "Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN"; ValueType: dword; ValueName: iexplore.exe; ValueData: "0"   

[Icons]
Name: "{group}\OfflineExpert\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\OfflineExpert\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\{#MyAppIdentifier}*.ini"
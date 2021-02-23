#SingleInstance force

[Part 1]

;Program begins 
Start:

; ensures that this runs in elevated mode
If Not A_IsAdmin 
{
	Run, *RunAs %A_ScriptFullPath%
	ExitApp 
}

; Constants
SetWorkingDir %A_ScriptDir%
StartPage = %A_WorkingDir%\%CourseIdentifier%-start.html
IniFile = %A_WorkingDir%\%CourseIdentifier%.ini
RunLevel = 1

; Check for HTML start page
If !FileExist(StartPage) {
	MsgBox, 48, Missing Components, % "Files missing in " . A_ScriptDir . ". Please reinstall OfflineExpert for " . CourseTitle
	IfMsgBox OK
		ExitApp
}

; Check for .ini file
If !FileExist(IniFile) {
	IniWrite, ./videos, % IniFile, MediaDirectory, DefaultPath
	IniWrite, ./videos, % IniFile, MediaDirectory, Path
}

; Read from the .ini file
IniRead, MediaDirectory, % IniFile, MediaDirectory, Path
IniRead, MediaDirectoryDefault, % IniFile, MediaDirectory, DefaultPath
IniRead, IniUserID, % IniFile, Registration, UserID
IniRead, IniCode, % IniFile, Registration, Code

; Check the registration code
try 
	CheckRegistrationCode(IniCode, IniUserID, CourseID)
catch e {
	MsgBox, 48, Registration Error, % "There was an error with the registration information. Please register again.`r`n`r`nError details:`r`n`r`n" . e.Message
	IfMsgBox OK
		GoTo, Register
}

; Run splash
SplashImage,%A_WorkingDir%\images\lk_square.jpg, B ZH300 ZW-1 CWFFFFFF, % "Loading... Press F6 now for options.", % "OfflineExpert for " . CourseTitle

; Write to registry
RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN, iexplore.exe, "0"
RegWrite, REG_DWORD, HKEY_LOCAL_MACHINE, Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_LOCALMACHINE_LOCKDOWN, iexplore.exe, "0"
Sleep 1000

; Start IE in kiosk
pac := ComObjCreate("Shell.Application").windows.count
run, iexplore.exe -k %StartPage%
ie := ComObjCreate("Shell.Application").windows.item[pac]

; Wait for IE to complete loading the page
While ie.readyState != 4 || ie.document.readyState != "complete" || ie.busy 
{
	Sleep 1000
	if (A_index > 10)
		MsgBox, Could not load
	Break
}

; Delay 3s while allowing for directory change
Sleep 3000

; Wait for options dialog to close if open
While (RunLevel > 1)
	Sleep 1000
	
SplashImage, Off
ExitApp

; Hotkey definition
F6::
{
	
	MediaDirectoryDisplay = % MediaDirectory
	RunLevel = 2
	ShowOptions:
		Gui, Add, Text, xm, Video path
		Gui, Add, Edit, x+m w400 vtempMediaDirectory, % MediaDirectoryDisplay
		Gui, Add, Button, x+m, Browse
		Gui, Add, Button, xm Default, OK
		Gui, Add, Button, x+m, Cancel
		Gui, Add, Button, x+m, Restore Defaults
		Gui, +AlwaysOnTop
		Gui, Show
		return
	
	Refresh:
		Gui, Destroy
		Goto, ShowOptions
	
	ButtonBrowse:
		Gui +OwnDialogs
		FileSelectFolder, Folder, , 2, Select the videos directory on the host machine
		If Folder = 
			Goto, Refresh
		IfNotInString, Folder, videos 
		{
			MsgBox, 4145, Invalid directory structure, The correct directory structure is ...\videos. Please select a different directory.
			IfMsgBox, OK
				Goto, ButtonBrowse
			IfMsgBox, Cancel
				Goto, Refresh 
		}
		MediaDirectoryDisplay := FixPath(Folder)
		Goto, Refresh
	return
	
	ButtonOK: 
		Gui, Submit
		MediaDirectory := FixPath(tempMediaDirectory)
		IniWrite, % MediaDirectory, % IniFile, MediaDirectory, Path
		Goto, WriteHTML
	return
	
	ButtonRestoreDefaults:
		MediaDirectoryDisplay = % MediaDirectoryDefault
		Goto, Refresh
	return
	
	ButtonCancel:
	GuiClose:
		RunLevel = 1
	return
	
	WriteHTML:
		Loop, %A_WorkingDir%\%CourseIdentifier%*.html  
		{
			FileRead, HTMLContent, % A_LoopFileFullPath
			FindText := "m)^var video_directory.+?$"
			ReplaceText := "var video_directory = " . chr(34) . MediaDirectory . chr(34) . ";"
			NewContent := RegExReplace(HTMLContent, FindText, ReplaceText)
			FileDelete, % A_LoopFileFullPath
			FileAppend, % NewContent, % A_LoopFileFullPath 
		}
		RunLevel = 1
	return
}

Register:
	If IniCode = ERROR
		IniCode = 
	If IniUserID = ERROR
		IniUserID = 
	
	Gui, OEReg:Add, Text, xm W300, Please enter your registration information below. All values are case sensitive.`r`n`r`nFor registration assistance, please contact your provider or send an email to techsupport@learnkey.com. You will need to provide the course ID below.`r`n
	Gui, OEReg:Add, Text, xm, Course ID
	Gui, OEReg:Font, s12, Consolas
	Gui, OEReg:Add, Text, xm, % CourseID
	Gui, OEReg:Font
	Gui, OEReg:Add, Text, xm, User ID
	Gui, OEReg:Add, Edit, xm W300 vDialogUserID Limit255, % IniUserID
	Gui, OEReg:Add, Text, xm, Registration code
	Gui, OEReg:Font, s12, Consolas
	Gui, OEReg:Add, Edit, xm W300 Center vDialogRegistrationCode Limit27, % RegExReplace(IniCode, "(...)(...)(...)(...)(...)(...)(...)", "$1-$2-$3-$4-$5-$6-$7")
	Gui, OEReg:Font
	Gui, OEReg:Add, Button, gSubmitRegistration, Submit
	Gui, OEReg:Show
return

OERegGuiClose:
	ExitApp
return
	
SubmitRegistration:
	Gui, OEReg:Submit
	Gui, OEReg:Destroy
	DialogUserID := Trim(DialogUserID)
	DialogRegistrationCode := Trim(RegExReplace(DialogRegistrationCode, "-"))
	IniWrite, % DialogUserID, % IniFile, Registration, UserID
	IniWrite, % DialogRegistrationCode, % IniFile, Registration, Code
	GoTo, Start
return

CheckRegistrationCode(IniCode, IniUserID, CourseID) {
	; Code check 0: blank
	If ((IniCode = "ERROR") or (IniUserID = "ERROR"))
		throw Exception("Unregistered (0)")

	; Code check 1: format
	If (RegExMatch(IniCode,"^[0-9A-F][A-Z]{20}$") != 1)
		throw Exception("Invalid registration code (1)")
	
	; Code check 2: letter range
	CharacterShift := Format("{1:i}", "0x" . SubStr(IniCode, 1, 1))
	BeginLetter := Chr(65 + CharacterShift)
	EndLetter := Chr(Asc(BeginLetter) + 16)
	If (RegExMatch(SubStr(IniCode,2),"[" . BeginLetter . "-" . EndLetter . "]{20}") != 1)
		throw Exception("Invalid registration code (2)")
	
	; Perform UserID name calculations
	UserIDLength := StrLen(IniUserID)
	UserIDSum = 0
	Loop, Parse, IniUserID
		UserIDSum += Asc(A_LoopField)
	HexUserIDLength := Format("{1:0.2X}", UserIDLength)
	HexUserIDSum := Format("{1:0.4X}", UserIDSum)

	; Code check 3: check UserID sum
	IniSum := Format("{1:i}", "0x" . Base262Hex(SubStr(IniCode,18,4), CharacterShift))
	If (IniSum != UserIDSum)
		throw Exception("Invalid registration code (3)")
	
	; Code check 4: check UserID length
	IniLength := Format("{1:i}", "0x" . Base262Hex(SubStr(IniCode,16,2), CharacterShift))
	If (IniLength != UserIDLength)
		throw Exception("Invalid registration code (4)")
	
	; Get Salt
	Salt := Format("{1:i}","0x" . Base262Hex(SubStr(IniCode,2,7), CharacterShift))
		
	; Get expiration date
	IniExpirationDate := Format("{1:i}", "0x" . Base262Hex(SubStr(IniCode,9,7), CharacterShift)) - Salt
	IniExpirationYear := SubStr(IniExpirationDate,1,4)
	IniExpirationMonth := SubStr(IniExpirationDate,5,2)
	IniExpirationDay := SubStr(IniExpirationDate,7,2)
	IniExpirationMonthDays := SubStr("312831303130313130313031",IniExpirationMonth * 2 - 1, 2)
		
	; Code check 5: check valid date
	If ((IniExpirationYear not between 2000 and 4000) or (IniExpirationMonth not between 1 and 12) or (IniExpirationDay not between 1 and IniExpirationMonthDays))
		throw Exception("Invalid registration code (5)")
	
	; Derive issue date
	IniIssueDate := Salt - IniExpirationDate - CourseID - IniSum
	IniIssueYear := SubStr(IniIssueDate,1,4)
	IniIssueMonth := SubStr(IniIssueDate,5,2)
	IniIssueDay := SubStr(IniIssueDate,7,2)
	IniIssueMonthDays := SubStr("312931303130313130313031",IniIssueMonth * 2 - 1, 2)
	
	; Code check 6: check valid course ID
	If ((IniIssueDate > IniExpirationDate) or (IniIssueYear not between 2000 and 4000) or (IniIssueMonth not between 1 and 12) or (IniIssueDay not between 1 and IniIssueMonthDays))
		throw Exception("Invalid registration code (6)")
		
	; Get current date
	Today := A_YYYY . A_MM . A_DD

	; Code check 7: check today against issue date
	If (Today < IniIssueDate)
		throw Exception("Registration code not yet valid (7)")
	
	; Code check 8: check today against expiration date
	If (IniExpirationDate < Today)
		throw Exception("Registration code expired (8)")
	
	; SUCCESS!
}

Base262Hex(Base26String, Offset)
{
	HexString =
	Loop, Parse, Base26String
		HexString .= Format("{1:X}",Asc(A_LoopField) - 65 - Offset)
	return HexString
}

FixPath(dir) 
{
	FixedPath := dir
	FixedPath := RegExReplace(FixedPath, "\\$")
	FixedPath := RegExReplace(FixedPath, "i)^([A-Z]):\\", "file:\\\$1:\")
	FixedPath := RegExReplace(FixedPath, "^\\\\", "file:\\")
	FixedPath := RegExReplace(FixedPath, "\\", "/")
	return % FixedPath 
}
# Make background black
$console = $host.ui.rawui
$console.backgroundcolor = "Black"
clear-host

# Pre-main global functions

function Wait-AnyKey {
  $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  Write-Host
}

function Wait-Number($min, $max) {
  try {
    $pressed = [int][string]$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character
  } catch {
    $pressed = 0
  }
  Write-Host "$min-$max"
  if ($pressed -ge $min -AND $pressed -le $max) {
    return $pressed
  } else {
    Write-Host "$pressed is not a valid choice. Please try again." -ForegroundColor Red
    Wait-Number $min $max
  }
}

function Wait-Y {
  Write-Host "`n`nEnter Y to continue or N to try again." -ForegroundColor Cyan
  $pressed = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown').Character
  if ($pressed -eq "y") {
    return $true
  } elseif ($pressed -eq "n") {
    return $false
  } else {
    return Wait-Y
  }
}

# Pre-main global variables

<# Part 1: 
   $courseName = "IC3 GS5" #>
[Part 1]

<# Part 2:
   $domainIDs = @("281119","281129") #>
[Part 2]

$destination = ".\media"
$destinationResolved = Resolve-Path $destination -ErrorAction SilentlyContinue -ErrorVariable _destinationTemp
if (!$destinationResolved) {
  $destinationResolved = $_destinationTemp[0].TargetObject
}

$root = "."
$rootResolved = Resolve-Path $root -ErrorAction SilentlyContinue -ErrorVariable _rootTemp
if (!$rootResolved) {
  $rootResolved = $_rootTemp[0].TargetObject
}

##### Notice to user #####
Write-Host "This script will download and replace the media for the " -NoNewLine
Write-Host $courseName -ForegroundColor Cyan -NoNewLine
Write-Host " OfflineExpert course."
Write-Host "`nAffected parent directory:"
Write-Host "`t$destinationResolved" -ForegroundColor Cyan
Write-Host "`nAffected subfolders:"
Write-Host "`t" -NoNewLine
Write-Host $domainIDs -Separator ", " -ForegroundColor Cyan
Write-Host "`nExisting files in these subfolders will be removed and overwritten." -ForegroundColor Red
Write-Host "`nPress any key to continue" -ForegroundColor Cyan -NoNewLine
Wait-AnyKey

# End of notice. Time to do the heavy lifting.

########### MAIN ###########

# Global functions

function Write-Result([bool]$bool) { # Write a cyan or red success or failure to screen
  $result = "Failure"
  $color = "Red"
  if ($bool) {
    $result = "Success"
    $color = "Cyan"
  }
  if ($host.UI.RawUI.CursorPosition.X -eq 0) {
    Write-Host "$result" -ForegroundColor $color
  } else {
    Write-Host "`t$result" -ForegroundColor $color -NoNewLine
  }
}

# Global variables

$fso = New-Object -ComObject scripting.filesystemobject
$client = New-Object System.Net.WebClient
$year = (Get-Date).year

##### Choose simulation mode #####
Clear-Host
Write-Host "Choose simulation mode"
Write-Host "`nS" -ForegroundColor Cyan -NoNewLine
Write-Host "`tSimulation mode: media folders will not be replaced or downloaded"
Write-Host "N" -ForegroundColor Cyan -NoNewLine
Write-Host "`tNormal mode: all actions will occur as otherwise described"
$pressed = Read-Host -Prompt "`nMode"
$simulate = ($pressed -eq "s")

##### Delete existing subdirectories and create new ones #####
Clear-Host
Write-Host "Deleting media subdirectories belonging to this course and creating new ones.`n"
Do {
  Write-Host "`n`tSession`tDelete`tCreate"
  Write-Host   "`t-------`t------`t------"

  foreach ($ID in $domainIDs) {  
    Write-Host "`t$ID" -NoNewLine
    $delete = $true
    try {
      # This is the only delete method that works with OneDrive
      if (!$simulate) {
        $fso.DeleteFolder("$destination\$ID*")
      }
    } catch {
      $delete = $false
    }
    Write-Result $delete
    
    $create = $true
    try {
      if (!$simulate) {
        $null = New-Item -ItemType "directory" -Path "$destination\$ID\CD\WinFlash"
      }
    } catch {
      $create = $false
    }
    Write-Result $create
    Write-Host
  }
}
Until (Wait-Y)

##### Download media #####
Clear-Host
Write-Host "Downloading media."

<# Part 3: 
   $fileNames = @(("H0001","M0001"),("H0001","FM001","C0001")) #>
[Part 3]

Do {
  Write-Host "`n`tDomain`tPrefix`tResult`tSize"
  Write-Host "`t------`t------`t-------`t--------"

  $i = 0
  foreach ($ID in $domainIDs) {
    foreach ($file in $fileNames[$i]) {
      
      $url = "https://media-aws.onlineexpert.com/realcbt/$ID/CD/WinFlash/$file.mp4"
      $destinationFilename = "$destination\$ID\CD\WinFlash\$file.mp4"
      
      Write-Host "`t$ID`t$file" -NoNewLine
      
      $download = $true
      try {
        if (!$simulate) {
          $client.DownloadFile($url,$destinationFilename)
        }
      } catch {
        $download = $false
      }
      Write-Result $download
          
      $filesize = "N/A"
      try {
        $destinationFile = Get-ChildItem $destinationFilename -ErrorAction Stop
        $filesize = "$(% {([int]($destinationFile.length / 104857.6))/10}) MB"
      } catch {}    
      Write-Host "`t$filesize`n"
    }
    $i = $i + 1
  }
}
Until (Wait-Y)

##### Download common assets #####
Clear-Host
Write-Host "`nDownloading and extracting assets."
do {
  try {
    $fso.DeleteFolder("C:\Temp\OfflineExpert")
  } catch {}

  $zipPath = "C:\Temp\OfflineExpert\assets.zip"
  New-Item $zipPath -Force

  $global:ProgressPreference = "SilentlyContinue"

  $download = $true
  try {  
    Invoke-RestMethod -Uri "https://api.github.com/repos/learnkeyinc/offlineexpert/zipball/" -OutFile $zipPath 
  } catch {
    $download = $false
  }

  Write-Host
  Write-Result $download
  Write-Host

  Write-Host "`nUnzipping." -ForegroundColor Cyan -NoNewLine
  $unzip = $true

  try {
    Expand-Archive -Path $zipPath -DestinationPath "C:\Temp\OfflineExpert"
    Move-Item "C:\Temp\OfflineExpert\learnkeyinc-offlineexpert-*\*" "C:\Temp\OfflineExpert" -Force
  } catch {
    $unzip = $false
  }
  Write-Result $unzip

  $global:ProgressPreference = "Continue"

  Write-Host "`nMoving.`t" -ForegroundColor Cyan -NoNewLine
  $move = $true

  try {
    Move-Item "C:\Temp\OfflineExpert\assets\*" "." -Force
  } catch {
    $move = $false
  }
  
  try {
    $fso.DeleteFile(".\glossaries\.gitignore")
  } catch {}
  
  Write-Result $move
}
Until (Wait-Y)

##### Create course-specific assets #####
Clear-Host
Write-Host "Creating and opening course-specific assets"

<# Part 4:
   $courseAssets = @("ic3-gs5-start.html","ic3-gs5-domain-1.html") #>
[Part 4]

$glossaryPath = ""

do {
  foreach ($asset in $courseAssets) {
    $asset = $asset -replace "\\\\",'\'
    if ($asset.substring(0,13) -eq ".\glossaries\") {
      $glossaryPath = $asset
    }
    $new = $true
    try {
      New-Item ".\$asset"
    } catch {
      $new = $false
    }
    Write-Host (Resolve-Path ".\$asset")
    Write-Result $new  
  }
}
Until (Wait-Y)

##### Glossary edit #####
Clear-Host
Write-Host "OnlineExpert Course ID needed" -Foregroundcolor Cyan
Write-Host "`n`tExample: https://lms.onlineexpert.com/Student/Home#/course/home/12345/" -NoNewLine
Write-Host "126" -BackgroundColor Cyan -ForegroundColor Black -NoNewLine
Write-Host "/12"
Write-Host "`nGo to https://lms.learnkey.com and log in as a student. Open the course and paste the entire URL below. Or, if you already know the ID, simply enter it below:"
Do {
  $lmsURL = Read-Host "`nURL or course ID"
  if ($lmsURL.length -lt 10) {
    $lmsID = $lmsURL
  } else {
    $lmsID = $lmsURL.Split("/")[-2]
  }
  Write-Host "`nOnlineExpert Course ID: " -NoNewLine
  Write-Host $lmsID -ForegroundColor Cyan
  
  Write-Host "`nRetrieving glossary." -NoNewLine
  $request = $true
  try {
    $webrequest = Invoke-WebRequest "https://lms.onlineexpert.com" -SessionVariable websession

    $response = Invoke-RestMethod "https://lms.onlineexpert.com/student/coursehomeapi/GetGlossary?Origin=https://lms.onlineexpert.com&Referer=https://lms.onlineexpert.com/Student/Home&courseId=$lmsID" -Method 'POST' -WebSession $websession
  } catch {
    $request = $false
  }
  Write-Result $request

  $entries = $response.result

  $glossary = $entries | Group-Object 'def','con' | % { $_.Group | Select 'def','con' -First 1 } | Sort 'def' 
  
  $glossaryJSON = $glossary | ConvertTo-Json

  Write-Host "`n$($glossary.Length)" -NoNewLine -ForegroundColor Cyan
  Write-Host " terms found."
} 
Until (Wait-Y)

Write-Host "`nIMPORTANT" -BackgroundColor Red -ForegroundColor Black
Write-Host "Before continuing, ensure that the following file has the correct contents from Google Drive:" -ForegroundColor Red
Write-Host (Resolve-Path $glossaryPath) -ForegroundColor Red
Write-Host "Press any key to continue." -ForegroundColor Red
Wait-AnyKey
Do {
  Write-Host "`nWriting to " -NoNewLine
  Write-Host (Resolve-Path $glossaryPath) -ForegroundColor Cyan

  $glossaryReplace = $true
  try {
    ((Get-Content -Path $glossaryPath -Raw) -replace "\[PS\]",$glossaryJSON) | Set-Content -Path $glossaryPath
  } catch {
    $glossaryReplace = $false
  }
  Write-Result $glossaryReplace
}
Until (Wait-Y)

##### Completed notice #####
Clear-Host
Write-Host "`nScript complete. Assets have been created in the " -NoNewLine
Write-Host $rootResolved -ForegroundColor Cyan -NoNewLine
Write-Host " directory."
Write-Host "`nTo open all the course-specific assets for editing, choose an option below."
Write-Host "`n1: Open in Notepad++ tabs"
Write-Host "2: Open in Notepad windows"
Write-Host "3: Open in Sublime Text 3 tabs"
Write-Host "4: Exit"

$choice = Wait-Number 1 4
switch ($choice) {
  1 { 
      foreach ($asset in $courseAssets) {
        start notepad++ "`".\$asset`""
      }
    }
  2 {
      foreach ($asset in $courseAssets) {
        start notepad "`".\$asset`""
      }
    }
  3 {
      foreach ($asset in $courseAssets) {
        start "c:\program files\sublime text 3\sublime_text.exe" "`".\$asset`""
      }
    } 
}

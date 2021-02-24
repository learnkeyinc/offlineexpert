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

function Write-Result { # Write a cyan or red success or failure to screen
  param (
    $bool
  )
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

##### Delete existing subdirectories and create new ones #####
Clear-Host
Write-Host "Deleting media subdirectories belonging to this course and creating new ones.`n"

Write-Host "`n`tSession`tDelete`tCreate"
Write-Host   "`t-------`t------`t------"

foreach ($ID in $domainIDs) {  
  Write-Host "`t$ID" -NoNewLine
  $delete = $true
  try {
    # This is the only delete method that works with OneDrive
    $fso.DeleteFolder("$destination\$ID*")
  } catch {
    $delete = $false
  }
  Write-Result($delete)
  
  $create = $true
  try {
    $null = New-Item -ItemType "directory" -Path "$destination\$ID\CD\WinFlash"
  } catch {
    $create = $false
  }
  Write-Result($create)
  Write-Host
}

Write-Host "`nPress any key to begin downloading media" -ForegroundColor Cyan -NoNewLine
Wait-AnyKey

##### Download media #####
Clear-Host
Write-Host "Downloading media."

<# Part 3: 
   $fileNames = @(("H0001","M0001"),("H0001","FM001","C0001")) #>
[Part 3]

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
      $client.DownloadFile($url,$destinationFilename)
    } catch {
      $download = $false
    }
    Write-Result($download)
        
    $filesize = "N/A"
    try {
      $destinationFile = Get-ChildItem $destinationFilename -ErrorAction Stop
      $filesize = "$(% {([int]($destinationFile.length / 104857.6))/10}) MB"
    } catch {}    
    Write-Host "`t$filesize`n"
  }
  $i = $i + 1
}
Write-Host "`nPress any key to begin downloading other assets" -ForegroundColor Cyan -NoNewLine
Wait-AnyKey

##### Download common assets #####
Clear-Host
Write-Host "`nDownloading and extracting assets."

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
Write-Result($download)
Write-Host

Write-Host "`nUnzipping." -ForegroundColor Cyan -NoNewLine
$unzip = $true

try {
  Expand-Archive -Path $zipPath -DestinationPath "C:\Temp\OfflineExpert"
  Move-Item "C:\Temp\OfflineExpert\learnkeyinc-offlineexpert-*\*" "C:\Temp\OfflineExpert" -Force
} catch {
  $unzip = $false
}
Write-Result($unzip)

$global:ProgressPreference = "Continue"

Write-Host "`nMoving.`t" -ForegroundColor Cyan -NoNewLine
$move = $true

try {
  Move-Item "C:\Temp\OfflineExpert\assets\*" "." -Force
} catch {
  $move = $false
}
Write-Result($move)
Write-Host "`nPress any key to create course-specific assets" -ForegroundColor Cyan
Wait-AnyKey

##### Create course-specific assets #####
Clear-Host
Write-Host "Creating and opening course-specific assets"

<# Part 4:
   $courseAssets = @("ic3-gs5-start.html","ic3-gs5-domain-1.html") #>
[Part 4]

foreach ($asset in $courseAssets) {
  $new = $true
  try {
    New-Item ".\$asset"
  } catch {
    $new = $false
  }
  Write-Host (Resolve-Path ".\$asset")
  Write-Result($new)  
}

Write-Host "`nFiles created. Press any key to continue."
Wait-AnyKey

##### Complete notice #####
Clear-Host
Write-Host "`nScript complete. Assets have been created in the " -NoNewLine
Write-Host $destinationResolved -ForegroundColor Cyan -NoNewLine
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
        start notepad++ ".\$asset"
      }
    }
  2 {
      foreach ($asset in $courseAssets) {
        start notepad ".\$asset"
      }
    }
  3 {
      foreach ($asset in $courseAssets) {
        start "c:\program files\sublime text 3\sublime_text.exe" ".\Start.bat"
      }
    } 
}

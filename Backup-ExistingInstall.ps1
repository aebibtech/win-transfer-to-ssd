# Backup-ExistingInstall.ps1
# Author: Paul Abib S. Camano
# Backup an existing Windows install to a WIM file.
#Requires -RunAsAdministrator

# Drive Letters for finding a Windows install
$letter = @(
    "B","C","D","E","F","G","H","I","J",
    "K","L","M","N","0","P","Q","R","S",
    "T","U","V","W","X","Y","Z"
)

$DRV_LETTER = $null

# Look for a valid Windows install
foreach ($l in $letter) {
    if(Test-Path "${l}:\Windows\write.exe" ) {
        $DRV_LETTER = $l
        Write-Host
        Write-Host "Windows Install found on ${DRV_LETTER}:\Windows"
        Write-Host
        break
    }
}

if(!$DRV_LETTER -eq $null) {
    Write-Host -ForegroundColor Yellow "No Windows install found. Exiting"
    exit
}


$ROOT_PATH = $PSScriptRoot.Remove($PSScriptRoot.Length - 1)

if(!(Test-Path "${DRV_LETTER}:\os.wim")) {
    Write-Host
    Write-Host "Capturing Current OS to ${DRV_LETTER}:\os.wim"
    
    cmd /c Dism.exe /Capture-Image /ImageFile:"${DRV_LETTER}:\os.wim" /CaptureDir:"${DRV_LETTER}:\" /Name:"Backup Existing Install" /ConfigFile:"${ROOT_PATH}\wimscript.ini" /compress:none
}

if(Test-Path "${DRV_LETTER}:\os.wim") {
    Write-Host
    Write-Host -ForegroundColor Green "Capture Existing Windows Image Successful!"
    Write-Host -ForegroundColor Green "Apply it to the SSD."
    Write-Host
} else {
    Write-Host
    Write-Host -ForegroundColor Yellow "Image Capture failed."
    Write-Host
}
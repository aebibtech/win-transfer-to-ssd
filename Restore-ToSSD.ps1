# Restore-ToSSD.ps1
# Author: Paul Abib S. Camano
# Restores an os.wim file to a new SSD. 

# Look for os.wim in all drives.
function Get-DriveLetter {
    # Drive Letters for finding a Windows install
    $letter = @(
        "B","C","D","E","F","G","H","I","J",
        "K","L","M","N","0","P","Q","R","S",
        "T","U","V","W","X","Y","Z"
    )

    Write-Host "Looking for the os.wim file that was captured earlier. . ."
    Start-Sleep -Seconds 1.5

    $DRV_LETTER = $null
    foreach ($l in $letter) {
        if(Test-Path "${l}:\os.wim" ) {
            $DRV_LETTER = $l
            Write-Host
            Write-Host "os.wim found on ${DRV_LETTER}:\"
            Write-Host
            return $DRV_LETTER
        }
    }

    if(!$DRV_LETTER) {
        Write-Host
        Write-Host -ForegroundColor Yellow "os.wim is not found. Exiting."
        Write-Host
        exit
    }
}

# Check for Empty Disk
function Get-SSD {
    $disk = Get-Disk | Where-Object -Property PartitionStyle -EQ -Value "RAW"
    
    if (!$disk) {
        Write-Host
        Write-Host -ForegroundColor Yellow 'No empty SSD found.' 
        Write-Host
        exit 
    }
    
    Write-Host 'SSD' $disk.FriendlyName 'with disk number ' $disk.DiskNumber 'is selected for Windows installation.'
    return $disk
}

function New-Gpt {
    $disk = Get-SSD

    # Initialize the SSD
    Write-Host "Initializing SSD with GPT Partition Style." -ForegroundColor Green
    Initialize-Disk -InputObject $disk -PartitionStyle GPT -Verbose

    # Create and format the ESP Partition
    Write-Host "Creating and Formatting EFI System Partition..." -ForegroundColor Green
    New-Partition -InputObject $disk -DriveLetter B -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -Size 100MB -Verbose |
    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "ESP_SSD"

    # Create the MSR partition
    Write-Host "Creating MSR Partition..." -ForegroundColor Green
    New-Partition -InputObject $disk -GptType "{E3C9E316-0B5C-4DB8-817D-F92DF00215AE}" -Size 16MB -Verbose

    # Create and format the Windows install partition
    Write-Host "Creating and Formatting Windows Install Partition..." -ForegroundColor Green
    New-Partition -InputObject $disk -DriveLetter T -UseMaximumSize -Verbose |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "SSD"
}

function New-Mbr {

    $disk = Get-SSD

    # Initialize the SSD
    Write-Host "Initializing SSD with MBR Partition Style." -ForegroundColor Green
    Initialize-Disk -InputObject $disk -PartitionStyle MBR -Verbose

    # Create and format the Windows install partition
    Write-Host "Creating and Formatting Windows Install Partition..." -ForegroundColor Green
    New-Partition -InputObject $disk -IsActive -DriveLetter T -UseMaximumSize -Verbose |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "SSD" -Verbose
}

function Initialize-SSD {
    # Get Fimware Type (BIOS or UEFI)
    $firmType = (Get-ComputerInfo).BiosFirmwareType
    Write-Host "Firmware Type: " "${firmType}".ToUpper()

    if ($firmType -eq "Uefi") { New-Gpt }
    else { New-Mbr }
    return $firmType
}

function Restore-Windows {
    $firmType = Initialize-SSD
    $DRV_LETTER = Get-DriveLetter
    $IMGFILE = "${DRV_LETTER}:\os.wim"
    $WINOS = "T:\Windows"
    $BOOT = "B:"

    Write-Host ""
    Write-Host "Restoring Windows to SSD. . ." -ForegroundColor Yellow
    cmd /c Dism.exe /Apply-Image /ImageFile:$IMGFILE /index:1 /ApplyDir:T:\

    Write-Host ""
    Write-Host "Running bcdboot " $firmType.ToUpper()
    Write-Host "Windows on " $WINOS
    Write-Host "Boot Drive on " $BOOT
    if ($firmType -eq "Uefi") {
        cmd /c bcdboot.exe $WINOS /s $BOOT /f UEFI /v
    } else {
        cmd /c bcdboot.exe $WINOS /s T: /f BIOS /v
    }

    Write-Host ""
    Write-Host "Done!"
}

Write-Host "Aebibtech Restore to SSD" -ForegroundColor Green
Write-Host "Starting restore process. . ." -ForegroundColor Green
Write-Host

# Call WinNTSetup
Restore-Windows

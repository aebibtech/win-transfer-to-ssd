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
    Initialize-Disk -InputObject $disk -PartitionStyle GPT -Verbose

    # Create and format the ESP Partition
    New-Partition -InputObject $disk -DriveLetter B -GptType "{c12a7328-f81f-11d2-ba4b-00a0c93ec93b}" -Size 100MB -Verbose |
    Format-Volume -FileSystem FAT32 -NewFileSystemLabel "ESP_SSD"

    # Create the MSR partition
    New-Partition -InputObject $disk -GptType "{E3C9E316-0B5C-4DB8-817D-F92DF00215AE}" -Size 16MB -Verbose

    # Create and format the Windows install partition
    New-Partition -InputObject $disk -DriveLetter T -UseMaximumSize -Verbose |
    Format-Volume -FileSystem NTFS -NewFileSystemLabel "SSD"
}

function New-Mbr {
    $disk = Get-SSD

    # Initialize the SSD
    Initialize-Disk -InputObject $disk -PartitionStyle MBR -Verbose

    # Create and format the Windows install partition
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
    $ROOT_PATH = $PSScriptRoot.Remove($PSScriptRoot.Length - 1)
    $WINNT_SETUP = "${ROOT_PATH}\Aebibtech-Installer\win10\WinNTSetup_x64.exe"
    $DRV_LETTER = Get-DriveLetter
    $PARAMS = "/source:${DRV_LETTER}:\os.wim /wimindex:1"

    Write-Host ""
    Write-Host "Restoring Windows to SSD. . ." -ForegroundColor Yellow

    if ($firmType -eq "Uefi") {
        Start-Process -FilePath $WINNT_SETUP -ArgumentList "NT6 ${PARAMS} /syspart:B: /tempdrive:T: /nobootsect /bcd:UEFI /setup"
    } else {
        Start-Process -FilePath $WINNT_SETUP -ArgumentList "NT6 ${PARAMS} /syspart:T: /tempdrive:T: /bcd:BIOS /setup"
    }

    Write-Host ""
    Write-Host "Done!"
}

# Call WinNTSetup
Restore-Windows

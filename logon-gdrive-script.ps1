try{  
    Get-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name GpNetworkStartTimeoutPolicyValue -ErrorAction Stop  
}  
catch [System.Management.Automation.ItemNotFoundException] {  
    New-Item -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon'
    New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name GpNetworkStartTimeoutPolicyValue -Value 60 -PropertyType DWord -Force
}  
catch {  
    New-ItemProperty -Path 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name GpNetworkStartTimeoutPolicyValue -Value 60 -PropertyType DWord -Force
}

Write-Host "Regedit done"
function Get-UserPath {

    switch ($env:USERNAME) {
        { Test-Path -Path "\\ls-fs01\Userdata\Staff\$env:USERNAME" } {
            return "\\ls-fs01\Userdata\Staff\$env:USERNAME\Documents" }
        { Test-Path -Path "\\ls-fs01\Userdata\StudentDocs\$env:USERNAME" } {
            return "\\ls-fs01\Userdata\StudentDocs\$env:USERNAME\My Documents" }
        Default { "$env:USERNAME\'s Documents could not be found" }
    }
}

Write-Host "User got"

function Get-MoveStatus {
    $FSDocs = Get-UserPath
    $DocsMoved = "$FSDocs\movedToGDrive.txt"
    if (-not (Test-Path -Path $DocsMoved)) {
        return [false]
    } else { return [true] }
}

Get-MoveStatus | Write-Host

Write-Host "Move got"
Write-Host $env:USERNAME

function New-DriveFS {
    if (-not (Test-Path -Path "C:\Users\$env:USERNAME\AppData\Local\Google\DriveFS")) {

        Write-Host "Couldnt find drivefs on system"

        $MSIArguments = @(
        "/i"
        "\\ls-fs02\Network Data\Tech\0nwardsAndUpwards\Google\Drive\GoogleDriveSetup.exe"
        "/qn"
        "/norestart"
        "/L*v"
        "C:\DriveFSLog"
        )
        
        Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow



    } else {
        Write-Host "Found drivefs on system"
        continue }
}

try { Get-MoveStatus }
    catch [true] {
        Write-Host "Was moved"
        New-DriveFS
    }
    catch [false] {
        
        Write-Host "Wasnt moved"

        $StartProcArgs = @(
        ($FSDocs)
        "C:\Users\$env:USERNAME\Desktop\temporary"
        "/move"
        "/e"
        "/j"
        "/z"
        ">C:\DriveFSLog"
        )
    
        Start-Process "robocopy" -ArgumentList $StartProcArgs -Wait -NoNewWindow 

        New-DriveFS

        $StartProcArgs = @(
        "C:\Users\$env:USERNAME\Desktop\temporary"
        "G:\My Drive\Windows\Documents"
        "/move"
        "/e"
        "/j"
        "/z"
        ">C:\DriveFSLog"
        )
    
        Start-Process "robocopy" -ArgumentList $StartProcArgs -Wait -NoNewWindow

        New-Item $DocsMoved
        Set-Content $DocsMoved "All Documents have been moved to your Google Drive"

    }
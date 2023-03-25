#Script to install chrome.exe via GPO

$Chrome = 'C:\Program Files\Google\Chrome'

if (-not (Test-Path -Path $Chrome)) {
   
    $MSIArguments = @(
    "/i"
    ('"{0}"' -f "\\ls-fs02\Network Data\Tech\0nwardsAndUpwards\Google\Chrome\ChromeSetup.exe")
    "/qn"
    "/norestart"
    "/L*v"
    $logFile
    )
    
    Start-Process "msiexec.exe" -ArgumentList $MSIArguments -Wait -NoNewWindow
    }
else  { }


#Script to set registry values for DriveFS if not already set
try{  
    Get-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name AllowedAccountsPattern -ErrorAction Stop  
}  
catch [System.Management.Automation.ItemNotFoundException] {  
    New-Item -Path HKLM:\Software\Policies\Google\DriveFS -Force
    New-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name AllowedAccountsPattern -Value .*lakerschools.org -Force
    New-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name AutoStartOnLogin -Value 1 -Type String
    New-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name DefaultMountPoint -Value U:
}  
catch {  
    New-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name AllowedAccountsPattern -Value .*lakerschools.org -Type String -Force
    New-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name AutoStartOnLogin -Value 1 -Type String
    New-ItemProperty -Path HKLM:\Software\Policies\Google\DriveFS -Name DefaultMountPoint -Value U:
}


#Script to install GCPW on Lakers Devices

if (-not (Test-Patj -Path 'C:\Program Files\Google\Credential Provider')) {
    $domainsAllowedToLogin = "lakerschools.org"

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationFramework

<# Check if one or more domains are set #>
if ($domainsAllowedToLogin.Equals('')) {
    $msgResult = [System.Windows.MessageBox]::Show('The list of domains cannot be empty! Please edit this script.', 'GCPW', 'OK', 'Error')
    exit 5
}

function Get-Admin() {
    $admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match 'S-1-5-32-544')
    return $admin
}

<# Check if the current user is an admin and exit if they aren't. #>
if (-not (Get-Admin)) {
    $msgResult = [System.Windows.MessageBox]::Show('Please run as administrator!', 'GCPW', 'OK', 'Error')
    exit 5
}

<# Choose the GCPW file to download. 32-bit and 64-bit versions have different names #>
$gcpwFileName = 'gcpwstandaloneenterprise.msi'
if ([Environment]::Is64BitOperatingSystem) {
    $gcpwFileName = 'gcpwstandaloneenterprise64.msi'
}

<# Download the GCPW installer. #>
$gcpwUrlPrefix = 'https://dl.google.com/credentialprovider/'
$gcpwUri = $gcpwUrlPrefix + $gcpwFileName
Write-Host 'Downloading GCPW from' $gcpwUri
Invoke-WebRequest -Uri $gcpwUri -OutFile $gcpwFileName

<# Run the GCPW installer and wait for the installation to finish #>
$arguments = "/i `"$gcpwFileName`""
$installProcess = (Start-Process msiexec.exe -ArgumentList $arguments -PassThru -Wait)

<# Check if installation was successful #>
if ($installProcess.ExitCode -ne 0) {
    $msgResult = [System.Windows.MessageBox]::Show('Installation failed!', 'GCPW', 'OK', 'Error')
    exit $installProcess.ExitCode
}
else {
    $msgResult = [System.Windows.MessageBox]::Show('Installation completed successfully!', 'GCPW', 'OK', 'Info')
}

<# Set the required registry key with the allowed domains #>
$registryPath = 'HKEY_LOCAL_MACHINE\Software\Google\GCPW'
$name = 'domains_allowed_to_login'
[microsoft.win32.registry]::SetValue($registryPath, $name, $domainsAllowedToLogin)

$domains = Get-ItemPropertyValue HKLM:\Software\Google\GCPW -Name $name

if ($domains -eq $domainsAllowedToLogin) {
    $msgResult = [System.Windows.MessageBox]::Show('Configuration completed successfully!', 'GCPW', 'OK', 'Info')
}
else {
    $msgResult = [System.Windows.MessageBox]::Show('Could not write to registry. Configuration was not completed.', 'GCPW', 'OK', 'Error')

}

}

Write-Host $msgResult
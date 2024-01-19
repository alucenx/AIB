# Cleanup and Generalization
$cleanupState = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\Setup\Status\SysprepStatus' -Name 'CleanupState' -ErrorAction SilentlyContinue
$generalizationState = Get-ItemPropertyValue -Path 'HKLM:\SYSTEM\Setup\Status\SysprepStatus' -Name 'GeneralizationState' -ErrorAction SilentlyContinue
if ($cleanupState -eq $null) {
    New-Item -Path 'HKLM:\SYSTEM\Setup\Status\SysprepStatus' -Force | Out-Null
    }
if ($cleanupState -ne 2) {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\Setup\Status\SysprepStatus' -Name 'CleanupState' -Value 2
}
if ($generalizationState -eq $null) {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\Setup\Status\SysprepStatus' -Name 'GeneralizationState' -Value 7
}
# Software Protection Platform
if (-not (Test-Path 'HKLM:\Software\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform')) {
    New-Item -Path 'HKLM:\Software\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform' -Force | Out-Null
}
Set-ItemProperty -Path 'HKLM:\Software\Microsoft\WindowsNT\CurrentVersion\SoftwareProtectionPlatform' -Name 'SkipRearm' -Value 1
Remove-Item -Path 'C:\Windows\Panther' -Force -Recurse -ErrorAction SilentlyContinue
$cdromStartValue = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\cdrom' -Name 'start').start
if ($cdromStartValue -ne 1) {
    Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\cdrom' -Name 'start' -Value 1
}
foreach ($service in Get-Service -Name RdAgent, WindowsAzureTelemetryService, WindowsAzureGuestAgent -ErrorAction SilentlyContinue) {
    while ((Get-Service $service.Name).Status -ne 'Running') {
        Start-Sleep -Seconds 5
    }
}
if (Test-Path $Env:SystemRoot\windows\system32\Sysprep\unattend.xml) {
    Remove-Item $Env:SystemRoot\windows\system32\Sysprep\unattend.xml -Force
}
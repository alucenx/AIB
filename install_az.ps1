# Install the latest version of Azure PowerShell module
Install-Module -Name Az -AllowClobber -Force -Scope AllUsers -Verbose
Start-Sleep -Seconds 90
# Import the Az module
Import-Module Az -Force
Start-Sleep -Seconds 25

# Use the managed identity details obtained earlier
$managedIdentity = Get-AzUserAssignedIdentity -Name "AIBManageID" -ResourceGroupName "ImageBuilderAN-RG"

# Get access token for the managed identity
$accessToken = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token

$storageAccountName = "imagebuilderan"
$resourceGroupName = "ImageBuilderAN-RG"
$fileShareName = "aib-fs"

# Test the connection to the Azure storage account
$connectTestResult = Test-NetConnection -ComputerName "$storageAccountName.file.core.windows.net" -Port 445

if ($connectTestResult.TcpTestSucceeded) {
    # Get storage account keys
    $storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName

    if ($storageAccountKeys.Count -eq 0) {
        throw 'No storage account keys found.'
    }

    # Display the first key (you can adjust the index if needed)
    $storageAccountKey = $storageAccountKeys[0].Value
    Write-Host "Storage Account Key: $storageAccountKey"

    # Save the password using cmdkey
    cmd.exe /C "cmdkey /add:`"$($storageAccountName).file.core.windows.net`" /user:`"localhost\$($storageAccountName)`" /pass:`"$($storageAccountKey)`""

    # Map the drive
    New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$($storageAccountName).file.core.windows.net\$($fileShareName)" -Persist

    # Check if C:\temp directory exists, create if not
    if (-not (Test-Path -Path "C:\temp" -PathType Container)) {
        New-Item -Path "C:\temp" -ItemType Directory
    }

    # Copy the file from network drive to local directory
    Copy-Item -Path "Z:\software.zip" -Destination "C:\temp" -Force
} else {
    Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}

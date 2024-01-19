# Install the latest version of Azure PowerShell module
Install-Module -Name Az -AllowClobber -Force -Scope AllUsers -Verbose

# Import the Az module
Import-Module Az -Force

# Use the managed identity details obtained earlier
$managedIdentity = Get-AzUserAssignedIdentity -Name "AIBManageID" -ResourceGroupName "ImageBuilderAN-RG"

# Get access token for the managed identity
$accessToken = (Get-AzAccessToken -ResourceUrl https://management.azure.com).Token

# Create a PSCredential object
$managedIdentityCredential = [PSCredential]::new($managedIdentity.ClientId, (ConvertTo-SecureString -String $accessToken -AsPlainText -Force))

# Connect to Azure using the managed identity credentials
Connect-AzAccount -Credential $managedIdentityCredential -Tenant $managedIdentity.TenantId -ServicePrincipal

$storageAccountName = "imagebuilderan"
$resourceGroupName = "ImageBuilderAN-RG"
$fileShareName = "aib-fs"
$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName

if ($storageAccountKeys.Count -eq 0) {
    throw 'No storage account keys found.'
}

$storageAccountKey = $storageAccountKeys[0].Value

# Map the file share
$cmdkeyCommand = "cmdkey.exe /add:$fileShareName.file.core.windows.net /user:$storageAccountName /pass:$storageAccountKey"
Invoke-Expression -Command $cmdkeyCommand

# Now, you can access the mapped file share using the specified drive letter (e.g., Z:)
# You can change the drive letter based on your preference
$driveLetter = "Z:"
$netUseCommand = "net use $driveLetter \\$storageAccountName.file.core.windows.net\$fileShareName /persistent:yes"
Invoke-Expression -Command $netUseCommand

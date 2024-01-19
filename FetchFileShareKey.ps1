$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -AccountName $storageAccountName
if ($storageAccountKeys.Count -eq 0) {
    throw 'No storage account keys found.'
}
$storageAccountKey = $storageAccountKeys[0].Value
$cmdkeyCommand = "cmdkey.exe /add:$fileShareName /user:$storageAccountName /pass:$storageAccountKey"
Invoke-Expression -Command $cmdkeyCommand
[System.Environment]::SetEnvironmentVariable("StorageAccountKey", $storageAccountKey, [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable("TemplateName", "${imageTemplateName}", [System.EnvironmentVariableTarget]::Machine)

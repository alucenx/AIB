$storageAccountName = "imagebuilderan"
$fileShareName = "aib-fs"
$destinationPath = 'C:\temp'
$downloadPath = Join-Path $destinationPath $installZip
$installZip = 'software.zip'
$filePath = $installZip

# Map the network drive using the file share key
$cmdkeyCommand = "cmdkey.exe /add:$fileShareName /user:$storageAccountName /pass:$storageAccountKey"
Invoke-Expression -Command $cmdkeyCommand
New-PSDrive -Name Z -PSProvider FileSystem -Root "\\$storageAccountName.file.core.windows.net\$fileShareName" -Persist -Credential $(New-Object System.Management.Automation.PSCredential -ArgumentList "$storageAccountName\$fileShareName", (ConvertTo-SecureString -String $storageAccountKey -AsPlainText -Force))


# Prepare for installation and configuration

if (-not (Test-Path $destinationPath -PathType Container)) {
    New-Item -Path $destinationPath -ItemType Directory
}

$downloadPath = Join-Path $destinationPath $installZip

try {
    Get-Item -Path Z:\$filePath -ErrorAction Stop | Copy-Item -Destination $downloadPath -Force
} catch {
    throw "Failed to download $installZip $_"
}

Start-Sleep -Seconds 5
$softwarePath = Join-Path $destinationPath $installZip
Expand-Archive -Path $softwarePath -DestinationPath $destinationPath -Force

Write-Host "Contents of $destinationPath after extracting software.zip"
Get-ChildItem $destinationPath

$innerZips = @('x64_CrowdStrike_WindowsSensor_6.37.15103.0_en-US_002.zip', 'x64_Linde_DaxFonts_2.2_en-US_003.zip', 'x64_Microsoft_LocalAdminPasswordSolutionEnterprise_7.2.1.0_en-US_001.zip', 'x64_Microsoft_EdgeWebView2RT_93.0.961.47_MUI_001.zip', 'vdot.zip')

foreach ($zip in $innerZips) {
    $zipPath = Join-Path $destinationPath $zip
    $extractPath = Join-Path $destinationPath ($zip.Replace('.zip', ''))
    Write-Host "Extracting $zip..."
    Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
}

foreach ($zip in $innerZips) {
    $extractPath = Join-Path $destinationPath ($zip.Replace('.zip', ''))
    Write-Host "Contents of $extractPath after extracting $zip"
    Get-ChildItem $extractPath
}

Start-Process -FilePath 'powershell.exe' -ArgumentList "-executionpolicy bypass -file $destinationPath\Install-Applications.ps1"
Start-Process -FilePath 'powershell.exe' -ArgumentList "-executionpolicy bypass -file $destinationPath\VDOT\Windows_VDOT.ps1 -Optimizations All -AcceptEULA"
########################################################################################################################
# ASC_Guest_Config.ps1
#
# Creates a Guest Configuration policy and deploys it to a specified management group. Policy is used to check for the
# presence of audit configuration on Windows Servers required for optimal ASC threat detection.
#
# e.g.
# ASC_Guest_Config.ps1 -resourceGroup <rg> -storageAccountName <sa> -storageContainerName <sc> -managementGroup <mg>
#
########################################################################################################################

param(
    [Parameter(Mandatory=$true)]
    [string]$resourceGroup,
    [Parameter(Mandatory=$true)]
    [string]$storageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$storageContainerName,
    [Parameter(Mandatory=$true)]
    [string]$managementGroup
)

function checkModules ($moduleName, $majorVer, $minorVer ) {

    try{
        $psModule = (get-module -ListAvailable -Name $moduleName).Version
        if(($psModule.Major -ge $majorVer) -and ($psModule.Minor -ge $minorVer))
        {
            Write-Host "$moduleName module found."
        }
        else
        {
            throw [System.ApplicationException] "$moduleName module not found or below verson $majorVer.$minorVer.x"
        }
    }
    catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}
checkModules 'GuestConfiguration' 1 2
checkModules 'Az' 3 7
checkModules 'PSDscResources' 2 12
checkModules 'AuditPolicyDSC' 1 4

function checkPrereq {

    try {

        Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName `
        |ForEach-Object{$_.context}|Get-AzStorageBlob -Container $storageContainerName|Out-Null

    }
    catch {

        Write-Host "Please enter a valid Resource Group, Storage Account and Storage Container." -ForegroundColor Yellow
        Write-Host $_.Exception.Message -ForegroundColor Red
        exit
    }
}
checkPrereq

# Complile the DSC MOF to use with Azure Policy. This will check for the presence of local audit policy and registy key settings.
Configuration Audit_ASC_VM_Config
{
    Import-DscResource -ModuleName 'PSDscResources'
    Import-DscResource -ModuleName 'AuditPolicyDsc'

    Node Audit_ASC_VM_Config
    {
        AuditPolicyGuid ProccessCreationNoAuditing
        {
            Name      = 'Process Creation'
            AuditFlag = 'No Auditing'
            Ensure    = 'Absent'
        }

        AuditPolicyGuid ProccessCreationFailure
        {
            Name      = 'Process Creation'
            AuditFlag = 'Failure'
            Ensure    = 'Absent'
        }

        Registry IncludeCmdLine
        {
            Ensure      = 'Present'
            Key         = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit'
            ValueName   = 'ProcessCreationIncludeCmdLine_Enabled'
            ValueType   = 'DWord'
            ValueData   = 1
        }
    }
}
Audit_ASC_VM_Config -OutputPath ./Config

# Create a new Guest Config. Package based on compiled MOF.
New-GuestConfigurationPackage -Name 'Audit_ASC_VM_Config' -Configuration './Config/Audit_ASC_VM_Config.MOF'

# Upload the Guest Config. Package to blob storage.
function publish {
    param(
    [Parameter(Mandatory=$true)]
    $resourceGroup,
    [Parameter(Mandatory=$true)]
    $storageAccountName,
    [Parameter(Mandatory=$true)]
    $storageContainerName,
    [Parameter(Mandatory=$true)]
    $filePath,
    [Parameter(Mandatory=$true)]
    $blobName
    )

    # Get Storage Context
    $Context = Get-AzStorageAccount -ResourceGroupName $resourceGroup `
        -Name $storageAccountName | `
        ForEach-Object { $_.Context }

    # Upload file
    Set-AzStorageBlobContent -Context $Context `
        -Container $storageContainerName `
        -File $filePath `
        -Blob $blobName `
        -Force|Out-Null

    # Get url with SAS token
    $StartTime = (Get-Date)
    $ExpiryTime = $StartTime.AddYears('3')  # THREE YEAR EXPIRATION
    $SAS = New-AzStorageBlobSASToken -Context $Context `
        -Container $storageContainerName `
        -Blob $blobName `
        -StartTime $StartTime `
        -ExpiryTime $ExpiryTime `
        -Permission rl `
        -FullUri

    # Output
    return $SAS
}

try
{
  
  $uri = publish `
  -resourceGroup $resourceGroup `
  -storageAccountName $storageAccountName `
  -storageContainerName $storageContainerName `
  -filePath ./Audit_ASC_VM_Config/Audit_ASC_VM_Config.zip `
  -blobName 'Audit_ASC_VM_Config.zip' -ErrorAction Stop
}
catch
{
    Write-Host "==================="
    Write-Host "Error uploading to storage account" -ForegroundColor Red
    write-host "ERROR: $_.Exception.Message" -ForegroundColor Red
    Write-Host "==================="
    exit
}
# Wait some time to avoid failures
Write-Host "Waiting for 15 secs to avoid failures...."
Start-Sleep -Seconds 15

# Create a new Guest Config. Policy based on the uploaded package.
New-GuestConfigurationPolicy `
    -ContentUri $uri `
    -DisplayName 'Audit Virtual Machine ASC Configuration' `
    -Description 'Audit if ASC configuration settings are present on Windows VM.' `
    -Path './policyDefinitions' `
    -Platform 'Windows' `
    -Version 1.0.0 `
    -Verbose

# Publish policy to chosen Mananagement Group
try
{
    Write-Host "Waiting for 15 secs to avoid failures...."
    Start-Sleep -Seconds 15
    Publish-GuestConfigurationPolicy -Path .\policyDefinitions -ManagementGroupName $managementGroup
}
catch
{
    Write-Host "==================="
    Write-Host "Please provide a valid Management Group with enough privileges to publish policy" -ForegroundColor Red
    Write-Host "Management Group: " -NoNewline
    Write-Host $managementGroup -ForegroundColor Yellow
    write-host "ERROR: $_.Exception.Message" -ForegroundColor Red
    Write-Host "==================="
    exit
}
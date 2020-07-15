﻿param(
    [string] [Parameter(Mandatory=$true)] $vaultName,
    [string] [Parameter(Mandatory=$true)] $KeyName,
    [string] [Parameter(Mandatory=$true)] $KeySize,
    [string] [Parameter(Mandatory=$true)] $KeyDestination,
    [string] [Parameter(Mandatory=$true)] $DESName,
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Par.meter(Mandatory=$true)] $Location    
    )

$KeyVault = Get-AzKeyVault -VaultName $vaultName
$KeyExpires = (Get-Date).AddYears(2).ToUniversalTime()
$KeyNotBefore = (Get-Date).ToUniversalTime()

$Key = Add-AzKeyVaultKey -VaultName $KeyVault.VaultName -Name $Keyname -Expires $KeyExpires -NotBefore $KeyNotBefore -Size $KeySize -Destination $KeyDestination

$desConfig = New-AzDiskEncryptionSetConfig -Location $Location -SourceVaultId $keyVault.ResourceId -KeyUrl $key.Key.Kid -IdentityType SystemAssigned

$des = New-AzDiskEncryptionSet -Name $DESName -ResourceGroupName $ResourceGroupName -DiskEncryptionSet $desConfig
Set-AzKeyVaultAccessPolicy -VaultName $keyVault.VaultName -ObjectId $des.Identity.PrincipalId -PermissionsToKeys wrapkey,unwrapkey,get
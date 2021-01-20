﻿Configuration ASR
{
   param
   (
        [String]$VaultName,
        [String]$HyperVSite,
        [System.Management.Automation.PSCredential]$Admincreds,
        [System.Management.Automation.PSCredential]$Tenantcreds
    )

    Import-DscResource -Module xPendingReboot # Used for Reboots

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script InstallAzModule
        {
            SetScript =
            {
                # Install Azure PowerShell
                $NuGetCheck = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
                IF ($NuGetCheck -eq $Null) {Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force}
                $AzModCheck = Get-Module -Name Az -ErrorAction SilentlyContinue
                IF ($AzModCheck -eq $Null) {Install-Module Az -Force}
                IF ($AzModCheck -eq $Null) {Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force}
                IF ($AzModCheck -eq $Null) {Import-Module Az}                
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $Admincreds
        }

        Script ConfigureASR
        {
            SetScript =
            {                 
                # Create Credentials
                $Creds = $using:TenantCreds
                $Creds.GetNetworkCredential().Password | fl > C:\CredsPlainPassword.txt

                $AzureCreds = New-Object System.Management.Automation.PSCredential ("$($Creds.UserName)", $Creds.Password)
                $AzureCreds.GetType() | fl > C:\AzureCredsType.txt
                $AzureCreds.UserName | fl > C:\AzureCredsUsername.txt
                $AzureCreds.GetNetworkCredential().Password | fl > C:\AzureCredsPlainTextPassword.txt
                $AzureCreds.Password.Length | fl > C:\AzureCredsPasswordLength.txt

                Connect-AzAccount -Environment AzureUSGovernment -Credential $AzureCreds

                New-Item -Path C:\TestAfterLoginLogin -Type Directory                ​
                
                # Get Vault
                $Vault = Get-AzRecoveryServicesVault -Name "$using:VaultName"
                Set-AzRecoveryServicesAsrVaultContext -Vault $Vault

                New-Item -Path C:\TestAfterVaultContext -Type Directory                
                
                # Create Hyper-V Site
                $FabricCheck = Get-AzRecoveryServicesAsrFabric -Name "$using:HyperVSite" -ErrorAction SilentlyContinue
                IF ($FabricCheck -eq $Null) {New-AzRecoveryServicesAsrFabric -Type HyperVSite -Name "$using:HyperVSite"}

                # Generate and Download Registration Key
                $SiteIdentifier = Get-AzRecoveryServicesAsrFabric -Name "$using:HyperVSite" | Select-Object -ExpandProperty SiteIdentifier
                $path = Get-AzRecoveryServicesVaultSettingsFile -Vault $Vault -SiteIdentifier $SiteIdentifier -SiteFriendlyName "$using:HyperVSite"
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[Script]InstallAzModule'
        }

        xPendingReboot AfterRoleInstallation
        {
            Name       = 'AfterRoleInstallation'
        }

     }
  }
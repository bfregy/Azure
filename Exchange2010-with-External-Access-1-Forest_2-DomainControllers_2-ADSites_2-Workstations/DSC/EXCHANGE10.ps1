﻿configuration EXCHANGE10
{
   param
   (
        [String]$NetBiosDomain,
        [String]$DBName,
        [String]$SetupDC,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        Script InstallExchange2010
        {
            SetScript =
            {
                Set-Content -Path S:\ExchangeInstall\DeployExchange.cmd -Value "I:\Setup.com /roles:mb,ca,ht /mdbname:$using:DBName /dbfilepath:M:\$using:DBName\$using:DBName.edb /logfolderpath:M:\$using:DBName /dc:$using:SetupDC"
                S:\ExchangeInstall\DeployExchange.cmd
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
        }
    }
}
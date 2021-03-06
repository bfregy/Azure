configuration PREPAREADEXCHANGE19
{
   param
   (
        [String]$ExchangeOrgName,
        [String]$NetBiosDomain,
        [String]$BaseDN,
        [System.Management.Automation.PSCredential]$Admincreds
    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module xStorage # Used by Disk

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        xMountImage MountExchangeISO
        {
            ImagePath   = 'S:\ExchangeInstall\Exchange2019.iso'
            DriveLetter = 'L'
        }

        xWaitForVolume WaitForISO
        {
            DriveLetter      = 'L'
            RetryIntervalSec = 5
            RetryCount       = 10
        }

        Script PrepareExchange2019AD
        {
            SetScript =
            {
                # Create Exchange AD Deployment
                L:\Setup.exe /PrepareSchema /DomainController:"$using:dc1Name" /IAcceptExchangeServerLicenseTerms
                L:\Setup.exe /PrepareAD /on:"$using:ExchangeOrgName" /IAcceptExchangeServerLicenseTerms
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[xWaitForVolume]WaitForISO'
        }
    }
}
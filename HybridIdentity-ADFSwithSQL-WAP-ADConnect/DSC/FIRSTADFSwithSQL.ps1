configuration FIRSTADFSwithSQL
{
   param
   (
        [String]$SQLHost,
        [String]$RootDomainFQDN,
        [String]$NetBiosDomain,
        [String]$IssuingCAName,
        [String]$RootCAName,     
        [System.Management.Automation.PSCredential]$Admincreds


    )
    Import-DscResource -Module xPSDesiredStateConfiguration # Used for xRemoteFile
    Import-DscResource -Module ComputerManagementDsc # Used for TimeZone

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        WindowsFeature ADFS-Federation
        {
            Ensure = 'Present'
            Name   = 'ADFS-Federation'
        }

        TimeZone SetTimeZone
        {
            IsSingleInstance = 'Yes'
            TimeZone         = 'Eastern Standard Time'
        }

        File MachineConfig
        {
            Type = 'Directory'
            DestinationPath = 'C:\MachineConfig'
            Ensure = "Present"
        }

        File Certificates
        {
            Type = 'Directory'
            DestinationPath = 'C:\Certificates'
            Ensure = "Present"
            DependsOn = '[File]MachineConfig'
        }

        Script GetADFSCertificates
        {
            SetScript =
            {
                # Update GPO's
                gpupdate /force

                # Create Credentials
                $Load = "$using:DomainCreds"
                $Password = $DomainCreds.Password
                $fsgmsa = 'FsGmsa$'

                # Move Crypto Keys
                $dest1 = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys"
                $dest2 = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\Temp\"
                New-Item -Path $Dest2 -ItemType directory
                Get-ChildItem $dest1 -exclude "Temp" | Move-Item -Destination $dest2

                # Check if Service Communication Certificate Exists
                $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:RootDomainFQDN"}).Thumbprint

                # Get Service Communication Certificate
                IF ($thumbprint -eq $null) {Get-Certificate -Template WebServer1 -SubjectName "CN=adfs.$using:rootdomainfqdn" -DNSName "adfs.$using:rootdomainfqdn" -CertStoreLocation "cert:\LocalMachine\My"}

                # Get Service Communication Certificate
                $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:RootDomainFQDN"}).Thumbprint

                # Grant FsGmsa Full Access to Service Communication Certificate Private Keys
                Start-Sleep -s 60
                $account = "$using:NetBiosDomain\$fsgmsa"
                $file = Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys -Exclude "Temp"
                $fullPath=$file.FullName
                $acl=(Get-Item $fullPath).GetAccessControl('Access')
                $permission=$account,"Full","Allow"
                $accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
                $acl.AddAccessRule($accessRule)
                Set-Acl $fullPath $acl

                # Move Crypto Keys
                Get-ChildItem $dest2 | Move-Item -Destination $dest1
                Remove-Item $dest2 -Force -ErrorAction 0

                # Export Service Communication Certificate
                Get-ChildItem -Path cert:\LocalMachine\my\$thumbprint | Export-PfxCertificate -FilePath "C:\Certificates\adfs.$using:RootDomainFQDN.pfx" -Password $Password

                $RootExport = Get-ChildItem -Path cert:\Localmachine\Root\ | Where-Object {$_.Subject -like "CN=$using:RootCAName*"}
                Export-Certificate -Cert $RootExport -FilePath "C:\Certificates\$using:RootCAName.cer" -Type CER

                $IssuingExport = Get-ChildItem -Path cert:\Localmachine\CA\ | Where-Object {$_.Subject -like "CN=$using:IssuingCAName*"}
                Export-Certificate -Cert $IssuingExport -FilePath "C:\Certificates\$using:IssuingCAName.cer" -Type CER

                # Move Crypto Keys
                $dest2 = "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys\Temp\"
                New-Item -Path $Dest2 -ItemType directory
                Get-ChildItem $dest1 -exclude "Temp" | Move-Item -Destination $dest2

                # Check if Token Signing Certificate Exists
                $signthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs-signing.$using:RootDomainFQDN"}).Thumbprint

                # Get Token Signing Certificate
                IF ($signthumbprint -eq $null) {Get-Certificate -Template WebServer1 -SubjectName "CN=adfs-signing.$using:rootdomainfqdn" -DNSName "adfs-signing.$using:rootdomainfqdn" -CertStoreLocation "cert:\LocalMachine\My"}

                # Grant FsGmsa Full Access to Signing Certificate Private Keys
                Start-Sleep -s 60
                $account = "$using:NetBiosDomain\$fsgmsa"
                $file = Get-ChildItem C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys -Exclude "Temp"
                $fullPath=$file.FullName
                $acl=(Get-Item $fullPath).GetAccessControl('Access')
                $permission=$account,"Full","Allow"
                $accessRule=new-object System.Security.AccessControl.FileSystemAccessRule $permission
                $acl.AddAccessRule($accessRule)
                Set-Acl $fullPath $acl

                # Move Crypto Keys
                Get-ChildItem $dest2 | Move-Item -Destination $dest1
                Remove-Item $dest2 -Force -ErrorAction 0

                # Check if Token Signing Certificate Exists
                $signthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs-signing.$using:RootDomainFQDN"}).Thumbprint

                # Export Token Signing Certificate
                Get-ChildItem -Path cert:\LocalMachine\my\$signthumbprint | Export-PfxCertificate -FilePath "C:\Certificates\adfs-signing.$using:RootDomainFQDN.pfx" -Password $Password
            }
            GetScript =  { @{} }
            TestScript = { $false}
            DependsOn = '[File]Certificates'
        }

        Script ConfigureADFS
        {
            SetScript =
            {
                # Create Issuance Authorization Rules File
                Set-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -Value '@RuleTemplate = "AllowAllAuthzRule"'
                Add-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -Value '=> issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",'
                Add-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt -Value 'Value = "true");'

                # Create Issuance Transform Rules File                Set-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '@RuleName = "ActiveDirectoryUserSID"'                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value 'c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '=> issue(store = "Active Directory", types = ("http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"), query = ";objectSID;{0}", param = c.Value);'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '@RuleName = "ActiveDirectoryUPN"'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value 'c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]'
                Add-Content -Path C:\MachineConfig\IssuanceTransformRules.txt -Value '=> issue(store = "Active Directory", types = ("http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn"), query = ";userPrincipalName;{0}", param = c.Value);'

                # Get Service Communication Certificate
                $thumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs.$using:RootDomainFQDN"}).Thumbprint

                # Get Token Signing Certificate
                $signthumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object {$_.Subject -like "CN=adfs-signing.$using:RootDomainFQDN"}).Thumbprint

                Import-Module ADFS
                Install-AdfsFarm -CertificateThumbprint $thumbprint -FederationServiceName "adfs.$using:RootDomainFQDN" -GroupServiceAccountIdentifier "$using:NetBiosDomain\FsGmsa$" -SQLConnectionString "Data Source=$using:SQLHost;Initial Catalog=ADFSConfiguration;Integrated Security=True;Min Pool Size=20"
                
                # Create Relying Pary Trust Script
                [string]$IssuanceAuthorizationRules=Get-Content -Path C:\MachineConfig\IssuanceAuthorizationRules.txt
                [string]$IssuanceTransformRules=Get-Content -Path C:\MachineConfig\IssuanceTransformRules.txt

                # Create Relying Party Trusts
                Add-ADFSRelyingPartyTrust -Name 'Outlook Web App 2019' -Enabled $true -Notes "This is a trust for https://owa2019.$using:RootDomainFQDN/owa" -WSFedEndpoint "https://owa2019.$using:RootDomainFQDN/owa" -Identifier "https://owa2019.$using:RootDomainFQDN/owa" -IssuanceTransformRules $IssuanceTransformRules -IssuanceAuthorizationRules $IssuanceAuthorizationRules
                Add-ADFSRelyingPartyTrust -Name 'Exchange Admin Center (EAC) 2019' -Enabled $true -Notes "This is a trust for https://owa2019.$using:RootDomainFQDN/ecp" -WSFedEndpoint "https://owa2019.$using:RootDomainFQDN/ecp" -Identifier "https://owa2019.$using:RootDomainFQDN/ecp" -IssuanceTransformRules $IssuanceTransformRules -IssuanceAuthorizationRules $IssuanceAuthorizationRules

                # Turn off Certificate Auto Certificate Rollover
                Set-ADFSProperties -AutoCertificateRollover $False
                
                # Add Token Signing Certificate
                Add-AdfsCertificate -CertificateType "Token-Signing" -Thumbprint $signthumbprint

                # Set Token Signing Certificate
                Set-AdfsCertificate -IsPrimary -CertificateType "Token-Signing" -Thumbprint $signthumbprint
                
                # Remove Self-Signed Certificate
                Get-AdfsCertificate | Where-Object {$_.CertificateType -eq 'Token-Signing'} | Where-Object {$_.IsPrimary -ne 'True'} | Remove-AdfsCertificate

                # Enable Certificate Copy
                $EnableSMB = Get-NetFirewallRule "FPS-SMB-In-TCP" -ErrorAction 0
                IF ($EnableSMB -ne $null) {Enable-NetFirewallRule -Name "FPS-SMB-In-TCP"}

                # Enable Test Sign-In
                Set-AdfsProperties -EnableIdPInitiatedSignonPage $true
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainCreds
            DependsOn = '[Script]GetADFSCertificates'
        }
    }
}
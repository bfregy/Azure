﻿configuration CONFIGDNS
{
   param
   (
        [String]$computerName,
        [String]$InternaldomainName,
        [String]$ExternaldomainName,
        [String]$ReverseLookup1,
        [String]$ReverseLookup2,
        [String]$dc1lastoctet,
        [String]$dc2lastoctet,
        [String]$icaIP,
        [String]$ocspIP,
        [String]$ex1IP,
        [String]$ex2IP,
        [Int]$RetryCount=100,
        [Int]$RetryIntervalSec=600,
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module xDnsServer
    Import-DscResource -ModuleName ActiveDirectoryDsc

    Node localhost
    {
        WaitForADDomain DscForestWait
        {
            DomainName = $InternaldomainName
            Credential= $Admincreds
            RestartCount = $RetryCount
            WaitTimeout = $RetryIntervalSec
        }

        xDnsServerADZone ExternalDomain
        {
            Name             = "$ExternaldomainName"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            DependsOn = '[WaitForADDomain]DscForestWait'
        }

        xDnsServerADZone ReverseADZone1
        {
            Name             = "$ReverseLookup1.in-addr.arpa"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            DependsOn = '[WaitForADDomain]DscForestWait'
        }

        xDnsServerADZone ReverseADZone2
        {
            Name             = "$ReverseLookup2.in-addr.arpa"
            DynamicUpdate = 'Secure'
            Ensure           = 'Present'
            ReplicationScope = 'Domain'
            DependsOn = '[WaitForADDomain]DscForestWait'
        }

        xDnsRecord DC1PtrRecord
        {
            Name      = "$dc1lastoctet"
            Zone      = "$ReverseLookup1.in-addr.arpa"
            Target    = "$computerName.$InternaldomainName"
            Type      = 'Ptr'
            Ensure    = 'Present'
            DependsOn = "[xDnsServerADZone]ReverseADZone1"
        }

        xDnsRecord DC2PtrRecord
        {
            Name      = "$dc2lastoctet"
            Zone      = "$ReverseLookup2.in-addr.arpa"
            Target    = "$computerName.$InternaldomainName"
            Type      = 'Ptr'
            Ensure    = 'Present'
            DependsOn = "[xDnsServerADZone]ReverseADZone2"
        }

        xDnsRecord crlrecord
        {
            Name      = "crl"
            Zone      = "$ExternaldomainName"
            Target    = "$icaIP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
        }

        xDnsRecord ocsprecord
        {
            Name      = "ocsp"
            Zone      = "$ExternaldomainName"
            Target    = "$ocspIP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
        }

        xDnsRecord owa2010record1
        {
            Name      = "owa2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex1IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
        }

        xDnsRecord owa2010record2
        {
            Name      = "owa2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex2IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
        }

        xDnsRecord autodiscover2010record1
        {
            Name      = "autodiscover2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex1IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
        }

        xDnsRecord autodiscover2010record2
        {
            Name      = "autodiscover2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex2IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
        }

        xDnsRecord outlook2010record1
        {
            Name      = "outlook2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex1IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
         }

        xDnsRecord outlook2010record2
        {
            Name      = "outlook2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex2IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
         }

        xDnsRecord eas2010record1
        {
            Name      = "eas2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex1IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
         }

        xDnsRecord eas2010record2
        {
            Name      = "eas2010"
            Zone      = "$ExternaldomainName"
            Target    = "$ex2IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
         }

        xDnsRecord smtprecord1
        {
            Name      = "smtp"
            Zone      = "$ExternaldomainName"
            Target    = "$ex1IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
         }

        xDnsRecord smtprecord2
        {
            Name      = "smtp"
            Zone      = "$ExternaldomainName"
            Target    = "$ex2IP"
            Type      = 'ARecord'
            Ensure    = 'Present'
            DependsOn = '[xDnsServerADZone]ExternalDomain'
         }

    }
}
# Microsoft Tunnel for Microsoft Intune

Click the button below to deploy

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Felliottfieldsjr%2FKillerHomeLab%2FDevelopment%2FMicrosoft-Tunnel_for_Microsoft-Intune%2Fazuredeploy.json)
[![Deploy To Azure US Gov](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.svg?sanitize=true)](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Felliottfieldsjr%2FKillerHomeLab%2FDevelopment%2FMicrosoft-Tunnel_for_Microsoft-Intune%2Fazuredeploy.json)

This Templates deploys a Single Forest/Domain:

- 1 - Active Directory Forest/Domain
- 1 - Domain Controller
- 1 - Enterprise Certificate Authority Server
- 1 - Online Certificate Status Protocol Server
- 1 - Domain Joined Windows 10 Workstation
- 1 - Microsoft VPN Intune Gateway

The deployment leverages Desired State Configuration scripts to further customize the following:

AD DNS Zone Record Creation:
- CRL (For CRL Download)
- OCSP (For OCSP Server)

PKI
- Enterprise CA Configuration
- OCSP Configuaration

Parameters that support changes
- Admin Username.  Enter a valid Admin Username
- Admin Password.  Enter a valid Admin Password
- WindowsServerLicenseType.  Choose Windows Server License Type (Example:  Windows_Server or None)
- WindowsClientLicenseType.  Choose Windows Client License Type (Example:  Windows_Client or None)
- Naming Convention. Enter a name that will be used as a naming prefix for (Servers, VNets, etc) you are using.
- Sub DNS Domain.  OPTIONALLY, enter a valid DNS Sub Domain. (Example:  sub1. or sub1.sub2.    This entry must end with a DOT )
- Sub DNS BaseDN.  OPTIONALLY, enter a valid DNS Sub Base DN. (Example:  DC=sub1, or DC=sub1,DC=sub2,    This entry must end with a COMMA )
- Net Bios Domain.  Enter a valid Net Bios Domain Name (Example:  sub1).
- Internal Domain.  Enter a valid Internal Domain (Exmaple:  killerhomelab)
- TLD.  Select a valid Top-Level Domain using the Pull-Down Menu.
- External Domain.  Enter a valid External Domain FQDN (Exmaple:  killerhomelab.com)
- Vnet1ID.  Enter first 2 octets of your desired Address Space for Virtual Network 1 (Example:  10.1)
- Reverse Lookup1.  Enter first 2 octets of your desired Address Space in Reverse (Example:  1.10)
- Enterprise CA Name.  Enter a Name for your Enterprise Certificate Authority
- EnterpriseCAHashAlgorithm.  Hash Algorithm for Enterprise CA
- EnterpriseCAKeyLength.  Key Length for Enterprise CA
- DC1OSVersion.  Select 2016-Datacenter (Windows 2016) or 2019-Datacenter (Windows 2019) Domain Controller 1 OS Version
- ECAOSVersion.  Select 2016-Datacenter (Windows 2016) or 2019-Datacenter (Windows 2019) Enterprise CA OS Version
- OCSPOSVersion.  Select 2016-Datacenter (Windows 2016) or 2019-Datacenter (Windows 2019) OCSP OS Version
- WEBOSVersion.  Select 2016-Datacenter (Windows 2016) or 2019-Datacenter (Windows 2019) OS Version
- GWOSVersion.  Select 2016-Datacenter (Windows 2016) or 2019-Datacenter (Windows 2019) OS Version
- WK1OSVersion.  Workstation1 OS Version is not configurable and set to 19h1-pro (Windows 10).
- DC1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- ECAVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- OCSPVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- WEBVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- UBVMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
- WK1VMSize.  Enter a Valid VM Size based on which Region the VM is deployed.
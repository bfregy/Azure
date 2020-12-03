﻿configuration CONFIGSQLALWAYSON
{
   param
   (
        [String]$SQLNode1,     
        [String]$SQLNode2, 
        [String]$SQLDBName,
        [String]$SQLDBOwner,     
        [String]$SQLServiceAccount1,                     
        [String]$SQLServiceAccount2,                     
        [String]$NetBiosDomain,
        [String]$DomainName,
        [String]$StorageAccountName,
        [String]$StorageAccountKey,
        [String]$StorageEndpoint,        
        [System.Management.Automation.PSCredential]$Admincreds
    )

    Import-DscResource -Module SqlServerDsc # Used for SQL Object Creation

    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($Admincreds.UserName)", $Admincreds.Password)
    [System.Management.Automation.PSCredential ]$DomainDBCreds = New-Object System.Management.Automation.PSCredential ("${NetBiosDomain}\$($SQLDBOwner)", $Admincreds.Password)

    Node localhost
    {
        LocalConfigurationManager
        {
            RebootNodeIfNeeded = $true
        }

        File SQLBackup
        {
            Type = 'Directory'
            DestinationPath = 'C:\SQLBackup'
            Ensure = "Present"
        }

       Script CreateAzureFSW
        {
            SetScript =
            {
		        # Create Cloud Storage Account
                $CloudWitness = Get-ClusterQuorum | Where-Object {$_.QuorumResource -like "Cloud Witness"}
		        IF ($CloudWitness -eq $null) {Set-ClusterQuorum -CloudWitness -AccountName "$using:StorageAccountName" -AccessKey "$using:StorageAccountKey" -EndPoint "$using:StorageEndPoint"}
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $DomainDBCreds
        }

        SqlDatabase CreateSQLDatabase
        {
            Name = $SQLDBName
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            RecoveryModel = "Full"
            OwnerName = 
            PsDscRunAsCredential = $AdminCreds
        }

       Script BackupRestoreDB
        {
            SetScript =
            {
                # Variables
                $SQLSvc1 = "$using:NetBiosDomain\$using:SQLServiceAccount1"
                $SQLSvc2 = "$using:NetBiosDomain\$using:SQLServiceAccount2"
                
                # Create Shares
                $BackupShare = Get-SmbShare -Name SQLBackup -ErrorAction 0
                IF ($Backupshare -eq $null) {New-SmbShare -Name SQLBackup -Path C:\SQLBackup -FullAccess "$SQLSvc1","$SQLSvc2",Administrators}
                
                # Backup Database
                Backup-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.bak" -ServerInstance "$using:SQLNode1"
                Backup-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.log" -ServerInstance "$using:SQLNode1" -BackupAction Log

                # Restore the database and log on the secondary (using NO RECOVERY)  
                Restore-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.bak" -ServerInstance "$using:SQLNode2" -NoRecovery
                Restore-SqlDatabase -Database "$using:SQLDBName" -BackupFile "\\$using:SQLNode1\SQLBackup\$using:SQLDBName.log" -ServerInstance "$using:SQLNode2" -RestoreAction Log -NoRecovery
            }
            GetScript =  { @{} }
            TestScript = { $false}
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[File]SQLBackup', '[SqlDatabase]CreateSQLDatabase'
        }

        SqlEndpoint CreateSQL1Endpoint
        {
            EndpointName = 'Endpoint1'
            EndpointType = 'DatabaseMirroring'
            Ensure = "Present"
            Port = 5022
            ServerName = $SQLNode1
            InstanceName = "MSSQLSERVER"
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[File]SQLBackup', '[SqlDatabase]CreateSQLDatabase', '[Script]BackupRestoreDB'
        }

        SqlEndpoint CreateSQL2Endpoint
        {
            EndpointName = 'Endpoint2'
            EndpointType = 'DatabaseMirroring'
            Ensure = "Present"
            Port = 5022
            ServerName = $SQLNode2
            InstanceName = "MSSQLSERVER"
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[File]SQLBackup', '[SqlDatabase]CreateSQLDatabase', '[Script]BackupRestoreDB'
        }

        SqlAG CreateSQLAG
        {
            Name = "SQL-AG"
            ServerName = $SQLNode1
            InstanceName = "MSSQLSERVER"
            Ensure = "Present"
            AvailabilityMode = "SynchronousCommit"
            FailoverMode = "Automatic"
            EndpointHostName = "$SQLNode1.$DomainName"
            DependsOn = '[SqlEndpoint]CreateSQL1Endpoint','[SqlEndpoint]CreateSQL2Endpoint'
        }

        SqlAGReplica AddNodetoSQLAG
        {
            Ensure = "Present"
            Name = "$SQLNode2"
            AvailabilityGroupName = "SQL-AG"
            ServerName = $SQLNode2
            InstanceName = "MSSQLSERVER"
            PrimaryReplicaServerName = $SQLNode1
            PrimaryReplicaInstanceName = "MSSQLSERVER"
            AvailabilityMode = "SynchronousCommit"
            FailoverMode = "Automatic"
            EndpointHostName = "$SQLNode2.$DomainName"
            PsDscRunAsCredential = $AdminCreds
            DependsOn = '[SqlEndpoint]CreateSQL1Endpoint','[SqlEndpoint]CreateSQL2Endpoint', '[SqlAG]CreateSQLAG'
        }
    }
}
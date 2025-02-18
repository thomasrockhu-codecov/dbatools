function Get-DbaDbPartitionFunction {
    <#
    .SYNOPSIS
        Gets database Partition Functions.

    .DESCRIPTION
        Gets database Partition Functions.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Database
        To get users from specific database(s).

    .PARAMETER ExcludeDatabase
        The database(s) to exclude - this list is auto populated from the server.

    .PARAMETER PartitionFunction
        The name(s) of the partition function(s).

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: Database, Partition
        Author: Klaas Vandenberghe ( @PowerDbaKlaas )

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Get-DbaDbPartitionFunction

    .EXAMPLE
        PS C:\> Get-DbaDbPartitionFunction -SqlInstance sql2016

        Gets all database partition functions.

    .EXAMPLE
        PS C:\> Get-DbaDbPartitionFunction -SqlInstance Server1 -Database db1

        Gets the partition functions for the db1 database.

    .EXAMPLE
        PS C:\> Get-DbaDbPartitionFunction -SqlInstance Server1 -ExcludeDatabase db1

        Gets the partition functions for all databases except db1.

    .EXAMPLE
        PS C:\> 'Sql1','Sql2/sqlexpress' | Get-DbaDbPartitionFunction

        Gets the partition functions for the databases on Sql1 and Sql2/sqlexpress.

    .EXAMPLE
        PS C:\> Get-DbaDbPartitionFunction -SqlInstance localhost -Database TestDB -PartitionFunction partFun01

        Gets the partition function partFun01 for the TestDB on localhost.

    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [object[]]$Database,
        [object[]]$ExcludeDatabase,
        [Alias("Name")]
        [string[]]$PartitionFunction,
        [switch]$EnableException
    )

    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance -SqlCredential $SqlCredential
            } catch {
                Stop-Function -Message "Failure" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            $databases = $server.Databases | Where-Object IsAccessible

            if ($Database) {
                $databases = $databases | Where-Object Name -In $Database
            }
            if ($ExcludeDatabase) {
                $databases = $databases | Where-Object Name -NotIn $ExcludeDatabase
            }

            foreach ($db in $databases) {
                if (!$db.IsAccessible) {
                    Write-Message -Level Warning -Message "Database $db is not accessible. Skipping."
                    continue
                }

                $partitionFunctions = $db.partitionfunctions

                if ($PartitionFunction) {
                    $partitionFunctions = $partitionFunctions | Where-Object { $_.Name -in $PartitionFunction }
                }

                if (!$partitionfunctions) {
                    Write-Message -Message "No Partition Functions exist in the $db database on $instance" -Target $db -Level Verbose
                    continue
                }

                $partitionFunctions | ForEach-Object {

                    Add-Member -Force -InputObject $_ -MemberType NoteProperty -Name ComputerName -value $server.ComputerName
                    Add-Member -Force -InputObject $_ -MemberType NoteProperty -Name InstanceName -value $server.ServiceName
                    Add-Member -Force -InputObject $_ -MemberType NoteProperty -Name SqlInstance -value $server.DomainInstanceName
                    Add-Member -Force -InputObject $_ -MemberType NoteProperty -Name Database -value $db.Name

                    Select-DefaultView -InputObject $_ -Property ComputerName, InstanceName, SqlInstance, Database, CreateDate, Name, NumberOfPartitions
                }
            }
        }
    }
}
$ErrorActionPreference = 'stop'
Set-PSDebug -Strict

$_mdtSqlConnectionString = 'Data Source=sccmserver01v.server.com;Initial Catalog=deskside-mdt-prod;Network Library=DBNMPNTW;Integrated Security=SSPI'
$_OperatingSystems = @{Windows_7_Prod=1;Windows_7_Dev=2}
$_mandatoryRoles = @('core-gbl') # these do not get applied to roles listed in $_ignoreMandatoryRoles variable
$_mandatoryEndRoles = @('core_all-end') # these are mandatory even for roles in $_ignoreMandatoryRoles 
# roles which end in thse names won't be added to a regional role
$_noRegionalRoles = @('-gbl', '-all', '-end') #items in here are not searched for regional roles. if you add amend this you may need to amend Add-ToDomainGroup in postbuild script
$_ignoreMandatoryRoles = @('os_only-gbl', 'thin_client-gbl')
################################# Set-MDTComputerRole function has been hardcoded to ignore the above role if it detects os_only-gbl ###########################################

<#
    .Synopsis
        General SQL Client command module

	.Description
 	    This module simplifies the use of sql, it exposes the general functions you may want to use against an SQL server
		
	.Link
    		
	.Notes
		NAME:      Sccm.Data.SqlClient
		AUTHOR:    Abu Belal
		LASTEDIT:  04/02/2015
        
    .History
        1.0 - 04/02/2015 Initial release.        
#>

function Read-SqlServer
{
	<#
		.Synopsis
			Reads data from SQL
			
			IF ANY CHANGES ARE MADE TO THIS FUNCTION, FOR THE SAKE OF BACKWARDS COMPATABILITY ENSURE IT WILL ALWAYS RETURN A DATATABLE AND NOTHING ELSE
		
		.Description
			Reads data based on sqlCommand query and returns a datatable
			This funciton does not support SqlConnection being defined within $sqlCommand object
		
		.Example
			[System.Data.DataTable] $dataTable = Read-SqlServer $connectionString $sqlCommand
			
		.Notes
			AUTHOR:		Abu Belal
			LASTEDIT:	06-Mar-2013
			
			AUTHOR:		Abu Belal
			LASTEDIT:	07-June-2013
						Added finally statement around sql try, this ensures connection is closed but errors are thrown back to caller to handle
	
	#>
	param
	(
		[Parameter(HelpMessage = "SQL connection string")]
		[String] $sqlServerConnectionString, 
		[Parameter(HelpMessage = "SQL connection command, use New-SqlCommand function to generate a new command")]
		[System.Data.SqlClient.SqlCommand] $sqlCommand
	)
	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection($sqlServerConnectionString)
	
	$sqlCommand.Connection = $sqlConnection		
	
	$sqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($sqlCommand)
	
	[System.Data.DataTable] $dataTable =  New-Object System.Data.DataTable
	
	try
	{
		$sqlDataAdapter.Fill($dataTable) | Out-Null		
		
	}
	catch
	{	
		throw
	}
	finally
	{
		$sqlConnection.Close()
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	
	return ,$dataTable
	
}

function Write-SqlServer
{
	<#
		.Synopsis
			Writes data to SQL 
		
		.Description
			Writes data to SQL server
			This funciton does not support SqlConnection being defined within $sqlCommand object
		
		.Example
			Write-SqlServer $connectionString $sqlcommand
		
		.Notes
			AUTHOR:		Abu Belal
			LASTEDIT:	12-June-2013
	
	#>	
	param
	(
		[Parameter(HelpMessage = "SQL connection string")]
		[String] $sqlServerConnectionString, 
		[Parameter(HelpMessage = "SQL connection command, use New-SqlCommand function to generate a new command")]
		[System.Data.SqlClient.SqlCommand] $sqlCommand
	)
	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sqlConnection = New-Object System.Data.SqlClient.SqlConnection($sqlServerConnectionString)	
	$sqlCommand.Connection = $sqlConnection
	
	try
	{	
		$sqlConnection.Open()
		
		return $sqlCommand.ExecuteNonQuery()
	}
	catch
	{
		throw
	}
	finally
	{	
		$sqlConnection.Close()
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function New-SqlCommand
{
	<#
		.Synopsis
			Creates an sql command object
		
		.Description
			Shorthand function to create an SQL command object needed for some of the other functions within this module
		
		.Example
			$sqlcommand = New-SqlCommand
		
		.Notes
			AUTHOR:		Abu Belal
			LASTEDIT:	12-June-2013
	
	#>	
	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sqlCommand = New-Object System.Data.SqlClient.SqlCommand
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $sqlCommand

}

function Get-MdtOperatingSystem
{	
	return $_OperatingSystems
}

function Get-MDTRoleApps([string] $commaSeperatedRoleNames)
{

	# $commaSeperatedRoleNames must be in this format 'os_only-ldn', 'os_global-gbl' note the apostrophe and comma
	$sqlCommand = New-SqlCommand
	
	$sqlCommand.CommandText =  ("SELECT * FROM RolePackages WHERE ROLE IN (" + $commaSeperatedRoleNames + ") ORDER BY ID,Sequence")
	
	$datatable = Read-SqlServer -sqlServerConnectionString $_mdtSqlConnectionString -sqlCommand $sqlCommand
	
	return $datatable
	
}

function Reserve-Name($hostname, $engineer, $uuid)
{	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sqlCommand = New-SqlCommand
	
	$hostname = $hostname.ToUpper()
	$sqlCommand.CommandText = "SELECT * FROM SccmTempReservedHostName WHERE ReservedHostName='" + $hostname + "' AND ReservedTimeEnd > GetDate()"
	
	Write-Verbose ('[DEBUG] Issueing ' + $sqlCommand.CommandText + ' command against MDT database')
	
	$data = Read-SqlServer -sqlServerConnectionString $_mdtSqlConnectionString -sqlCommand $sqlCommand
	
	if ($data.Rows.Count -ne 0)
	{
		foreach ($row in $data.Rows)
		{
			if ($row.UUID -eq $uuid)
			{
				# already reserved for this machine
				Write-Verbose '[DEBUG] Supplied computer name is already reserved for this computer in MDT'
				return $true
			}
		}
		
		# name has been reserved by another machine
		throw 'Bad luck! The supplied computer name has been reserved by another machine. Try generating a new name or manually enter another.'	
	}
	
	# nothing has reserved so go ahead and reserve it
	Write-Verbose '[INFO] No name reserved in MDT, we will reserve it for 2 hours'
	$sqlCommand.CommandText = "INSERT INTO SccmTempReservedHostName (ReservedHostName, EngineerName, UUID) VALUES ('" + $hostname + "', '" + $engineer + "', '" + $uuid + "')"
	Write-Verbose ('[DEBUG] issueing ' + $sqlCommand.CommandText + ' command against MDT database')
	
	Write-SqlServer -sqlServerConnectionString $_mdtSqlConnectionString -sqlCommand $sqlCommand
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $true
	
}

function Connect-MDTDatabase 
{
    [CmdletBinding()]
    param
    (
		[Parameter(Position = 1)] $_mdtSqlConnectionString = 'Data Source=sccmserver01v.server.com;Initial Catalog=deskside-mdt-prod;Network Library=DBNMPNTW;Integrated Security=SSPI'
    )
	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
	#Write-Verbose ('[DEBUG] Connecting to: ' + $_mdtSqlConnectionString)
    $mdtSQLConnection = New-Object System.Data.SqlClient.SqlConnection
    $mdtSQLConnection.ConnectionString = $_mdtSqlConnectionString
    $mdtSQLConnection.Open()
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $mdtSQLConnection
}

function Get-MdtLocations
{	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sqlCommand = New-SqlCommand

	#$sqlCommand.CommandText = "SELECT ID, Location, JoinDomain, MachineObjectOU, SccmSiteName, SccmSiteCode FROM SccmLocationSettings"	
	$sqlCommand.CommandText = "SELECT * FROM SccmLocationSettings"	
	Write-Verbose ('[DEBUG] issueing ' + $sqlCommand.CommandText + ' command against MDT database')
	
	$mdtLocations = Read-SqlServer -sqlServerConnectionString $_mdtSqlConnectionString -sqlCommand $sqlCommand
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return ,$mdtLocations
}

function Get-MdtMakeModels
{	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sqlCommand = New-SqlCommand
	
	$sqlCommand.CommandText = 'SELECT Make, Model FROM MakeModelSettings WHERE len(Model) = 1 '
	Write-Verbose ('[DEBUG] issueing ' + $sqlCommand.CommandText + ' command against MDT database')
	
	$mdtMakeModels = Read-SqlServer -sqlServerConnectionString $_mdtSqlConnectionString -sqlCommand $sqlCommand
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return ,$mdtMakeModels
}

function New-MDTComputer 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)] $assetTag,
        [Parameter(ValueFromPipelineByPropertyName = $true)] $macAddress,
        [Parameter(ValueFromPipelineByPropertyName = $true)] $serialNumber,
        [Parameter(ValueFromPipelineByPropertyName = $true)] $uuid,
        [Parameter(ValueFromPipelineByPropertyName = $true)] $description,
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)] $settings
    )
	
    process
    {	
		Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
        # Insert a new computer row and get the identity result
        $sql = "INSERT INTO ComputerIdentity (AssetTag, SerialNumber, MacAddress, UUID, Description) VALUES ('$assetTag', '$serialNumber', '$macAddress', '$uuid', '$description') SELECT @@IDENTITY"
        Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
		$mdtConnection = Connect-MDTDatabase
        $identityCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList ($sql, $mdtConnection)
        $identity = $identityCmd.ExecuteScalar()
        Write-Verbose '[INFO] Added computer identity record'
    
        # Insert the settings row, adding the values as specified in the hash table
        $settingsColumns = $settings.Keys -join ','
        $settingsValues = $settings.Values -join "','"
        $sql = "INSERT INTO Settings (Type, ID, $settingsColumns) VALUES ('C', $identity, '$settingsValues')"
        Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
        $settingsCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList ($sql, $mdtConnection)
        $null = $settingsCmd.ExecuteScalar()
            
        Write-Verbose '[INFO] Added settings for the specified computer'
        
        # Write the new record back to the pipeline
        Get-MDTComputer -ID $identity
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
    }
}

function Get-MDTComputer 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)] $id = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $assetTag = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $macAddress = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $serialNumber = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $uuid = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $description = ''
    )
	
    process
    {
		Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
		# Build a select statement based on what parameters were specified
        if ($id -eq '' -and $assetTag -eq '' -and $macAddress -eq '' -and $serialNumber -eq '' -and $uuid -eq '' -and $description -eq '')
        {
            $sql = 'SELECT * FROM ComputerSettings'
        }
        elseif ($id -ne '')
        {
            $sql = "SELECT * FROM ComputerSettings WHERE ID = $id"
        }
        else
        {
            # Specified the initial command
            $sql = 'SELECT * FROM ComputerSettings WHERE '
        
            # Add the appropriate where clauses
            if ($assetTag -ne '')
            {
                $sql = "$sql AssetTag='$assetTag' AND"
            }
        
            if ($macAddress -ne '')
            {
                $sql = "$sql MacAddress='$macAddress' AND"
            }

            if ($serialNumber -ne '')
            {
                $sql = "$sql SerialNumber='$serialNumber' AND"
            }

            if ($uuid -ne '')
            {
                $sql = "$sql UUID='$uuid' AND"
            }

            if ($description -ne '')
            {
                $sql = "$sql Description='$description' AND"
            }
    
            # Chop off the last " AND"
            $sql = $sql.Substring(0, $sql.Length - 4)
        }
    
		$mdtConnection = Connect-MDTDatabase
		Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
        $selectAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList ($sql, $mdtConnection)
        $selectDataset = New-Object -TypeName System.Data.Dataset
        $null = $selectAdapter.Fill($selectDataset, 'ComputerSettings')
        $selectDataset.Tables[0].Rows
		$mdtConnection.Close()
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
    }
}

function Set-MDTComputer 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)] $id,
        [Parameter(Mandatory = $true)] $settings
    )

	process
    {	
		Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
        # Add each each hash table entry to the update statement
        $sql = 'UPDATE Settings SET'
        foreach ($setting in $settings.GetEnumerator())
        {
            $sql = "$sql $($setting.Key) = '$($setting.Value)', "
        }
        
        # Chop off the trailing ", "
        $sql = $sql.Substring(0, $sql.Length - 2)

        # Add the where clause
        $sql = "$sql WHERE ID = $id AND Type = 'C'"
        
        # Execute the command
		$mdtConnection = Connect-MDTDatabase
        Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')       
        $settingsCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList ($sql, $mdtConnection)
        $null = $settingsCmd.ExecuteScalar()
		$mdtConnection.Close()
            
        Write-Verbose '[INFO] Added settings for the specified computer'
        
        # Write the updated record back to the pipeline
        Get-MDTComputer -ID $id
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
    }
}

function Remove-MDTComputer 
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)] $id
    )
	
    process
    {	
		Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
        # Build the delete command
        $sql = "DELETE FROM ComputerIdentity WHERE ID = $id"
        
		$mdtConnection = Connect-MDTDatabase
        # Issue the delete command
        Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
        $cmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList ($sql, $mdtConnection)
        $null = $cmd.ExecuteScalar()
		$mdtConnection.Close()

        Write-Verbose "Removed the computer with ID = $id."
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
    }
}

function Get-CustomMdtRoleSettings($roleName)
{

	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
    # Build the select command
    $sql = ("SELECT * FROM SccmRoleSettings WHERE Role = '" + $roleName + "'")
        
    # Issue the select command and return the results
    Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
	
	$mdtConnection = Connect-MDTDatabase
    $selectAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList ($sql, $mdtConnection)
    $selectDataset = New-Object -TypeName System.Data.Dataset
    $null = $selectAdapter.Fill($selectDataset, 'SccmRoleSettings')
    $dataReturn = $selectDataset.Tables[0].Rows
	$mdtConnection.Close()

	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $dataReturn
}

function Get-CustomMdtRoles 
{
    PARAM
    (                
        $columns,
		$cpu,
		$ram
    )

	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
    # Build the select command
    $sql = "SELECT $columns FROM SccmRoleSettings WHERE Type = 'R' AND SccmRoleCPU <= $cpu AND SccmRoleRAM <= $ram"
        
    # Issue the select command and return the results
    Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
	
	$mdtConnection = Connect-MDTDatabase
    $selectAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList ($sql, $mdtConnection)
    $selectDataset = New-Object -TypeName System.Data.Dataset
    $null = $selectAdapter.Fill($selectDataset, 'SccmRoleSettings')
    $dataReturn = $selectDataset.Tables[0].Rows
	$mdtConnection.Close()

	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $dataReturn
}

function Set-MDTComputerRole 
{
    [CmdletBinding()]
    PARAM
    (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)] [int] $id,
		[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)] [System.Collections.ArrayList] $roles
        #[Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)] [Array] $roles
    )

	$ignoreMandatory = $false
	
	foreach ($ignoreMandatoryRole in $_ignoreMandatoryRoles)
	{
		if ($roles.Contains($ignoreMandatoryRole))
		{				
			$ignoreMandatory = $true
			
			break
		}
	}			
	
	if (!$ignoreMandatory)
	{
		for ($i=0; $i -lt $_mandatoryRoles.Count; $i++)
		{
			$roles.Insert($i, $_mandatoryRoles[$i])
		}
	}

	# add regional end roles				
	for ($iRole = 0; $iRole -lt $roles.Count; $iRole++)
	{
		for ($inoRegionalRole = 0; $inoRegionalRole -lt $_noRegionalRoles.Count; $inoRegionalRole++ )
		{
			if ($roles[$iRole].EndsWith($_noRegionalRoles[$inoRegionalRole]))
			{
				break
			}
			else
			{
				if ($inoRegionalRole -eq ($_noRegionalRoles.Count - 1))
				{
					$roles.Add('region_' + ($roles[$iRole].Split('-')[1]) + '-end')
				}
			}
		}
	}
	
	foreach ($mandatoryEndRole in $_mandatoryEndRoles)
	{
		$roles.Add($mandatoryEndRole)
	}
	
    Set-MDTArray $id 'C' 'Settings_Roles' 'Role' $roles
}

function Set-MDTArray 
{
    PARAM
    (
        $id,
        $type,
        $table,
        $column,
        $array
    )
   	
	$mdtConnection = Connect-MDTDatabase
		
    # Now insert each row in the array
    $seq = 1
    foreach ($item in $array)
    {
        # Insert the  row
        $sql = "INSERT INTO $table (Type, ID, Sequence, " + $column + ") VALUES ('" + $type + "'," + $id + "," + $seq + ",'" + $item + "')"
      	Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
        $settingsCmd = New-Object -TypeName System.Data.SqlClient.SqlCommand -ArgumentList ($sql, $mdtConnection)
        $null = $settingsCmd.ExecuteScalar()

        # Increment the counter
        $seq = $seq + 1
    }
        
    Write-Verbose "[INFO] Added records to $table for Type = $type and ID = $id."
}

function Get-CustomAppliedRoles($mdtComputerID)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$sql = "SELECT * FROM ComputerRoles WHERE ID=" + $mdtComputerID
	
	$mdtConnection = Connect-MDTDatabase
	Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
    $selectAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList ($sql, $mdtConnection)
    $selectDataset = New-Object -TypeName System.Data.Dataset
    $null = $selectAdapter.Fill($selectDataset, 'ComputerSettings')
    $selectDataset.Tables[0].Rows
	$mdtConnection.Close()
		
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function Get-SccmComputerSettings
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true)] $id = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $assetTag = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $macAddress = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $serialNumber = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $uuid = '',
        [Parameter(ValueFromPipelineByPropertyName = $true)] $description = ''
    )
	
    process
    {
		Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
		# Build a select statement based on what parameters were specified
        if ($id -eq '' -and $assetTag -eq '' -and $macAddress -eq '' -and $serialNumber -eq '' -and $uuid -eq '' -and $description -eq '')
        {
            $sql = 'SELECT * FROM SccmComputerSettings'
        }
        elseif ($id -ne '')
        {
            $sql = "SELECT * FROM SccmComputerSettings WHERE ID = $id"
        }
        else
        {
            # Specified the initial command
            $sql = 'SELECT * FROM SccmComputerSettings WHERE '
        
            # Add the appropriate where clauses
            if ($assetTag -ne '')
            {
                $sql = "$sql AssetTag='$assetTag' AND"
            }
        
            if ($macAddress -ne '')
            {
                $sql = "$sql MacAddress='$macAddress' AND"
            }

            if ($serialNumber -ne '')
            {
                $sql = "$sql SerialNumber='$serialNumber' AND"
            }

            if ($uuid -ne '')
            {
                $sql = "$sql UUID='$uuid' AND"
            }

            if ($description -ne '')
            {
                $sql = "$sql Description='$description' AND"
            }
    
            # Chop off the last " AND"
            $sql = $sql.Substring(0, $sql.Length - 4)
        }
    
		$mdtConnection = Connect-MDTDatabase
		Write-Verbose ('[DEBUG] issueing ' + $sql + ' command against MDT database')
        $selectAdapter = New-Object -TypeName System.Data.SqlClient.SqlDataAdapter -ArgumentList ($sql, $mdtConnection)
        $selectDataset = New-Object -TypeName System.Data.Dataset
        $null = $selectAdapter.Fill($selectDataset, 'ComputerSettings')
        $selectDataset.Tables[0].Rows
		$mdtConnection.Close()
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
    }
}

Export-ModuleMember -Function *
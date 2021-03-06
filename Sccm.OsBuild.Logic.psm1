$ErrorActionPreference = 'stop'
Set-PSDebug -Strict

$_winpe = $false

if (Test-Path -Path 'HKLM:\software\microsoft\windows nt\currentversion\winpe')
{
	Write-Verbose '[DEBUG] We are running in WINPE'
	$_winpe = $true
	
	$_taskSequenceUI = New-Object -ComObject Microsoft.SMS.TSProgressUI
	$_taskSequenceUI.CloseProgressDialog()
	$_tsEnv = New-Object -ComObject 'Microsoft.SMS.TSEnvironment'	
}
else
{
	Write-Verbose '[DEBUG] We are not running in WINPE'
}

$PSScriptDirectory = (Split-Path $MyInvocation.MyCommand.Path -Parent).ToLower()
Import-Module ($PSScriptDirectory + '\Sccm.OsBuild.Data.psm1') -Verbose

$_deploymentShare = '\\ldnsoftware.server.com\SCCM\MDT\DesksideDeploymentShare\Production'
$_helpMessage = ('[WARN] In order to use this you must have read only permissions to ' + $_deploymentShare + '. You can not build machines without getting pass this. Be aware these credential are verified by another process.')
$_tempDrive = 'T:'
$_mdtSqlConnectionString = 'Data Source=sccmserver01v.server.com;Initial Catalog=deskside-mdt-prod;Network Library=DBNMPNTW;Integrated Security=SSPI'
$_skipHostNames = New-Object System.Collections.Generic.List[string]

#region diagnostics functions
function Get-CurrentLineNumber
{
	$MyInvocation.ScriptLineNumber
}

function Get-CurrentFileName
{
	$MyInvocation.ScriptName
}
#endregion diagnostics

function Get-CustomOperatingSystems
{	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return Get-MdtOperatingSystem
		
}

function Set-CustomOperatingSystem($index)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	Write-Verbose ('[DEBUG] Setting WIM image idex to ' + $index)
	
	if ($_winpe)
	{
		$_tsEnv.Value('OSDImageIndex') = $index	
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
}

function Get-CustomDomains
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	Write-Verbose '[INFO] Getting locations from MDT...'
	$domains = New-Object System.Collections.ArrayList
	$dtLocations = Get-MdtLocations		
		
	foreach ($row in $dtLocations)
	{
		if (! $domains.Contains($row.JoinDomain))
		{
			Write-Verbose ('[DEBUG] Adding ' + $row.JoinDomain + ' to list')
			[Void] $domains.Add($row.JoinDomain)
		}
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $domains
}

function Get-CustomComputerBuildSites
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$htsites  = New-Object System.Collections.Hashtable	
	$dtLocations = Get-MdtLocations		
	
	foreach ($row in $dtLocations)
	{
		if (!($htsites.ContainsKey($row.SccmSiteName)))
		{
			if ($row.SccmSiteName -ne ([System.DBNull]::Value))
			{
				[Void] $htsites.Add($row.SccmSiteName, $row.SccmSiteCode)
			}
		}
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $htsites
}

function Get-CustomComputerTypes
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$htMakeModels  = New-Object System.Collections.Hashtable			
	$dtMakeModels = Get-MdtMakeModels
	
	foreach ($row in $dtMakeModels)
	{
		if (! $htMakeModels.ContainsKey($row.Make))
		{
			$htMakeModels.Add($row.Make, $row.Model)
		}
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $htMakeModels
}

function Connect-CustomBuildDrive
{
	<#
		.Synopsis
			connect to t
		
		.Description
			to be written
		
		.Example
			to be written
		
		.Notes
			AUTHOR:		Abu Belal
			LASTEDIT:	12-June-2013
	
	#>	
	param
	(
		[Parameter(HelpMessage = "Username")]
		[String] $username, 
		[Parameter(HelpMessage = "Password")]
		[String] $password,
		[Parameter(HelpMessage = "Domain")]
		[String] $domain,
		[Parameter(HelpMessage = "Deployment share to authenticate against")]
		[String] $deploymentshare = $_deploymentShare
	)
	
	$wScriptNetwork = New-Object -ComObject WScript.Network
	
	try
	{	
		Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
		
		
		
		$wScriptNetwork.MapNetworkDrive($_tempDrive, $deploymentshare, $false, $domain + '\' + $username, $password)
		
		if ($_winpe)
		{	
			Write-Verbose "Writing $username , password and $domain to TS variables"
			$_tsEnv.Value('SccmUsername') = $username
			$_tsEnv.Value('SccmDomain') = $domain
			$_tsEnv.Value('SccmPassword') = $password
		}
		else
		{
			Write-Verbose 'not in winpe, skipping TS variables'
		}
		
		Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
		return ,$true
	}
	catch
	{	
		Write-Verbose ('[ERROR] ' + $_ ) 
		Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
		throw $_
	}
	finally
	{	
		$drives = Get-PSDrive 
		
		foreach ($drive in $drives) 
		{ 
			if ($drive.Name.ToUpper() -eq $_tempDrive.Replace(':',''))
			{
				$wScriptNetwork.RemoveNetworkDrive($_tempDrive, $true, $true)
				break
			}
		}		
	}
}

function Get-CustomSystemDetails
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$systemDetails = New-Object System.Collections.Hashtable
	
	$cpu = (Get-WmiObject -Class Win32_Processor).MaxClockSpeed
	# need to do this so it's comptabile with ps2
	try
	{
		$systemDetails.Add('cpu', $cpu[0])
	}
	catch
	{
		$systemDetails.Add('cpu', $cpu)
	}
	
	$systemDetails.Add('ram', [system.Math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory /1024/1024/1024))
		
		
	if ($_winpe)
	{
		$systemDetails.Add('uuid', $_tsEnv.Value('uuid'))
		$systemDetails.Add('mac', $_tsEnv.Value('macaddress001'))
		[Guid] $uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).uuid
		$systemDetails.Add('netbootguid', '\' + [System.BitConverter]::ToString($uuid.ToByteArray()).Replace('-','\'))
	}
	else
	{
		$systemDetails.Add('uuid', (Get-WmiObject -Class Win32_ComputerSystemProduct).uuid)
		$systemDetails.Add('mac', (Get-WmiObject -class win32_networkadapter -filter "NetConnectionStatus = 2").MACAddress)
		[Guid] $uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).uuid
		$systemDetails.Add('netbootguid', '\' + [System.BitConverter]::ToString($uuid.ToByteArray()).Replace('-','\'))
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $systemDetails
}

function Get-CustomMdtComputerName
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$systemDetails = Get-CustomSystemDetails
	
	$mdtComputerRecord = Get-MDTComputer -uuid ($systemDetails.uuid)
	
	if ($mdtComputerRecord.Count -gt 1)
	{
		throw ("Someone has been messing with the MDT database!!!! Too many records exist in MDT for this uuid: " + $systemDetails.uuid)
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $mdtComputerRecord.OSDComputerName
}

function Get-CustomWeekGroups($userDomainIn, $username, $password, $domainToSearchFor)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
       
	$strFilter = '(&(objectCategory=group)(samaccountname=wks-softwaredeployment*))'
	
	#$searchGroupResult = New-Object System.Collections.Hashtable
	$searchGroupResult = New-Object 'System.Collections.Generic.SortedDictionary[string, string]'
	
	$searchResults = Search-CustomActiveDirectory $strFilter ('samaccountname','distinguishedName','grouptype') $userDomainIn $username $password
		
	foreach ($searchResult in $searchResults)
	{
		if ($searchResult.Properties['grouptype'][0] -eq -2147483640)
		{
			$searchGroupResult.Add($searchResult.Path, $searchResult.Properties['samaccountname'][0])
			Write-Verbose ('Found universal group type ' + $searchResult.Properties['samaccountname'][0])
		}
		else
		{
			if ((Get-DomainFromDN $searchResult.Properties['distinguishedName'][0].ToUpper() ) -eq $domainToSearchFor.ToUpper())
			{
				if (! $searchGroupResult.Keys.Contains($searchResult.Path))
				{
					$searchGroupResult.Add($searchResult.Path, $searchResult.Properties['samaccountname'][0])
					Write-Verbose ('Found ' + $searchResult.Properties['samaccountname'][0])
				}
			}
		}	   	
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $searchGroupResult
}

Function Get-CustomAdUser($searchString, $userDomainIn, $username, $password)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
       
	$strFilter = '(&(objectCategory=User)(samaccountname=*' + $searchString + '*))'
	
	$searchUserResult = New-Object System.Collections.Hashtable
	
	$searchResults = Search-CustomActiveDirectory $strFilter 'userPrincipalName' $userDomainIn $username $password

	foreach ($searchResult in $searchResults)
	{
		$searchUserResult.Add($searchResult.Path, $searchResult.Properties['userPrincipalName'][0])
	   	Write-Verbose ('Found ' + $searchResult.Properties['userPrincipalName'][0])
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	return $searchUserResult
}

# if domaintosearch is filled, then search will be limited to just that domain
function Search-CustomActiveDirectory($searchFilter, [string[]] $searchPropertiesToLoad, $userDomainIn, $username, $password, $domainToSearch = '')
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$userAuthDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
	(New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
	[System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain, $userDomainIn, $username, $password)))
	
	$domains = $null
	# always connect to parent domain to get hold of children
	#if ($userAuthDomain.Forest.Name.ToLower() -ne $userAuthDomain.Name.ToLower())
	if ($userAuthDomain.Parent -ne $null)
	{
		Write-Verbose ('[DEBUG] Current authenticated domain is child domain ' + $userAuthDomain.Forest.Name + ' switching to parent domain to get all child domains')
		
		$userDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
		(New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
		[System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain, $userAuthDomain.Parent.Name , ($username + '@'+ $userDomainIn), $password)))
		
		$domains = $userDomain.Children
		$domains += $userDomain # add parent domain
		#$domains += $userAuthDomain		
	}
	else
	{
		$domains = $userAuthDomain.Children
		$domains += $userAuthDomain	
	}	
	
	Write-Verbose ('[DEBUG] Number of child domains to search: ' + $domains.Count )
	
	$searchObjects = New-Object System.Collections.Generic.List[Object]	
	$searchObjects.Clear()
	
	foreach ($domain in $domains)
	{
		if ($domainToSearch -ne '')
		{
			# this ensures we only search one domain
			if ($domain.Name.ToUpper() -ne $domainToSearch)
			{
				continue
			}
		}
		try
		{
			Write-Verbose ('[DEBUG] Searching domain ' + $domain.Name)
			
			$directoryEntry = New-Object system.DirectoryServices.DirectoryEntry(('LDAP://' + $domain.Name), ($username + '@'+ $userDomainIn), $password)
			$directorySearcher = (New-Object System.DirectoryServices.DirectorySearcher($directoryEntry, $searchFilter, $searchPropertiesToLoad))			
			$directorySearcher.CacheResults = $true
			$directorySearcher.PageSize = 10
			$directorySearcher.ServerTimeLimit = New-Object System.TimeSpan(0,0,30)
			$directorySearcher.ClientTimeout = New-Object System.TimeSpan(0,10,0)

			$searchResult = $directorySearcher.FindAll()
			
			foreach ($result in $searchResult)
			{
				$searchObjects.Add($result)
			}
			
			Write-Verbose ('[DEBUG] total number of computers found: ' + $searchObjects.Count + ' (this list gets appended from previous domain search)')
			
			$searchResult.Dispose()
		}
		catch
		{
			Write-Verbose ('[ERROR] ' + $_ )
			Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
			throw New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryOperationException('An error occured whilst trying to work against AD! Full details are ' + $_ )
						 
		}
		finally
		{
			$directoryEntry.Dispose()
			$directorySearcher.Dispose()
		}
	}
	
	Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
	
	return ,$searchObjects
}

function Get-CustomAdComputers($computerSite, $computerType, $userDomainIn, $username, $password)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$computerPrefix = ($computerSite + $computerType)
	
	$dtDomainComputers = New-Object System.Data.DataTable('DomainComputers')
	$dtDomainComputers.Columns.Add((New-Object System.Data.DataColumn('Name', [string])))
	$dtDomainComputers.Columns.Add((New-Object System.Data.DataColumn('netbootGUID', [string])))
	
	$computerNames = New-Object System.Collections.Generic.List[string]
	$computerNames.Clear()
				
	$userAuthDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
	(New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
	[System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain, $userDomainIn, $username, $password)))
	
	#$domains = $userDomain.Forest.Domains - this doens't work in winpe therefore we need the extra code below
	
	$domains = $null
	# always connect to parent domain to get hold of children
	if ($userAuthDomain.Forest.Name.ToLower() -ne $userAuthDomain.Name.ToLower())
	{
		$userDomain = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain(
		(New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext(
		[System.DirectoryServices.ActiveDirectory.DirectoryContextType]::Domain, $userAuthDomain.Parent.Name , ($username + '@'+ $userDomainIn), $password)))
		
		$domains = $userDomain.Children
		$domains += $userDomain
		#$domains += $userAuthDomain		
	}
	else
	{
		$domains = $userAuthDomain.Children
		$domains += $userAuthDomain	
	}	
	
	[String[]] $propertiesToLoad = 'Name','netbootGUID'
	
	foreach ($domain in $domains)
	{
		try
		{
			$directoryEntry = New-Object system.DirectoryServices.DirectoryEntry(('LDAP://' + $domain.Name), ($username + '@'+ $userDomainIn), $password)
			$directorySearcher = (New-Object System.DirectoryServices.DirectorySearcher($directoryEntry, ('(&(ObjectClass=Computer)(name=' + $computerPrefix + '*))'), $propertiesToLoad))			
			$directorySearcher.CacheResults = $true
			$directorySearcher.PageSize = 10
			$directorySearcher.ServerTimeLimit = New-Object System.TimeSpan(0,0,30)
			$directorySearcher.ClientTimeout = New-Object System.TimeSpan(0,10,0)

			$searchResult = $directorySearcher.FindAll()
			
			foreach ($result in $searchResult)
			{
				$dtRow = $dtDomainComputers.NewRow()
				$dtRow.Name = ($result.Properties['name'].ToUpper())
				if ($result.Properties.Contains('netbootguid'))
				{
					$dtRow.netbootGUID = '\' + [System.BitConverter]::ToString($result.Properties['netbootGUID'][0]).Replace('-','\') #($result.Properties['netbootGUID'])
				}
				else
				{
					$dtRow.netbootGUID = 'NODETAILS'
				}
				$dtDomainComputers.Rows.Add($dtRow)
				$computerNames.Add($result.Properties['name'].ToUpper())
			}
			
			$searchResult.Dispose()
		}
		catch
		{
			Write-Verbose ('[ERROR] ' + $_ )
			Write-Verbose ('[DEBUG] Exiting function' + $myInvocation.MyCommand)
			throw New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryOperationException('An error occured whilst trying to work against AD! Full details are ' + $_ )
						 
		}
		finally
		{
			$directoryEntry.Dispose()
			$directorySearcher.Dispose()
		}
	}
		
	$dtDomainComputers.DefaultView.Sort = 'Name ASC'
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
	
	return ,$dtDomainComputers
}

# checks hostname is available and reserves in MDT
function Test-Hostname($newComputername, $userDomainIn, $username, $password)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$computerType = $newComputername.Substring(3, 1)
	$computerSite = $newComputername.Substring(0, 3)
	
	$dtComputerNames = Get-CustomAdComputers $computerSite $computerType $userDomainIn $username $password
	
	$computerNames = New-Object System.Collections.Generic.List[string]
	
	if ($computerNames.Contains($newComputername.ToUpper()))	
	{
		Write-Verbose ('[ERROR] Provided computer name already exists in the AD forest! Please choose another name.')
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		throw New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException('Provided computer name already exists in the AD forest! Please choose another name.')
	}
	else
	{	
		$ping = Test-Ping $newComputername
		
		if ($ping.StatusCode -eq 0)
		{
			Write-Verbose ('[ERROR]' + $newComputername + ' is responding to ping request! Please check DNS and delete record or disconnect machine from network.')
			Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
			throw New-Object System.Net.NetworkInformation.PingException($newComputername + ' is currently pinging on the network! Please check DNS and delete record or disconnect machine from network.')
		}
	}
	
	Reserve-Name $newComputername $username (Get-CustomSystemDetails).uuid
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function Rename-CustomComputer($newName)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	if ($_winpe)
	{
		Rename-Computer $newName
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function Update-CustomMdtRecord($weekGroup, $managedBy, $buildEngineer, $buildDate, $domainToJoin, $domainOU)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$computerDetails = New-Object System.Collections.Hashtable
	
	$SccmMDTLocations = Get-MdtLocations
	
	Write-Verbose ('[DEBUG] Have locations from MDT')
	
	foreach ($row in $SccmMDTLocations.Rows)
	{
		Write-Verbose ('[DEBUG] Using details from ' + $row.Location)
		Write-Verbose ('[DEBUG] Verifying against ' + $domainOU)
		
		 if ($row.MachineObjectOU.ToLower() -eq $domainOU.ToLower())
		 {
		 	
		 	try
			{
			 	$computerDetails.Add('KeyboardLocale', $row.KeyboardLocale)
				$computerDetails.Add('UserLocale', $row.UserLocale)
				$computerDetails.Add('SystemLocale', $row.SystemLocale)
				$computerDetails.Add('TimeZoneName', $row.TimeZoneName)						
				
				break
			}
			catch
			{				
				Write-Verbose ('[ERROR] ' + $_)
				throw New-Object System.IO.InvalidDataException('Regional settings are missing for ' + $domainOU + ' in Locations table. You must ensure KeyboardLocale, UserLocale, SystemLocale and TimeZoneName are populated')
			}		 	
		 }
	}
	
	Write-Verbose ('[DEBUG] Checking all values exist...')
	
	foreach ($value in $computerDetails.Values) 
	{ 
		if ($value -eq [System.DBNull]::Value)
		{
			Write-Verbose ('[ERROR] Regional settings are missing for ' + $domainOU + ' in Locations table. You must ensure KeyboardLocale, UserLocale, SystemLocale and TimeZoneName are populated')
			throw New-Object System.IO.InvalidDataException('Regional settings are missing for ' + $domainOU + ' in Locations table. You must ensure KeyboardLocale, UserLocale, SystemLocale and TimeZoneName are populated')
		}
	}
	
	Write-Verbose ('[DEBUG] Checking all values exist... Done!')
	
	Write-Verbose ('[DEBUG] Adding all values..')			
	$computerDetails.Add('SccmManagedBy', $managedBy)
	$computerDetails.Add('SccmWeekGroup', $weekGroup)
	$computerDetails.Add('SccmBuildEngineer', $buildEngineer)
	$computerDetails.Add('SccmBuildDate', $buildDate)
	$computerDetails.Add('JoinDomain', $domainToJoin)
	$computerDetails.Add('MachineObjectOU', $domainOU)
	
	$thisNetBootGUID = (Get-CustomSystemDetails).netbootguid
	
	$computerDetails.Add('SccmNetbootGUID', $thisNetBootGUID)
		
	$systemDetails = Get-CustomSystemDetails
	
	$mdtRecord = Get-MDTComputer -uuid $systemDetails.uuid
	
	Write-Verbose ('[DEBUG] Adding all values..Done!')
	
	if ($mdtRecord.ID -ne $null)
	{
		Set-MDTComputer -id $mdtRecord.ID -settings $computerDetails
	}
	else
	{
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		throw 'Crap, nothing exists in MDT for this computer. Have you been a fool and skipped any next buttons??'
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function Get-CustomADComputerName($userDomainIn, $username, $password, [ref] $computerDomainOut)
{	 
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$thisNetBootGUID = (Get-CustomSystemDetails).netbootguid
	
	Write-Host ('netbootguid is : ' + $thisNetBootGUID)
	
	$srComputerNames = Search-CustomActiveDirectory ('(&(&(&(objectClass=computer)(netbootGuid=' + $thisNetBootGUID + '))))') 'name','netbootguid' $userDomainIn $username $password

	Write-Verbose ('[DEBUG] Found ' + $srComputerNames.Count + ' from Search-CustomActiveDirectory call')
	
	foreach ($result in $srComputerNames)
	{
		try
		{
			Write-Debug ('[DEBUG] Converting netbootguid from ' + $result.Properties['netbootGUID'][0] + ' to custom format' )
			$netbootguid = ('\' + [System.BitConverter]::ToString($result.Properties['netbootGUID'][0]).Replace('-','\'))
									
			if ($netbootguid -eq $thisNetBootGUID.Trim())
			{
				Write-Verbose ('[INFO] Found an existing computer name in AD based on netbootGUID number ' + $thisNetBootGUID)
				Write-Verbose ('[INFO] Setting computer name to ' + $result.Properties['name'].ToUpper())
				Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
				$computerDomainOut.Value = $result.Path.Split('/')[2]
				Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
				return $result.Properties['name'].ToUpper()
			}
		}
		catch
		{
			Write-Verbose ('[ERROR] netBootGUID seems screwed ' + $_ )
			throw ('there is a problem converting the netbootGUID for this machine. the exact error is :' + $_)
		}
	}
	
	Write-Verbose ('[INFO] No computer name found in AD that matches this systems netbootGUID number ' + $thisNetBootGUID)
	Write-Verbose ('[INFO] This machine is either new out of box or previous account in AD has been deleted. Will need to generate a new name.')
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

# generates a new hostname based on computer name availability in AD
function New-CustomComputerName($computerSite, $computerType, $userDomainIn, $username, $password)
{	
	$dHosts = New-Object System.Collections.Generic.List[int]

	$thisNetBootGUID = (Get-CustomSystemDetails).netbootguid

	$computerPrefix = ($computerSite + $computerType)

	#region find existing record

	$srComputerNames = Search-CustomActiveDirectory ('(&(&(&(objectClass=computer)(netbootGuid=' + $thisNetBootGUID + '))))') 'name','netbootguid' 'server.com' 'belala' 'Applex1!'

	if ($srComputerNames.Count -ne 0)
	{
		foreach ($result in $srComputerNames)
		{
			try
			{			
				$netbootguid = ('\' + [System.BitConverter]::ToString($result.Properties['netbootGUID'][0]).Replace('-','\'))
										
				if ($netbootguid -eq $thisNetBootGUID.Trim())
				{
					$computerDomainOut.Value = $result.Path.Split('/')[2]
					return $result.Properties['name'].ToUpper()
				}
			}
			catch
			{		
				throw ('there is a problem converting the netbootGUID for this machine. the exact error is :' + $_)
			}
		}
	}
	#endregion find existing record

	$dtComputerNames = Get-CustomAdComputers $computerSite $computerType $userDomainIn $username $password

	# get only machine whose name is less than 7 chars
	foreach ($c in $dtComputerNames)
	{
		if ($c.Name.Length -le ($computerPrefix.Length + 3) )
		{
			# strip the chars out to leave only numbers, if there is a 0 remove it
			$number = $c.Name.Substring($computerPrefix.Length)		
			
		 	$dHosts.Add([System.Convert]::ToInt32($number))
		}
	}

	$dHosts.Sort()

	if ($dHosts.Count -eq 0)
	{
		$newName = $computerPrefix + '001'
		
		return $newName.ToUpper()
	}

	$newNumberFound = $false

	for ($i = 0; $i -le $dHosts.Count; $i++)
	{
		$newNumber = ''
		$newName = ''
		
		if ($i -le $dHosts.Count)
		{		
			# low number gap exists
			if ($dHosts[$i] - 1)
			{
				$newNumber = ($dHosts[$i] - 1)
							
				if (!$dHosts.Contains($newNumber))
				{
					$newNumberFound = $true	
					
					Write-Host ('lower number found ' + $newNumber)
				}			
			}
			
			if ($dHosts[$i] + 1 -eq $dHosts[$i + 1])
			{
				Write-Host 'not a gap'
				continue
			}
			else
			{
				$newNumber = ($dHosts[$i] + 1)
				
				$newNumberFound = $true
				Write-Host ('gap found ' + $newNumber)
			}
			
			if ($newNumberFound)
			{
			
				switch ($newNumber.ToString().Length) 
				{
					1 {
						$newNumber = ('00' + $newNumber.ToString())
						
						$newName = $computerPrefix + $newNumber
						break
					}
					2 {
						$newNumber = ('0' + $newNumber.ToString())
						
						$newName = $computerPrefix + $newNumber
						
						break
					}
					default {
						
						$newName = $computerPrefix + $newNumber.ToString()
						
						break
					}
				}
				try
				{	
					# if name cant be reserved keep trying 
					if (Reserve-Name $newName 'belala' (Get-CustomSystemDetails).uuid)
					{
						$ping = Test-Ping $newName
						
						if ($ping.StatusCode -eq 0)
						{
							Write-Host ($newName + ' is pingable on network, getting next name')
							$newNumberFound = $false
							continue
						}
						
						return $newName.ToUpper()
						break
					}
				}
				catch
				{
					Write-Host ($newName + ' has been reserved in MDT, getting next name')
					$newNumberFound = $false
					continue
				}			
			}	
		}
	}
}

function Test-Ping($targetSystem)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	$pingResult = Get-WmiObject -Query ("SELECT * FROM Win32_PingStatus WHERE Address = '" + $targetSystem + "'")
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $pingResult
}

function Remove-CustomMdtRecord
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$systemDetails = Get-CustomSystemDetails
	
	$mdtRecord = Get-MDTComputer -uuid $systemDetails.uuid
	
	if ($mdtRecord.ID -ne $null)
	{
		Remove-MDTComputer -id $mdtRecord.ID
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function New-CustomMdtComputer($computerName, $computerType)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$systemDetails = Get-CustomSystemDetails
	
	$mdtRecord = Get-MDTComputer -uuid $systemDetails.uuid
	
	if ($mdtRecord.ID -ne $null)
	{
		Remove-MDTComputer -id $mdtRecord.ID
	}
	
	$macAddresses = New-Object System.Collections.Generic.List[string]
	
	if ($systemDetails.mac.count -gt 1)
	{
		foreach ($macAddress in $systemDetails.mac)
		{
			$macAddresses.Add($macAddress)
		}
		
		$macAddresses.Sort()
		
		$systemDetails.mac = $macAddresses[1]
	}
    
    $settings = $null

    #if ($computerType -eq 'l')
    #{
		#Write-Verbose '[INFO] Letter L detected in hostname, setting OSDBitLockerMode to TPM' 	
        #$settings = @{OSDBitlockerMode='TPM';OSDBitLockerCreateRecoveryPassword='AD';OSInstall='YES';OSDComputerName='' + $computerName + ''}
    #}
    #else
    #{
    #     $settings = @{OSInstall='YES';OSDComputerName='' + $computerName + ''}
    #}   

	$settings = @{OSInstall='YES';OSDComputerName='' + $computerName + ''}

	New-MDTComputer -uuid $systemDetails.uuid -macAddress $systemDetails.mac -description $computerName -settings $settings
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function Get-CustomLocations([string] $computerDomain)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	Write-Verbose '[INFO] Getting all locations from MDT...'
	$dtLocations = Get-MdtLocations
	
	$sdLocations = New-Object 'System.Collections.Generic.SortedDictionary[string,string]'
	
	try
	{
		Write-Verbose ('[INFO] Filtering for locations valid for ' + $computerDomain.ToUpper())
		foreach ($row in $dtLocations)
		{
			if ($row.JoinDomain.ToUpper() -eq $computerDomain.ToUpper())
			{
				Write-Verbose ('[DEBUG] Adding selectable valid location: ' + $row.Location + ' with OU path ' + $row.MachineObjectOU )
				$sdLocations.Add($row.Location, $row.MachineObjectOU)
			}
		}
	}
	catch
	{
		Write-Verbose '[ERROR] Looks like someone has added the same OU path to more than one record in MDT locations database. This MUST be corrected.'
		throw 'looks like someone added the same OU path to more than one record in Locations database, this needs to be corrected'
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	return $sdLocations
}

function Get-CustomMdtComputerRoles
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$systemDetails = Get-CustomSystemDetails
		
	$mdtRoles = New-Object 'System.Collections.Generic.SortedDictionary[string, string]'
	
	Write-Verbose ('[DEBUG] CPU speed: ' + $systemDetails.cpu )
	Write-Verbose ('[DEBUG] RAM: ' + $systemDetails.ram )
	Write-Verbose '[INFO] Getting list of roles valid for this machines CPU and RAM...'
	$roles = Get-CustomMdtRoles 'Role,ID' $systemDetails.cpu $systemDetails.ram	
	
	foreach ($role in $roles)
	{
		Write-Verbose ('[INFO] Adding selectable role Name' + $role.Role)
		$mdtRoles.Add($role.ID, $role.Role)
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	
	return $mdtRoles
}

function Set-CustomMdtComputerlRole([string] $role)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$systemDetails = Get-CustomSystemDetails
	
	$mdtComputerRecord = Get-MDTComputer -uuid ($systemDetails.uuid)
	
	[System.Collections.ArrayList] $rolesToAdd = New-Object System.Collections.ArrayList
	
	# get ALL roles which is why we specified high cpu and mem
	$roles = Get-CustomMdtRoles 'Role' 1000000 10000000
	# get the first part of the role name (excel from excel-ldn)
	$thisRole = $role.Split('-')[0].ToLower()
	
	$globalRoleExists = $false
	# check for a global role for the aboe role
	foreach ($roleName in $roles)
	{
		$globalRoleChecks = $roleName.Role.Split('-').ToLower()
		
		if ($globalRoleChecks[0].ToLower() -eq $thisRole -and $globalRoleChecks[1].ToLower() -eq 'gbl')
		{
			#if ($rolesToAdd.IndexOf($roleName) -lt 0)
			#{
				$rolesToAdd.Add($roleName.Role)
				$globalRoleExists = $true
			#}
			
			#if ($rolesToAdd.IndexOf($role) -lt 0)
			#{
				$rolesToAdd.Add($role)
			#}
		}		
	}
	
	if (!$globalRoleExists)
	{		
		throw New-Object System.Data.SqlTypes.SqlNullValueException('Unable to find a global role for ' + $role + '. The MDT database must contain ' + $thisRole + '-gbl')
	}
	
	Set-MDTComputerRole -id $mdtComputerRecord.ID $rolesToAdd
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function Get-CustomComputerFromAD($computerName, $userDomainIn, $username, $password)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$searchResult = Search-CustomActiveDirectory ('(&(ObjectClass=Computer)(name=' + $computerName + '))') ('description', 'distinguishedName', 'managedBy') $userDomainIn $username $password
	
	$htDetailsFromAD = New-Object 'System.Collections.Generic.Dictionary[string, string]'
	
	if ($searchResult.Count -eq 1)
	{
		$recordFromAD = $searchResult[0]
		
		foreach ($property in $recordFromAD.Properties.GetEnumerator())
		{
			$htDetailsFromAD.Add($property.Key, $property.Value)
		}
		
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		
		return $htDetailsFromAD
	}
	else
	{	
		
		Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		Write-Verbose '[ERROR] More than one computer using this computer name found. For safety sake please manually delete one (incorrect) record from AD'
		throw New-Object System.DirectoryServices.ActiveDirectory.ActiveDirectoryObjectExistsException('More than one computer using this hostname found. For safety sake please manually delete this record from AD')
	}	
}

function Get-DomainFromDN($dn)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$items = $dn.Split(',')
	
	$domainPath = ''
	
	foreach ($item in $items)
	{
		if ($item.Contains('DC='))
		{
			$domainPath += $item.Replace('DC=', '.')
		}
	}
	
	if ($domainPath.Substring(0, 1) -eq '.')
	{
		$domainPath.Remove(0, 1)
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	
	return $domainPath
}

function Remove-CustomComputerFromAD($adsPath, $userDomainIn, $username, $password)
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$directoryEntry = New-Object system.DirectoryServices.DirectoryEntry(($adsPath), ($username + '@'+ $userDomainIn), $password)
	
	if ($_winpe)
	{	
		$directoryEntry.DeleteTree()
	}
	else
	{
		Write-Verbose 'We are not in WINPE so wont be deleting this computer from AD'
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}


Export-ModuleMember -Function *
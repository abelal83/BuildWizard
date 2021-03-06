#Set-StrictMode -Version 2
Set-PSDebug -Strict
$ErrorActionPreference = 'stop'

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{   
	$arguments = "-command " + $myinvocation.mycommand.definition		
	Start-Process 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe' -Verb runAs -ArgumentList $arguments	
	exit 0 
}

Start-Transcript -Path C:\Sccm\Sccm.osbuild.postinstall.log -Verbose

if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{
	Write-Host 'Running in elevated mode'
}

#region css style
$_cssStle = '<style>body {
	font: normal 11px auto "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
	color: #4f6b72;
	background: #E6EAE9;
}
a {
	color: #c75f3e;
}
#mytable {
	width: 700px;
	padding: 0;
	margin: 0;
}
caption {
	padding: 0 0 5px 0;
	width: 700px;	 
	font: italic 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
	text-align: right;
}
th {
	font: bold 11px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
	color: #4f6b72;
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	border-top: 1px solid #C1DAD7;
	letter-spacing: 2px;
	text-transform: uppercase;
	text-align: left;
	padding: 6px 6px 6px 12px;
	background: #CAE8EA
}
th.nobg {
	border-top: 0;
	border-left: 0;
	border-right: 1px solid #C1DAD7;
	background: none;
}
td {
	border-right: 1px solid #C1DAD7;
	border-bottom: 1px solid #C1DAD7;
	background: #fff;
	padding: 6px 6px 6px 12px;
	color: #4f6b72;
}
td.alt {
	background: #F5FAFA;
	color: #797268;
}
th.spec {
	border-left: 1px solid #C1DAD7;
	border-top: 0;
	background: #fff
	font: bold 10px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
}
th.specalt {
	border-left: 1px solid #C1DAD7;
	border-top: 0;
	background: #f5fafa;
	font: bold 10px "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;
	color: #797268;
}</style>'
#endregion css style

$_smtpServer = 'smtpdeskside.server.com'
$_emailLog = New-Object System.Text.StringBuilder

$PSScriptDirectory = (Split-Path $MyInvocation.MyCommand.Path -Parent).ToLower()

function Send-CustomMailMessage($smtpFrom, $displayName, $subject, $body, $smtpTo, $attachments = $null, $html = $true)
{	
	<#
		.Synopsis
			Sends emails by relay
		
		.Description
			Can be used to send emails as someone else
		
		.Example
			Send-CustomMailMessage $_mailErrorTo 'belal, abu' 'relayed emailed' 'body of email' 'abu@gmail.com'
		
		.Notes
			AUTHOR:		Abu Belal
			LASTEDIT:	06-June-2013
			EDITS:		Removed logging info
						Removed try catch around send mail, callee should handle this
	
	#>	
	
	$developer = "abu.belal@email.com"
	
	$from = New-Object System.Net.Mail.MailAddress($smtpFrom, $displayName)		
	$mail = New-Object System.Net.Mail.MailMessage	
	$smtp = New-Object Net.Mail.SmtpClient($_smtpServer)
	
	$mail.From = $from
	$mail.To.Add($smtpTo)	
	#$mail.BCC.Add($_mailErrorToCc)
	$mail.Subject = $subject
	$mail.Body = $body
	$mail.IsBodyHtml = $html
	
	if ($attachments -ne $null)
	{
		foreach ($attachement in $attachments)
		{			
			$mail.Attachments.Add($attachement)
		}
	}
	
	$smtp.Send($mail)

}

try
{
	Import-Module ($PSScriptDirectory + '\Sccm.OsBuild.Data.psm1') -Verbose
	Import-Module ($PSScriptDirectory + '\Sccm.OsBuild.Logic.psm1') -Verbose
}
catch
{
	Send-CustomMailMessage ('Sccm.OsBuild.PostInstall.ERROR@' + $Env:COMPUTERNAME) 'Sccm.OsBuild.PostInstall' ('Build error on ' + $Env:COMPUTERNAME) $_ 'abu.belal@email.com'#'deskside@email.com'
}

function Get-RoleInfo
{

#region old code
	#$mdtRecord = Get-CustomMDTComputerSettings	
	#$appliedRoles = Get-CustomAppliedRoles $mdtRecord.ID	
	#foreach ($role in $appliedRoles)
	#{
	#	Write-Log ('[INFO] Applied role ' + $role.Role) 'Software role'
	#}	
#endregion 
	
	try
	{	
		$ztiLogFile = ''
		
		if ([System.IO.File]::Exists('C:\_SMSTaskSequence\Logs\ZTIGather.log'))
		{
			$ztiLogFile = Get-Content 'C:\_SMSTaskSequence\Logs\ZTIGather.log'
		}
		
		if ([System.IO.File]::Exists('C:\Windows\CCM\Logs\ZTIGather.log'))
		{
			$ztiLogFile = Get-Content 'C:\Windows\CCM\Logs\ZTIGather.log'
		}
		
		$hashTable = New-Object 'System.Collections.Generic.SortedDictionary[string,string]'

		$breakOut = $false

		for ($i = ($ztiLogFile.Count - 1); $i -ge 0; $i--)
		{
			$item = $ztiLogFile[$i]
			
			if ($breakOut)
			{
				foreach ($roleItem in $hashTable.GetEnumerator())
				{
					Write-Log ('[INFO] Applied role ' + $roleItem.Value) 'Software role'
				}
				break
			}
				
			if ($item.Contains('Added ROLE value from SQL:  ROLE ='))
			{
				$lastEntry = $i
				
				Write-Host $ztiLogFile[$i]		
				
				for ($l = $lastEntry - 1; $l -ge 0; $l--)
				{
					$lItem = $ztiLogFile[$l]
					if ($lItem.Contains('Added ROLE value from SQL:  ROLE ='))
					{
						$nextEntry = $l
						#Write-Host $ztiLogFile[$l]
						
						$breakOut = $true
						
						break
					}
					else
					{
						$content = $ztiLogFile[$l]
						
						if ($content.StartsWith('<![LOG[Property '))
						{
							#Write-Host $content					
							
							$start = $content.IndexOf('=')
							$end = $content.IndexOf(']LOG]')
							
							$hashTable.Add($content.Substring(16, 11), $content.Substring(($start + 2), ($end - $start - 2)))		
						}		
						#Write-Host $content.Substring(($start + 2), ($end - $start - 2))
					}
				}		
			}	
		}
	}		
	catch
	{
		Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Get-OSDDomainInfo'	
	
	}
	
}

function Get-OSDDomainInfo
{
	try
	{
		$ztiLogFile = ''
		
		if ([System.IO.File]::Exists('C:\_SMSTaskSequence\Logs\ZTIGather.log'))		
		{
			$ztiLogFile = Get-Content 'C:\_SMSTaskSequence\Logs\ZTIGather.log'
		}
		
		if ([System.IO.File]::Exists('C:\Windows\CCM\Logs\ZTIGather.log'))
		{
			$ztiLogFile = Get-Content 'C:\Windows\CCM\Logs\ZTIGather.log'
		}			
		
		$foundDomain = $false		
		$foundDomainOU = $false
		
		for ($i = ($ztiLogFile.Count - 1); $i -ge 0; $i--)
		{
			$item = $ztiLogFile[$i]
			
			if ($item.Contains('Property OSDDomainName is now ='))
			{
				$content = $ztiLogFile[$i]
				$start = $content.IndexOf('=')
				$end = $content.IndexOf(']LOG]')
				
				$osdDomain = $content.Substring($start, ($end - $start))
				
				Write-Log ('[INFO] Joined domain ' + $osdDomain) 'Join Domain'
				
				$foundDomain = $true
				
				if ($foundDomain)
				{
					break
				}
			}
			
			if ($item.Contains('Property OSDDomainOUName is now ='))
			{
				$content = $ztiLogFile[$i]
				$start = $content.IndexOf('=')
				$end = $content.IndexOf(']LOG]')
				
				$osdDomainOUName = $content.Substring($start, ($end - $start))
				
				Write-Log ('[INFO] Moved to OU ' + $osdDomainOUName) 'OU Location'
				
				$foundDomainOU = $true
				
				if ($foundDomain)
				{
					break
				}
			}			
		}
	}
	catch
	{
		Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Get-OSDDomainInfo'	
	
	}
}

function GetAppInstallState
{
	$executionHistory = 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\Mobile Client\Software Distribution\Execution History\System\'
	
	try
	{
	
	#region old stuff which doesnt work in OSD mode
#		$osdBaseVariable = (Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SOFTWARE\MICROSOFT\MPSD\OSD -Name OSDBaseVariableName).OSDBaseVariableName
#		
#		$osdProperties = Get-Item Registry::HKEY_LOCAL_MACHINE\SOFTWARE\MICROSOFT\MPSD\OSD
#		
#		foreach ($property in $osdProperties.Property)
#		{		
#			if ($property.Length -eq ($osdBaseVariable.Length + 3))
#			{			
#				if ($property.Substring(0, $property.Length - 3) -eq $osdBaseVariable)
#				{
#					$propertyValue = (Get-ItemProperty Registry::HKEY_LOCAL_MACHINE\SOFTWARE\MICROSOFT\MPSD\OSD -Name $property).$property
#				
#					Write-Log ('[DEBUG] Adding ' + $propertyValue + ' to hashtable for packages success lookup')
#					$hashTable.Add($property, $propertyValue)
#				}
#			}
#		}
	#endregion old stuff
	
		# the above has been replaced with this code
		$ztiLogFile = ''
		
		if ([System.IO.File]::Exists('C:\_SMSTaskSequence\Logs\ZTIGather.log'))
		{
			$ztiLogFile = Get-Content 'C:\_SMSTaskSequence\Logs\ZTIGather.log'
		}
		
		if ([System.IO.File]::Exists('C:\Windows\CCM\Logs\ZTIGather.log'))
		{
			$ztiLogFile = Get-Content 'C:\Windows\CCM\Logs\ZTIGather.log'
		}
		
		$hashTable = New-Object 'System.Collections.Generic.SortedDictionary[string,string]'

		$breakOut = $false

		for ($i = ($ztiLogFile.Count - 1); $i -ge 0; $i--)
		{
			$item = $ztiLogFile[$i]
			
			if ($breakOut)
			{
				break
			}
				
			if ($item.Contains('Added PACKAGES value from SQL:  PACKAGES'))
			{
				$lastEntry = $i
				
				#Write-Host $ztiLogFile[$i]		
				
				for ($l = $lastEntry - 1; $l -ge 0; $l--)
				{
					$lItem = $ztiLogFile[$l]
					if ($lItem.Contains('Added PACKAGES value from SQL:  PACKAGES'))
					{
						$nextEntry = $l
						#Write-Host $ztiLogFile[$l]
						
						$breakOut = $true
						
						break
					}
					else
					{
						$content = $ztiLogFile[$l]
						
						if ($content.StartsWith('<![LOG[Property '))
						{
							Write-Host $content					
							
							$start = $content.IndexOf('=')
							$end = $content.IndexOf(']LOG]')
							
							$hashTable.Add($content.Substring(16, 11), $content.Substring(($start + 2), ($end - $start - 2)))		
						}		
						#Write-Host $content.Substring(($start + 2), ($end - $start - 2))
					}
				}		
			}	
		}
	
		
		if ($hashTable.Count -eq 0)
		{
			Write-Log ('[WARN] No applications have been installed. This is normal if OS only has been selected.') 'AppInstall State'
			
			return
		}
		
		foreach ($item in $hashTable.GetEnumerator())
		{
			try
			{
				$keyPath = $executionHistory + $item.Value.Split(':')[0]
				$subKeys =  Get-Item Registry::$keyPath
						
				$keyPath += '\' + $subKeys.GetSubKeyNames()[0]
				
				Write-Log ('[DEBUG] keypath to check for app install success is ' + $keyPath)
				
				$state = (Get-ItemProperty Registry::$keyPath -Name '_State').'_State'
				
				if ($state.ToLower() -eq 'success')
				{
					Write-Log ('[INFO] ' + $state) ($item.Key + ' - ' + $item.Value)
				}
				else
				{
					Write-Log ('[WARN] ' + $state) ($item.Key + ' - ' + $item.Value)
				}
			}
			catch
			{
				Write-Log ('[ERROR] ' + $_ ) ($item.Key + ' - ' + $item.Value)
			}		
		}
	}
	catch
	{
		Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'AppInstall state'				
	}
}

function Set-ManagedBy
{
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	$managedBy = $_mdtComputerRecord.SccmManagedBy
	
	if ($managedBy -ne [System.DBNull]::Value)
	{
		try
		{
			$thisComputersOwner = Get-CustomUserFromAD $managedBy
					
			Set-CustomADComputerSetting $_thisComputerFromAD.Path 'managedby' $thisComputersOwner.distinguishedName[0]
			Write-Log ('[INFO] Successully set to ' + $thisComputersOwner.displayName[0]) 'Set managedby field'
			
			if ($thisComputersOwner.displayName[0])
			{
				Set-CustomADComputerSetting $_thisComputerFromAD.Path 'description' $thisComputersOwner.displayName[0]
				Write-Log ('[INFO] Successfully set to ' + $thisComputersOwner.displayName[0]) 'Set description field'
			}
			else
			{
				Write-Log ('[WARN] Computer description not set as user account has no displayname ' + $thisComputersOwner.displayName[0]) 'Set description field'
			}		
		}
		catch
		{
			Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Set managedBy'						
		}
	}
	else
	{		
		$managedBy = $_mdtComputerRecord.SccmBuildEngineer		
		$thisComputersOwner = Get-CustomUserFromAD $managedBy
	
		Write-Log '[WARN] No managed by user selected, defaulting to build engineer' 'Set managedBy'
		Write-Log '[WARN] No managed by user selected defaulting to build engineer' 'Set description'
		
		Set-CustomADComputerSetting $_thisComputerFromAD.Path 'managedby' $thisComputersOwner.distinguishedName[0]
		Write-Log ('[WARN] Successully set to ' + $thisComputersOwner.displayName[0]) 'Set managedby field to build engineer'
		Set-CustomADComputerSetting $_thisComputerFromAD.Path 'description' $thisComputersOwner.displayName[0]
		Write-Log ('[WARN] Successfully set to ' + $thisComputersOwner.displayName[0]) 'Set description field to build engineer'
		
	}
	
	
	Write-Log ('[INFO] ' + $_mdtComputerRecord.SccmBuildEngineer) 'Build Engineer'

	
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
}

function Remove-DomainUsersFromGroups
{
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	try
	{
		Remove-CustomAllDomainAccountsFromLocalGroup $_thisComputerFQDN.Hostname -groupName 'Administrators'
		Write-Log '[INFO] All domain user accounts removed from Administrators' 'Remove accounts'
		Remove-CustomAllDomainAccountsFromLocalGroup $_thisComputerFQDN.Hostname -groupName 'Remote Desktop Users'
		Write-Log '[INFO] All domain user accounts removed from Remote Desktop Users' 'Remove accounts'
	}
	catch
	{
		Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Remove Domain Users From Local Groups'

	}
}


function Add-ToLocalGroup
{
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$managedBy = $_mdtComputerRecord.SccmManagedBy
	
	if ($managedBy -ne '')
	{
		try
		{
			$thisComputersOwner = Get-CustomUserFromAD $managedBy
			
			$ntAccount = GetUserDomainAndUserName $thisComputersOwner		
			$sDomain = ($ntAccount.Value.Split('\'))[0]

			$computerOwnerWinNT = [ADSI]("WinNT://" + $sDomain + "/" + $thisComputersOwner.sAMAccountName)
			$localGroup = [ADSI]("WinNT://" + $_thisComputerFromAD.Properties.name[0] + "/Remote Desktop Users")
			# change to admin of needed
			#$localGroup = [ADSI]("WinNT://" + $computerDirectoryEntry.Name + "/Administrators")
			$localGroup.PSBase.Invoke("Add", $computerOwnerWinNT.Path)
			Write-Log ('[INFO] Added ' + $thisComputersOwner.sAMAccountName + ' to Remote Desktop Users') 'Add to RDP group'
			Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		}
		catch
		{
			Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Add to local groups'
						
			Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		}
	}
	
}

function Remove-AllGroups
{
	<#
		.Synopsis
			Removes all group membership except for domain users or domain computers

		.Description
 			Removes all groups from a given objects membership list, requires rights on the group object it attempts to remove from

		.Example
			
			Remove-AllGroups "LDAP://CN=ldnw492,CN=Deskside,DC=server,DC=com"
			    		
		.Notes		
			AUTHOR:    Abu Belal
			LASTEDIT:  11-Jan-2013

	#>	

	$theObject = New-Object System.DirectoryServices.DirectoryEntry($_thisComputerFromAD.Path)
	
	$theObject.Close()
	
	$memberOf = $theObject.memberOf
	
	foreach ($group in $memberOf)
	{
		try
		{
			$groupObject = New-Object System.DirectoryServices.DirectoryEntry("LDAP://" + $group)		
			$groupObject.Invoke("Remove", $theObject.Path)		
			$groupObject.CommitChanges()
			Write-Log ('[INFO] Removed from ' + $group ) 'Remove group membership'
		
		}
		catch [System.UnauthorizedAccessException]
		{ 	
			Write-Log ('[ERROR] Account does not have permission to remove machine from ' + $group ) 'Remove group membership'	
		}
		catch
		{	
			Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Remove group membership'			
		}
		finally
		{ 	
			$groupObject.Close()	
		}
		
	}	
}

function Add-ToDomainGroup
{
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$mdtRecord = Get-CustomMDTComputerSettings
	
	$appliedRoles = Get-CustomAppliedRoles $mdtRecord.ID
	
	$appliedRegionalRole = ''
	
	foreach ($role in $appliedRoles)
	{
		if (!($role.Role.Contains('-gbl') -or $role.Role.Contains('-end')))
		{
			$appliedRegionalRole = $role.Role
		}
	}
	
	$regionalRoleSettings = Get-CustomMdtRoleSettings $appliedRegionalRole
	
	$additionalGroups = $regionalRoleSettings.SccmAdditionalGroups
	
	if ($additionalGroups -eq '' -or $additionalGroups -eq  [System.DBNull]::Value )
	{
		Write-Log ('[WARN] No additional groups in ' + $appliedRegionalRole + ' role (this may be perfectly fine)') 'Add additional groups'
		
		Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		return
	}
	
	$arrGroups = $additionalGroups.Split('|')
	
	foreach ($group in $arrGroups)
	{	
		try
		{
			$trimmedGroup =  $group.Trim()
		
			Add-CustomToDomainGroup $_thisComputerFromAD.Path $trimmedGroup
			
			Write-Log ('[INFO] Machine added to group: ' + $trimmedGroup) 'Add additional groups'
		}
		catch
		{
			Write-Log ('[ERROR] whilst adding to ' + $trimmedGroup + ' Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Add additional groups'
		}	
	}
	
	Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
	
}

function Add-ToWeekGroup
{	
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$weekGroup = $_mdtComputerRecord.SccmWeekGroup
	
	if ($weekGroup -ne '')
	{
		try
		{		
			Add-CustomToDomainGroup $_thisComputerFromAD.Path $weekGroup.Trim()		
			Write-Log ('[INFO] Machine added to week group: ' + $weekGroup) 'Set week deployment group'			
			Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand
		)
		}
		catch
		{
			Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Set week deployment group'			
			Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		}
	}
	else
	{
		Write-Log '[WARN] No Week group was selected' 'Set week deployment group'	
	}
}

function Set-NetBootGUID
{
	Write-Log ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$netbootGUID = $_mdtComputerRecord.SccmNetbootGUID
	
	if ($netbootGUID -ne '')
	{
		try
		{			
			[Guid] $uuid = (Get-WmiObject -Class Win32_ComputerSystemProduct).uuid			
						
			Set-CustomADComputerSetting $_thisComputerFromAD.Path 'netbootGUID' $uuid.ToByteArray()
			Write-Log ('[INFO] netBootGUID set to: ' + $netbootGUID) 'Set netBootGUID'
			Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		}
		catch
		{
			Write-Log ('[ERROR] Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Set netBootGUID'						
			Write-Log ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
		}
	}
	
}

#region helper function

function GetUserDomainAndUserName([System.DirectoryServices.DirectoryEntry] $directoryEntry)
{
	$objectSid = $directoryEntry.Properties["objectsid"][0]	
	[Security.Principal.SecurityIdentifier] $securityIdentifier = New-Object Security.Principal.SecurityIdentifier($objectSid, 0)
	[System.Security.Principal.NTAccount] $ntAccount = $securityIdentifier.Translate([Security.Principal.NTAccount])
	
	return $ntAccount
}

function Get-CustomMDTComputerSettings
{
	$systemDetails = Get-CustomSystemDetails
	
	$macAddresses = New-Object System.Collections.Generic.List[string]
		
	if ($systemDetails.mac.count)
	{
		if ($systemDetails.mac.count -gt 1)
		{
			foreach ($macAddress in $systemDetails.mac)
			{
				$macAddresses.Add($macAddress)
			}
			
			$macAddresses.Sort()
			
			$systemDetails.mac = $macAddresses[1]
		}		
	}

	$mdtComputerRecord = Get-SccmComputerSettings -macAddress $systemDetails.mac
	
	return $mdtComputerRecord
}

function Set-CustomADComputerSetting([string] $LDAPObjectPath, [string] $propertyName, $propertyValue)
{
	$directoryEntryComputer = New-Object System.DirectoryServices.DirectoryEntry($LDAPObjectPath)
	$directoryEntryComputer.InvokeSet($propertyName, $propertyValue) 
	$directoryEntryComputer.CommitChanges()
}

function Remove-CustomAllDomainAccountsFromLocalGroup([string] $computername, [string] $groupName)
{
	
	$directoryEntryComputer = New-Object System.DirectoryServices.DirectoryEntry("WinNT://" + $computername + ",computer")
	$localGroup = $directoryEntryComputer.Children.Find($groupName, "group")	
	$members = $localGroup.Invoke("members", $null)
	
	foreach ($member in $members)
	{		
		[System.DirectoryServices.DirectoryEntry] $directoryEntry = New-Object DirectoryServices.DirectoryEntry($member)		
		Write-Host $directoryEntry.Path
		[System.DirectoryServices.DirectoryEntry] $directoryEntryParent = New-Object DirectoryServices.DirectoryEntry($directoryEntry.Parent)

		if ($directoryEntryParent.SchemaClassName -ne $null)
		{
			if ($directoryEntry.SchemaClassName.ToLower() -eq "user" -and $directoryEntryParent.SchemaClassName.ToLower() -eq "domain")
			{
				$localGroup.Invoke("Remove", $directoryEntry.Path)
				$localGroup.CommitChanges()
				$directoryEntry.Close()
			}
		}
	}
	
	$localGroup.Dispose()	
}

function Remove-CustomFromAllDomainGroups([string] $LDAPObjectPath)
{
	<#
		.Synopsis
			Removes all group membership except for domain users or domain computers

		.Description
 			Removes all groups from a given objects membership list, requires rights on the group object it attempts to remove from

		.Example
			
			Remove-AllGroups "LDAP://CN=ldnw492,CN=Deskside,DC=server,DC=com"
			    		
		.Notes		
			AUTHOR:    Abu Belal
			LASTEDIT:  11-Jan-2013

	#>	

	$theObject = New-Object System.DirectoryServices.DirectoryEntry($LDAPObjectPath)
	
	$theObject.Close()
	
	$memberOf = $theObject.memberOf
	
	foreach ($group in $memberOf)
	{
		try
		{
			$groupObject = New-Object System.DirectoryServices.DirectoryEntry("LDAP://" + $group)		
			$groupObject.Invoke("Remove", $theObject.Path)		
			$groupObject.CommitChanges()
		
		}
		finally
		{ 	
			$groupObject.Close()	
		}
		
	}	
}

function Add-CustomToDomainGroup([string] $LDAPObjectPath, [string] $LDAPAddToGroupPath)
{
	<#
		.Synopsis	
			Adds an AD object to a group

		.Description
			Adds an AD object to given group, requires rights on the group object being added to
 			
		.Example
			Add-CustomAdGroup
			    		
		.Notes		
			AUTHOR:    Abu Belal
			LASTEDIT:  03-June-2013

	#>
	
	$groupObject = New-Object System.DirectoryServices.DirectoryEntry($LDAPAddToGroupPath)		
	$groupObject.Invoke("Add", $LDAPObjectPath)		
	$groupObject.CommitChanges()
	$groupObject.Close()	
}

function Get-FQDN()
{
	<#
		.Synopsis
			Get's local machines fully FQDN

		.Description
 			Returns a custom psobject containing hostname and fully qualified domain name

		.Example
			
			Get-FQDN
			$fqdn = Get-FQDN
    		
		.Notes		
			AUTHOR:    Abu Belal
			LASTEDIT:  11-Jan-2013

	#>

	[string] $domainName = [Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName
	[string] $hostName = [Net.Dns]::GetHostName()		
	[string] $fqdn = ""
	
	if (!$hostName.Contains($domainName))
	{	
		$fqdn = $hostName + "." + $domainName		
	}
	
	else
	{
		$fqdn = $hostName
	}
	
	$fqdnProperties = @{
				Hostname = $hostName 
				Domain = $domainName
				Fullname = $hostName + "." + $domainName
				}
				
	$fqdnObject =  New-Object PSObject -Property $fqdnProperties
	
	return $fqdnObject
}

function Get-CustomComputerFromAD([String] $dnsHostname)
{
	<#
		.Synopsis
			Searches AD for computer

		.Description
 			Searches the AD based on the $dnsHostname parameter. Function returns ActiveDirectory.SearchResult object

		.Example
			
			Get-ComputerFromAD ldnw492.server.com
			$result = Get-ComputerFromAD ldnw492.server.com
    		
		.Notes		
			AUTHOR:    Abu Belal
			LASTEDIT:  11-Jan-2013

	#>
	
	$directoryEntryRoot = [DirectoryServices.ActiveDirectory.Domain]::GetComputerDomain()
	
	$directorySearcher = New-Object System.DirectoryServices.DirectorySearcher	
	$directorySearcher.SearchRoot = $directoryEntryRoot.GetDirectoryEntry()
	$directorySearcher.SearchScope = [DirectoryServices.SearchScope]::Subtree	
	$directorySearcher.Filter = "(&(objectClass=computer)(dNSHostName=" + $dnsHostname + "))"
	
	$searchResult = $directorySearcher.FindOne()

	return $searchResult

}


function Get-CustomUserFromAD([string] $LDAPObjectPath)
{
	$directoryEntryUser = New-Object System.DirectoryServices.DirectoryEntry($LDAPObjectPath)
	
	return $directoryEntryUser
}

function Write-Log([string] $message, [string] $taskName = '')
{	
	$log = ((Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " " + $message + "`r`n")
	
	if ($message.ToUpper().Contains('[ERROR]'))
	{
		Add-EmailTableData $taskName ('<font color=red>' + $log + '</font>')
	}
	elseif ($message.ToUpper().Contains('[WARN]'))
	{
		Add-EmailTableData $taskName ('<font color=blue>' + $log + '</font>')
	
	}
	elseif ($message.ToUpper().Contains('[DEBUG]'))
	{
		# don't write anything
	}
	else
	{
		Add-EmailTableData $taskName $log
	}
	
	Write-Host $log	
}

function Convert-HexStringToByteArray
{
	################################################################
	#.Synopsis
	# Convert a string of hex data into a System.Byte[] array. An
	# array is always returned, even if it contains only one byte.
	#.Parameter String
	# A string containing hex data in any of a variety of formats,
	# including strings like the following, with or without extra
	# tabs, spaces, quotes or other non-hex characters:
	# 0x41,0x42,0x43,0x44
	# x41x42x43x44
	# 41-42-43-44
	# 41424344
	# The string can be piped into the function too.
	################################################################
	 [CmdletBinding()]
	 Param ( [Parameter(Mandatory = $True, ValueFromPipeline = $True)] [String] $String )

	#Clean out whitespaces and any other non-hex crud.
	 #$String = $String.ToLower() -replace '[^a-f0-9\,x-:]',''
	 $String = $String.ToLower() -replace '[^a-f0-9]'

	#Try to put into canonical colon-delimited format.
	# $String = $String -replace '0x|\x|-|,',':'

	#Remove beginning and ending colons, and other detritus.
	# $String = $String -replace '^:+|:+$|x|\',''

	#Maybe there's nothing left over to convert...
	 if ($String.Length -eq 0) { ,@() ; return }

	#Split string with or without colon delimiters.
	 if ($String.Length -eq 1)
	 { ,@([System.Convert]::ToByte($String,16)) }
	 elseif (($String.Length % 2 -eq 0) -and ($String.IndexOf(":") -eq -1))
	 { ,@($String -split '([a-f0-9]{2})' | foreach-object { if ($_) {[System.Convert]::ToByte($_,16)}}) }
	 elseif ($String.IndexOf(":") -ne -1)
	 { ,@($String -split ':+' | foreach-object {[System.Convert]::ToByte($_,16)}) }
	 else
	 { ,@() }
	 #The strange ",@(...)" syntax is needed to force the output into an
	 #array even if there is only one element in the output (or none).
}

function Add-EmailTableData($taskName, $taskResult)
{
	[Void] $_emailLog.Append('<tr>')
	[Void] $_emailLog.AppendLine()

	[Void] $_emailLog.Append('<td>' + $taskName + '</td>')
	[Void] $_emailLog.AppendLine()
	
	[Void] $_emailLog.Append('<td>' + $taskResult + '</td>')
	[Void] $_emailLog.AppendLine()
	   
	[Void] $_emailLog.Append('</tr>')
	[Void] $_emailLog.AppendLine()
}

#endregion helper functions

$_mdtComputerRecord = Get-CustomMDTComputerSettings
$_thisComputerFQDN = Get-FQDN
$_thisComputerFromAD = $null

[Void] $_emailLog.Append('<html><head>' + $_cssStle + '</head><body>')
[Void] $_emailLog.Append('<h2 align="center">Build Status</h2>')
[Void] $_emailLog.Append('<table id=#buildresult cellspacing="0" border="0">')
[Void] $_emailLog.AppendLine()
[Void] $_emailLog.Append('<tr>')
[Void] $_emailLog.AppendLine()
[Void] $_emailLog.Append('<td>Task</td>')
[Void] $_emailLog.AppendLine()
[Void] $_emailLog.Append('<td>Result</td>')
[Void] $_emailLog.Append('</tr>')
[Void] $_emailLog.AppendLine()

try
{
	if ($_thisComputerFQDN.Domain -ne $null)
	{
		# this computer is a member of a domain
		$_thisComputerFromAD = Get-CustomComputerFromAD $_thisComputerFQDN.Fullname

		Get-OSDDomainInfo
		Set-NetBootGUID
		Remove-AllGroups	
		Add-ToWeekGroup
		Remove-DomainUsersFromGroups
		Add-ToLocalGroup
		Add-ToDomainGroup
		Set-ManagedBy			
		Get-RoleInfo
		GetAppInstallState				
	}
	else
	{
		# this computer is not a member of a domain
	}
}
catch
{	
	Write-Log ('[ERROR] Something TERRIBLE occured! Full details are: ' + $Error[0] + ' <br> ' + $Error[0].ScriptStacktrace) 'Main Code Section'

}

[Void] $_emailLog.Append('</table>')
[Void] $_emailLog.AppendLine()

Write-Log '[DEBUG] sending email'

Send-CustomMailMessage ('Sccm.OsBuild.PostInstall@' + $Env:COMPUTERNAME) 'Sccm.OsBuild.PostInstall' ('Build completed on ' + $Env:COMPUTERNAME) $_emailLog 'deskside@email.com'

Write-Log '[DEBUG] sending email done'
Stop-Transcript
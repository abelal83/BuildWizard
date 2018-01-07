$ErrorActionPreference = 'stop'
Set-PSDebug -Strict

$PSScriptDirectory = (Split-Path $MyInvocation.MyCommand.Path -Parent).ToLower()
Import-Module ($PSScriptDirectory + '\Sccm.OsBuild.Logic.psm1') -Verbose
Import-Module ($PSScriptDirectory + '\Sccm.OsBuild.Data.psm1') -Verbose
$_settingsFileJson = Get-Content ($PSScriptDirectory + '\Sccm.OsBuild.Scripts.Settings.json') -Raw | ConvertFrom-Json

$_smtpServer = $_settingsFileJson.Generic_Settings.SMTP_Server
$_cssStle = $_settingsFileJson.Generic_Settings.CSS_Style
$_emailTo = $_settingsFileJson.Generic_Settings.Email_To

$_sccmOsdReportURL = $_settingsFileJson.Sccm_OsBuild_Failure.SCCMOsdReportURL

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

function Add-EmailTableData($property, $value)
{
	[Void] $_emailLog.Append('<tr>')
	[Void] $_emailLog.AppendLine()

	[Void] $_emailLog.Append('<td>' + $property + '</td>')
	[Void] $_emailLog.AppendLine()
	
	[Void] $_emailLog.Append('<td>' + $value + '</td>')
	[Void] $_emailLog.AppendLine()
	   
	[Void] $_emailLog.Append('</tr>')
	[Void] $_emailLog.AppendLine()
}

$_systemDetails = Get-CustomSystemDetails

$_emailLog = New-Object System.Text.StringBuilder
[Void] $_emailLog.Append('<html><head>' + $_cssStle + '</head><body>')
[Void] $_emailLog.Append('<h2 align="center">Build Failed</h2>')
[Void] $_emailLog.Append('View realtime build report by clicking <a href="' + $_sccmOsdReportURL + $_systemDetails.mac + '">here </a> and review for problems')
[Void] $_emailLog.Append('<br><br>')
[Void] $_emailLog.Append('<table id=#buildresult cellspacing="0" border="0">')
[Void] $_emailLog.AppendLine()
[Void] $_emailLog.Append('<tr>')
[Void] $_emailLog.AppendLine()
[Void] $_emailLog.Append('<td>Property</td>')
[Void] $_emailLog.AppendLine()
[Void] $_emailLog.Append('<td>Value</td>')
[Void] $_emailLog.Append('</tr>')
[Void] $_emailLog.AppendLine()

$_mdtComputerSettings = Get-SccmComputerSettings -macAddress $_systemDetails.Item('mac')

foreach ($property in $_mdtComputerSettings.Table.Columns)
{
	if (($_mdtComputerSettings[$property.ColumnName]) -ne [System.DBNull]::Value)
	{
		Write-Host $property.ColumnName $_mdtComputerSettings[$property.ColumnName]
		
		Add-EmailTableData $property.ColumnName $_mdtComputerSettings[$property.ColumnName]
	}
}

$_appliedRoles = Get-CustomAppliedRoles $_mdtComputerSettings['ID']

foreach ($role in $_appliedRoles)
{
	Add-EmailTableData 'Roles' $role.Role
}	

[Void] $_emailLog.Append('</table>')
[Void] $_emailLog.AppendLine()

Send-CustomMailMessage ('Sccm.OsBuild.Failure@' + $_mdtComputerSettings['OSDComputerName']) 'Sccm.OsBuild.Failure' ('Build FAILED on ' + $_mdtComputerSettings['OSDComputerName']) $_emailLog $_emailTo
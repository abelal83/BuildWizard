# this script should only contain logi needed to modify the UI and to make calls to the osbuild logic module
# we do this to keep a nice layer of seperation between UI, logic and actual data
$ErrorActionPreference = 'stop'
Set-PSDebug -Strict

# enable to true to stop debug messages
$noDebugMessages = $false

$PSScriptDirectory = (Split-Path $MyInvocation.MyCommand.Path -Parent).ToLower()

if ($Host.Version.Major -lt 3)
{
	throw "This script needs at least Powershell v3 minimum."
}

# this function will populate all the controls with values
function Add-ControlValues
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$domains = Get-CustomDomains
	$comboBoxLoginDomains.Items.AddRange($domains)
	
	$computerSites = Get-CustomComputerBuildSites	
	$comboBoxComputerSite.DataSource = New-Object System.Windows.Forms.BindingSource($computerSites, $null)
	$comboBoxComputerSite.DisplayMember = "Key"
	$comboBoxComputerSite.ValueMember = "Value"
	$comboBoxComputerSite.SelectedItem = $null
		
	$computerTypes = Get-CustomComputerTypes
	$comboBoxComputerType.DataSource = New-Object System.Windows.Forms.BindingSource($computerTypes, $null)
	$comboBoxComputerType.DisplayMember = "Key"
	$comboBoxComputerType.ValueMember = "Value"
	$comboBoxComputerType.SelectedItem = $null

	$computerOSs = Get-CustomOperatingSystems
	$comboBoxComputerOS.DataSource = New-Object System.Windows.Forms.BindingSource($computerOSs, $null)
	$comboBoxComputerOS.DisplayMember = "Key"
	$comboBoxComputerOS.ValueMember = "Value"
	$comboBoxComputerOS.SelectedIndex = 1
	
	$comboBoxComputerDomain.Items.AddRange($domains)	
	
	$comboBoxComputerDomain.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxComputerSite.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxComputerType.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxLoginDomains.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxUserName.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxWeekGroup.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxUserComputerRole.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxUserComputerOU.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$comboBoxComputerOS.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	
	$toolTipRoles = New-Object System.Windows.Forms.ToolTip
	$toolTipRoles.SetToolTip($comboBoxUserComputerRole, 'Only roles applicable to this Systems hardware will be displayed')
	$toolTipRoles.SetToolTip($textBoxComputerName, 'You can only generate new name if this computer does not exist in AD. ')
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function Set-ControlState
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$tabPageComputer.Enabled = $false
	$tabPageUser.Enabled = $false
	$comboBoxUserName.Enabled = $false
	#$comboBoxWeekGroup.Enabled = $false
	#$comboBoxUserComputerRole.Enabled = $false
	$buttonComputerNext.Enabled = $false
	$buttonUserNext.Enabled = $false
}

function Enable-ComputerNextButton
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)

	if ($textBoxComputerName.Text -ne '' -and $comboBoxComputerDomain.Text -ne '')
	{
		$buttonComputerNext.Enabled = $true
	}
	else
	{
		$buttonComputerNext.Enabled = $false
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function Enable-UserNextButton
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	if ($comboBoxWeekGroup.Text -ne '' -and $comboBoxUserComputerRole.Text -ne '' -and $comboBoxUserComputerRole.Text -ne '' -and $comboBoxUserComputerOU.Text -ne '' -and $comboBoxComputerOS.Text -ne '')
	{
		$buttonUserNext.Enabled = $true
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function LoginNext_OnClick
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	Write-Verbose 'Attempting to map build drive for authentication...'	
	Connect-CustomBuildDrive -username $textBoxLoginUsername.Text -password $textBoxLoginPassword.Text -domain $comboBoxLoginDomains.Text
	Write-Verbose 'Done!'
			
	Write-Verbose 'Running Enable-ComputerControls...'
	Enable-ComputerTabControls
	Write-Verbose 'Running Enable-ComputerControls done!'
	
	$tabPageComputer.Enabled = $true
		
	$tabControl.SelectedIndex = 1
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function Enable-ComputerTabControls
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
    
	$computerDomain = ''
	
	if ($textBoxComputerName.Text -eq '')
	{
		Write-Verbose 'Getting computer record from AD...'
			
		$textBoxComputerName.Text = Get-CustomADComputerName $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text ([ref] $computerDomain)

	}
	Write-Verbose 'Done!'
	
	if ($textBoxComputerName.Text -ne '')
	{	
		Write-Verbose 'This computer has a name assigned'
		
		Write-Verbose 'Disable all controls as this already has a name assigned'
		$comboBoxComputerSite.Enabled = $false
		$comboBoxComputerType.Enabled = $false		
		$buttonComputerGenerateHostname.Enabled = $false
		
		$buttonComputerDeleteFromAD.Enabled = $true
	}
	else
	{
		Write-Verbose 'Enable all controls as this machine has no record in AD based on netbootGUID'
		$comboBoxComputerSite.Enabled = $true
		$comboBoxComputerType.Enabled = $true		
		$buttonComputerGenerateHostname.Enabled = $true
		
		$buttonComputerDeleteFromAD.Enabled = $false
	}
	
	if ($computerDomain -ne '')
	{
		$comboBoxComputerDomain.SelectedItem = $computerDomain
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function ComputerNext_OnClick
{	
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)

	Write-Host 'Checking hostname availability....'
	Test-Hostname $textBoxComputerName.Text $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text
		
	New-CustomMdtComputer $textBoxComputerName.Text $comboBoxComputerType.SelectedValue
	Write-Verbose 'Done!'
	
	Set-CustomOperatingSystem $comboBoxComputerOS.SelectedItem.Value
	
	Enable-ComputerTabControls

	$weekGroups = Get-CustomWeekGroups $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text $comboBoxComputerDomain.Text $comboBoxComputerDomain.Text
		
	$comboBoxWeekGroup.DataSource = New-Object System.Windows.Forms.BindingSource($weekGroups, $null)
	$comboBoxWeekGroup.DisplayMember = "Value"
	$comboBoxWeekGroup.ValueMember = "Key"
	$comboBoxWeekGroup.SelectedItem = $null
	
	$tabPageUser.Enabled = $true
	
	$computerRoles = Get-CustomMdtComputerRoles
	$comboBoxUserComputerRole.DataSource = New-Object System.Windows.Forms.BindingSource($computerRoles, $null)
	$comboBoxUserComputerRole.DisplayMember = "Value"
	$comboBoxUserComputerRole.ValueMember = "Key"
	$comboBoxUserComputerRole.SelectedItem = $null
	$comboBoxUserComputerRole.SelectedItem = $null	
	
	$computerLocations = Get-CustomLocations $comboBoxComputerDomain.Text
	$comboBoxUserComputerOU.DataSource = New-Object System.Windows.Forms.BindingSource($computerLocations, $null)
	$comboBoxUserComputerOU.DisplayMember = "Key"
	$comboBoxUserComputerOU.ValueMember = "Value"
	$comboBoxUserComputerOU.SelectedItem = $null
	
	$tabControl.SelectedIndex = 2

	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function ComputerGenerateHostname_OnClick()
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$newName = New-CustomComputerName $comboBoxComputerSite.SelectedValue $comboBoxComputerType.SelectedValue $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text
	
	$textBoxComputerName.Text = $newName.ToUpper()
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
		
}

function UserNext_OnClick
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	if ($comboBoxWeekGroup.Text -eq '')
	{
		throw 'Are you mad bro? Why you not select a week group?!'
	}
	
	$buildEngineer = Search-CustomActiveDirectory ('(samaccountname=' + $textBoxLoginUsername.Text + ')') 'Path' $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text $comboBoxLoginDomains.Text

	#Update-CustomMdtRecord $comboBoxWeekGroup.SelectedItem.Key $comboBoxUserName.SelectedItem.Key $textBoxLoginUsername.Text (Get-Date -Format "yyyy-MM-dd HH:mm:ss") $comboBoxComputerDomain.Text $comboBoxUserComputerOU.SelectedItem.Value
	Update-CustomMdtRecord $comboBoxWeekGroup.SelectedItem.Key $comboBoxUserName.SelectedItem.Key ($buildEngineer[0].Path) (Get-Date -Format "yyyy-MM-dd HH:mm:ss") $comboBoxComputerDomain.Text $comboBoxUserComputerOU.SelectedItem.Value
		
	Set-CustomMdtComputerlRole $comboBoxUserComputerRole.Text
	
	Rename-CustomComputer $textBoxComputerName.Text
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
			
	$form.Dispose()
}

function UserSearch_OnClick
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	if ($textBoxUserSearch.Text -ne '')
	{	
		$searchUsers = Get-CustomAdUser $textBoxUserSearch.Text $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text
		$comboBoxUserName.DataSource = New-Object System.Windows.Forms.BindingSource($searchUsers, $null)
		$comboBoxUserName.DisplayMember = "Value"
		$comboBoxUserName.ValueMember = "Key"
		$comboBoxUserName.SelectedItem = $null
		
		$comboBoxUserName.Enabled = $true
	}
	else
	{
		Write-Verbose 'Are you stupid? Why are you searching for no user?'
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function ComputerDeleteFromMdt_OnClick
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	Remove-CustomMdtRecord
	
	Enable-ComputerTabControls
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)	
}

function ComputerDeleteFromAD_OnClick
{
	Write-Verbose ('[DEBUG] Entered function ' + $myInvocation.MyCommand)
	
	$recordFromAd = Get-CustomComputerFromAD $textBoxComputerName.Text $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text
	
	$info = ''
	
	foreach ($item in $recordFromAd.GetEnumerator())
	{
		$info += $item.Key + ': ' + $item.Value + "`r`n`r`n"
	}
	
	$yesOrNo = [System.Windows.Forms.MessageBox]::Show('Are you sure you want to delete this from AD? Please check ALL details before you do so!' + "`r`n`r`n $info", 'Are you DAMN sure?', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Exclamation, [System.Windows.Forms.MessageBoxDefaultButton]::Button2)
	
	if ($yesOrNo -eq 'Yes')
	{
		Remove-CustomComputerFromAD $recordFromAd.adspath $comboBoxLoginDomains.Text $textBoxLoginUsername.Text $textBoxLoginPassword.Text
		
		$textBoxComputerName.Text = ''
	
		Enable-ComputerTabControls
	}
	
	Write-Verbose ('[DEBUG] Exiting function ' + $myInvocation.MyCommand)
}

function global:Write-Verbose
{
	param
	(
		[Parameter(Position = 1)] $Message
	)
	
	if (($Message.ToUpper().StartsWith('[DEBUG]') -and $noDebugMessages))
	{
		return
	}
	
	$textBoxLog.AppendText((Get-Date -Format "yyyy-MM-dd HH:mm:ss") + " " + $Message + "`r`n")
}
$ErrorActionPreference = 'stop'
Set-PSDebug -Strict

$PSScriptDirectory = (Split-Path $MyInvocation.MyCommand.Path -Parent).ToLower()
Import-Module ($PSScriptDirectory + '\Sccm.OsBuild.Logic.psm1') -Verbose
. ($PSScriptDirectory + '\Sccm.OsBuild.Wizard.UI.Logic.ps1') -Verbose

#Generated Form Function
function GenerateForm {
########################################################################
# Code Generated By: SAPIEN Technologies PrimalForms (Community Edition) v1.0.6.0
# Generated On: 17/06/2015 09:47
# Generated By: abelal
########################################################################

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
#endregion

#region Generated Form Objects
$form = New-Object System.Windows.Forms.Form
$label2 = New-Object System.Windows.Forms.Label
$textBoxLog = New-Object System.Windows.Forms.TextBox
$tabControl = New-Object System.Windows.Forms.TabControl
$tabPageLogin = New-Object System.Windows.Forms.TabPage
$buttonLoginNext = New-Object System.Windows.Forms.Button
$comboBoxLoginDomains = New-Object System.Windows.Forms.ComboBox
$labelDomain = New-Object System.Windows.Forms.Label
$textBoxLoginPassword = New-Object System.Windows.Forms.TextBox
$labelPassword = New-Object System.Windows.Forms.Label
$labelUsername = New-Object System.Windows.Forms.Label
$textBoxLoginUsername = New-Object System.Windows.Forms.TextBox
$tabPageComputer = New-Object System.Windows.Forms.TabPage
$labelComputerOS = New-Object System.Windows.Forms.Label
$comboBoxComputerOS = New-Object System.Windows.Forms.ComboBox
$label3 = New-Object System.Windows.Forms.Label
$comboBoxComputerDomain = New-Object System.Windows.Forms.ComboBox
$buttonComputerGenerateHostname = New-Object System.Windows.Forms.Button
$buttonComputerDeleteFromAD = New-Object System.Windows.Forms.Button
$buttonComputerNext = New-Object System.Windows.Forms.Button
$comboBoxComputerType = New-Object System.Windows.Forms.ComboBox
$labelType = New-Object System.Windows.Forms.Label
$labelSite = New-Object System.Windows.Forms.Label
$comboBoxComputerSite = New-Object System.Windows.Forms.ComboBox
$textBoxComputerName = New-Object System.Windows.Forms.TextBox
$labelComputerName = New-Object System.Windows.Forms.Label
$tabPageUser = New-Object System.Windows.Forms.TabPage
$comboBoxUserComputerOU = New-Object System.Windows.Forms.ComboBox
$labelUserOu = New-Object System.Windows.Forms.Label
$comboBoxUserComputerRole = New-Object System.Windows.Forms.ComboBox
$labelUserRole = New-Object System.Windows.Forms.Label
$label1 = New-Object System.Windows.Forms.Label
$comboBoxWeekGroup = New-Object System.Windows.Forms.ComboBox
$buttonUserNext = New-Object System.Windows.Forms.Button
$label5 = New-Object System.Windows.Forms.Label
$comboBoxUserName = New-Object System.Windows.Forms.ComboBox
$buttonUserSearch = New-Object System.Windows.Forms.Button
$textBoxUserSearch = New-Object System.Windows.Forms.TextBox
$labelUserInfo = New-Object System.Windows.Forms.Label
$tabPageHelp = New-Object System.Windows.Forms.TabPage
$label4 = New-Object System.Windows.Forms.Label
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.
$buttonComputerGenerateHostname_OnClick= 
{
	#TODO: Place custom script here
	ComputerGenerateHostname_OnClick
	
	Enable-ComputerNextButton

}

$buttonComputerDeleteFromAD_OnClick= 
{
#TODO: Place custom script here

	ComputerDeleteFromAD_OnClick
	
	Enable-ComputerNextButton

}

$buttonUserSearch_OnClick= 
{
#TODO: Place custom script here
	UserSearch_OnClick
}

$buttonUserNext_OnClick= 
{
#TODO: Place custom script here

	UserNext_OnClick	
}

$buttonLoginNext_OnClick= 
{
#TODO: Place custom script here

	LoginNext_OnClick

}

$buttonComputerNext_OnClick= 
{
#TODO: Place custom script here
	ComputerNext_OnClick
}

$handler_comboBoxComputerDomain_SelectedIndexChanged=
{
	Enable-ComputerNextButton
}

$handler_comboBoxUserComputerRole_SelectedIndexChanged=
{
	Enable-UserNextButton
}

$handler_comboBoxUserName_SelectedIndexChanged=
{
	Enable-UserNextButton
}

$handler_comboBoxUserComputerOU_SelectedIndexChanged= 
{
	Enable-UserNextButton
}

$handler_comboBoxComputerOS_SelectedIndexChanged= 
{
	Enable-UserNextButton
}

$handler_comboBoxWeekGroup_SelectedIndexChanged=
{
	Enable-UserNextButton
}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$form.WindowState = $InitialFormWindowState
	
	Add-ControlValues
	
	Set-ControlState
}

#----------------------------------------------
#region Generated Form Code
$form.Text = "Sccm OS Build Wizard"
$form.Name = "form"
$form.ControlBox = $False
$form.StartPosition = 1
$form.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 849
$System_Drawing_Size.Height = 493
$form.ClientSize = $System_Drawing_Size
$form.FormBorderStyle = 2

$label2.TabIndex = 2
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 18
$label2.Size = $System_Drawing_Size
$label2.Text = "Log"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 459
$System_Drawing_Point.Y = 13
$label2.Location = $System_Drawing_Point
$label2.DataBindings.DefaultDataSourceUpdateMode = 0
$label2.Name = "label2"

$form.Controls.Add($label2)

$textBoxLog.Multiline = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 381
$System_Drawing_Size.Height = 443
$textBoxLog.Size = $System_Drawing_Size
$textBoxLog.DataBindings.DefaultDataSourceUpdateMode = 0
$textBoxLog.ReadOnly = $True
$textBoxLog.Name = "textBoxLog"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 456
$System_Drawing_Point.Y = 34
$textBoxLog.Location = $System_Drawing_Point
$textBoxLog.TabIndex = 1

$form.Controls.Add($textBoxLog)

$tabControl.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 438
$System_Drawing_Size.Height = 469
$tabControl.Size = $System_Drawing_Size
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 12
$System_Drawing_Point.Y = 12
$tabControl.Location = $System_Drawing_Point
$tabControl.DataBindings.DefaultDataSourceUpdateMode = 0
$tabControl.Name = "tabControl"
$tabControl.SelectedIndex = 0

$form.Controls.Add($tabControl)
$tabPageLogin.TabIndex = 0
$tabPageLogin.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 430
$System_Drawing_Size.Height = 443
$tabPageLogin.Size = $System_Drawing_Size
$tabPageLogin.Text = "Login"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 4
$System_Drawing_Point.Y = 22
$tabPageLogin.Location = $System_Drawing_Point
$System_Windows_Forms_Padding = New-Object System.Windows.Forms.Padding
$System_Windows_Forms_Padding.All = 3
$System_Windows_Forms_Padding.Bottom = 3
$System_Windows_Forms_Padding.Left = 3
$System_Windows_Forms_Padding.Right = 3
$System_Windows_Forms_Padding.Top = 3
$tabPageLogin.Padding = $System_Windows_Forms_Padding
$tabPageLogin.Name = "tabPageLogin"
$tabPageLogin.DataBindings.DefaultDataSourceUpdateMode = 0

$tabControl.Controls.Add($tabPageLogin)
$buttonLoginNext.TabIndex = 6
$buttonLoginNext.Name = "buttonLoginNext"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 23
$buttonLoginNext.Size = $System_Drawing_Size
$buttonLoginNext.UseVisualStyleBackColor = $True

$buttonLoginNext.Text = "Next"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 414
$buttonLoginNext.Location = $System_Drawing_Point
$buttonLoginNext.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonLoginNext.add_Click($buttonLoginNext_OnClick)

$tabPageLogin.Controls.Add($buttonLoginNext)

$comboBoxLoginDomains.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 228
$System_Drawing_Size.Height = 21
$comboBoxLoginDomains.Size = $System_Drawing_Size
$comboBoxLoginDomains.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxLoginDomains.Name = "comboBoxLoginDomains"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 200
$comboBoxLoginDomains.Location = $System_Drawing_Point
$comboBoxLoginDomains.TabIndex = 5

$tabPageLogin.Controls.Add($comboBoxLoginDomains)

$labelDomain.TabIndex = 4
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 23
$labelDomain.Size = $System_Drawing_Size
$labelDomain.Text = "Domain"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 174
$labelDomain.Location = $System_Drawing_Point
$labelDomain.DataBindings.DefaultDataSourceUpdateMode = 0
$labelDomain.Name = "labelDomain"

$tabPageLogin.Controls.Add($labelDomain)

$textBoxLoginPassword.PasswordChar = '*'
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 228
$System_Drawing_Size.Height = 20
$textBoxLoginPassword.Size = $System_Drawing_Size
$textBoxLoginPassword.DataBindings.DefaultDataSourceUpdateMode = 0
$textBoxLoginPassword.Name = "textBoxLoginPassword"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 142
$textBoxLoginPassword.Location = $System_Drawing_Point
$textBoxLoginPassword.TabIndex = 3

$tabPageLogin.Controls.Add($textBoxLoginPassword)

$labelPassword.TabIndex = 2
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 23
$labelPassword.Size = $System_Drawing_Size
$labelPassword.Text = "Password"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 116
$labelPassword.Location = $System_Drawing_Point
$labelPassword.DataBindings.DefaultDataSourceUpdateMode = 0
$labelPassword.Name = "labelPassword"

$tabPageLogin.Controls.Add($labelPassword)

$labelUsername.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 23
$labelUsername.Size = $System_Drawing_Size
$labelUsername.Text = "Username"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 58
$labelUsername.Location = $System_Drawing_Point
$labelUsername.DataBindings.DefaultDataSourceUpdateMode = 0
$labelUsername.Name = "labelUsername"

$tabPageLogin.Controls.Add($labelUsername)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 228
$System_Drawing_Size.Height = 20
$textBoxLoginUsername.Size = $System_Drawing_Size
$textBoxLoginUsername.DataBindings.DefaultDataSourceUpdateMode = 0
$textBoxLoginUsername.Name = "textBoxLoginUsername"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 84
$textBoxLoginUsername.Location = $System_Drawing_Point
$textBoxLoginUsername.TabIndex = 1

$tabPageLogin.Controls.Add($textBoxLoginUsername)


$tabPageComputer.TabIndex = 1
$tabPageComputer.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 430
$System_Drawing_Size.Height = 443
$tabPageComputer.Size = $System_Drawing_Size
$tabPageComputer.Text = "Computer"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 4
$System_Drawing_Point.Y = 22
$tabPageComputer.Location = $System_Drawing_Point
$System_Windows_Forms_Padding = New-Object System.Windows.Forms.Padding
$System_Windows_Forms_Padding.All = 3
$System_Windows_Forms_Padding.Bottom = 3
$System_Windows_Forms_Padding.Left = 3
$System_Windows_Forms_Padding.Right = 3
$System_Windows_Forms_Padding.Top = 3
$tabPageComputer.Padding = $System_Windows_Forms_Padding
$tabPageComputer.Name = "tabPageComputer"
$tabPageComputer.DataBindings.DefaultDataSourceUpdateMode = 0

$tabControl.Controls.Add($tabPageComputer)
$labelComputerOS.TabIndex = 9
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 170
$System_Drawing_Size.Height = 17
$labelComputerOS.Size = $System_Drawing_Size
$labelComputerOS.Text = "Select Operating System"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 335
$labelComputerOS.Location = $System_Drawing_Point
$labelComputerOS.DataBindings.DefaultDataSourceUpdateMode = 0
$labelComputerOS.Name = "labelComputerOS"

$tabPageComputer.Controls.Add($labelComputerOS)

$comboBoxComputerOS.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 234
$System_Drawing_Size.Height = 21
$comboBoxComputerOS.Size = $System_Drawing_Size
$comboBoxComputerOS.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxComputerOS.Name = "comboBoxComputerOS"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 356
$comboBoxComputerOS.Location = $System_Drawing_Point
$comboBoxComputerOS.TabIndex = 7
$comboBoxComputerOS.add_SelectedIndexChanged($handler_comboBoxComputerOS_SelectedIndexChanged)

$tabPageComputer.Controls.Add($comboBoxComputerOS)

$label3.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 16
$label3.Size = $System_Drawing_Size
$label3.Text = "Domain"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 120
$label3.Location = $System_Drawing_Point
$label3.DataBindings.DefaultDataSourceUpdateMode = 0
$label3.Name = "label3"

$tabPageComputer.Controls.Add($label3)

$comboBoxComputerDomain.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 231
$System_Drawing_Size.Height = 21
$comboBoxComputerDomain.Size = $System_Drawing_Size
$comboBoxComputerDomain.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxComputerDomain.Name = "comboBoxComputerDomain"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 139
$comboBoxComputerDomain.Location = $System_Drawing_Point
$comboBoxComputerDomain.TabIndex = 3
$comboBoxComputerDomain.add_SelectedIndexChanged($handler_comboBoxComputerDomain_SelectedIndexChanged)

$tabPageComputer.Controls.Add($comboBoxComputerDomain)

$buttonComputerGenerateHostname.TabIndex = 6
$buttonComputerGenerateHostname.Name = "buttonComputerGenerateHostname"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 134
$System_Drawing_Size.Height = 23
$buttonComputerGenerateHostname.Size = $System_Drawing_Size
$buttonComputerGenerateHostname.UseVisualStyleBackColor = $True

$buttonComputerGenerateHostname.Text = "Generate Hostname"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 294
$buttonComputerGenerateHostname.Location = $System_Drawing_Point
$buttonComputerGenerateHostname.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonComputerGenerateHostname.add_Click($buttonComputerGenerateHostname_OnClick)

$tabPageComputer.Controls.Add($buttonComputerGenerateHostname)

$buttonComputerDeleteFromAD.TabIndex = 2
$buttonComputerDeleteFromAD.Name = "buttonComputerDeleteFromAD"
$buttonComputerDeleteFromAD.Enabled = $False
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 129
$System_Drawing_Size.Height = 23
$buttonComputerDeleteFromAD.Size = $System_Drawing_Size
$buttonComputerDeleteFromAD.UseVisualStyleBackColor = $True

$buttonComputerDeleteFromAD.Text = "Delete record from AD"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 154
$System_Drawing_Point.Y = 82
$buttonComputerDeleteFromAD.Location = $System_Drawing_Point
$buttonComputerDeleteFromAD.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonComputerDeleteFromAD.add_Click($buttonComputerDeleteFromAD_OnClick)

$tabPageComputer.Controls.Add($buttonComputerDeleteFromAD)

$buttonComputerNext.TabIndex = 8
$buttonComputerNext.Name = "buttonComputerNext"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 23
$buttonComputerNext.Size = $System_Drawing_Size
$buttonComputerNext.UseVisualStyleBackColor = $True

$buttonComputerNext.Text = "Next"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 414
$buttonComputerNext.Location = $System_Drawing_Point
$buttonComputerNext.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonComputerNext.add_Click($buttonComputerNext_OnClick)

$tabPageComputer.Controls.Add($buttonComputerNext)

$comboBoxComputerType.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 234
$System_Drawing_Size.Height = 21
$comboBoxComputerType.Size = $System_Drawing_Size
$comboBoxComputerType.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxComputerType.Name = "comboBoxComputerType"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 200
$comboBoxComputerType.Location = $System_Drawing_Point
$comboBoxComputerType.TabIndex = 4

$tabPageComputer.Controls.Add($comboBoxComputerType)

$labelType.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 248
$System_Drawing_Size.Height = 23
$labelType.Size = $System_Drawing_Size
$labelType.Text = "Type (only valid if this machine doesn''t exist in AD)"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 174
$labelType.Location = $System_Drawing_Point
$labelType.DataBindings.DefaultDataSourceUpdateMode = 0
$labelType.Name = "labelType"

$tabPageComputer.Controls.Add($labelType)

$labelSite.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 248
$System_Drawing_Size.Height = 23
$labelSite.Size = $System_Drawing_Size
$labelSite.Text = "Site (only valid if this machine doesn''t exist in AD)"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 236
$labelSite.Location = $System_Drawing_Point
$labelSite.DataBindings.DefaultDataSourceUpdateMode = 0
$labelSite.Name = "labelSite"

$tabPageComputer.Controls.Add($labelSite)

$comboBoxComputerSite.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 234
$System_Drawing_Size.Height = 21
$comboBoxComputerSite.Size = $System_Drawing_Size
$comboBoxComputerSite.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxComputerSite.Name = "comboBoxComputerSite"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 262
$comboBoxComputerSite.Location = $System_Drawing_Point
$comboBoxComputerSite.TabIndex = 5

$tabPageComputer.Controls.Add($comboBoxComputerSite)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 20
$textBoxComputerName.Size = $System_Drawing_Size
$textBoxComputerName.DataBindings.DefaultDataSourceUpdateMode = 0
$textBoxComputerName.Name = "textBoxComputerName"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 85
$textBoxComputerName.Location = $System_Drawing_Point
$textBoxComputerName.TabIndex = 1

$tabPageComputer.Controls.Add($textBoxComputerName)

$labelComputerName.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 100
$System_Drawing_Size.Height = 12
$labelComputerName.Size = $System_Drawing_Size
$labelComputerName.Text = "Computer Name"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 58
$labelComputerName.Location = $System_Drawing_Point
$labelComputerName.DataBindings.DefaultDataSourceUpdateMode = 0
$labelComputerName.Name = "labelComputerName"

$tabPageComputer.Controls.Add($labelComputerName)


$tabPageUser.TabIndex = 3
$tabPageUser.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 430
$System_Drawing_Size.Height = 443
$tabPageUser.Size = $System_Drawing_Size
$tabPageUser.Text = "User"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 4
$System_Drawing_Point.Y = 22
$tabPageUser.Location = $System_Drawing_Point
$tabPageUser.Name = "tabPageUser"
$tabPageUser.DataBindings.DefaultDataSourceUpdateMode = 0

$tabControl.Controls.Add($tabPageUser)
$comboBoxUserComputerOU.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 234
$System_Drawing_Size.Height = 21
$comboBoxUserComputerOU.Size = $System_Drawing_Size
$comboBoxUserComputerOU.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxUserComputerOU.Name = "comboBoxUserComputerOU"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 334
$comboBoxUserComputerOU.Location = $System_Drawing_Point
$comboBoxUserComputerOU.TabIndex = 6
$comboBoxUserComputerOU.add_SelectedIndexChanged($handler_comboBoxUserComputerOU_SelectedIndexChanged)

$tabPageUser.Controls.Add($comboBoxUserComputerOU)

$labelUserOu.TabIndex = 7
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 150
$System_Drawing_Size.Height = 23
$labelUserOu.Size = $System_Drawing_Size
$labelUserOu.Text = "Select the OU for machine"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 307
$labelUserOu.Location = $System_Drawing_Point
$labelUserOu.DataBindings.DefaultDataSourceUpdateMode = 0
$labelUserOu.Name = "labelUserOu"

$tabPageUser.Controls.Add($labelUserOu)

$comboBoxUserComputerRole.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 234
$System_Drawing_Size.Height = 21
$comboBoxUserComputerRole.Size = $System_Drawing_Size
$comboBoxUserComputerRole.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxUserComputerRole.Name = "comboBoxUserComputerRole"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 275
$comboBoxUserComputerRole.Location = $System_Drawing_Point
$comboBoxUserComputerRole.Sorted = $True
$comboBoxUserComputerRole.TabIndex = 5
$comboBoxUserComputerRole.add_SelectedIndexChanged($handler_comboBoxUserComputerRole_SelectedIndexChanged)

$tabPageUser.Controls.Add($comboBoxUserComputerRole)

$labelUserRole.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 126
$System_Drawing_Size.Height = 23
$labelUserRole.Size = $System_Drawing_Size
$labelUserRole.Text = "Select role for machine"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 248
$labelUserRole.Location = $System_Drawing_Point
$labelUserRole.DataBindings.DefaultDataSourceUpdateMode = 0
$labelUserRole.Name = "labelUserRole"

$tabPageUser.Controls.Add($labelUserRole)

$label1.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 207
$System_Drawing_Size.Height = 23
$label1.Size = $System_Drawing_Size
$label1.Text = "Select week group for machine"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 184
$label1.Location = $System_Drawing_Point
$label1.DataBindings.DefaultDataSourceUpdateMode = 0
$label1.Name = "label1"

$tabPageUser.Controls.Add($label1)

$comboBoxWeekGroup.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 234
$System_Drawing_Size.Height = 21
$comboBoxWeekGroup.Size = $System_Drawing_Size
$comboBoxWeekGroup.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxWeekGroup.Name = "comboBoxWeekGroup"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 210
$comboBoxWeekGroup.Location = $System_Drawing_Point
$comboBoxWeekGroup.TabIndex = 4
$comboBoxWeekGroup.add_SelectedIndexChanged($handler_comboBoxWeekGroup_SelectedIndexChanged)

$tabPageUser.Controls.Add($comboBoxWeekGroup)

$buttonUserNext.TabIndex = 7
$buttonUserNext.Name = "buttonUserNext"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 75
$System_Drawing_Size.Height = 23
$buttonUserNext.Size = $System_Drawing_Size
$buttonUserNext.UseVisualStyleBackColor = $True

$buttonUserNext.Text = "Next"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 35
$System_Drawing_Point.Y = 414
$buttonUserNext.Location = $System_Drawing_Point
$buttonUserNext.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonUserNext.add_Click($buttonUserNext_OnClick)

$tabPageUser.Controls.Add($buttonUserNext)

$label5.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 244
$System_Drawing_Size.Height = 23
$label5.Size = $System_Drawing_Size
$label5.Text = "Select user after searching above"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 121
$label5.Location = $System_Drawing_Point
$label5.DataBindings.DefaultDataSourceUpdateMode = 0
$label5.Name = "label5"

$tabPageUser.Controls.Add($label5)

$comboBoxUserName.FormattingEnabled = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 232
$System_Drawing_Size.Height = 21
$comboBoxUserName.Size = $System_Drawing_Size
$comboBoxUserName.DataBindings.DefaultDataSourceUpdateMode = 0
$comboBoxUserName.Name = "comboBoxUserName"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 147
$comboBoxUserName.Location = $System_Drawing_Point
$comboBoxUserName.TabIndex = 3
$comboBoxUserName.add_SelectedIndexChanged($handler_comboBoxUserName_SelectedIndexChanged)

$tabPageUser.Controls.Add($comboBoxUserName)

$buttonUserSearch.TabIndex = 2
$buttonUserSearch.Name = "buttonUserSearch"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 102
$System_Drawing_Size.Height = 23
$buttonUserSearch.Size = $System_Drawing_Size
$buttonUserSearch.UseVisualStyleBackColor = $True

$buttonUserSearch.Text = "Search"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 168
$System_Drawing_Point.Y = 84
$buttonUserSearch.Location = $System_Drawing_Point
$buttonUserSearch.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonUserSearch.add_Click($buttonUserSearch_OnClick)

$tabPageUser.Controls.Add($buttonUserSearch)

$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 126
$System_Drawing_Size.Height = 20
$textBoxUserSearch.Size = $System_Drawing_Size
$textBoxUserSearch.DataBindings.DefaultDataSourceUpdateMode = 0
$textBoxUserSearch.Name = "textBoxUserSearch"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 36
$System_Drawing_Point.Y = 86
$textBoxUserSearch.Location = $System_Drawing_Point
$textBoxUserSearch.TabIndex = 1

$tabPageUser.Controls.Add($textBoxUserSearch)

$labelUserInfo.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 218
$System_Drawing_Size.Height = 23
$labelUserInfo.Size = $System_Drawing_Size
$labelUserInfo.Text = "Who is this computer being built for?"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 34
$System_Drawing_Point.Y = 57
$labelUserInfo.Location = $System_Drawing_Point
$labelUserInfo.DataBindings.DefaultDataSourceUpdateMode = 0
$labelUserInfo.Name = "labelUserInfo"

$tabPageUser.Controls.Add($labelUserInfo)


$tabPageHelp.TabIndex = 2
$tabPageHelp.UseVisualStyleBackColor = $True
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 430
$System_Drawing_Size.Height = 443
$tabPageHelp.Size = $System_Drawing_Size
$tabPageHelp.Text = "Help"
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 4
$System_Drawing_Point.Y = 22
$tabPageHelp.Location = $System_Drawing_Point
$tabPageHelp.Name = "tabPageHelp"
$tabPageHelp.DataBindings.DefaultDataSourceUpdateMode = 0

$tabControl.Controls.Add($tabPageHelp)
$label4.TabIndex = 0
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Width = 391
$System_Drawing_Size.Height = 213
$label4.Size = $System_Drawing_Size
$label4.Text = "If you need help, go find another job!"

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 21
$System_Drawing_Point.Y = 19
$label4.Location = $System_Drawing_Point
$label4.DataBindings.DefaultDataSourceUpdateMode = 0
$label4.Name = "label4"

$tabPageHelp.Controls.Add($label4)



#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $form.WindowState
#Init the OnLoad event to correct the initial state of the form
$form.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$form.ShowDialog()| Out-Null

} #End Function

#Call the Function
GenerateForm

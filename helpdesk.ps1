# This script uses the template provided by Damien Van Robaeys that is at https://www.systanddeploy.com/2019/09/buld-powershell-systray-tool-with-sub.html.
# Additions by @4D5A.

# Part used for the restart button
Param
 (
 [String]$Restart
 )
 
If ($Restart -ne "") 
 {
  Start-Sleep 10
 }

Function Get-InterfaceIndex {
    $global:InterfaceIndex = (Get-NetRoute "0.0.0.0/0").InterfaceIndex
}
Function Get-DnsServers {
    Get-InterfaceIndex
    $global:DNSServers = (Get-DNSClientServerAddress -InterfaceIndex $global:InterfaceIndex -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses | Out-String)
}

Function Reset-DnsServerAddresses {
    Get-InterfaceIndex
    Set-DnsClientServerAddress -InterfaceIndex $global:InterfaceIndex -ResetServerAddresses
}

Function UsePublicDnsServers {
    Get-InterfaceIndex
    Set-DnsClientServerAddress -InterfaceIndex $global:InterfaceIndex -ServerAddresses ("8.8.8.8","8.8.4.4")
}

Function Test-DnsClientResolution {
    $global:DNSResolution = (Resolve-DnsName -Name www.google.com -Type A | Select-Object Name, IPAddress | Out-String)
}

Function Test-ClientConnection {
    $global:ClientConnectionResponse = (Test-Connection -TargetName 8.8.8.8 -IPv4)
}

Function Get-PublicIP {
    $global:publicipaddress = (Invoke-WebRequest -URI "http://ipinfo.io/ip".Content)
}

Function Get-Username {
    $global:username = ($env:USERNAME)
}


Function Get-NetworkAdapterSettings {
    $networkAdapterSettingsReport = "$env:USERPROFILE\Desktop\networkAdapterSettingsReport.txt"
    $networkAdapterSettings = (Get-NetAdapter -Name * -IncludeHidden | Format-List -Property * | Out-String)
    Set-Content -Path "$networkAdapterSettingsReport" -Value $networkAdapterSettings
    notepad.exe $networkAdapterSettingsReport
}

Function Get-ArpData {
    $global:ArpData = (Get-NetNeighbor)
}

# Declare assemblies 
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')    | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework')   | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing')    | out-null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null
 
# Example of GUI to display
[xml]$xaml =  
@"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
WindowStyle="None"
Height="600"
Width="400"
ResizeMode="NoResize"
ShowInTaskbar="False"
AllowsTransparency="True"
Background="Transparent"
>
<border  BorderBrush="Black" BorderThickness="1" Margin="10,10,10,10">
 
<grid Name="grid" Background="White">
 <stackpanel HorizontalAlignment="Center" VerticalAlignment="Center">
  <button Name="MyButton" Width="80" Height="20"></button>
 </StackPanel>  
</Grid> 
</Border>
</Window>
"@
 
# GUI to load
$window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $xaml))
# Declare controls here
$MyButton = $window.findname("MyButton") 
$MyButton.Content = "Button 1"
 
# Add an icon to the systrauy button
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\mmc.exe")
 
# Create object for the systray 
$Systray_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
# Text displayed when you pass the mouse over the systray icon
$Systray_Tool_Icon.Text = "My sytray tool"
# Systray icon
$Systray_Tool_Icon.Icon = $icon
$Systray_Tool_Icon.Visible = $true
 
# First menu displayed in the Context menu
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $SecurityModeData = "User"
}
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $SecurityModeData = "Admin"
}
$Menu1 = New-Object System.Windows.Forms.MenuItem
$Menu1.Text = "Started in $SecurityModeData mode."
 
# Second menu displayed in the Context menu
$Menu2 = New-Object System.Windows.Forms.MenuItem
$Menu2.Text = "Network Tools"

# Third menu displayed in the Context menu
$Menu3 = New-Object System.Windows.Forms.MenuItem
$Menu3.Text = "Special Tools"
 
# Fourth menu displayed in the Context menu - This will restart kill the systray tool and launched it again in 10 seconds
$Menu_Restart_Tool = New-Object System.Windows.Forms.MenuItem
$Menu_Restart_Tool.Text = "Restart the tool"

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Fifth menu displayed in the Context menu - This will restart kill the systray tool and launched it again in 10 seconds
    $Menu_Restart_Tool_As_Admin = New-Object System.Windows.Forms.MenuItem
    $Menu_Restart_Tool_As_Admin.Text = "Restart the tool as admin"
}
 
# Sixth menu displayed in the Context menu - This will close the systray tool
$Menu_Exit = New-Object System.Windows.Forms.MenuItem
$Menu_Exit.Text = "Exit"
 
# Create the context menu for all menus above
$contextmenu = New-Object System.Windows.Forms.ContextMenu
$Systray_Tool_Icon.ContextMenu = $contextmenu
$Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu1)
$Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu2)
$Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu3)
$Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Restart_Tool)
$Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Restart_Tool_As_Admin)
$Systray_Tool_Icon.contextMenu.MenuItems.AddRange($Menu_Exit)
 
# Create submenu for the menu 2
$Menu2_SubMenu1 = $Menu2.MenuItems.Add("Get DNS")
$Menu2_SubMenu2 = $Menu2.MenuItems.Add("Test DNS")
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Menu2_SubMenu3 = $Menu2.MenuItems.Add("Reset DNS server addresses")
}
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Menu2_SubMenu4 = $Menu2.MenuItems.Add("Use Public DNS")
}
$Menu2_SubMenu5 = $Menu2.MenuItems.Add("Flush DNS")
$Menu2_SubMenu6 = $Menu2.MenuItems.Add("Ping Google")
$Menu2_SubMenu7 = $Menu2.MenuItems.Add("Renew IP Address")
$Menu2_SubMenu8 = $Menu2.MenuItems.Add("Get Public IP")
$Menu2_SubMenu9 = $Menu2.MenuItems.Add("Get Username")

# Create submenu for the menu 3
$Menu3_SubMenu1 = $Menu3.MenuItems.Add("Get Network Adapter Settings")
$Menu3_SubMenu2 = $Menu3.MenuItems.Add("Get Network Interface Settings")
#$Menu3_SubMenu3 = $Menu3.MenuItems.Add("Get ARP Data")
#$Menu3_SubMenu4 = $Menu3.MenuItems.Add("Get DNS Cache")
#$Menu3_SubMenu5 = $Menu3.MenuItems.Add("Get Winsock")
#$Menu3_SubMenu6 = $Menu3.MenuItems.Add("Get Traceroute")
#$Menu3_SubMenu7 = $Menu3.MenuItems.Add("Renew IP Address")
 
 
 
 
# Action after clicking on the systray icon - This will display the GUI mentioned above
$Systray_Tool_Icon.Add_Click({
 If ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
  $window.Left = $([System.Windows.SystemParameters]::WorkArea.Width-$window.Width)
  $window.Top = $([System.Windows.SystemParameters]::WorkArea.Height-$window.Height)
  $window.Show()
  $window.Activate() 
 }  
})
 
# Action after clicking on the Menu 2 - Submenu 1
$Menu2_SubMenu1.Add_Click({
    Get-DnsServers
 [System.Windows.Forms.MessageBox]::Show($global:DNSServers)
})
 
# Action after clicking on the Menu 2 - Submenu 2
$Menu2_SubMenu2.Add_Click({
    Test-DnsClientResolution
 [System.Windows.Forms.MessageBox]::Show("$global:DNSResolution")
})

# Action after clicking on the Menu 2 - Submenu 3
$Menu2_SubMenu3.Add_Click({ 
    Reset-DnsServerAddresses
    Get-DnsServers
 [System.Windows.Forms.MessageBox]::Show("Your Dns servers have been set as $global:DNSServers")
})

# Action after clicking on the Menu 2 - Submenu 4
$Menu2_SubMenu4.Add_Click({ 
    UsePublicDnsServers
    Get-DnsServers
 [System.Windows.Forms.MessageBox]::Show("Your Dns servers have been set as $global:DNSServers")
})

# Action after clicking on the Menu 2 - Submenu 5
$Menu2_SubMenu5.Add_Click({ 
    Clear-DnsClientCache
 [System.Windows.Forms.MessageBox]::Show("The cache was cleared.")
})

# Action after clicking on the Menu 2 - Submenu 6
$Menu2_SubMenu6.Add_Click({ 
    Test-ClientConnection
 [System.Windows.Forms.MessageBox]::Show("$global:ClientConnectionResponse")
})

# Action after clicking on the Menu 2 - Submenu 7
$Menu2_SubMenu7.Add_Click({ 
 [System.Windows.Forms.MessageBox]::Show("Menu 2 - Submenu 2")
})

# Action after clicking on the Menu 2 - Submenu 8
$Menu2_SubMenu8.Add_Click({ 
    Get-PublicIP
 [System.Windows.Forms.MessageBox]::Show("$global:publicipaddress")
})

# Action after clicking on the Menu 2 - Submenu 9
$Menu2_SubMenu9.Add_Click({ 
    Get-User
 [System.Windows.Forms.MessageBox]::Show("$global:username")
})

# Action after clicking on the Menu 3 - Submenu 1
$Menu3_SubMenu1.Add_Click({
    Get-NetworkAdapterSettings
})

# Action after clicking on the Menu 3 - Submenu 2
$Menu3_SubMenu2.Add_Click({
    Get-ArpData
 [System.Windows.Forms.MessageBox]::Show($global:ArpData)
})
 
 
# When Restart the tool is clicked, close everything and kill the PowerShell process then open again the tool
$Menu_Restart_Tool.add_Click({
 $Restart = "Yes"
 Start-Process -WindowStyle hidden powershell.exe ".\helpdesk.ps1 '$Restart'"  
 
 $MDTMonitoring_Icon.Visible = $false
 $window.Close()
 # $window_Config.Close() 
 Stop-Process $pid
  
 $Global:Timer_Status = $timer.Enabled
 If ($Timer_Status -eq $true)
  {
   $timer.Stop() 
  }  
 })

 # When Restart the tool is clicked, close everything and kill the PowerShell process then open again the tool
    $Menu_Restart_Tool_As_Admin.add_Click({
    $Restart = "Yes"
    Start-Process -WindowStyle hidden powershell.exe -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`"";

    $MDTMonitoring_Icon.Visible = $false
    $window.Close()
    # $window_Config.Close() 
    Stop-Process $pid
        
    $Global:Timer_Status = $timer.Enabled
    If ($Timer_Status -eq $true)
        {
        $timer.Stop() 
        }  
    })
 
# When Exit is clicked, close everything and kill the PowerShell process
$Menu_Exit.add_Click({
 $Systray_Tool_Icon.Visible = $false
 $window.Close()
 # $window_Config.Close() 
 Stop-Process $pid
  
 $Global:Timer_Status = $timer.Enabled
 If ($Timer_Status -eq $true)
  {
   $timer.Stop() 
  } 
 })
  
  
# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)
 
# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()
 
# Create an application context for it to all run within.
# This helps with responsiveness, especially when clicking Exit.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)

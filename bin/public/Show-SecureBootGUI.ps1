function Show-SecureBootGUI {
    <#
    .SYNOPSIS
        Displays a WPF-based graphical interface for Secure Boot 2026 certificate management
    
    .DESCRIPTION
        Launches a modern, user-friendly GUI for managing Windows Secure Boot 2026
        certificate updates. The interface provides real-time status monitoring,
        interactive update configuration, and detailed execution logging.
        
        Features:
        - Three-tab interface: Status Overview, Update Configuration, Execution Log
        - Real-time certificate status display with color coding
        - Migration analysis for KEK, DB Windows, and DB MS UEFI certificates
        - Servicing status with AvailableUpdates bit decoding
        - Interactive update controls (Manual/CFR modes)
        - High Confidence Bucket opt-out option
        - Company branding with experience4you logo
        - Support contact integration (support@experience4you.de)
        - Automatic Secure Boot disabled detection and warnings
        
        The GUI uses the centralized Get-SecureBootData function for all data
        collection, maintaining clean architecture and code reusability.
    
    .EXAMPLE
        Show-SecureBootGUI
        
        Launches the Secure Boot certificate management GUI
    
    .INPUTS
        None
        This function does not accept pipeline input
    
    .OUTPUTS
        None
        Displays interactive WPF window
    
    .NOTES
        File Name      : Show-SecureBootGUI.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, .NET Framework 4.5+, Administrator rights
        Copyright 2026 - experience4you GmbH
        
        UI Framework   : Windows Presentation Foundation (WPF)
        Color Scheme   : CI Colors (#ff8700 orange, #383b47 dark gray)
        Dependencies   : Get-SecureBootData, Set-SecureBootUpdates
    
    .LICENSE
        MIT License
        
        Copyright (c) 2026 experience4you GmbH
        
        Permission is hereby granted, free of charge, to any person obtaining a copy
        of this software and associated documentation files (the "Software"), to deal
        in the Software without restriction, including without limitation the rights
        to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
        copies of the Software, and to permit persons to whom the Software is
        furnished to do so, subject to the following conditions:
        
        The above copyright notice and this permission notice shall be included in all
        copies or substantial portions of the Software.
        
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
        IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
        FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
        AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
        LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
        OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
        SOFTWARE.
    #>
    
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Windows.Forms

    # XAML Definition
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Secure Boot 2026 - Certificate Update Manager" 
        Height="800" Width="1000" 
        WindowStartupLocation="CenterScreen"
        Background="#383b47">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#ff8700"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#cc6d00"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="20,8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border Name="Border" Background="#4a4d5a" BorderThickness="0" CornerRadius="5,5,0,0" Margin="2,0">
                            <ContentPresenter x:Name="ContentSite" 
                                            VerticalAlignment="Center" 
                                            HorizontalAlignment="Center"
                                            ContentSource="Header" 
                                            Margin="20,8"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter TargetName="Border" Property="Background" Value="#ff8700"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Setter Property="Foreground" Value="White"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#ff8700"/>
            <Setter Property="BorderBrush" Value="#ff8700"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Margin" Value="5"/>
            <Setter Property="Padding" Value="10"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="3"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Margin" Value="5"/>
        </Style>
    </Window.Resources>
    
    <Grid Margin="10">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <!-- Header -->
        <Border Grid.Row="0" Background="#ff8700" CornerRadius="5" Padding="15" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Secure Boot 2026 Certificate Update Manager" FontSize="24" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Name="txtDeviceInfo" FontSize="12" Foreground="White" Margin="0,5,0,0"/>
                    <TextBlock Name="txtSecureBootStatus" FontSize="12" Foreground="White" FontWeight="Bold"/>
                </StackPanel>
                
                <Image Grid.Column="1" Name="imgLogo" 
                       Height="45" 
                       VerticalAlignment="Top" 
                       HorizontalAlignment="Right"
                       Margin="10,0,0,0"/>
            </Grid>
        </Border>
        
        <!-- Main Content Tabs -->
        <TabControl Grid.Row="1" Background="#4a4d5a" BorderThickness="0">
            <!-- Status Tab -->
            <TabItem Header="Status Overview">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="10">
                        <!-- KEK Certificates -->
                        <GroupBox Header="KEK Certificates">
                            <StackPanel Name="pnlKEKCerts"/>
                        </GroupBox>
                        
                        <!-- DB Certificates -->
                        <GroupBox Header="DB Certificates">
                            <StackPanel Name="pnlDBCerts"/>
                        </GroupBox>
                        
                        <!-- Analysis -->
                        <GroupBox Header="Migration Analysis">
                            <StackPanel Name="pnlAnalysis"/>
                        </GroupBox>
                        
                        <!-- Servicing Status -->
                        <GroupBox Header="Servicing Status">
                            <StackPanel Name="pnlServicing"/>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Update Tab -->
            <TabItem Header="Update Configuration">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="20">
                        <TextBlock Text="Choose Update Method:" FontSize="16" FontWeight="Bold" Margin="0,0,0,10"/>
                        
                        <RadioButton Name="rbManual" Content="Manual Update (Recommended)" IsChecked="True" FontSize="14"/>
                        <TextBlock Text="   → Sets registry bits immediately and triggers scheduled task" 
                                   FontSize="11" Foreground="#cccccc" Margin="25,0,0,10"/>
                        
                        <RadioButton Name="rbCFR" Content="Controlled Feature Rollout (CFR)" FontSize="14"/>
                        <TextBlock Text="   → Lets Windows Update manage deployment automatically" 
                                   FontSize="11" Foreground="#cccccc" Margin="25,0,0,20"/>
                        
                        <Separator Background="#ff8700" Height="2" Margin="0,10"/>
                        
                        <TextBlock Text="Additional Options:" FontSize="16" FontWeight="Bold" Margin="0,10,0,10"/>
                        
                        <CheckBox Name="chkHighConfidence" Content="Opt-out of High Confidence Bucket auto-updates" 
                                  FontSize="13"/>
                        <TextBlock Text="   (Prevents automatic high confidence updates)" 
                                   FontSize="11" Foreground="#cccccc" Margin="25,0,0,20"/>
                        
                        <Separator Background="#ff8700" Height="2" Margin="0,10"/>
                        
                        <TextBlock Name="txtUpdateStatus" FontSize="13" Foreground="#ff8700" 
                                   FontWeight="Bold" Margin="0,10" TextWrapping="Wrap"/>
                        
                        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,20,0,0">
                            <Button Name="btnApplyUpdate" Content="Apply Update" Width="150" Height="40" FontSize="14"/>
                            <Button Name="btnRefresh" Content="Refresh Status" Width="150" Height="40" FontSize="14"/>
                        </StackPanel>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            
            <!-- Log Tab -->
            <TabItem Header="Execution Log">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    
                    <TextBox Name="txtLog" Grid.Row="0" 
                             Background="#2a2d38" Foreground="White" 
                             FontFamily="Consolas" FontSize="11"
                             IsReadOnly="True" VerticalScrollBarVisibility="Auto"
                             TextWrapping="Wrap" Margin="10"/>
                    
                    <Button Name="btnClearLog" Grid.Row="1" Content="Clear Log" 
                            Width="120" HorizontalAlignment="Right" Margin="10"/>
                </Grid>
            </TabItem>
        </TabControl>
        
        <!-- Footer -->
        <Border Grid.Row="2" Background="#2a2d38" CornerRadius="5" Padding="10" Margin="0,10,0,0">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                
                <StackPanel Grid.Column="0" Orientation="Horizontal">
                    <TextBlock Text="Status: " FontWeight="Bold"/>
                    <TextBlock Name="txtStatusBar" Text="Ready" Foreground="#ff8700"/>
                </StackPanel>
                
                <StackPanel Grid.Column="1" Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Center">
                    <TextBlock Text="Need help? Contact us: " Foreground="#aaaaaa" FontSize="11" VerticalAlignment="Center"/>
                    <TextBlock Name="txtSupportEmail" Text="support@experience4you.de" 
                               Foreground="#ff8700" FontSize="11" 
                               TextDecorations="Underline" 
                               Cursor="Hand"
                               VerticalAlignment="Center"/>
                </StackPanel>
                
                <Button Name="btnClose" Grid.Column="2" Content="Close" Width="100"/>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    # Load XAML
    $reader = New-Object System.Xml.XmlNodeReader $xaml
    $window = [Windows.Markup.XamlReader]::Load($reader)

    # Get controls
    $controls = @{}
    $xaml.SelectNodes("//*[@Name]") | ForEach-Object {
        $controls[$_.Name] = $window.FindName($_.Name)
    }

    # Helper function to add log entry
    function Add-LogEntry {
        param([string]$Message, [string]$Type = "Info")
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        $prefix = switch($Type) {
            "Success" { "[+]" }
            "Error"   { "[x]" }
            "Warning" { "[!]" }
            default   { "[i]" }
        }
        
        $controls.txtLog.AppendText("$timestamp $prefix $Message`r`n")
        $controls.txtLog.ScrollToEnd()
    }

    # Helper function to add status item
    function Add-StatusItem {
        param(
            [System.Windows.Controls.Panel]$Panel,
            [string]$Text,
            [string]$Color = "White"
        )
        
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = $Text
        $tb.Foreground = $Color
        $tb.Margin = "5,2"
        $tb.FontSize = 12
        $Panel.Children.Add($tb) | Out-Null
    }

    # Function to load and display status
    function Update-StatusDisplay {
        param([switch]$ShowLog)
        
        try {
            if($ShowLog) { Add-LogEntry "Loading system status..." }
            $controls.txtStatusBar.Text = "Loading..."
            
            # Get centralized data
            $data = Get-SecureBootData
            
            # Update device info
            $controls.txtDeviceInfo.Text = "Computer: $($data.Device.Computer) | $($data.Device.OEM) $($data.Device.Model) | BIOS $($data.Device.BIOS) | OS $($data.Device.OSBuild)"
            $controls.txtSecureBootStatus.Text = "Secure Boot: $($data.SecureBootState)"
            
            # Check if Secure Boot is disabled
            $secureBootDisabled = $data.SecureBootState -notmatch 'Enabled|enabled'
            
            # Clear previous content
            $controls.pnlKEKCerts.Children.Clear()
            $controls.pnlDBCerts.Children.Clear()
            $controls.pnlAnalysis.Children.Clear()
            $controls.pnlServicing.Children.Clear()
            
            # === SECURE BOOT DISABLED WARNING ===
            if($secureBootDisabled) {
                # Warning in Status Overview (Analysis section)
                Add-StatusItem -Panel $controls.pnlAnalysis -Text "⚠⚠⚠ SECURE BOOT IS DISABLED ⚠⚠⚠" -Color "#ff0000"
                Add-StatusItem -Panel $controls.pnlAnalysis -Text "Certificate updates are NOT required when Secure Boot is disabled." -Color "#ffaa00"
                Add-StatusItem -Panel $controls.pnlAnalysis -Text "Please enable Secure Boot in BIOS/UEFI if you want to use this feature." -Color "#ffaa00"
                Add-StatusItem -Panel $controls.pnlAnalysis -Text "" -Color "White"
                
                # Disable update functionality
                $controls.txtUpdateStatus.Text = "⚠ Secure Boot is DISABLED - Updates not applicable"
                $controls.txtUpdateStatus.Foreground = "#ff0000"
                $controls.btnApplyUpdate.IsEnabled = $false
                $controls.rbManual.IsEnabled = $false
                $controls.rbCFR.IsEnabled = $false
                $controls.chkHighConfidence.IsEnabled = $false
                
                if($ShowLog) { Add-LogEntry "Warning: Secure Boot is disabled" "Warning" }
            } else {
                # Re-enable controls if previously disabled
                $controls.rbManual.IsEnabled = $true
                $controls.rbCFR.IsEnabled = $true
                $controls.chkHighConfidence.IsEnabled = $true
            }
            
            # Display KEK certificates
            foreach($cert in $data.Certificates.KEK) {
                $statusText = if($cert.Present) {
                    if($cert.Revoked) { "✓ Present [REVOKED]" } else { "✓ Present" }
                } else { "✗ Not found" }
                $color = if($cert.Present -and -not $cert.Revoked) { "#00ff00" } else { "#ffaa00" }
                Add-StatusItem -Panel $controls.pnlKEKCerts -Text "$statusText - $($cert.CertName)" -Color $color
            }
            
            # Display DB certificates
            foreach($cert in $data.Certificates.DB) {
                $statusText = if($cert.Present) {
                    if($cert.Revoked) { "✓ Present [REVOKED]" } else { "✓ Present" }
                } else { "✗ Not found" }
                $color = if($cert.Present -and -not $cert.Revoked) { "#00ff00" } else { "#ffaa00" }
                Add-StatusItem -Panel $controls.pnlDBCerts -Text "$statusText - $($cert.CertName)" -Color $color
            }
            
            # Display Analysis - now from centralized data
            $statusSymbol = if($data.Analysis.KEK.UpdateRequired) { "⚠" } 
                           elseif($data.Analysis.KEK.Status -eq 'Error') { "✗" }
                           else { "✓" }
            $guiColor = switch($data.Analysis.KEK.Color) {
                'Green' { '#00ff00' }
                'Yellow' { '#ffaa00' }
                'Red' { '#ff0000' }
                default { 'White' }
            }
            Add-StatusItem -Panel $controls.pnlAnalysis -Text "$statusSymbol $($data.Analysis.KEK.Message)" -Color $guiColor
            
            $statusSymbol = if($data.Analysis.DBWindows.UpdateRequired) { "⚠" }
                           elseif($data.Analysis.DBWindows.Status -eq 'Error') { "✗" }
                           else { "✓" }
            $guiColor = switch($data.Analysis.DBWindows.Color) {
                'Green' { '#00ff00' }
                'Yellow' { '#ffaa00' }
                'Red' { '#ff0000' }
                default { 'White' }
            }
            Add-StatusItem -Panel $controls.pnlAnalysis -Text "$statusSymbol $($data.Analysis.DBWindows.Message)" -Color $guiColor
            
            $statusSymbol = if($data.Analysis.DBMSUEFI.UpdateRequired) { "⚠" }
                           elseif($data.Analysis.DBMSUEFI.Status -eq 'Error') { "✗" }
                           else { "✓" }
            $guiColor = switch($data.Analysis.DBMSUEFI.Color) {
                'Green' { '#00ff00' }
                'Yellow' { '#ffaa00' }
                'Red' { '#ff0000' }
                default { 'White' }
            }
            Add-StatusItem -Panel $controls.pnlAnalysis -Text "$statusSymbol $($data.Analysis.DBMSUEFI.Message)" -Color $guiColor
            
            # Servicing Status
            if($null -ne $data.Servicing.AvailableUpdates) {
                $hexValue = '0x{0:X4}' -f $data.Servicing.AvailableUpdates
                Add-StatusItem -Panel $controls.pnlServicing -Text "AvailableUpdates: $hexValue" -Color "#aaaaaa"
                
                if($data.Servicing.AvailableUpdates -eq 0x5944) {
                    Add-StatusItem -Panel $controls.pnlServicing -Text "  Status: Initial state - all operations pending" -Color "#ffaa00"
                } elseif($data.Servicing.AvailableUpdates -eq 0x4000) {
                    Add-StatusItem -Panel $controls.pnlServicing -Text "  Status: All operations completed" -Color "#00ff00"
                } elseif($data.Servicing.AvailableUpdates -gt 0) {
                    Add-StatusItem -Panel $controls.pnlServicing -Text "  Status: In progress - some operations completed" -Color "#ffaa00"
                }
            } else {
                Add-StatusItem -Panel $controls.pnlServicing -Text "AvailableUpdates: Not set" -Color "#aaaaaa"
            }
            
            if($null -ne $data.Servicing.UEFICA2023Status -and $data.Servicing.UEFICA2023Status -ne '') {
                $statusColor = switch($data.Servicing.UEFICA2023Status) {
                    'NotStarted' { '#aaaaaa' }
                    'InProgress' { '#ffaa00' }
                    'Updated'    { '#00ff00' }
                    default      { 'White' }
                }
                Add-StatusItem -Panel $controls.pnlServicing -Text "UEFICA2023Status: $($data.Servicing.UEFICA2023Status)" -Color $statusColor
                
                # Update the update status message
                if($data.Servicing.UEFICA2023Status -eq 'Updated') {
                    $controls.txtUpdateStatus.Text = "✓ System is already up-to-date. No action required."
                    $controls.txtUpdateStatus.Foreground = "#00ff00"
                    $controls.btnApplyUpdate.IsEnabled = $false
                } elseif ($data.Servicing.UEFICA2023Status -eq 'InProgress') {
                    $controls.txtUpdateStatus.Text = "⚠ Update in progress. Please wait for completion. Reboots may be required after applying."
                    $controls.txtUpdateStatus.Foreground = "#ffaa00"
                    $controls.btnApplyUpdate.IsEnabled = $false
                } else {
                    $controls.txtUpdateStatus.Text = "⚠ Update available. Please configure and apply updates. Reboots may be required after applying."
                    $controls.txtUpdateStatus.Foreground = "#ff8700"
                    $controls.btnApplyUpdate.IsEnabled = $true
                }
            }
            
            $controls.txtStatusBar.Text = "Ready"
            if($ShowLog) { Add-LogEntry "Status loaded successfully" "Success" }
            
        } catch {
            $controls.txtStatusBar.Text = "Error loading status"
            if($ShowLog) { Add-LogEntry "Error: $($_.Exception.Message)" "Error" }
        }
    }

    # Event: RadioButton CFR changed
    $controls.rbCFR.Add_Checked({
        Add-LogEntry "CFR mode selected"
    })
    
    $controls.rbManual.Add_Checked({
        Add-LogEntry "Manual mode selected"
    })

    # Event: Apply Update button
    $controls.btnApplyUpdate.Add_Click({
        try {
            $controls.btnApplyUpdate.IsEnabled = $false
            $controls.txtStatusBar.Text = "Applying update..."
            
            $updateMode = if($controls.rbCFR.IsChecked) { 'CFR' } else { 'Manual' }
            $optOut = $controls.chkHighConfidence.IsChecked
            
            Add-LogEntry "Initiating update with mode: $updateMode" "Info"
            
            # Call the update function
            Set-SecureBootUpdates -UpdateMode $updateMode -OptOutHighConfidence:$optOut
            
            Add-LogEntry "Update completed successfully" "Success"
            $controls.txtStatusBar.Text = "Update completed"
            
            # Refresh status
            Start-Sleep -Seconds 2
            Update-StatusDisplay -ShowLog
            
        } catch {
            Add-LogEntry "Update failed: $($_.Exception.Message)" "Error"
            $controls.txtStatusBar.Text = "Update failed"
            $controls.btnApplyUpdate.IsEnabled = $true
        }
    })

    # Event: Refresh button
    $controls.btnRefresh.Add_Click({
        Add-LogEntry "Refreshing status..." "Info"
        Update-StatusDisplay -ShowLog
    })

    # Event: Clear Log button
    $controls.btnClearLog.Add_Click({
        $controls.txtLog.Clear()
    })

    # Event: Close button
    $controls.btnClose.Add_Click({
        $window.Close()
    })
    
    # Event: Support email click
    $controls.txtSupportEmail.Add_MouseLeftButtonDown({
        try {
            Start-Process "mailto:support@experience4you.de?subject=Secure Boot 2026 Support Request"
        } catch {
            # Copy to clipboard as fallback
            Set-Clipboard -Value "support@experience4you.de"
            Add-LogEntry "Support email copied to clipboard" "Info"
        }
    })

    # Initial load
    Add-LogEntry "Secure Boot 2026 Certificate Manager started" "Info"
    
    # Load company logo
    try {
        $moduleRoot = $MyInvocation.MyCommand.Module.ModuleBase
        if(-not $moduleRoot) {
            $moduleRoot = Split-Path (Split-Path $PSCommandPath -Parent) -Parent
        }
        
        $logoPath = Join-Path $moduleRoot "img\e4y_RGB_white_gray.png"
        
        if(Test-Path $logoPath) {
            $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.UriSource = New-Object System.Uri($logoPath, [System.UriKind]::Absolute)
            $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmap.EndInit()
            $bitmap.Freeze()
            $controls.imgLogo.Source = $bitmap
            Add-LogEntry "Company logo loaded" "Success"
        }
    } catch {
        # Logo loading is optional, continue without it
    }
    
    Update-StatusDisplay -ShowLog

    # Show window
    $window.ShowDialog() | Out-Null
}

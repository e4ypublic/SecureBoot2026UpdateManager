<#
.SYNOPSIS
    Main entry point for the Secure Boot Update Tool with GUI and console modes. Version 1.0.0

.DESCRIPTION
    Get-SecureBoot2026 is the primary script for checking and managing 2026 Windows Secure Boot
    updates.
    
    By default, the script launches a graphical user interface (GUI) for interactive use.
    When -Silent is specified, it operates in console mode with three operating modes:
    
    - Check: Displays current Secure Boot status, device info, and certificate analysis
    - Update: Configures Secure Boot updates (CFR or Manual mode) and triggers the scheduled task
    - Full: Executes both Check and Update operations sequentially
    
    The script requires administrative privileges and automatically imports the SecureBootUpdate
    PowerShell module from the bin\ directory. The GUI provides a modern interface with three
    tabs for device information, certificate details, and update configuration.
    
    Architecture:
    - Data-First pattern: Get-SecureBootData centralizes all data collection
    - Presentation layer: Show-SecureBootGUI (WPF) or Show-SecureBootConsole (CLI)
    - Update engine: Set-SecureBootUpdates configures registry and triggers scheduled task

.PARAMETER Mode
    Specifies the operation mode when running in console mode (-Silent).
    Valid values:
    - Check: Only display current Secure Boot status and analysis
    - Update: Only configure and apply Secure Boot updates
    - Full: Perform both Check and Update operations (default)

.PARAMETER UpdateMode
    Specifies the Secure Boot update mode when Mode is 'Update' or 'Full'.
    Valid values:
    - CFR: Configure Canary-First Rollout (gradual deployment)
    - Manual: Manual update mode (default)

.PARAMETER OptOutHighConfidence
    When specified, opts out of high-confidence updates during CFR mode.
    Only applicable when UpdateMode is 'CFR'.

.PARAMETER Silent
    Suppresses the GUI and runs the script in console mode with text output.
    When omitted, the GUI is launched by default for interactive use.

.PARAMETER ExportPath
    Specifies a file path to export the collected Secure Boot data as JSON.
    Only applicable in console mode (-Silent). If specified, the data will be
    exported to the given path after collection.

.EXAMPLE
    .\Get-SecureBoot2026.ps1
    
    Launches the graphical user interface (GUI) for interactive Secure Boot management.
    This is the default behavior when no parameters are specified.

.EXAMPLE
    .\Get-SecureBoot2026.ps1 -Silent
    
    Runs in console mode with default Full mode, displaying Secure Boot status and
    applying updates with Manual update mode.

.EXAMPLE
    .\Get-SecureBoot2026.ps1 -Mode Check -Silent
    
    Displays only the current Secure Boot status, device information, and certificate
    analysis in the console without making any configuration changes.

.EXAMPLE
    .\Get-SecureBoot2026.ps1 -Mode Update -UpdateMode CFR -Silent
    
    Configures Secure Boot to use Canary-First Rollout (CFR) mode and triggers the
    update task without displaying status information.

.EXAMPLE
    .\Get-SecureBoot2026.ps1 -Mode Full -UpdateMode CFR -OptOutHighConfidence -Silent
    
    Performs a full check and update operation with CFR mode, opting out of high-confidence
    updates, all in console mode.

.EXAMPLE
    .\Get-SecureBoot2026.ps1 -Mode Check -Silent -ExportPath "C:\Reports\SecureBoot.json"
    
    Checks Secure Boot status and exports the data to a JSON file at the specified path.

.INPUTS
    None. This script does not accept pipeline input.

.OUTPUTS
    System.Void
    The script produces console output or displays a GUI window. In console mode,
    it writes formatted text to the host. No objects are returned to the pipeline.

.NOTES
    File Name      : Get-SecureBoot2026.ps1
    Author         : experience4you GmbH
    Prerequisite   : PowerShell 5.1+, Administrator privileges, UEFI-based system
    Copyright      : Copyright (c) 2026 experience4you GmbH

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
[CmdletBinding(SupportsShouldProcess=$true)]
param(
  [ValidateSet('Check','Update','Full')]
  [string]$Mode = 'Full',
  
  [Parameter(ParameterSetName='Update')]
  [ValidateSet('CFR','Manual')]
  [string]$UpdateMode = 'Manual',
  
  [Parameter(ParameterSetName='Update')]
  [switch]$OptOutHighConfidence,

  [string]$ExportPath,
  
  [switch]$Silent
)

#Module Import
Import-Module $PSScriptRoot\bin\SecureBootUpdate.psm1 -Force -ErrorAction Stop

# Admin check
function Test-Admin {
  $id=[Security.Principal.WindowsIdentity]::GetCurrent()
  ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if(-not (Test-Admin)){ 
    Write-Host "[x] Please run as Administrator." -ForegroundColor Red
    exit 1 
}

# Show GUI by default unless -Silent is specified
if(-not $Silent) {
    Show-SecureBootGUI
    exit 0
}

# === CONSOLE MODE ===
# Continue with console mode if -Silent specified

# 1) CHECK / DISPLAY
if($Mode -in @('Check','Full')){
    $data = Get-SecureBootData
    Show-SecureBootConsole -Data $data
    # Export to JSON if path specified
    if($ExportPath) {
        try {
            $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8 -Force
            Write-Host "[+] Data exported to: $ExportPath" -ForegroundColor Green
        } catch {
            Write-Host "[x] Failed to export data: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# 2) UPDATE
if($Mode -in @('Update','Full')){
    Set-SecureBootUpdates -UpdateMode $UpdateMode -OptOutHighConfidence:$OptOutHighConfidence
}

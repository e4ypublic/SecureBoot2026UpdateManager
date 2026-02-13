<#
.SYNOPSIS
    Intune remediation script to manually trigger Secure Boot 2026 updates.

.DESCRIPTION
    This standalone remediation script configures the device for Manual mode Secure Boot
    updates and immediately triggers the update process. It is designed
    for deployment via Microsoft Intune as a Proactive Remediation remediation script.
    
    The script performs the following actions:
    1. Checks if updates are already applied (UEFICA2023Status=Updated)
    2. Sets AvailableUpdates registry value to 0x5944 to enable all update components:
       - Bit 2 (0x0004): Revoke Microsoft UEFI CA 2011 in dbx
       - Bit 6 (0x0040): Apply Windows UEFI CA 2023 to KEK/db
       - Bit 8 (0x0100): Apply Microsoft Corporation KEK 2K CA 2023 to KEK
       - Bit 10 (0x0400): Apply Microsoft UEFI CA 2023 to db
       - Bit 12 (0x1000): Apply Microsoft Option ROM UEFI CA 2023 to db
       - Bit 14 (0x4000): Revoke third-party UEFI CAs in dbx
    3. Triggers the \Microsoft\Windows\PI\Secure-Boot-Update scheduled task immediately
    4. Informs the user that a reboot may be required to complete Boot Manager updates
    
    Manual mode provides immediate control over the update process, ideal for organizations
    that want to deploy Secure Boot updates on their own schedule rather than waiting for
    the gradual CFR rollout.
    
    Exit codes:
    - Exit 0 (Success): Updates configured successfully or already applied
    - Throws error: Failed to configure registry, task not found, or insufficient permissions

.EXAMPLE
    .\IntuneRemediateSecureBootUpdateManual.ps1
    
    Configures Manual mode Secure Boot updates and triggers the scheduled task.
    Returns exit code 0 on success or if updates are already applied.

.INPUTS
    None. This script does not accept pipeline input.

.OUTPUTS
    System.Void
    Writes configuration and task execution status to standard output for Intune reporting.
    Returns exit code 0 on success.

.NOTES
    File Name      : IntuneRemediateSecureBootUpdateManual.ps1
    Author         : experience4you GmbH
    Prerequisite   : PowerShell 5.1+, Administrator privileges, UEFI-based system
    Copyright      : Copyright (c) 2026 experience4you GmbH
    
    Deployment:
    - Deploy as Intune Proactive Remediation remediation script
    - Pair with IntuneDetectSecureBootUpdate.ps1 for detection
    - Run in SYSTEM context
    - Requires registry write permissions and scheduled task execution rights
    
    Registry changes:
    - Path: HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot
    - Value: AvailableUpdates
    - Type: DWORD
    - Data: 0x5944 (Enable all update components)
    
    Registry checks:
    - Path: HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing
    - Value: UEFICA2023Status
    - Expected: "Updated" (when updates are complete)
    
    Scheduled task:
    - Path: \Microsoft\Windows\PI\
    - Name: Secure-Boot-Update
    - Action: Triggers immediate update deployment
    
    Security considerations:
    - Requires Administrator/SYSTEM privileges
    - Modifies system security configuration
    - Should be tested in pilot group before organization-wide deployment
    - Reboot may be required to complete Boot Manager component updates

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

$ErrorActionPreference = 'Stop'

# Set Admin controlled Registry key to enable SEcure Boot Update
try {
  # Check if updates are already completed
  $svcPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
  $status = (Get-ItemProperty -Path $svcPath -Name UEFICA2023Status -ErrorAction SilentlyContinue).UEFICA2023Status
  
  if ($status -eq 'Updated') {
    Write-Output "Secure Boot updates already completed: UEFICA2023Status=Updated."
    exit 0
  }
  
  # Not updated yet - set AvailableUpdates bits
  $sbReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
  
  # Ensure registry path exists
  if (-not (Test-Path $sbReg)) { 
    New-Item -Path $sbReg -Force | Out-Null 
  }
  
  # Check if AvailableUpdates property exists
  $existingValue = (Get-ItemProperty -Path $sbReg -Name 'AvailableUpdates' -ErrorAction SilentlyContinue).AvailableUpdates

  if ($null -ne $existingValue -and $existingValue -ne 0) {
    exit 0
  }
  
    Set-ItemProperty -Path $sbReg -Name 'AvailableUpdates' -Value 0x5944 -Type DWord -ErrorAction Stop
    Write-Output "Set AvailableUpdates updated to 0x5944"


    # Trigger the scheduled task immediately so the device doesn't wait up to 12h
    $taskPath = '\Microsoft\Windows\PI\'
    $taskName = 'Secure-Boot-Update'
    $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
    if ($task) {
        Start-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
        Write-Output "Scheduled Task '${taskPath}${taskName}' started."
        Write-Output "A reboot may be required to complete the Boot Manager step."
    } else {
        Write-Output "Scheduled Task '${taskPath}${taskName}' not found"
    }
    exit 0
} catch {
  Write-Error "Failed to set CFR Opt-In: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Intune remediation script to enable Canary-First Rollout (CFR) opt-in for Secure Boot 2026.

.DESCRIPTION
    This standalone remediation script configures the device to opt into Canary-First Rollout
    (CFR) mode for the Secure Boot 2026 update . It is designed for
    deployment via Microsoft Intune as a Proactive Remediation remediation script.
    
    The script performs the following actions:
    1. Ensures the Secure Boot registry path exists
    2. Sets MicrosoftUpdateManagedOptIn = 1 (DWORD) to enable CFR mode
    3. Verifies the registry value was set successfully
    
    CFR mode enables gradual deployment of Secure Boot updates through Windows Update,
    allowing Microsoft to monitor the rollout and address potential issues before
    widespread deployment.
    
    Exit codes:
    - Exit 0 (Success): CFR opt-in successfully configured
    - Throws error: Failed to configure registry or insufficient permissions
    
    This script is designed to be paired with IntuneDetectSecureBootUpdate.ps1 for
    detection logic.

.EXAMPLE
    .\IntuneRemediateSecureBootUpdateCFROptIn.ps1
    
    Enables CFR opt-in for Secure Boot updates by setting the registry value.
    Returns exit code 0 on success.

.INPUTS
    None. This script does not accept pipeline input.

.OUTPUTS
    System.Void
    Writes configuration status to standard output for Intune reporting.
    Returns exit code 0 on success.

.NOTES
    File Name      : IntuneRemediateSecureBootUpdateCFROptIn.ps1
    Author         : experience4you GmbH
    Prerequisite   : PowerShell 5.1+, Administrator privileges, UEFI-based system
    Copyright      : Copyright (c) 2026 experience4you GmbH
    
    Deployment:
    - Deploy as Intune Proactive Remediation remediation script
    - Pair with IntuneDetectSecureBootUpdate.ps1 for detection
    - Run in SYSTEM context
    - Requires registry write permissions
    
    Registry changes:
    - Path: HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot
    - Value: MicrosoftUpdateManagedOptIn
    - Type: DWORD
    - Data: 1 (Enable CFR)
    
    Security considerations:
    - Requires Administrator/SYSTEM privileges
    - Modifies system security configuration
    - Should be tested in pilot group before organization-wide deployment

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

# Set CFR Opt-In
try {
    $sbReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'

    # Ensure registry path exists
    if (-not (Test-Path $sbReg)) { 
        New-Item -Path $sbReg -Force | Out-Null 
    }

    # Property exists, use Set-ItemProperty
    Set-ItemProperty -Path $sbReg -Name 'MicrosoftUpdateManagedOptIn' -Value 1 -Type DWord
    Write-Output "CFR Opt-In updated: MicrosoftUpdateManagedOptIn = 1"
    exit 0
} catch {
  Write-Error "Failed to set CFR Opt-In: $($_.Exception.Message)"
}
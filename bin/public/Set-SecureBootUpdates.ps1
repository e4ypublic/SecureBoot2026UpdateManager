function Set-SecureBootUpdates {
    <#
    .SYNOPSIS
        Configures and initiates Secure Boot 2026 certificate updates
    
    .DESCRIPTION
        Applies Secure Boot certificate update configuration using either Manual
        or Controlled Feature Rollout (CFR) mode. In Manual mode, sets the
        AvailableUpdates registry key and triggers the Secure-Boot-Update scheduled
        task. In CFR mode, opts into Microsoft-managed gradual rollout.
        
        Optionally allows opting out of High Confidence Bucket automatic updates
        for more controlled deployment in enterprise environments.
    
    .PARAMETER UpdateMode
        Specifies the update deployment method:
        - Manual: Immediate update via registry and scheduled task (recommended)
        - CFR: Controlled Feature Rollout managed by Windows Update
    
    .PARAMETER OptOutHighConfidence
        Opts out of High Confidence Bucket automatic updates, preventing
        automatic certificate deployment for high-confidence systems
    
    .EXAMPLE
        Set-SecureBootUpdates -UpdateMode Manual
        
        Initiates immediate Secure Boot certificate update
    
    .EXAMPLE
        Set-SecureBootUpdates -UpdateMode CFR -OptOutHighConfidence
        
        Opts into CFR rollout and disables High Confidence auto-updates
    
    .EXAMPLE
        Set-SecureBootUpdates -UpdateMode Manual -WhatIf
        
        Shows what changes would be made without applying them
    
    .NOTES
        File Name      : Set-SecureBootUpdates.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, Administrator rights, UEFI Secure Boot enabled
        Copyright 2026 - experience4you GmbH
        
        Registry Paths Modified:
        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\AvailableUpdates
        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\MicrosoftUpdateManagedOptIn
        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\HighConfidenceOptOut
        
        Scheduled Task:
        - \Microsoft\Windows\PI\Secure-Boot-Update
    
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
        [ValidateSet('CFR','Manual')]
        [string]$UpdateMode = 'Manual',
        
        [switch]$OptOutHighConfidence
    )
 
    Write-Host ""
    Write-Host "=== UPDATE (Registry) ===" -ForegroundColor Yellow
    Write-Host ""
    
    # Determine update mode based on parameter
    switch ($UpdateMode) {
        'CFR' {
            # Controlled Feature Rollout - let MS manage the deployment
            if($PSCmdlet.ShouldProcess("HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot", "Set CFR Opt-In (MicrosoftUpdateManagedOptIn=1)")){ 
                try {
                    $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
                    Set-ItemProperty -Path $regPath -Name 'MicrosoftUpdateManagedOptIn' -Value 1 -Type DWord
                    Write-Host "[+] CFR Opt-In updated: MicrosoftUpdateManagedOptIn = 1 (was: $existingValue)" -ForegroundColor Green
                
                    Write-Host "[i] Windows Update will deploy Secure Boot certificates via Controlled Feature Rollout" -ForegroundColor Cyan
                }
                catch {
                    Write-Host "Failed to set CFR options: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
        
        'Manual' {
            # Manual/Admin-controlled deployment - set AvailableUpdates registry directly
            
            # First check if already updated
            $svcPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
            $status = (Get-ItemProperty -Path $svcPath -Name UEFICA2023Status -ErrorAction SilentlyContinue).UEFICA2023Status
            
            if ($status -eq 'Updated') {
                Write-Host "[+] Secure Boot updates already completed: UEFICA2023Status=Updated" -ForegroundColor Green
            } elseif ($status -eq 'InProgress') {
                Write-Host "[+] Secure Boot updates already in progress: UEFICA2023Status=InProgress" -ForegroundColor Green
            } else {
                if($PSCmdlet.ShouldProcess("HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot", "Set AvailableUpdates to 0x5944")){
                    try {
                        $regPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
                        
                        # Check if property exists
                        $existingValue = (Get-ItemProperty -Path $regPath -Name 'AvailableUpdates' -ErrorAction SilentlyContinue).AvailableUpdates
                        if ($null -ne $existingValue -and $existingValue -ne 0) {
                            Write-Host "[i] AvailableUpdates already set: $existingValue" -ForegroundColor Cyan
                        }
                        Set-ItemProperty -Path $regPath -Name 'AvailableUpdates' -Value 0x5944 -Type DWord -ErrorAction Stop
                        Write-Host "[+] AvailableUpdates updated to 0x5944" -ForegroundColor Green
                        
                        # Start the Secure Boot Update scheduled task
                        if($PSCmdlet.ShouldProcess("Scheduled Task '\Microsoft\Windows\PI\Secure-Boot-Update'", "Start task")){
                            try {
                                $taskPath = '\Microsoft\Windows\PI\'
                                $taskName = 'Secure-Boot-Update'
                                
                                $task = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
                                
                                if($task){
                                    Start-ScheduledTask -TaskPath $taskPath -TaskName $taskName -ErrorAction Stop
                                    Write-Host "[+] Scheduled Task '$taskPath$taskName' started successfully" -ForegroundColor Green
                                } else {
                                    Write-Warning "Scheduled Task '$taskPath$taskName' not found - check system LCU/support level"
                                }
                            }
                            catch {
                                Write-Host "[x] Failed to start scheduled task: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                    }
                    catch {
                        Write-Host "[x] Failed to set AvailableUpdates: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
        }
    }
    # Optional: Opt out of High Confidence Bucket
    if($OptOutHighConfidence) {
        Set-ItemProperty -Path $regPath -Name 'HighConfidenceOptOut' -Value 1 -Type DWord
        Write-Host "[+] High Confidence Opt-Out updated: HighConfidenceOptOut = 1" -ForegroundColor Green
        Write-Host "[i] High Confidence bucket auto-updates disabled" -ForegroundColor Cyan
    }
}
function Show-SecureBootConsole {
    <#
    .SYNOPSIS
        Displays Secure Boot 2026 data in formatted console output
    
    .DESCRIPTION
        Formatted console output for Secure Boot certificate status, migration
        analysis, and servicing configuration. Consumes structured data from
        Get-SecureBootData and presents it in a readable, color-coded format
        for command-line use.
        
        This function serves as the console presentation layer, separated from
        data collection logic to maintain clean architecture.
    
    .PARAMETER Data
        PSCustomObject returned by Get-SecureBootData containing all certificate
        and servicing information
    
    .EXAMPLE
        $data = Get-SecureBootData
        Show-SecureBootConsole -Data $data
        
        Displays Secure Boot status in console format
    
    .EXAMPLE
        Get-SecureBootData | Show-SecureBootConsole
        
        Pipeline usage for streamlined output
    
    .INPUTS
        PSCustomObject
        Accepts pipeline input from Get-SecureBootData
    
    .OUTPUTS
        None
        Outputs formatted text to console with color coding
    
    .NOTES
        File Name      : Show-SecureBootConsole.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher
        Copyright 2026 - experience4you GmbH
    
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
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [PSCustomObject]$Data
    )
    
    process {
        # Device Information
        Write-Host "[i] Computer: $($Data.Device.Computer)"
        Write-Host "[i] Device: $($Data.Device.OEM) $($Data.Device.Model) | BIOS $($Data.Device.BIOS) | OS $($Data.Device.OSBuild)"
        Write-Host "[i] Secure Boot: $($Data.SecureBootState)"
        
        # === CERTIFICATES ===
        Write-Host ""
        Write-Host "=== SECURE BOOT CERTIFICATES ===" -ForegroundColor Yellow
        Write-Host ""
        
        # KEK Certificates
        Write-Host "KEK Certificates:" -ForegroundColor Cyan
        foreach($cert in $Data.Certificates.KEK) {
            $status = if($cert.Present) { "[TRUE]" } else { "[FALSE]" }
            $statusText = if($cert.Present) {
                if($cert.Revoked) { "Present + [REVOKED]" } else { "Present" }
            } else { "Not found" }
            $color = if($cert.Present -and -not $cert.Revoked) { "Green" } 
                     elseif($cert.Present -and $cert.Revoked) { "Green" }
                     else { "Yellow" }
            Write-Host "  $status $($cert.CertName) - $statusText" -ForegroundColor $color
        }
        
        Write-Host ""
        Write-Host "DB Certificates:" -ForegroundColor Cyan
        foreach($cert in $Data.Certificates.DB) {
            $status = if($cert.Present) { "[TRUE]" } else { "[FALSE]" }
            $statusText = if($cert.Present) {
                if($cert.Revoked) { "Present + [REVOKED]" } else { "Present" }
            } else { "Not found" }
            $color = if($cert.Present -and -not $cert.Revoked) { "Green" } 
                     elseif($cert.Present -and $cert.Revoked) { "Green" }
                     else { "Yellow" }
            Write-Host "  $status $($cert.CertName) - $statusText" -ForegroundColor $color
        }
        
        # === MIGRATION ANALYSIS ===
        Write-Host ""
        Write-Host ""
        Write-Host "=== MIGRATION ANALYSIS ===" -ForegroundColor Yellow
        
        # KEK Analysis
        $kekPrefix = if($Data.Analysis.KEK.UpdateRequired) { "[!]" } 
                     elseif($Data.Analysis.KEK.Status -eq 'Error') { "[FALSE]" }
                     else { "[TRUE]" }
        Write-Host "$kekPrefix $($Data.Analysis.KEK.Message)" -ForegroundColor $Data.Analysis.KEK.Color
        
        # DB Windows Analysis
        $dbWinPrefix = if($Data.Analysis.DBWindows.UpdateRequired) { "[!]" }
                       elseif($Data.Analysis.DBWindows.Status -eq 'Error') { "[FALSE]" }
                       else { "[TRUE]" }
        Write-Host "$dbWinPrefix $($Data.Analysis.DBWindows.Message)" -ForegroundColor $Data.Analysis.DBWindows.Color
        
        # DB MS UEFI Analysis
        $dbMSPrefix = if($Data.Analysis.DBMSUEFI.UpdateRequired) { "[!]" }
                      elseif($Data.Analysis.DBMSUEFI.Status -eq 'Error') { "[FALSE]" }
                      else { "[TRUE]" }
        Write-Host "$dbMSPrefix $($Data.Analysis.DBMSUEFI.Message)" -ForegroundColor $Data.Analysis.DBMSUEFI.Color
        
        # === SERVICING STATUS ===
        Write-Host ""
        Write-Host ""
        Write-Host "=== SERVICING STATUS ===" -ForegroundColor Yellow
        Write-Host ""
        
        # AvailableUpdates
        if($null -ne $Data.Servicing.AvailableUpdates) {
            $hexValue = '0x{0:X4}' -f $Data.Servicing.AvailableUpdates
            Write-Host "AvailableUpdates: $hexValue" -ForegroundColor Cyan
            
            $pendingBits = Get-AvailableUpdatesBits -Value $Data.Servicing.AvailableUpdates
            if($pendingBits) {
                Write-Host "  Pending operations:" -ForegroundColor Gray
                foreach($bit in $pendingBits) {
                    Write-Host ("    [0x{0:X4}] {1}" -f $bit.Bit, $bit.Desc) -ForegroundColor Gray
                }
            } else {
                Write-Host "  No pending operations" -ForegroundColor Green
            }
            
            # Expected progression
            if($Data.Servicing.AvailableUpdates -eq 0x5944) {
                Write-Host "  Status: Initial state - all operations pending" -ForegroundColor Yellow
            } elseif($Data.Servicing.AvailableUpdates -eq 0x4000) {
                Write-Host "  Status: All operations completed" -ForegroundColor Green
            } elseif($Data.Servicing.AvailableUpdates -gt 0) {
                Write-Host "  Status: In progress - some operations completed" -ForegroundColor Yellow
            } else {
                Write-Host "  Status: Not configured" -ForegroundColor Gray
            }
        } else {
            Write-Host "AvailableUpdates: Not set" -ForegroundColor Gray
        }
        
        Write-Host ""
        
        # CFR Opt-In
        $cfrStatus = if($null -eq $Data.Servicing.CFR_OptIn -or $Data.Servicing.CFR_OptIn -eq 0) { 
            "NOT Opted IN (0 or not set)" 
        } else { 
            "Opted IN ($($Data.Servicing.CFR_OptIn))" 
        }
        $cfrColor = if($null -eq $Data.Servicing.CFR_OptIn -or $Data.Servicing.CFR_OptIn -eq 0) { "Gray" } else { "Green" }
        Write-Host "Controlled Feature Rollout (CFR): $cfrStatus" -ForegroundColor $cfrColor
        
        # HighConfidence Opt-Out
        $hcStatus = if($null -eq $Data.Servicing.HighConfidenceOptOut -or $Data.Servicing.HighConfidenceOptOut -eq 0) { 
            "NOT Opted OUT (0 or not set - high confidence bucket auto-updates currently enabled)" 
        } else { 
            "Opted OUT ($($Data.Servicing.HighConfidenceOptOut) - auto-updates disabled)" 
        }
        $hcColor = if($null -eq $Data.Servicing.HighConfidenceOptOut -or $Data.Servicing.HighConfidenceOptOut -eq 0) { "Green" } else { "Yellow" }
        Write-Host "HighConfidenceBucket Opt out: $hcStatus" -ForegroundColor $hcColor
        
        Write-Host ""
        Write-Host "--- Certificate Deployment Status ---" -ForegroundColor Cyan
        Write-Host ""
        
        # UEFICA2023Status
        if($null -ne $Data.Servicing.UEFICA2023Status -and $Data.Servicing.UEFICA2023Status -ne '') {
            $statusText = switch($Data.Servicing.UEFICA2023Status) {
                'NotStarted' { 'Not Started - Update has not yet run'; $color = 'Gray'; break }
                'InProgress' { 'In Progress - Update is actively running'; $color = 'Yellow'; break }
                'Updated'    { 'Updated - All keys and boot manager deployed successfully'; $color = 'Green'; break }
                default      { $Data.Servicing.UEFICA2023Status; $color = 'White'; break }
            }
            Write-Host "UEFICA2023Status: $statusText" -ForegroundColor $color
        } else {
            Write-Host "UEFICA2023Status: Not set" -ForegroundColor Gray
        }
        
        # UEFICA2023Error
        if($null -ne $Data.Servicing.UEFICA2023Error) {
            if($Data.Servicing.UEFICA2023Error -eq 0) {
                Write-Host "UEFICA2023Error: 0 (No errors)" -ForegroundColor Green
            } else {
                Write-Host "UEFICA2023Error: $($Data.Servicing.UEFICA2023Error) (Error encountered - check Event Logs)" -ForegroundColor Red
                Write-Host "  Recommendation: Review Secure Boot events in Windows Event Logs" -ForegroundColor Yellow
            }
        } else {
            Write-Host "UEFICA2023Error: Not set" -ForegroundColor Green
        }
    }
}

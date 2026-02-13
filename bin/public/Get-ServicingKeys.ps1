function Get-ServicingKeys {
    <#
    .SYNOPSIS
        Retrieves Secure Boot servicing registry configuration
    
    .DESCRIPTION
        Reads all relevant registry keys from the Secure Boot servicing path
        that control the Windows 2026 certificate update process. This includes
        update status, rollout configuration, and deployment progress tracking.
    
    .EXAMPLE
        Get-ServicingKeys
        
        AvailableUpdates         : 22852
        CFR_OptIn               : 1
        HighConfidenceOptOut    : 0
        UEFICA2023Status        : Updated
        UEFICA2023Error         : 0
        WindowsUEFICA2023Capable : 2
    
    .OUTPUTS
        PSCustomObject with properties:
        - AvailableUpdates: Bitmask of pending certificate operations
        - CFR_OptIn: Controlled Feature Rollout opt-in status
        - HighConfidenceOptOut: High confidence bucket auto-update opt-out
        - UEFICA2023Status: Certificate deployment status (NotStarted/InProgress/Updated)
        - UEFICA2023Error: Error code from last update attempt
        - WindowsUEFICA2023Capable: Windows UEFI CA 2023 capability status
    
    .NOTES
        File Name      : Get-ServicingKeys.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, Administrator rights
        Copyright 2026 - experience4you GmbH
        
        Registry Paths:
        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot
        - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing
    
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
    
    $base = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot'
    $svc = Join-Path $base 'Servicing'
    
    [pscustomobject]@{
        AvailableUpdates = (Get-ItemProperty $base -Name 'AvailableUpdates' -ErrorAction SilentlyContinue).AvailableUpdates
        CFR_OptIn = (Get-ItemProperty $base -Name 'MicrosoftUpdateManagedOptIn' -ErrorAction SilentlyContinue).MicrosoftUpdateManagedOptIn
        HighConfidenceOptOut = (Get-ItemProperty $base -Name 'HighConfidenceOptOut' -ErrorAction SilentlyContinue).HighConfidenceOptOut
        UEFICA2023Status = (Get-ItemProperty $svc -Name 'UEFICA2023Status' -ErrorAction SilentlyContinue).UEFICA2023Status
        UEFICA2023Error = (Get-ItemProperty $svc -Name 'UEFICA2023Error' -ErrorAction SilentlyContinue).UEFICA2023Error
        WindowsUEFICA2023Capable = (Get-ItemProperty $svc -Name 'WindowsUEFICA2023Capable' -ErrorAction SilentlyContinue).WindowsUEFICA2023Capable
    }
}
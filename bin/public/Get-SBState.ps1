function Get-SBState {
    <#
    .SYNOPSIS
        Retrieves the current Secure Boot state of the system
    
    .DESCRIPTION
        Checks whether Secure Boot is enabled, disabled, or unsupported on the
        current system. Uses the Confirm-SecureBootUEFI cmdlet and handles various
        error conditions to provide a clear status message.
    
    .EXAMPLE
        Get-SBState
        
        Returns: "Enabled", "Disabled", "Unsupported (BIOS/No UEFI)", or "Unknown"
    
    .OUTPUTS
        System.String
        Returns one of the following states:
        - "Enabled" : Secure Boot is active
        - "Disabled" : Secure Boot is inactive but UEFI is present
        - "Unsupported (BIOS/No UEFI)" : System uses legacy BIOS
        - "Unknown" : Status could not be determined
    
    .NOTES
        File Name      : Get-SBState.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, UEFI firmware
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
    
    try { 
        $b = Confirm-SecureBootUEFI -ErrorAction Stop 
        if($b){ "Enabled" } else { "Disabled" }
    } 
    catch [System.PlatformNotSupportedException] { 
        "Unsupported (BIOS/No UEFI)" 
    }
    catch { 
        "Unknown" 
    }
}
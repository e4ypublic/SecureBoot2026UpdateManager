function Get-AvailableUpdatesBits {
    <#
    .SYNOPSIS
        Decodes the AvailableUpdates registry value into individual bit flags
    
    .DESCRIPTION
        Parses the AvailableUpdates bitmask value from the Secure Boot servicing
        registry and returns detailed information about each pending operation.
        Each bit represents a specific certificate update or boot manager operation
        that will be applied during the Secure Boot 2026 update process.
    
    .PARAMETER Value
        The integer value of the AvailableUpdates registry key
    
    .EXAMPLE
        Get-AvailableUpdatesBits -Value 0x5944
        
        Returns all pending operations for the initial update state
    
    .OUTPUTS
        System.Collections.Hashtable[]
        Array of hashtables containing Bit, Order, and Description for each pending operation
    
    .NOTES
        File Name      : Get-AvailableUpdatesBits.ps1
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
    
    param([int]$Value)
    
    $bits = @(
        @{Bit=0x0040; Order=1; Desc="Add Windows UEFI CA 2023 to DB"}
        @{Bit=0x0800; Order=2; Desc="Add Microsoft Option ROM UEFI CA 2023 to DB"}
        @{Bit=0x1000; Order=3; Desc="Add Microsoft UEFI CA 2023 to DB"}
        @{Bit=0x4000; Order=2; Desc="Conditional modifier (only if MS Corp UEFI CA 2011 exists)"}
        @{Bit=0x0004; Order=4; Desc="Apply KEK signed by Platform Key"}
        @{Bit=0x0100; Order=5; Desc="Apply Windows UEFI CA 2023 signed boot manager"}
    )
    
    $bits | Where-Object { $Value -band $_.Bit } | Sort-Object Order
}
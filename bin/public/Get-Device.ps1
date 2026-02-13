function Get-Device {
    <#
    .SYNOPSIS
        Retrieves system hardware and firmware information
    
    .DESCRIPTION
        Collects comprehensive device information including manufacturer, model,
        BIOS/UEFI version, and Windows build details. This information is used
        for diagnostic purposes and displayed in the Secure Boot management GUI.
    
    .EXAMPLE
        Get-Device
        
        Computer : DESKTOP-ABC123
        OEM      : Dell Inc.
        Model    : OptiPlex 7090
        BIOS     : 2.15.0
        OSBuild  : 10.0.26100 (26100).2161
    
    .OUTPUTS
        PSCustomObject
        Object containing Computer, OEM, Model, BIOS, and OSBuild properties
    
    .NOTES
        File Name      : Get-Device.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, Administrator rights
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
    
    $cs   = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $os   = Get-CimInstance Win32_OperatingSystem
    
    [pscustomobject]@{
        Computer = $env:COMPUTERNAME
        OEM      = $cs.Manufacturer
        Model    = $cs.Model
        BIOS     = $bios.SMBIOSBIOSVersion
        OSBuild  = "$($os.Version) ($($os.BuildNumber)).$((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').UBR)"
    }
}
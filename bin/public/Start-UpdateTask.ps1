function Start-UpdateTask {
    <#
    .SYNOPSIS
        Starts the Windows Secure Boot Update scheduled task
    
    .DESCRIPTION
        Triggers the Microsoft-provided Secure-Boot-Update scheduled task that
        applies the 2026 certificate updates to the system's UEFI firmware.
        This task is part of the Windows servicing infrastructure and is created
        by compatible Windows updates (LCU).
        
        The task processes the AvailableUpdates registry key and deploys the
        configured certificates to KEK and DB stores.
    
    .EXAMPLE
        Start-UpdateTask
        
        Starts the Secure-Boot-Update scheduled task if available
    
    .OUTPUTS
        None
        Displays status messages and warnings to console
    
    .NOTES
        File Name      : Start-UpdateTask.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, Administrator rights, Recent Windows LCU installed
        Copyright 2026 - experience4you GmbH
        
        Scheduled Task Path: \Microsoft\Windows\PI\Secure-Boot-Update
    
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
    
    $path = '\Microsoft\Windows\PI\'
    $name = 'Secure-Boot-Update'
    
    if(Get-ScheduledTask -TaskName $name -TaskPath $path -ErrorAction SilentlyContinue) {
        Start-ScheduledTask -TaskPath $path -TaskName $name
    } else {
        Write-Warning "Scheduled Task $path$name nicht gefunden - System auf aktuellen LCU/Supportstand prüfen."
    }
}
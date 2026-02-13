function Get-SecureBootData {
    <#
    .SYNOPSIS
        Collects all Secure Boot 2026 certificate and servicing data
    
    .DESCRIPTION
        Centralized data collection function that gathers device information,
        Secure Boot status, certificate presence/revocation, migration analysis,
        and servicing configuration. Returns a structured PSCustomObject for
        consumption by GUI or console output formatters.
        
        This function serves as the single source of truth for all Secure Boot
        certificate status information, eliminating code duplication between
        GUI and console modes.
    
    .EXAMPLE
        $data = Get-SecureBootData
        $data.Analysis.KEK.Status
        
        Retrieves all Secure Boot data and accesses the KEK migration status
    
    .EXAMPLE
        Get-SecureBootData | ConvertTo-Json | Out-File report.json
        
        Exports the complete Secure Boot status to JSON format
    
    .OUTPUTS
        PSCustomObject with properties:
        - Device: OEM, Model, BIOS, OSBuild
        - SecureBootState: Current Secure Boot status
        - Certificates: KEK and DB certificate results
        - Analysis: Migration analysis for KEK, DBWindows, DBMSUEFI
        - Servicing: AvailableUpdates, CFR_OptIn, HighConfidenceOptOut, UEFICA2023Status, UEFICA2023Error
    
    .NOTES
        File Name      : Get-SecureBootData.ps1
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
    
    [CmdletBinding()]
    param()
    
    try {
        # Get device and Secure Boot state
        $device = Get-Device
        $sbState = Get-SBState
        
        # Define Certificates
        $KEKCerts = @(
            'Microsoft Corporation KEK CA 2011'
            'Microsoft Corporation KEK 2K CA 2023'
        )
        
        $DBCerts = @(
            'Microsoft Windows Production PCA 2011'
            'Microsoft Corporation UEFI CA 2011'
            'Windows UEFI CA 2023'
            'Microsoft UEFI CA 2023'
            'Microsoft Option ROM UEFI CA 2023'
        )
        
        # Test certificates
        $kekResults = $KEKCerts | ForEach-Object { Test-UEFICert -Var kek -Regex $_ }
        $dbResults  = $DBCerts | ForEach-Object { Test-UEFICert -Var db -Regex $_ }
        
        # Get servicing keys
        $servicing = Get-ServicingKeys
        
        # === MIGRATION ANALYSIS ===
        
        # KEK Migration Analysis
        $kek2011 = $kekResults | Where-Object { $_.CertName -eq 'Microsoft Corporation KEK CA 2011' }
        $kek2023 = $kekResults | Where-Object { $_.CertName -eq 'Microsoft Corporation KEK 2K CA 2023' }
        
        if($kek2011.Present -and $kek2023.Present) {
            $kekAnalysis = @{
                Status = 'Success'
                Message = 'KEK: 2011 and 2023 certs present - Migration successful'
                UpdateRequired = $false
                Color = 'Green'
            }
        } elseif($kek2011.Present -and -not $kek2023.Present) {
            $kekAnalysis = @{
                Status = 'UpdateRequired'
                Message = 'KEK: 2011 cert present, but 2023 missing - UPDATE REQUIRED'
                UpdateRequired = $true
                Color = 'Yellow'
            }
        } elseif(-not $kek2011.Present -and $kek2023.Present) {
            $kekAnalysis = @{
                Status = 'Modern'
                Message = 'KEK: Only 2023 cert present - Modern'
                UpdateRequired = $false
                Color = 'Green'
            }
        } else {
            $kekAnalysis = @{
                Status = 'Error'
                Message = 'KEK: No certificates found - PROBLEM!'
                UpdateRequired = $false
                Color = 'Red'
            }
        }
        
        # DB Windows Migration Analysis
        $dbWinProd2011 = $dbResults | Where-Object { $_.CertName -eq 'Microsoft Windows Production PCA 2011' }
        $dbWinUEFI2023 = $dbResults | Where-Object { $_.CertName -eq 'Windows UEFI CA 2023' }
        
        if($dbWinProd2011.Present -and $dbWinUEFI2023.Present) {
            $dbWindowsAnalysis = @{
                Status = 'Success'
                Message = 'DB Windows: 2011 and 2023 certs present - Migration successful'
                UpdateRequired = $false
                Color = 'Green'
            }
        } elseif($dbWinProd2011.Present -and -not $dbWinUEFI2023.Present) {
            $dbWindowsAnalysis = @{
                Status = 'UpdateRequired'
                Message = 'DB Windows: 2011 cert present, but 2023 missing - UPDATE REQUIRED'
                UpdateRequired = $true
                Color = 'Red'
            }
        } elseif(-not $dbWinProd2011.Present) {
            $dbWindowsAnalysis = @{
                Status = 'Error'
                Message = 'DB Windows: 2011 cert missing - OEM BIOS/Firmware issue!'
                UpdateRequired = $false
                Color = 'Red'
            }
        } else {
            $dbWindowsAnalysis = @{
                Status = 'Unknown'
                Message = 'DB Windows: Unexpected certificate configuration'
                UpdateRequired = $false
                Color = 'Yellow'
            }
        }
        
        # DB Microsoft UEFI CA Migration Analysis
        $dbMSUEFI2011 = $dbResults | Where-Object { $_.CertName -eq 'Microsoft Corporation UEFI CA 2011' }
        $dbMSUEFI2023 = $dbResults | Where-Object { $_.CertName -eq 'Microsoft UEFI CA 2023' }
        $dbMSOptionROM2023 = $dbResults | Where-Object { $_.CertName -eq 'Microsoft Option ROM UEFI CA 2023' }
        
        if($dbMSUEFI2011.Present) {
            if($dbMSUEFI2023.Present -and $dbMSOptionROM2023.Present) {
                $dbMSUEFIAnalysis = @{
                    Status = 'Success'
                    Message = 'DB MS UEFI: 2011 and all 2023 certs present - Migration successful'
                    UpdateRequired = $false
                    Color = 'Green'
                }
            } elseif($dbMSUEFI2023.Present -or $dbMSOptionROM2023.Present) {
                $dbMSUEFIAnalysis = @{
                    Status = 'UpdateRequired'
                    Message = 'DB MS UEFI: 2011 present, but not all 2023 certs - UPDATE REQUIRED'
                    UpdateRequired = $true
                    Color = 'Red'
                }
            } else {
                $dbMSUEFIAnalysis = @{
                    Status = 'UpdateRequired'
                    Message = 'DB MS UEFI: 2011 present, but no 2023 certs - UPDATE REQUIRED'
                    UpdateRequired = $true
                    Color = 'Red'
                }
            }
        } else {
            if($dbMSUEFI2023.Present -or $dbMSOptionROM2023.Present) {
                $dbMSUEFIAnalysis = @{
                    Status = 'Modern'
                    Message = 'DB MS UEFI: Microsoft Corporation UEFI CA 2011 missing, 2023 present - Modern!'
                    UpdateRequired = $false
                    Color = 'Green'
                }
            } else {
                $dbMSUEFIAnalysis = @{
                    Status = 'NotApplicable'
                    Message = 'DB MS UEFI: Microsoft Corporation UEFI CA 2011 not present, therefore no 2023 certs needed - No update required'
                    UpdateRequired = $false
                    Color = 'Green'
                }
            }
        }
        
        # Build structured data object
        $data = [PSCustomObject]@{
            Device = [PSCustomObject]@{
                Computer = $device.Computer
                OEM = $device.OEM
                Model = $device.Model
                BIOS = $device.BIOS
                OSBuild = $device.OSBuild
            }
            SecureBootState = $sbState
            Certificates = [PSCustomObject]@{
                KEK = $kekResults
                DB = $dbResults
            }
            Analysis = [PSCustomObject]@{
                KEK = [PSCustomObject]$kekAnalysis
                DBWindows = [PSCustomObject]$dbWindowsAnalysis
                DBMSUEFI = [PSCustomObject]$dbMSUEFIAnalysis
            }
            Servicing = [PSCustomObject]@{
                AvailableUpdates = $servicing.AvailableUpdates
                CFR_OptIn = $servicing.CFR_OptIn
                HighConfidenceOptOut = $servicing.HighConfidenceOptOut
                UEFICA2023Status = $servicing.UEFICA2023Status
                UEFICA2023Error = $servicing.UEFICA2023Error
            }
        }
        
        return $data
        
    } catch {
        throw "Failed to collect Secure Boot data: $($_.Exception.Message)"
    }
}

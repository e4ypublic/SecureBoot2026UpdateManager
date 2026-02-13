<#
.SYNOPSIS
    Intune detection script for Secure Boot 2026 update compliance.

.DESCRIPTION
    This standalone detection script checks whether a device is compliant with the
    Secure Boot 2026 update. It is designed for deployment
    via Microsoft Intune as a Proactive Remediation detection script.
    
    The script evaluates compliance based on:
    1. UEFICA2023Status registry value == "Updated"
    2. Presence of "Windows UEFI CA 2023" certificate in the DB UEFI variable
    3. Presence of "Microsoft Corporation KEK 2K CA 2023" certificate in the KEK variable
    4. Conditional check: If "Microsoft Corporation UEFI CA 2011" exists in DB,
       both "Microsoft UEFI CA 2023" and "Microsoft Option ROM UEFI CA 2023" must be present
    
    Exit codes:
    - Exit 0 (Compliant): Device has required 2023 certificates or UEFICA2023Status=Updated
    - Exit 0 (Not Applicable): Secure Boot not supported/enabled (non-UEFI system)
    - Exit 1 (Non-Compliant): Required 2023 certificates are missing
    
    The script is designed to be paired with a remediation script that opts the device
    into Canary-First Rollout (CFR) or Manual update mode.

.EXAMPLE
    .\IntuneDetectSecureBootUpdate.ps1
    
    Checks Secure Boot compliance. Returns exit code 0 if compliant or not applicable,
    exit code 1 if non-compliant and remediation is required.

.INPUTS
    None. This script does not accept pipeline input.

.OUTPUTS
    System.Void
    Writes compliance status to standard output for Intune reporting.
    Returns exit codes for Intune detection logic.

.NOTES
    File Name      : IntuneDetectSecureBootUpdate.ps1
    Author         : experience4you GmbH
    Prerequisite   : PowerShell 5.1+, UEFI-based system with Secure Boot
    Copyright      : Copyright (c) 2026 experience4you GmbH
    
    Deployment:
    - Deploy as Intune Proactive Remediation detection script
    - Pair with IntuneRemediateSecureBootUpdateCFROptIn.ps1 or
      IntuneRemediateSecureBootUpdateManual.ps1 for remediation
    - Run in SYSTEM context
    - Recommended schedule: Daily
    
    Registry paths checked:
    - HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing\UEFICA2023Status
    
    UEFI variables checked:
    - kek: Microsoft Corporation KEK 2K CA 2023
    - db: Windows UEFI CA 2023, Microsoft UEFI CA 2023, Microsoft Option ROM UEFI CA 2023
    - dbx: Certificate revocation list (for validation)

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
try {
    $isSb = Confirm-SecureBootUEFI -ErrorAction Stop
    if (!$isSb) {
        Write-Output "Not applicable: Secure Boot not supported/enabled" -ForegroundColor Gray
        exit 0
    }

    $svcPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
    $status = (Get-ItemProperty -Path $svcPath -Name UEFICA2023Status -ErrorAction SilentlyContinue).UEFICA2023Status
    if ($status -eq 'Updated') {
        Write-Output "Compliant: UEFICA2023Status=Updated."
        exit 0
    }
    if ($status -eq 'InProgress') {
        Write-Output "Compliant: UEFICA2023Status=InProgress."
        exit 0
    }

    # 3) Verify 2023 certs in DB/KEK via Get-SecureBootUEFI (string match)
    function Test-UEFICert {
        param(
            [Parameter(Mandatory)]
            [ValidateSet('db','dbdefault','kek','kekdefault')]
            [string]$Var,
            [Parameter(Mandatory)]
            [string]$Regex
        )
    
        try {
            $bytes = (Get-SecureBootUEFI -Name $Var -ErrorAction Stop).Bytes
            $text = [System.Text.Encoding]::ASCII.GetString($bytes)
            $isPresent = [regex]::IsMatch($text, $Regex, 'IgnoreCase')
            
            # Detailed mode: Check revocation status
            $isRevoked = $false
            if ($isPresent) {
                try {
                    $dbxBytes = (Get-SecureBootUEFI -Name 'dbx' -ErrorAction Stop).Bytes
                    $dbxText = [System.Text.Encoding]::ASCII.GetString($dbxBytes)
                    $isRevoked = [regex]::IsMatch($dbxText, $Regex, 'IgnoreCase')
                } catch {
                    # dbx not accessible or doesn't exist
                    $isRevoked = $null
                }
            }
            
            [PSCustomObject]@{
            Variable = $Var
            CertName = $Regex
            Present  = $isPresent
            Revoked  = $isRevoked
            }
        } catch {
            if ($Detailed) {
                [PSCustomObject]@{
                    Variable = $Var
                    CertName = $Regex
                    Present  = $false
                    Revoked  = $null
                    Error    = $_.Exception.Message
                }
            } else {
                $false
            }
        }
    }

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

    $kekResults = $KEKCerts | ForEach-Object { Test-UEFICert -Var kek -Regex $_ }
    $dbResults  = $DBCerts | ForEach-Object { Test-UEFICert -Var db -Regex $_ }

    # Extract KEK certificate status
    $kekHasKEK2023 = ($kekResults | Where-Object { $_.CertName -eq 'Microsoft Corporation KEK 2K CA 2023' }).Present

    # Extract DB certificate status
    $dbHasWindowsUEFI2023 = ($dbResults | Where-Object { $_.CertName -eq 'Windows UEFI CA 2023' }).Present
    $dbHasMSUEFI2011 = ($dbResults | Where-Object { $_.CertName -eq 'Microsoft Corporation UEFI CA 2011' }).Present
    $dbHasMSUEFI2023 = ($dbResults | Where-Object { $_.CertName -eq 'Microsoft UEFI CA 2023' }).Present
    $dbHasMSOptionROM2023 = ($dbResults | Where-Object { $_.CertName -eq 'Microsoft Option ROM UEFI CA 2023' }).Present

    # Conditional check: If MS UEFI CA 2011 exists in DB, both 2023 replacements must be present
    $conditionalDbOk = $true
    if ($dbHasMSUEFI2011) {
        $conditionalDbOk = ($dbHasMSUEFI2023 -and $dbHasMSOptionROM2023)
        if (-not $conditionalDbOk) {
            Write-Output "Non-compliant: MS UEFI CA 2011 present but 2023 replacements (MS UEFI CA 2023 + Option ROM) missing."
            exit 1
        }
    }

    # Main compliance check: Windows UEFI CA 2023 in DB + KEK 2K CA 2023 in KEK
    if ($dbHasWindowsUEFI2023 -and $kekHasKEK2023 -and $conditionalDbOk) {
        Write-Output "Compliant: 2023 certs present (Windows UEFI CA 2023 in DB, KEK 2K CA 2023 in KEK, conditional checks passed)."
        exit 0
    }

    # 4) Otherwise → non-compliant
    if (-not $dbHasWindowsUEFI2023) {
        Write-Output "Non-compliant: Windows UEFI CA 2023 not in DB."
    } elseif (-not $kekHasKEK2023) {
        Write-Output "Non-compliant: Microsoft Corporation KEK 2K CA 2023 not in KEK."
    } else {
        Write-Output "Non-compliant: 2023 certs not fully present"
    }
    exit 1
}
catch {
    Write-Error "Error during secureboot check: $($_.Exception.Message)"
}
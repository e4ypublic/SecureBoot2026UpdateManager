<#
.SYNOPSIS
    Intune Custom Compliance discovery script for Secure Boot certificate update status.

.DESCRIPTION
    This script checks whether a device has received the required Secure Boot 2023
    certificates and returns a JSON payload for Intune Custom Compliance.

    Compliance target:
    - Windows UEFI CA 2023 in DB
    - Microsoft Corporation KEK 2K CA 2023 in KEK
    - If Microsoft Corporation UEFI CA 2011 exists in DB, both replacement certs
      must exist: Microsoft UEFI CA 2023 and Microsoft Option ROM UEFI CA 2023

.NOTES
    The script always returns one JSON object on STDOUT.
#>

$ErrorActionPreference = 'Stop'

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
        return [regex]::IsMatch($text, $Regex, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    }
    catch {
        return $false
    }
}

$result = [ordered]@{
    ScriptVersion                         = '1.0.0'
    TimestampUtc                          = (Get-Date).ToUniversalTime().ToString('o')
    SecureBootSupported                   = $false
    SecureBootEnabled                     = $false
    UEFICA2023Status                      = $null
    DbHasWindowsUefiCa2023                = $false
    KekHasMicrosoftKek2kCa2023            = $false
    DbHasMicrosoftUefiCa2011              = $false
    DbHasMicrosoftUefiCa2023              = $false
    DbHasMicrosoftOptionRomUefiCa2023     = $false
    ConditionalDbOk                       = $false
    HasNewSecureBootCertificates          = $false
    ComplianceStatus                      = 'NonCompliant'
    Reason                                = 'Initialization'
}

try {
    try {
        $isSecureBootEnabled = Confirm-SecureBootUEFI -ErrorAction Stop
        $result.SecureBootSupported = $true
        $result.SecureBootEnabled = [bool]$isSecureBootEnabled
    }
    catch [System.PlatformNotSupportedException] {
        $result.SecureBootSupported = $false
        $result.SecureBootEnabled = $false
        $result.ConditionalDbOk = $false
        $result.HasNewSecureBootCertificates = $false
        $result.ComplianceStatus = 'NonCompliant'
        $result.Reason = 'SecureBoot unsupported (BIOS/no UEFI)'

        $result | ConvertTo-Json -Depth 6 -Compress
        exit 0
    }

    if (-not $result.SecureBootEnabled) {
        $result.ConditionalDbOk = $false
        $result.HasNewSecureBootCertificates = $false
        $result.ComplianceStatus = 'NonCompliant'
        $result.Reason = 'SecureBoot disabled'

        $result | ConvertTo-Json -Depth 6 -Compress
        exit 0
    }

    $svcPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\Servicing'
    $result.UEFICA2023Status = (Get-ItemProperty -Path $svcPath -Name UEFICA2023Status -ErrorAction SilentlyContinue).UEFICA2023Status

    $result.KekHasMicrosoftKek2kCa2023 = Test-UEFICert -Var 'kek' -Regex 'Microsoft Corporation KEK 2K CA 2023'
    $result.DbHasWindowsUefiCa2023 = Test-UEFICert -Var 'db' -Regex 'Windows UEFI CA 2023'
    $result.DbHasMicrosoftUefiCa2011 = Test-UEFICert -Var 'db' -Regex 'Microsoft Corporation UEFI CA 2011'
    $result.DbHasMicrosoftUefiCa2023 = Test-UEFICert -Var 'db' -Regex 'Microsoft UEFI CA 2023'
    $result.DbHasMicrosoftOptionRomUefiCa2023 = Test-UEFICert -Var 'db' -Regex 'Microsoft Option ROM UEFI CA 2023'

    if ($result.DbHasMicrosoftUefiCa2011) {
        $result.ConditionalDbOk = ($result.DbHasMicrosoftUefiCa2023 -and $result.DbHasMicrosoftOptionRomUefiCa2023)
    }
    else {
        $result.ConditionalDbOk = $true
    }

    $result.HasNewSecureBootCertificates = (
        $result.DbHasWindowsUefiCa2023 -and
        $result.KekHasMicrosoftKek2kCa2023 -and
        $result.ConditionalDbOk
    )

    if ($result.HasNewSecureBootCertificates) {
        $result.ComplianceStatus = 'Compliant'
        $result.Reason = 'Required Secure Boot certificates are present'
    }
    else {
        $reasons = @()

        if (-not $result.DbHasWindowsUefiCa2023) {
            $reasons += 'Windows UEFI CA 2023 missing in DB'
        }

        if (-not $result.KekHasMicrosoftKek2kCa2023) {
            $reasons += 'Microsoft Corporation KEK 2K CA 2023 missing in KEK'
        }

        if (-not $result.ConditionalDbOk) {
            $reasons += 'Microsoft Corporation UEFI CA 2011 present, but replacement DB certs missing'
        }

        $result.ComplianceStatus = 'NonCompliant'
        $result.Reason = ($reasons -join '; ')
    }

    $result | ConvertTo-Json -Depth 6 -Compress
    exit 0
}
catch {
    $result.ComplianceStatus = 'Error'
    $result.HasNewSecureBootCertificates = $false
    $result.Reason = "Script error: $($_.Exception.Message)"

    $result | ConvertTo-Json -Depth 6 -Compress
    exit 0
}

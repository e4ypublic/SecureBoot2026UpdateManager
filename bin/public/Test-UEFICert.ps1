function Test-UEFICert {
    <#
    .SYNOPSIS
        Tests for the presence of a specific certificate in UEFI Secure Boot variables
    
    .DESCRIPTION
        Searches UEFI Secure Boot signature databases (db, kek, etc.) for a specific
        certificate by name pattern. Also checks the dbx (revocation database) to
        determine if the certificate has been revoked.
        
        This function is critical for determining which 2011 and 2023 certificates
        are present in the system's firmware, enabling migration analysis.
    
    .PARAMETER Var
        The UEFI variable to search. Valid values:
        - db: Signature Database (authorized certificates)
        - dbdefault: Default Signature Database
        - kek: Key Exchange Key database
        - kekdefault: Default KEK database
    
    .PARAMETER Regex
        Regular expression pattern to search for (typically certificate common name)
    
    .EXAMPLE
        Test-UEFICert -Var kek -Regex 'Microsoft Corporation KEK CA 2011'
        
        Variable : kek
        CertName : Microsoft Corporation KEK CA 2011
        Present  : True
        Revoked  : False
    
    .EXAMPLE
        Test-UEFICert -Var db -Regex 'Windows UEFI CA 2023'
        
        Checks if the Windows UEFI CA 2023 certificate is present in the db
    
    .OUTPUTS
        PSCustomObject
        Returns object with Variable, CertName, Present, and Revoked properties
    
    .NOTES
        File Name      : Test-UEFICert.ps1
        Author         : experience4you GmbH
        Prerequisite   : PowerShell 5.1 or higher, UEFI Secure Boot system, Administrator rights
        Copyright 2026 - experience4you GmbH
        
        UEFI Variables:
        - db/dbdefault: Signature Database (authorized signatures)
        - kek/kekdefault: Key Exchange Keys
        - dbx: Forbidden Signatures Database (revoked certificates)
    
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
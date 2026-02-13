# Secure Boot 2026 Certificate Manager

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Platform](https://img.shields.io/badge/Platform-Windows%20UEFI-lightgrey.svg)](https://support.microsoft.com/en-us/topic/secure-boot-certificate-updates-guidance-for-it-professionals-and-organizations-e2b43f9f-b424-42df-bc6a-8476db65ab2f#bkmk_is_secure_boot_enabled)

**Comprehensive PowerShell toolkit for managing the Windows Secure Boot 2026 certificate update**

---

## 🔐 Generell Background

### What's Happening?

Microsoft's three Secure Boot certificates from 2011 are expiring between **June and October 2026**:

- **Microsoft Corporation KEK CA 2011** (Key Exchange Key)
- **Windows Production PCA 2011**
- **Microsoft Corporation UEFI CA 2011**

### Why Does This Matter?

- **Without updates**: Devices will not receive future boot security updates → **Critical security risk**
- **Goal**: Deploy 2023 replacement certificates before expiration:
  - **Microsoft Corporation KEK 2K CA 2023** (KEK)
  - **Windows UEFI CA 2023** (DB)
  - **Microsoft UEFI CA 2023** (DB)
  - **Microsoft Option ROM UEFI CA 2023** (DB)

**Note**: Not all devices include the Microsoft Corporation UEFI CA 2011 in firmware. Only devices that include this certificate require both **Microsoft UEFI CA 2023** and **Microsoft Option ROM UEFI CA 2023**. Otherwise, these two certificates do not need to be applied.


### Deployment Modes
- **Modes**: 
  - **Microsoft High Confidence Bucket**: Automatic update for high confidence devices 
  - **CFR (Canary-First Rollout)**: Gradual Windows Update deployment
  - **Manual**: Immediate administrator-controlled deployment

---

## ✨ Features

### 🖥️ **Dual Interface**
- **Modern WPF GUI** with 3-tab interface
- **Console CLI** for scripting and automation
- **Company Branding** with CI colors and logo

### 🔍 **Comprehensive Analysis**
- Secure Boot status detection
- UEFI certificate verification
- Device and firmware information collection
- Registry configuration analysis

### ⚙️ **Update Management**
- **CFR Opt-In Mode**: Enable Canary-First Rollout via Windows Update
- **Manual Mode**: Immediate deployment with 0x5944 bitmask
- **Opt-Out High Confidence**: Opt-Out option for high confidence mode
- Scheduled task triggering
- WhatIf/Confirm support for safe testing

### 🚀 **Intune Integration**
- **Proactive Remediation scripts** included
  - Detection script for compliance checking
  - CFR Opt-In remediation
  - Manual mode remediation
- Ready for deployment

---

## 🖼️ Screenshots

### GUI Main Window
![Gui Window](bin/img/GuiWindow.png?raw=true "Gui Window")

### Console Output
![Console Windows](bin/img/ConsoleWindow.png?raw=true "Console Window")

---

## 🚀 Quick Start

### Launch GUI

```powershell
.\Get-SecureBoot2026.ps1
```

### Check Status (Console)

```powershell
.\Get-SecureBoot2026.ps1 -Silent -Mode Check
```

### Enable CFR Opt-In (Console)

```powershell
.\Get-SecureBoot2026.ps1 -Silent -Mode Update -UpdateMode CFR
```

### Manual Update (Console)

```powershell
.\Get-SecureBoot2026.ps1 -Silent -Mode Full -UpdateMode Manual
```

---

## 📖 Usage

### GUI Mode (Default)

Launch the graphical interface for interactive management:

```powershell
.\Get-SecureBoot2026.ps1
```

---

### Console Mode

Display Secure Boot status in the terminal:

```powershell
# Check only (read-only)
.\Get-SecureBoot2026.ps1 -Silent -Mode Check

# Update only
.\Get-SecureBoot2026.ps1 -Silent -Mode Update -UpdateMode CFR

# Full (check + update)
.\Get-SecureBoot2026.ps1 -Silent -Mode Full -UpdateMode Manual
```

**Parameters**:
- `-Mode`: Check | Update | Full (default: Full)
- `-UpdateMode`: CFR | Manual (default: Manual)
- `-OptOutHighConfidence`: Opt out of high-confidence updates (CFR mode)
- `-Silent`: Suppress GUI, use console output
- `-ExportPath`: Export collected data to JSON file (requires -Silent)

---

### Automation examples

For scripted deployments without user interaction:

```powershell
# Enable CFR with opt-out of high confidence
.\Get-SecureBoot2026.ps1 -Silent -Mode Update -UpdateMode CFR -OptOutHighConfidence

# Manual update with WhatIf
.\Get-SecureBoot2026.ps1 -Silent -Mode Update -UpdateMode Manual -WhatIf

# Export data to JSON
.\Get-SecureBoot2026.ps1 -Silent -Mode Check -ExportPath "C:\Reports\SecureBoot.json"

# Export with timestamp
.\Get-SecureBoot2026.ps1 -Silent -Mode Check -ExportPath "SecureBoot_$(Get-Date -F 'yyyyMMdd_HHmmss').json"
```

---

## 🎯 Intune Deployment

The `StandaloneIntuneRemediations\` folder contains three scripts for Microsoft Intune Proactive Remediations.

### Detection Script

**File**: `IntuneDetectSecureBootUpdate.ps1`

**Purpose**: Checks device compliance with Secure Boot 2026 requirements

**Logic**:
- ✅ **Compliant (Exit 0)**: 
  - `UEFICA2023Status = Updated` **OR**
  - Windows UEFI CA 2023 in DB **AND** KEK 2K CA 2023 in KEK
  - If MS UEFI CA 2011 exists: MS UEFI CA 2023 + Option ROM CA 2023 present
- ⚠️ **Not Applicable (Exit 0)**: Secure Boot not supported/enabled
- ❌ **Non-Compliant (Exit 1)**: Required 2023 certificates missing

### Remediation Script (CFR Opt-In)

**File**: `IntuneRemediateSecureBootUpdateCFROptIn.ps1`

**Purpose**: Enables Canary-First Rollout for gradual deployment

**Deployment**: Use for pilot groups or organizations preferring gradual rollout

### Remediation Script (Manual Mode)

**File**: `IntuneRemediateSecureBootUpdateManual.ps1`

**Purpose**: Immediately triggers Secure Boot updates


**Deployment**: Use for production rollout with immediate application

### Intune Configuration

1. **Create Proactive Remediation**:
   - Navigate to: Devices → Scripts and remediations → Proactive remediations
   - Click **+ Create**
   
2. **Upload Scripts**:
   - **Detection script**: `IntuneDetectSecureBootUpdate.ps1`
   - **Remediation script**: Choose CFR or Manual variant
   
3. **Settings**:
   - **Run script in 64-bit PowerShell**: Yes
   - **Run this script using the logged-on credentials**: No (run as SYSTEM)
   - **Enforce script signature check**: No
   
4. **Schedule**:
   - **Run daily/hourly**
   - **Maximum timeout**: 10 minutes
   
5. **Assignments**:
   - Assign to pilot group (CFR) or production group (Manual)
   - Monitor compliance in Intune reporting

---

## 📄 License

This project is licensed under the **MIT License**.

```
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
```

---

**Version**: 1.0.0  
**Last Updated**: February, 2026  
**Maintained by**: experience4you GmbH
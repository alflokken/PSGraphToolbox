<#
.SYNOPSIS
    Build script for PSGraphToolbox module.

.DESCRIPTION
    Concatenates all .ps1 files from src/ into a single .psm1 module file
    and generates a module manifest (.psd1) with exported functions and aliases.

    Only top-level functions (no indentation) are exported.

.PARAMETER ModuleVersion
    Version number for the module manifest (e.g., "1.0.0").

.EXAMPLE
    .\build.ps1 -ModuleVersion "1.0.0"
#>
param (
    [Parameter(Mandatory)]
    [string]$ModuleVersion
)

if ( $PSVersionTable.PSVersion.Major -ne 5 ) { throw "build and test should be run in PowerShell 5.1" }

$ErrorActionPreference = "Stop"
$moduleName = "PsGraphToolbox"
$basePath = Split-Path $PSScriptRoot -Parent
$srcPath = Join-Path $basePath "src"
$outputPsm1 = Join-Path $basePath "$moduleName.psm1"
$outputPsd1 = Join-Path $basePath "$moduleName.psd1"

Write-Host "Building $moduleName v$ModuleVersion..." -ForegroundColor Cyan

# Get all .ps1 files recursively (exclude READMEs and other non-code files)
$files = Get-ChildItem -Path $srcPath -Filter "*.ps1" -Recurse | Sort-Object FullName
Write-Host "  Found $($files.Count) source files"

# Process files - concatenate content and extract exports
$moduleContent = @()
$functionsToExport = @()

foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    $moduleContent += "# Source: $($file.Name)"
    $moduleContent += $content
    $moduleContent += ""
    
    $lines = Get-Content -Path $file.FullName
    # top-level PS function (avoid JS functions which has parentheses)
    foreach ($line in $lines) {
        if ($line -match "^function\s+([A-Za-z][\w-]+)" -and $line -notmatch '\(') { 
            $obj = New-Object -TypeName PSObject
            $obj | Add-Member -NotePropertyName Name -NotePropertyValue $Matches[1]
            $obj | Add-Member -NotePropertyName Category -NotePropertyValue (Split-Path -Path $file.DirectoryName -Leaf)
            $functionsToExport += $obj
        }
    }
}

# Write module file
$moduleContent | Set-Content -Path $outputPsm1 -Encoding UTF8
Write-Host "  Created: $outputPsm1" -ForegroundColor Green

# Build manifest
$manifestParams = @{
    Path              = $outputPsd1
    RootModule        = "$moduleName.psm1"
    ModuleVersion     = $ModuleVersion
    Author            = "Alf Lokken"
    Description       = "PowerShell toolkit for Microsoft Graph and Entra ID operations"
    Tags              =  @("Microsoft Graph", "Entra ID", "Toolbox", "Automation")
    LicenseUri        = "https://raw.githubusercontent.com/alflokken/PS-GT/main/LICENSE"
    ProjectUri        = "https://github.com/alflokken/PS-GT"
    Copyright         = "(c) Alf Lokken. All rights reserved."
    PowerShellVersion = "5.1"
    FunctionsToExport = $functionsToExport.Name
    AliasesToExport   = @()
    CmdletsToExport   = @()
    VariablesToExport = @()
    RequiredModules   = @("Microsoft.Graph.Authentication")
    GUID              = "a1f1337a-5a61-490a-8748-8af6bd836b52"
}

New-ModuleManifest @manifestParams
Write-Host "  Created: $outputPsd1" -ForegroundColor Green

# Summary
Write-Host "`nBuild complete!" -ForegroundColor Green
Write-Host "  Functions exported: $($functionsToExport.Count)" -ForegroundColor Gray

# Generate docs with platyPS
Write-Host "`nGenerating documentation..." -ForegroundColor Cyan

# Ensure platyPS is present
if ( !(Get-Module -ListAvailable -Name "platyPS") ) { Install-Module platyPS -Repository PSGallery -Force -Scope CurrentUser }
Import-Module platyPS -ErrorAction Stop
Import-Module $outputPsd1 -Force -ErrorAction Stop

foreach ( $func in $functionsToExport ) {
    try { New-MarkdownHelp -Command $func.Name -OutputFolder (join-path $basePath "docs\$($func.Category)") -Force | Out-Null }
    catch { throw $_ }
}

Write-Host "  Documentation generated in: $($basePath)\docs" -ForegroundColor Green

# tests
Write-Host "`nRunning unit tests..." -ForegroundColor Cyan
if ( !(Get-MgContext) ) { Connect-MgGraph -NoWelcome }
Invoke-Pester -Path (Join-Path $basePath "tests\Core.Tests.ps1")
Invoke-Pester -Path (Join-Path $basePath "tests\Helpers.Unit.Tests.ps1")
invoke-pester -Path (Join-Path $basePath "tests\Graph.Integration.Tests.ps1")

# Package (zip architecture: moduleName/moduleVersion/psm1 and psd1)
$zipPath = Join-Path $basePath "$moduleName.zip"
Write-Host "`nCreating package $zipPath ..." -ForegroundColor Cyan
$outputPsm1, $outputPsd1 | Compress-Archive -DestinationPath $zipPath -Force
Write-Host "  Package created: $zipPath" -ForegroundColor Green
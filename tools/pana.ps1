# This script runs the pana tool on a package
# Usage: .\tools\pana.ps1 package_name
#   or: .\tools\pana.ps1 -Help

param(
    [Parameter(Position=0)]
    [string]$PackageName,
    
    [switch]$Help
)

# Enable strict mode for better error handling
$ErrorActionPreference = "Stop"

# Function to display help
function Show-Help {
    Write-Host "Usage: .\tools\pana.ps1 package_name"
    Write-Host ""
    Write-Host "Runs the pana tool on a package to check its pub.dev readiness."
    Write-Host ""
    Write-Host "Arguments:"
    Write-Host "  package_name    Name of the package in the packages\ directory"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Help           Show this help message"
    Write-Host ""
    Write-Host "Available packages:"
    if (Test-Path "packages") {
        Get-ChildItem "packages" -Directory | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
    }
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  .\tools\pana.ps1 puer"
}

# Function to cleanup temporary files
function Cleanup {
    if ($script:tmpDir -and (Test-Path $script:tmpDir)) {
        Write-Host "Cleaning up temporary files..."
        Remove-Item -Path $script:tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Set up cleanup on exit
$script:tmpDir = $null
try {
    # Check for help flag
    if ($Help -or [string]::IsNullOrEmpty($PackageName)) {
        Show-Help
        exit 0
    }

    # Get the package path
    $packagePath = "packages\$PackageName"

    # Check if the packages directory exists
    if (-not (Test-Path "packages")) {
        Write-Host "Error: packages\ directory not found"
        Write-Host "Make sure you run this script from the project root"
        exit 1
    }

    # Check if the package folder exists
    if (-not (Test-Path $packagePath)) {
        Write-Host "Error: Package '$PackageName' does not exist in packages\"
        Write-Host ""
        Write-Host "Available packages:"
        Get-ChildItem "packages" -Directory | ForEach-Object {
            Write-Host "  - $($_.Name)"
        }
        exit 1
    }

    Write-Host "Checking package: $PackageName"
    Write-Host ""

    # Create a unique temporary folder
    $script:tmpDir = Join-Path $env:TEMP "pana_$(New-Guid)"
    $tmpPackageDir = Join-Path $script:tmpDir $PackageName

    # Copy the package files to temporary directory
    Write-Host "Copying package to temporary directory..."
    New-Item -ItemType Directory -Path $tmpPackageDir -Force | Out-Null
    
    # Copy files one by one to avoid reserved device names (nul, con, prn, etc.)
    $reservedNames = @('CON', 'PRN', 'AUX', 'NUL', 'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9', 'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9')
    
    # Get the full path to resolve any relative paths
    $sourceFullPath = (Get-Item $packagePath).FullName
    
    Get-ChildItem -Path $sourceFullPath -Recurse | ForEach-Object {
        $itemName = $_.Name
        $isReserved = $reservedNames -contains $itemName.ToUpper()
        
        if ($isReserved) {
            Write-Host "Skipping reserved device name: $itemName"
        } else {
            $relativePath = $_.FullName.Substring($sourceFullPath.Length).TrimStart('\')
            $destPath = Join-Path $tmpPackageDir $relativePath
            
            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Path $destPath -Force -ErrorAction SilentlyContinue | Out-Null
            } else {
                $destDir = Split-Path $destPath -Parent
                if (-not (Test-Path $destDir)) {
                    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                }
                Copy-Item -Path $_.FullName -Destination $destPath -Force
            }
        }
    }

    # Activate pana if needed
    Write-Host "Ensuring pana is activated..."
    & fvm dart pub global activate pana
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to activate pana"
        exit 1
    }

    Write-Host ""
    Write-Host "Running pana analysis..."
    Write-Host "----------------------------------------"

    # Run pana on the temporary package
    & fvm dart pub global run pana $tmpPackageDir
    $panaExitCode = $LASTEXITCODE

    Write-Host "----------------------------------------"
    Write-Host "Analysis complete!"

    exit $panaExitCode

} finally {
    # Cleanup is always executed
    Cleanup
}

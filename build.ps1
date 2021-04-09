# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

param(
   [Parameter()]
   [string]
   $OutputDir
)

$moduleName = 'CloudEvents.Sdk'

#region Input
if (-not $OutputDir) {
   $OutputDir = $PSScriptRoot
}

$OutputDir = Join-Path $OutputDir $moduleName

if (-not (Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
#endregion

#region Helper Funcitons
function Write-InfoLog($message) {
   $dt = (Get-Date).ToLongTimeString()
   Write-Host "[$dt] INFO: $message" -ForegroundColor Green
}

function Write-ErrorLog($message) {
   $dt = (Get-Date).ToLongTimeString()
   Write-Host "[$dt] ERROR: $message" -ForegroundColor Red
}

function Test-BuildToolsAreAvailable {
   $dotnetSdk = Get-Command 'dotnet'
   if (-not $dotnetSdk) {
     throw "'dotnet' sdk is not available"
   }
}

function Start-Tests {
param(
   [Parameter()]
   [ValidateSet('unit', 'integration', 'all')]
   [string]
   $TestsType
)
   $pesterModule = Get-Module Pester -List
   if ($pesterModule -eq $null) {
      Write-ErrorLog "Pester Module is not available"
   } else {
      # Run Tests in external process because it will load build output binaries
      Write-InfoLog "Run $TestsType tests"
      $usePowerShell = (Get-Process -Id $pid).ProcessName

      $testLauncherScript = Join-Path (Join-Path $PSScriptRoot 'test') 'RunTests.ps1'
      $CloudEventsModulePath = Join-Path $OutputDir "$moduleName.psd1"
      $testProcessArguments = "-Command $testLauncherScript -CloudEventsModulePath '$CloudEventsModulePath' -TestsType '$TestsType' -EnableProcessExit"

      # Process Exit Code is 0 if all tests pass, otherwise it equals the number of failed tests
      $testProcess = Start-Process `
         -FilePath $usePowerShell `
         -ArgumentList $testProcessArguments `
         -PassThru `
         -NoNewWindow

      $testProcess | Wait-Process
   }
}
#endregion

$dotnetProjectName = 'CloudEventsPowerShell'
$dotnetProjectPath = Join-Path (Join-Path (Join-Path $PSScriptRoot 'src') $dotnetProjectName) "$dotnetProjectName.csproj"

# 1. Test dotnet command is available
Test-BuildToolsAreAvailable

# 2. Publish CloudEvents Module
Write-InfoLog "Publish CloudEvents.Sdk Module to '$OutputDir'"
dotnet publish -c Release -o $OutputDir $dotnetProjectPath

# 3. Cleanup Unnecessary Outputs
Get-ChildItem "$dotnetProjectName*" -Path $OutputDir  | Remove-Item -Confirm:$false

# 4. Run Unit Tests
Start-Tests -TestsType 'unit'

# 5. Run Integration Tests
Start-Tests -TestsType 'integration'

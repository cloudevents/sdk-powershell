# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

<#
    .SYNOPSIS
    Publish the CloudEvents.Sdk module to PSGallery

    .PARAMETER NuGetApiKey
    PowerShell Gallery API Key to be used to publish the module

    .PARAMETER ModuleReleaseDir
    Parent directory of the 'CloudEvents.Sdk' module that will be published
#>

param(
    [Parameter(Mandatory = $true)]
    [string]
    $NuGetApiKey,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]
    $ModuleReleaseDir
)

# Work with full path in case relative path is provided
$ModuleReleaseDir = (Resolve-Path $ModuleReleaseDir).Path

$moduleName = 'CloudEvents.Sdk'

# Build is successful and all tests pass
$env:PSModulePath += [IO.Path]::PathSeparator + $ModuleReleaseDir

$localModule = Get-Module $moduleName -ListAvailable
$psGalleryModule = Find-Module -Name $moduleName -Repository PSGallery

# Throw an exception if module with the same version is availble on PSGallery
if ( $null -ne $psGalleryModule -and `
     $null -ne $localModule -and `
     $psGalleryModule.Version -eq $localModule.Version ) {
    throw "'$moduleName' module with version '$($localModule.Version)' is already available on PSGallery"
}

Write-Host "Performing operation: Publish-Module -Name $moduleName -RequiredVersion $($localModule.Version) -NuGetApiKey *** -Repository PSGallery -Confirm:`$false"
Publish-Module -Name $moduleName -RequiredVersion $localModule.Version -NuGetApiKey $NuGetApiKey -Repository PSGallery -Confirm:$false -ErrorAction Stop

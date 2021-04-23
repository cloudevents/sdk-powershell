# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

param(
   [Parameter()]
   [ValidateScript({Test-Path $_})]
   [string]
   $CloudEventsModulePath,

   [Parameter()]
   [ValidateSet('unit', 'integration', 'all')]
   [string]
   $TestsType,

   [Parameter()]
   [Switch]
   $EnableProcessExit
)

Import-Module $CloudEventsModulePath

if ($TestsType -eq 'unit' -or $TestsType -eq 'all') {
   $pesterContainer = New-PesterContainer -Path (Join-Path $PSScriptRoot 'unit')
   $pesterConfiguration = [PesterConfiguration]::Default

   $pesterConfiguration.Run.Path = (Join-Path $PSScriptRoot 'unit')
   $pesterConfiguration.Run.Container = $pesterContainer
   $pesterConfiguration.Run.Exit = $EnableProcessExit.IsPresent

   Invoke-Pester -Configuration $pesterConfiguration
}

if ($TestsType -eq 'integration' -or $TestsType -eq 'all') {

   $testsData = @{
      CloudEventsModulePath = $CloudEventsModulePath
   }

   $pesterContainer = New-PesterContainer -Path (Join-Path $PSScriptRoot 'integration') -Data $testsData
   $pesterConfiguration = [PesterConfiguration]::Default

   $pesterConfiguration.Run.Path = (Join-Path $PSScriptRoot 'integration')
   $pesterConfiguration.Run.Container = $pesterContainer
   $pesterConfiguration.Run.Exit = $EnableProcessExit.IsPresent

   Invoke-Pester -Configuration $pesterConfiguration
}

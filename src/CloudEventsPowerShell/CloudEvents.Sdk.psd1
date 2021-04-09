# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

@{

# Script module or binary module file associated with this manifest.
RootModule = 'CloudEvents.Sdk.psm1'

# Version number of this module.
ModuleVersion = '0.1.4'

# Supported PSEditions
CompatiblePSEditions = @('Core')

# ID used to uniquely identify this module
GUID = 'd0d7d392-0eab-40a8-8a3f-78ba41ef2f02'

# Author of this module
Author = 'dmilov'

# Company or vendor of this module
CompanyName = 'The CloudEvents Authors'

# Copyright statement for this module
Copyright = '(c) The CloudEvents Authors'

# Description of the functionality provided by this module
Description = 'PowerShell CloudEvents SDK'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '7.0'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = @('CloudNative.CloudEvents.dll')

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = @(
'New-CloudEvent', 'Add-CloudEventData', 'Add-CloudEventJsonData', 'Add-CloudEventXmlData', 'Read-CloudEventData', 'Read-CloudEventJsonData', 'Read-CloudEventXmlData', # CloudEvent Object Functions
'ConvertTo-HttpMessage', 'ConvertFrom-HttpMessage' # Http Binding Functions
)

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

}


# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

param(
   [Parameter()]
   [ValidateScript({Test-Path $_})]
   [string]
   $CloudEventsModulePath)

Describe "Client-Server Integration Tests" {
   Context "Send And Receive CloudEvents over Http" {
     BeforeAll {
         $testServerUrl = 'http://localhost:52673/'

         $serverProcess = $null

         . (Join-Path $PSScriptRoot 'ProtocolConstants.ps1')

         # Starts CloudEvent Test Server
         $usePowerShell = (Get-Process -Id $pid).ProcessName
         $serverScript = Join-Path $PSScriptRoot 'HttpServer.ps1'
         $serverProcessArguments = "-Command $serverScript -CloudEventsModulePath '$CloudEventsModulePath' -ServerUrl '$testServerUrl'"

         $serverProcess = Start-Process `
            -FilePath $usePowerShell `
            -ArgumentList $serverProcessArguments `
            -PassThru `
            -NoNewWindow
      }

      AfterAll {
         # Requests Stop CloudEvent Test Server
         $serverStopRequest = `
            New-CloudEvent `
               -Id ([Guid]::NewGuid()) `
               -Type $script:ServerStopType `
               -Source $script:ClientSource | `
            ConvertTo-HttpMessage `
               -ContentMode Structured

         Invoke-WebRequest `
               -Uri $testServerUrl `
               -Headers $serverStopRequest.Headers `
               -Body $serverStopRequest.Body | Out-Null

         if ($serverProcess -ne $null -and `
             -not $serverProcess.HasExited) {
            $serverProcess | Wait-Process
         }
      }

      It 'Echo binary content mode cloud events' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                  -Type $script:EchoBinaryType `
                  -Source $script:ClientSource `
                  -Id 'integration-test-1' `
                  -Time (Get-Date) | `
               Add-CloudEventJsonData -Data @{
                  'a1' = 'b'
                  'a2' = 'c'
                  'a3' = 'd'
               }

         # Act

         ## Convert CloudEvent to HTTP Message
         $httpRequest = ConvertTo-HttpMessage `
               -CloudEvent $cloudEvent `
               -ContentMode Binary

         ## Invoke WebRequest with the HTTP Message
         $httpResponse = Invoke-WebRequest `
               -Uri $testServerUrl `
               -Headers $httpRequest.Headers `
               -Body $httpRequest.Body

         ## Convert HTTP Response to CloudEvent
         $resultCloudEvent = ConvertFrom-HttpMessage `
               -Headers $httpResponse.Headers `
               -Body $httpResponse.Content

         # Assert

         ## Assert echoed CloudEvent
         $resultCloudEvent | Should -Not -Be $null
         $resultCloudEvent.Source | Should -Be $script:ServerSource
         $resultCloudEvent.Type | Should -Be $script:EchoBinaryType
         $resultCloudEvent.Id | Should -Be $cloudEvent.Id
         $resultCloudEvent.Time | Should -BeGreaterThan $cloudEvent.Time

         ## Assert Result CloudEvent Data
         ## Read Data as Json
         $resultData = $resultCloudEvent | Read-CloudEventJsonData
         $resultData.a1 | Should -Be 'b'
         $resultData.a2 | Should -Be 'c'
         $resultData.a3 | Should -Be 'd'
      }

      It 'Echo binary content mode cloud events with XML data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                  -Type $script:EchoBinaryType `
                  -Source $script:ClientSource `
                  -Id 'integration-test-2' `
                  -Time (Get-Date) | `
               Add-CloudEventXmlData -Data @{
                  'a1' = @{
                     'a2' = 'c'
                     'a3' = 'd'
                  }
               } `
               -AttributesKeysInElementAttributes $false

         # Act

         ## Convert CloudEvent to HTTP Message
         $httpRequest = ConvertTo-HttpMessage `
               -CloudEvent $cloudEvent `
               -ContentMode Binary

         ## Invoke WebRequest with the HTTP Message
         $httpResponse = Invoke-WebRequest `
               -Uri $testServerUrl `
               -Headers $httpRequest.Headers `
               -Body $httpRequest.Body

         ## Convert HTTP Response to CloudEvent
         $resultCloudEvent = ConvertFrom-HttpMessage `
               -Headers $httpResponse.Headers `
               -Body $httpResponse.Content

         # Assert

         ## Assert echoed CloudEvent
         $resultCloudEvent | Should -Not -Be $null
         $resultCloudEvent.Source | Should -Be $script:ServerSource
         $resultCloudEvent.Type | Should -Be $script:EchoBinaryType
         $resultCloudEvent.Id | Should -Be $cloudEvent.Id
         $resultCloudEvent.Time | Should -BeGreaterThan $cloudEvent.Time

         ## Assert Result CloudEvent Data
         ## Read Data as Xml
         $resultData = $resultCloudEvent | Read-CloudEventXmlData -ConvertMode 'SkipAttributes'
         $resultData -is [hashtable] | Should -Be $true
         $resultData.a1 -is [hashtable] | Should -Be $true
         $resultData.a1.a2 | Should -Be 'c'
         $resultData.a1.a3 | Should -Be 'd'
      }

      It 'Echo structured content mode cloud events' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                  -Type $script:EchoStructuredType `
                  -Source $script:ClientSource `
                  -Id 'integration-test-3' `
                  -Time (Get-Date) | `
               Add-CloudEventJsonData -Data @{
                  'b1' = 'd'
                  'b2' = 'e'
                  'b3' = 'f'
               }

         # Act

         ## Convert CloudEvent to HTTP Message
         $httpRequest = ConvertTo-HttpMessage `
               -CloudEvent $cloudEvent `
               -ContentMode Structured

         ## Invoke WebRequest with the HTTP Message
         $httpResponse = Invoke-WebRequest `
               -Uri $testServerUrl `
               -Headers $httpRequest.Headers `
               -Body $httpRequest.Body

         ## Convert HTTP Response to CloudEvent
         $resultCloudEvent = ConvertFrom-HttpMessage `
               -Headers $httpResponse.Headers `
               -Body $httpResponse.Content

         # Assert

         ## Assert echoed CloudEvent
         $resultCloudEvent | Should -Not -Be $null
         $resultCloudEvent.Source | Should -Be $script:ServerSource
         $resultCloudEvent.Type | Should -Be $script:EchoStructuredType
         $resultCloudEvent.Id | Should -Be $cloudEvent.Id
         $resultCloudEvent.Time | Should -BeGreaterThan $cloudEvent.Time

         ## Assert Result CloudEvent Data
         ## Read Data as Json
         $resultData = $resultCloudEvent | Read-CloudEventJsonData
         $resultData.b1 | Should -Be 'd'
         $resultData.b2 | Should -Be 'e'
         $resultData.b3 | Should -Be 'f'
      }

      It 'Echo structured content mode cloud events with XML data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                  -Type $script:EchoStructuredType `
                  -Source $script:ClientSource `
                  -Id 'integration-test-4' `
                  -Time (Get-Date) | `
               Add-CloudEventXmlData -Data @{
                  'b1' = @{
                     'b2' = 'e'
                     'b3' = 'f'
                  }
               } `
               -AttributesKeysInElementAttributes $false

         # Act

         ## Convert CloudEvent to HTTP Message
         $httpRequest = ConvertTo-HttpMessage `
               -CloudEvent $cloudEvent `
               -ContentMode Structured

         ## Invoke WebRequest with the HTTP Message
         $httpResponse = Invoke-WebRequest `
               -Uri $testServerUrl `
               -Headers $httpRequest.Headers `
               -Body $httpRequest.Body

         ## Convert HTTP Response to CloudEvent
         $resultCloudEvent = ConvertFrom-HttpMessage `
               -Headers $httpResponse.Headers `
               -Body $httpResponse.Content

         # Assert

         ## Assert echoed CloudEvent
         $resultCloudEvent | Should -Not -Be $null
         $resultCloudEvent.Source | Should -Be $script:ServerSource
         $resultCloudEvent.Type | Should -Be $script:EchoStructuredType
         $resultCloudEvent.Id | Should -Be $cloudEvent.Id
         $resultCloudEvent.Time | Should -BeGreaterThan $cloudEvent.Time

         ## Assert Result CloudEvent Data
         ## Read Data as Xml
         $resultData = $resultCloudEvent | Read-CloudEventXmlData -ConvertMode 'SkipAttributes'
         $resultData -is [hashtable] | Should -Be $true
         $resultData.b1 -is [hashtable] | Should -Be $true
         $resultData.b1.b2 | Should -Be 'e'
         $resultData.b1.b3 | Should -Be 'f'
      }

      It 'Send cloud event expecting no result' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                  -Type 'no-content' `
                  -Source $script:ClientSource `
                  -Id 'integration-test-5' `
                  -Time (Get-Date) | `
               Add-CloudEventData `
                  -Data 'This is text data' `
                  -DataContentType 'application/text'

         # Act

         ## Convert CloudEvent to HTTP Message
         $httpRequest = ConvertTo-HttpMessage `
               -CloudEvent $cloudEvent `
               -ContentMode Structured

         ## Invoke WebRequest with the HTTP Message
         $httpResponse = Invoke-WebRequest `
               -Uri $testServerUrl `
               -Headers $httpRequest.Headers `
               -Body $httpRequest.Body

         # Assert
         $httpResponse.StatusCode | Should -Be ([int]([System.Net.HttpStatusCode]::NoContent))
      }
   }
}
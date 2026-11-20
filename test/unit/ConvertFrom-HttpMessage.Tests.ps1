# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "ConvertFrom-HttpMessage Function Tests" {
   BeforeEach {
      $script:expectedSpecVersion = '1.0'
      $script:expectedStructuredContentType = 'application/cloudevents+json'
   }

   Context "Accepts pipeline HTTP message objects" {
      It 'Round-trips ConvertTo-HttpMessage output through the pipeline' {
         $cloudEvent = New-CloudEvent -Type 'test' -Source 'urn:test' -Id 'round-trip-id' |
            Set-CloudEventData -Data 'payload' -DataContentType 'text/plain'
         $httpMessage = $cloudEvent | ConvertTo-HttpMessage -ContentMode Binary

         $actual = $httpMessage | ConvertFrom-HttpMessage

         $httpMessage.PSTypeNames | Should -Contain 'CloudEvents.HttpMessage'
         $actual.Id | Should -Be 'round-trip-id'
         $actual.Type | Should -Be 'test'
         $actual.Source | Should -Be 'urn:test'
         [Text.Encoding]::UTF8.GetString($actual.Data) | Should -Be 'payload'
      }

      It 'Binds Invoke-WebRequest-shaped Headers and Content properties' {
         $headers = [System.Collections.Generic.Dictionary[string, string[]]]::new()
         $headers.Add('Content-Type', [string[]]@('text/plain'))
         $headers.Add('ce-specversion', [string[]]@('1.0'))
         $headers.Add('ce-type', [string[]]@('test'))
         $headers.Add('ce-source', [string[]]@('urn:test'))
         $headers.Add('ce-id', [string[]]@('iwr-shaped-id'))
         $response = [pscustomobject]@{
            Headers = $headers
            Content = [Text.Encoding]::UTF8.GetBytes('response body')
         }

         $actual = $response | ConvertFrom-HttpMessage

         $actual.Id | Should -Be 'iwr-shaped-id'
         $actual.Type | Should -Be 'test'
         $actual.Source | Should -Be 'urn:test'
         [Text.Encoding]::UTF8.GetString($actual.Data) | Should -Be 'response body'
      }

      It 'Accepts a null Content property for a bodyless binary CloudEvent' {
         $headers = @{
            'Content-Type' = 'application/octet-stream'
            'ce-specversion' = '1.0'
            'ce-type' = 'test'
            'ce-source' = 'urn:test'
            'ce-id' = 'null-body-id'
         }
         $response = [pscustomobject]@{
            Headers = $headers
            Content = $null
         }

         $actual = $response | ConvertFrom-HttpMessage

         $actual.Id | Should -Be 'null-body-id'
         $actual.Type | Should -Be 'test'
         $actual.Data | Should -BeNullOrEmpty
      }

      It 'Looks up lowercase headers in a case-sensitive dictionary' {
         $headers = [System.Collections.Generic.Dictionary[string, string[]]]::new()
         $headers.Add('content-type', [string[]]@('text/plain'))
         $headers.Add('ce-specversion', [string[]]@('1.0'))
         $headers.Add('ce-type', [string[]]@('test'))
         $headers.Add('ce-source', [string[]]@('urn:test'))
         $headers.Add('ce-id', [string[]]@('lowercase-header-id'))

         $actual = ConvertFrom-HttpMessage `
            -Headers $headers `
            -Body ([Text.Encoding]::UTF8.GetBytes('payload'))

         $actual.Id | Should -Be 'lowercase-header-id'
         $actual.Type | Should -Be 'test'
         $actual.Source | Should -Be 'urn:test'
         $actual.DataContentType.ToString() | Should -Be 'text/plain'
         [Text.Encoding]::UTF8.GetString($actual.Data) | Should -Be 'payload'
      }

      It 'Recognizes the spec version when the headers include a Keys header' {
         $headers = [System.Collections.Generic.Dictionary[string, string[]]]::new()
         $headers.Add('Content-Type', [string[]]@('text/plain'))
         $headers.Add('Keys', [string[]]@('shadowed value'))
         $headers.Add('ce-specversion', [string[]]@('1.0'))
         $headers.Add('ce-type', [string[]]@('test'))
         $headers.Add('ce-source', [string[]]@('urn:test'))
         $headers.Add('ce-id', [string[]]@('keys-header-id'))

         $actual = ConvertFrom-HttpMessage `
            -Headers $headers `
            -Body ([Text.Encoding]::UTF8.GetBytes('payload'))

         $actual.Id | Should -Be 'keys-header-id'
         $actual.Type | Should -Be 'test'
         $actual.Source | Should -Be 'urn:test'
      }
   }

   Context "Converts CloudEvent in Binary Content Mode" {
      It 'Converts a CloudEvent with all properties and json format data' {

         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedId  = 'test-id-1'
         $expectedTime = Get-Date `
            -Year 2021 `
            -Month 1 `
            -Day 18 `
            -Hour 12 `
            -Minute 30 `
            -Second 23 `
            -MilliSecond 134
         $expectedDataContentType = 'application/json'

         $headers = @{
            'Content-Type' = @($expectedDataContentType, 'charset=utf-8')
            'ce-specversion' = $expectedSpecVersion
            'ce-type' = $expectedType
            'ce-time' = $expectedTime.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            'ce-id' = $expectedId
            'ce-source' = $expectedSource
         }

         $body =[Text.Encoding]::UTF8.GetBytes('{
  "l10": {
     "l2": {
        "l3": "wow"
     }
  },
  "l11": "mhm"
}')

         # Act
         $actual = ConvertFrom-HttpMessage `
                     -Headers $headers `
                     -Body $body

         # Assert
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.Id | Should -Be $expectedId
         $actual.Time.Year | Should -Be $expectedTime.Year
         $actual.Time.Month | Should -Be $expectedTime.Month
         $actual.Time.Day | Should -Be $expectedTime.Day
         $actual.Time.Hours | Should -Be $expectedTime.Hours
         $actual.Time.Minutes | Should -Be $expectedTime.Minutes
         $actual.Time.Seconds | Should -Be $expectedTime.Seconds
         $actual.Time.MilliSeconds | Should -Be $expectedTime.MilliSeconds
         $actual.DataContentType | Should -Be $expectedDataContentType

         ## Assert Data
         $actualHTData = $actual | Read-CloudEventJsonData -Depth 3

         $actualHTData | Should -Not -Be $null
         $actualHTData.l10.l2.l3 | Should -Be 'wow'
         $actualHTData.l11 | Should -Be 'mhm'

      }

      It 'Converts a CloudEvent with required properties and application/xml format data' {
         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedDataContentType = 'application/xml'
         $expectedId  = 'test-id-2'
         $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')

         $headers = @{
            'Content-Type' = @($expectedDataContentType, 'charset=utf-8')
            'ce-specversion' = $expectedSpecVersion
            'ce-type' = $expectedType
            'ce-source' = $expectedSource
            'ce-id' = $expectedId
         }

         $body = $expectedData

         # Act
         $actual = ConvertFrom-HttpMessage `
                     -Headers $headers `
                     -Body $body

         # Assert
         $actual | Should -Not -Be $null
         $actual.Id | Should -Be $expectedId
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.DataContentType | Should -Be $expectedDataContentType
         $actual.Data | Should -Be $expectedData

         ## Assert Data obtained by Read-CloudEventData
         $actualData = $actual | Read-CloudEventData

         $actualData | Should -Be $expectedData
      }

      It 'Returns null when ce-id is not specified' {
        # Arrange
        $expectedType = 'test'
        $expectedSource  = 'urn:test'
        $expectedDataContentType = 'application/xml'
        $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')

        $headers = @{
           'Content-Type' = @($expectedDataContentType, 'charset=utf-8')
           'ce-specversion' = $expectedSpecVersion
           'ce-type' = $expectedType
           'ce-source' = $expectedSource
        }

        $body = $expectedData

        # Act
        $actual = ConvertFrom-HttpMessage `
                    -Headers $headers `
                    -Body $body

        # Assert
        $actual | Should -Be $null
     }

     It 'Returns null when ce-source is not specified' {
        # Arrange
        $expectedType = 'test'
        $expectedDataContentType = 'application/xml'
        $expectedId  = 'test-id-3'
        $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')

        $headers = @{
           'Content-Type' = @($expectedDataContentType, 'charset=utf-8')
           'ce-specversion' = $expectedSpecVersion
           'ce-type' = $expectedType
           'ce-id' = $expectedId
        }

        $body = $expectedData

        # Act
        $actual = ConvertFrom-HttpMessage `
                    -Headers $headers `
                    -Body $body

        # Assert
        $actual | Should -Be $null
     }

     It 'Returns null when ce-type is not specified' {
        # Arrange
        $expectedSource  = 'urn:test'
        $expectedDataContentType = 'application/xml'
        $expectedId  = 'test-id-4'
        $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')

        $headers = @{
           'Content-Type' = @($expectedDataContentType, 'charset=utf-8')
           'ce-specversion' = $expectedSpecVersion
           'ce-source' = $expectedSource
           'ce-id' = $expectedId
        }

        $body = $expectedData

        # Act
        $actual = ConvertFrom-HttpMessage `
                    -Headers $headers `
                    -Body $body

        # Assert
        $actual | Should -Be $null
     }
   }

   Context "Converts CloudEvent in Structured Content Mode" {
      It 'Converts a CloudEvent with all properties and json format data' {
          # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedId  = 'test-id-1'
         $expectedTime = Get-Date `
            -Year 2021 `
            -Month 1 `
            -Day 18 `
            -Hour 12 `
            -Minute 30 `
            -Second 23 `
            -MilliSecond 134
         $expectedDataContentType = 'application/json'

         $headers = @{
            'Content-Type' = $expectedStructuredContentType
         }

         $eventData = @{
  'l10' = @{
     'l2' = @{
        'l3' = 'wow'
     }
  }
  'l11' = 'mhm'
}

         $structuredJsonBody = @{
            'specversion' = $expectedSpecVersion
            'type' = $expectedType
            'time' = $expectedTime.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            'id' = $expectedId
            'source' = $expectedSource
            'datacontenttype' = $expectedDataContentType
         }

         $structuredJsonBody['data_base64'] = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($eventData | ConvertTo-Json -Depth 3)))

         $body = [Text.Encoding]::UTF8.GetBytes(($structuredJsonBody | ConvertTo-Json))

         # Act
         $actual = ConvertFrom-HttpMessage `
                     -Headers $headers `
                     -Body $body

         # Assert
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.Id | Should -Be $expectedId
         $actual.Time.Year | Should -Be $expectedTime.Year
         $actual.Time.Month | Should -Be $expectedTime.Month
         $actual.Time.Day | Should -Be $expectedTime.Day
         $actual.Time.Hours | Should -Be $expectedTime.Hours
         $actual.Time.Minutes | Should -Be $expectedTime.Minutes
         $actual.Time.Seconds | Should -Be $expectedTime.Seconds
         $actual.Time.MilliSeconds | Should -Be $expectedTime.MilliSeconds
         $actual.DataContentType | Should -Be $expectedDataContentType

         ## Assert Data
         $actualHTData = $actual | Read-CloudEventJsonData -Depth 3

         $actualHTData | Should -Not -Be $null
         $actualHTData -is [hashtable] | Should -Be $true
         $actualHTData.l10.l2.l3 | Should -Be 'wow'
         $actualHTData.l11 | Should -Be 'mhm'
      }

      It 'Converts a CloudEvent with required properties and application/xml format data' {
         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedDataContentType = 'application/xml'
         $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')

         $headers = @{
            'Content-Type' = $expectedStructuredContentType
         }

         $structuredJsonBody = @{
            'specversion' = $expectedSpecVersion
            'type' = $expectedType
            'source' = $expectedSource
            'datacontenttype' = $expectedDataContentType
            'data' = $expectedData
         }

         $body = [Text.Encoding]::UTF8.GetBytes(($structuredJsonBody | ConvertTo-Json))

         # Act
         $actual = ConvertFrom-HttpMessage `
                     -Headers $headers `
                     -Body $body

         # Assert
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.DataContentType | Should -Be $expectedDataContentType
         $actual.Data | Should -Be $expectedData

         ## Assert Data obtained by Read-CloudEventData
         $actualData = $actual | Read-CloudEventData

         $actualData | Should -Be $expectedData
      }

      It 'Throws error when CloudEvent encoding is not non-batching JSON' {
         # Arrange
         $unsupportedContentFormat = 'application/cloudevents-batch+json'

         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedDataContentType = 'application/xml'
         $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')

         $headers = @{
            'Content-Type' = $unsupportedContentFormat
         }

         $structuredJsonBody = @{
            'specversion' = $expectedSpecVersion
            'type' = $expectedType
            'source' = $expectedSource
            'datacontenttype' = $expectedDataContentType
            'data' = $expectedData
         }

         $body = [Text.Encoding]::UTF8.GetBytes(($structuredJsonBody | ConvertTo-Json))

         # Act & Assert
         {ConvertFrom-HttpMessage `
                     -Headers $headers `
                     -Body $body } | `
         Should -Throw "*Unsupported CloudEvents encoding*"
      }

      It 'Returns null when no Content-Type header' {
        # Arrange

        $expectedType = 'test'
        $expectedSource  = 'urn:test'
        $expectedDataContentType = 'application/xml'
        $expectedData = [Text.Encoding]::UTF8.GetBytes('<much wow="xml"/>')
        $structuredJsonBody = @{
           'specversion' = $expectedSpecVersion
           'type' = $expectedType
           'source' = $expectedSource
           'datacontenttype' = $expectedDataContentType
           'data' = $expectedData
        }

        $body = [Text.Encoding]::UTF8.GetBytes(($structuredJsonBody | ConvertTo-Json))

        # Act & Assert
        $ce = ConvertFrom-HttpMessage `
                    -Headers @{} `
                    -Body $body
        $ce | Should -Be $null
     }
   }
}

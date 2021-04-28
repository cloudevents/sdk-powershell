# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "ConvertFrom-HttpMessage Function Tests" {
   BeforeAll {
      $expectedSpecVersion = '1.0'
      $expectedStructuredContentType = 'application/cloudevents+json'
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
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.DataContentType | Should -Be $expectedDataContentType
         $actual.Data | Should -Be $expectedData

         ## Assert Data obtained by Read-CloudEventData
         $actualData = $actual | Read-CloudEventData

         $actualData | Should -Be $expectedData
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
   }
}

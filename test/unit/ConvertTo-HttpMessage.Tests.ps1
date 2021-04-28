# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "ConvertTo-HttpMessage Function Tests" {
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
         $expectedTime  = Get-Date -Year 2021 -Month 1 -Day 18 -Hour 12 -Minute 30 -Second 0 -Millisecond 0
         $expectedDataContentType = 'application/json'

         $cloudEvent = New-CloudEvent `
                        -Type $expectedType `
                        -Source $expectedSource `
                        -Id $expectedId `
                        -Time $expectedTime

         $expectedData = @{ 'key1' = 'value2'; 'key3' = 'value4' }
         $cloudEvent = Set-CloudEventJsonData `
                        -CloudEvent $cloudEvent `
                        -Data $expectedData


         # Act
         $actual = $cloudEvent | ConvertTo-HttpMessage -ContentMode Binary

         # Assert
         $actual | Should -Not -Be $null
         $actual.Headers | Should -Not -Be $null
         $actual.Body | Should -Not -Be $null

         ## Assert Headers
         $actual.Headers['Content-Type'] | Should -Be $expectedDataContentType
         $actual.Headers['ce-source'] | Should -Be $expectedSource
         $actual.Headers['ce-specversion'] | Should -Be $expectedSpecVersion
         $actual.Headers['ce-type'] | Should -Be $expectedType
         $actual.Headers['ce-time'] | Should -Be ($expectedTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))
         $actual.Headers['ce-id'] | Should -Be $expectedId

         ## Assert Body

         ## Expected Body is
         ## {
         ##    "key1": "value2",
         ##    "key3": "value4"
         ## }


         $actualDecodedBody = [Text.Encoding]::UTF8.GetString($actual.Body) | ConvertFrom-Json -AsHashtable
         $actualDecodedBody.Keys.Count | Should -Be 2
         $actualDecodedBody.key1 | Should -Be $expectedData.key1
         $actualDecodedBody.key3 | Should -Be $expectedData.key3
      }

      It 'Converts a CloudEvent with required properties and application/xml format data' {
         # Arrange
         $expectedType = 'test'
         $expectedId = 'test-id-1'
         $expectedSource  = 'urn:test'
         $expectedDataContentType = 'application/xml'

         $cloudEvent = New-CloudEvent `
                        -Id $expectedId `
                        -Type $expectedType `
                        -Source $expectedSource

         $expectedData = '<much wow="xml"/>'
         $cloudEvent = Set-CloudEventData `
                        -CloudEvent $cloudEvent `
                        -Data $expectedData `
                        -DataContentType $expectedDataContentType

         # Act
         $actual = $cloudEvent | ConvertTo-HttpMessage -ContentMode Binary

         # Assert
         $actual | Should -Not -Be $null
         $actual.Headers | Should -Not -Be $null
         $actual.Body | Should -Not -Be $null

         ## Assert Headers
         $actual.Headers['Content-Type'] | Should -Be $expectedDataContentType
         $actual.Headers['ce-source'] | Should -Be $expectedSource
         $actual.Headers['ce-specversion'] | Should -Be $expectedSpecVersion
         $actual.Headers['ce-type'] | Should -Be $expectedType
         $actual.Headers['ce-id'] | Should -Be $expectedId

         ## Assert Body

         ## Expected Body is
         ## <much wow="xml"/>
         $actualDecodedBody =[Text.Encoding]::UTF8.GetString($actual.Body)
         $actualDecodedBody | Should -Be $expectedData
      }
   }

   Context "Converts CloudEvent in Structured Content Mode" {
      It 'Converts a CloudEvent with all properties and json format data' {
         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedId  = 'test-id-1'
         $expectedTime  = Get-Date -Year 2021 -Month 1 -Day 18 -Hour 12 -Minute 30 -Second 0 -Millisecond 0
         $expectedDataContentType = 'application/json'

         $cloudEvent = New-CloudEvent `
                        -Type $expectedType `
                        -Source $expectedSource `
                        -Id $expectedId `
                        -Time $expectedTime

         $expectedData = @{ 'key1' = 'value2'; 'key3' = 'value4' }
         $cloudEvent = Set-CloudEventJsonData `
                        -CloudEvent $cloudEvent `
                        -Data $expectedData


         # Act
         $actual = $cloudEvent | ConvertTo-HttpMessage -ContentMode Structured

         # Assert
         $actual | Should -Not -Be $null
         $actual.Headers | Should -Not -Be $null
         $actual.Body | Should -Not -Be $null

         ## Assert Headers
         $headerContentTypes = $actual.Headers['Content-Type'].ToString().Split(';')
         $headerContentTypes[0].Trim() | Should -Be $expectedStructuredContentType
         $headerContentTypes[1].Trim() | Should -Be 'charset=utf-8'

         $actual.Headers['ce-source'] | Should -Be $expectedSource
         $actual.Headers['ce-specversion'] | Should -Be $expectedSpecVersion
         $actual.Headers['ce-type'] | Should -Be $expectedType
         $actual.Headers['ce-time'] | Should -Be ($expectedTime.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))
         $actual.Headers['ce-id'] | Should -Be $expectedId

         ## Assert Body

         ## Expected Body is
         ## {
         ##   "specversion": "1.0",
         ##   "type": "test",
         ##   "source": "urn:test",
         ##   "id": "test-id-1",
         ##   "time": "2021-01-18T12:30:00.9785466+02:00",
         ##   "datacontenttype": "application/json",
         ##   "data": "{
         ##      "key1": "value2",
         ##      "key3": "value4"
         ##   }"
         ## }
         $actualDecodedBody = [Text.Encoding]::UTF8.GetString($actual.Body) | ConvertFrom-Json -Depth 1

         $actualDecodedBody.specversion | Should -Be $expectedSpecVersion
         $actualDecodedBody.type | Should -Be $expectedType
         $actualDecodedBody.source | Should -Be $expectedSource
         Get-Date $actualDecodedBody.time | Should -Be $expectedTime
         $actualDecodedBody.datacontenttype | Should -Be $expectedDataContentType
         $actualDecodedData = $actualDecodedBody.data | ConvertFrom-Json -AsHashtable
         $actualDecodedData.Keys.Count | Should -Be 2
         $actualDecodedData.key1 | Should -Be $expectedData.key1
         $actualDecodedData.key3 | Should -Be $expectedData.key3
      }

      It 'Converts a CloudEvent with required properties and application/xml format data' {
         # Arrange
         $expectedId = ([Guid]::NewGuid().ToString())
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedDataContentType = 'application/xml'

         $cloudEvent = New-CloudEvent `
                        -Id $expectedId `
                        -Type $expectedType `
                        -Source $expectedSource

         $expectedData = '<much wow="xml"/>'
         $cloudEvent = Set-CloudEventData `
                        -CloudEvent $cloudEvent `
                        -Data $expectedData `
                        -DataContentType $expectedDataContentType

         # Act
         $actual = $cloudEvent | ConvertTo-HttpMessage -ContentMode Structured

         # Assert
         $actual | Should -Not -Be $null
         $actual.Headers | Should -Not -Be $null
         $actual.Body | Should -Not -Be $null

         ## Assert Headers
         $headerContentTypes = $actual.Headers['Content-Type'].ToString().Split(';')
         $headerContentTypes[0].Trim() | Should -Be $expectedStructuredContentType
         $headerContentTypes[1].Trim() | Should -Be 'charset=utf-8'
         $actual.Headers['ce-source'] | Should -Be $expectedSource
         $actual.Headers['ce-specversion'] | Should -Be $expectedSpecVersion
         $actual.Headers['ce-type'] | Should -Be $expectedType
         $actual.Headers['ce-id'] | Should -Be $expectedId

         ## Assert Body

         ## Expected Body is
         ## {
         ##   "specversion": "1.0",
         ##   "type": "test",
         ##   "source": "urn:test",
         ##   "datacontenttype": "application/xml",
         ##   "data": "<much wow=/"xml/"/>"
         ## }
         $actualDecodedBody = [Text.Encoding]::UTF8.GetString($actual.Body) | ConvertFrom-Json -Depth 1
         $actualDecodedBody.specversion | Should -Be $expectedSpecVersion
         $actualDecodedBody.type | Should -Be $expectedType
         $actualDecodedBody.source | Should -Be $expectedSource
         $actualDecodedBody.datacontenttype | Should -Be $expectedDataContentType
         $actualDecodedBody.data | Should -Be $expectedData
      }
   }
}

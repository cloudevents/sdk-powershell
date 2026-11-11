# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Set-CloudEventData Function Tests" {
   Context "Sets Data" {
      It 'Sets byte[] data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedData = [Text.Encoding]::UTF8.GetBytes("test")
         $expectedDataContentType = 'application/octet-stream'


         # Act
         $actual = $cloudEvent | `
            Set-CloudEventData `
               -Data $expectedData `
               -DataContentType $expectedDataContentType

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be $expectedDataContentType
         $actual.DataContentType | Should -BeOfType ([System.Net.Mime.ContentType])
         $actual.Data | Should -Be $expectedData
         $actual.DataSchema | Should -BeNullOrEmpty
      }

      It 'Sets data when DataContentType is omitted' {
         $cloudEvent = New-CloudEvent -Id 'test-id' -Type test -Source 'urn:test'

         $actual = $cloudEvent | Set-CloudEventData -Data 'test'

         $actual.Data | Should -Be 'test'
         $actual.DataContentType | Should -BeNullOrEmpty
      }

      It 'Sets xml text data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedData = '<much wow="xml"/>'
         $expectedDataContentType = 'application/xml'


         # Act
         $actual = $cloudEvent | `
            Set-CloudEventData `
               -Data $expectedData `
               -DataContentType $expectedDataContentType

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be $expectedDataContentType
         $actual.Data | Should -Be $expectedData
      }
   }


   Context "Sets DataSchema" {
      It 'Sets or preserves DataSchema' -TestCases @(
         @{ Parameters = @{ DataSchema = 'https://example.com/schema.json' }; ExpectedDataSchema = 'https://example.com/schema.json' }
         @{ Parameters = @{ DataSchema = [System.Uri]'urn:test:schema' }; ExpectedDataSchema = 'urn:test:schema' }
         @{ Parameters = @{}; ExpectedDataSchema = 'https://example.com/original.json' }
      ) {
         param($Parameters, $ExpectedDataSchema)

         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'test-id'
         $cloudEvent.DataSchema = [System.Uri]'https://example.com/original.json'

         $actual = $cloudEvent | Set-CloudEventData -Data '{"a":"b"}' -DataContentType 'application/json' @Parameters

         $actual | Should -Be $cloudEvent
         $actual.DataSchema | Should -BeOfType ([System.Uri])
         $actual.DataSchema | Should -Be $ExpectedDataSchema
         $actual.Data | Should -Be '{"a":"b"}'
         $actual.DataContentType.ToString() | Should -Be 'application/json'
      }

      It 'Rejects invalid DataSchema values' -TestCases @(
         @{ DataSchema = $null }
         @{ DataSchema = '' }
         @{ DataSchema = 'schema.json' }
         @{ DataSchema = 'http://[invalid' }
      ) {
         param($DataSchema)

         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'test-id'

         { $cloudEvent | Set-CloudEventData -Data '{}' -DataContentType 'application/json' -DataSchema $DataSchema } |
            Should -Throw
      }
   }

   Context "Errors on invalid data content type" {
      It 'Throws error on invalid MIME content type' {
         # Arrange
         $invalidContentType = 'invalid'

         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         # Act & Assert
         { Set-CloudEventData `
               -CloudEvent $cloudEvent `
               -Data '1' `
               -DataContentType $invalidContentType } | `
         Should -Throw "*The specified content type is invalid*"
      }

      It 'Throws error on empty content type' {
         # Arrange
         $invalidContentType = [string]::Empty

         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         # Act & Assert
         { Set-CloudEventData `
               -CloudEvent $cloudEvent `
               -Data '1' `
               -DataContentType $invalidContentType } | `
         Should -Throw "*cannot be an empty string*"
      }

      It 'Throws error on null content type' {
         # Arrange
         $invalidContentType = $null

         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         # Act & Assert
         { Set-CloudEventData `
               -CloudEvent $cloudEvent `
               -Data '1' `
               -DataContentType $invalidContentType } | `
         Should -Throw "*cannot be an empty string*"
      }
   }
}
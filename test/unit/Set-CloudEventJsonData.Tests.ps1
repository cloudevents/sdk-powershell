# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Set-CloudEventJsonData Function Tests" {
   Context "Sets DataSchema" {
      It 'Sets or preserves DataSchema' -TestCases @(
         @{ Parameters = @{ DataSchema = 'https://example.com/schema.json' }; ExpectedDataSchema = 'https://example.com/schema.json' }
         @{ Parameters = @{ DataSchema = [System.Uri]'urn:test:schema' }; ExpectedDataSchema = 'urn:test:schema' }
         @{ Parameters = @{}; ExpectedDataSchema = 'https://example.com/original.json' }
      ) {
         param($Parameters, $ExpectedDataSchema)

         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'test-id'
         $cloudEvent.DataSchema = [System.Uri]'https://example.com/original.json'

         $actual = $cloudEvent | Set-CloudEventJsonData -Data @{ 'a' = 'b' } @Parameters

         $actual | Should -Be $cloudEvent
         $actual.DataSchema | Should -BeOfType ([System.Uri])
         $actual.DataSchema | Should -Be $ExpectedDataSchema
         ($actual.Data | ConvertFrom-Json).a | Should -Be 'b'
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

         { $cloudEvent | Set-CloudEventJsonData -Data @{} -DataSchema $DataSchema } |
            Should -Throw
      }
   }

   Context "Sets Json Data" {
      It 'Sets json data with depth 1' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedJson = '{
  "a": "b"
}'

         $htData = @{'a' = 'b'}

         # Act
         $actual = $cloudEvent | Set-CloudEventJsonData -Data $htData -Depth 1

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/json'
         $actual.Data | Should -Be $expectedJson
         $actual.DataSchema | Should -BeNullOrEmpty
      }

      It 'Sets json data with depth 4' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedJson = '{
  "1": {
    "2": {
      "3": {
        "4": "wow"
      }
    }
  }
}'

         $htData = @{
            '1' = @{
               '2' = @{
                  '3' = @{
                     '4' = 'wow'
                  }
               }
            }
         }

         # Act
         $actual = $cloudEvent | Set-CloudEventJsonData -Data $htData -Depth 4

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/json'
         $actual.Data | Should -Be $expectedJson
      }
   }
}
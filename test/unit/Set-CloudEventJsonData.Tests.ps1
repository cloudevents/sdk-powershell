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

      It 'Does not modify the event when DataSchema validation fails' -TestCases @(
         @{ DataSchema = $null }
         @{ DataSchema = 'schema.json' }
      ) {
         param($DataSchema)

         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'test-id'
         $cloudEvent.Data = 'original'
         $cloudEvent.DataContentType = [System.Net.Mime.ContentType]'application/original'
         $cloudEvent.DataSchema = [System.Uri]'https://example.com/original.json'

         {
            $cloudEvent | Set-CloudEventJsonData `
               -Data @{ updated = $true } `
               -DataSchema $DataSchema `
               -ErrorAction Stop
         } | Should -Throw

         $cloudEvent.Data | Should -Be 'original'
         $cloudEvent.DataContentType.ToString() | Should -Be 'application/original'
         $cloudEvent.DataSchema | Should -Be 'https://example.com/original.json'
      }
   }

   Context "Sets Json Data" {
      It 'Binds CloudEvent, Data, and DataSchema from pipeline properties' {
         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'property-bound-id'
         $inputObject = [pscustomobject]@{
            CloudEvent = $cloudEvent
            Data = @{ property = 'bound' }
            DataSchema = 'https://example.com/schema.json'
         }

         $actual = $inputObject | Set-CloudEventJsonData

         ($actual.Data | ConvertFrom-Json -AsHashtable).property | Should -Be 'bound'
         $actual.DataContentType.ToString() | Should -Be 'application/json'
         $actual.DataSchema | Should -Be 'https://example.com/schema.json'
      }

      It 'Does not bind a piped CloudEvent own Data property as the replacement Data' {
         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'guarded-id'
         $cloudEvent.Data = @{ existing = 'value' }
         $originalData = $cloudEvent.Data

         { $cloudEvent | Set-CloudEventJsonData -ErrorAction Stop } |
            Should -Throw '*The Data parameter must be specified when a CloudEvent is piped directly*'

         $cloudEvent.Data | Should -Be $originalData
      }

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
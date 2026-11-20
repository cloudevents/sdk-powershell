# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Set-CloudEventXmlData Function Tests" {
   Context "Sets Xml Data" {
      It 'Binds CloudEvent, Data, and DataSchema from pipeline properties' {
         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'property-bound-id'
         $inputObject = [pscustomobject]@{
            CloudEvent = $cloudEvent
            Data = @{ root = 'bound' }
            DataSchema = 'https://example.com/schema.xml'
         }

         $actual = $inputObject |
            Set-CloudEventXmlData -AttributesKeysInElementAttributes $false

         $actual.Data | Should -Be '<root>bound</root>'
         $actual.DataContentType.ToString() | Should -Be 'application/xml'
         $actual.DataSchema | Should -Be 'https://example.com/schema.xml'
      }

      It 'Preserves the positional AttributesKeysInElementAttributes argument' {
         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'positional-id'

         $actual = Set-CloudEventXmlData $cloudEvent @{ root = 'value' } $false

         $actual.Data | Should -Be '<root>value</root>'
         $actual.DataContentType.ToString() | Should -Be 'application/xml'
      }

      It 'Does not modify the event when DataSchema validation fails' -TestCases @(
         @{ DataSchema = $null }
         @{ DataSchema = 'schema.xml' }
      ) {
         param($DataSchema)

         $cloudEvent = New-CloudEvent -Type test -Source 'urn:test' -Id 'test-id'
         $cloudEvent.Data = 'original'
         $cloudEvent.DataContentType = [System.Net.Mime.ContentType]'application/original'
         $cloudEvent.DataSchema = [System.Uri]'https://example.com/original.xml'

         {
            $cloudEvent | Set-CloudEventXmlData `
               -Data @{ root = 'updated' } `
               -AttributesKeysInElementAttributes $false `
               -DataSchema $DataSchema `
               -ErrorAction Stop
         } | Should -Throw

         $cloudEvent.Data | Should -Be 'original'
         $cloudEvent.DataContentType.ToString() | Should -Be 'application/original'
         $cloudEvent.DataSchema | Should -Be 'https://example.com/original.xml'
      }

      It 'Sets xml data with depth 1' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedXml = '<a>b</a>'

         $htData = @{'a' = 'b'}

         # Act
         $actual = $cloudEvent | Set-CloudEventXmlData -Data $htData -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/xml'
         $actual.Data | Should -Be $expectedXml
      }

      It 'Sets xml data with depth 4' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedXml = '<1><2><3><4>wow</4></3></2></1>'

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
         $actual = $cloudEvent | Set-CloudEventXmlData -Data $htData -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/xml'
         $actual.Data | Should -Be $expectedXml
      }

      It 'Should throw when no single root key hashtable is passed to the Set-CloudEventXmlData Data parameter' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $htData = @{
            '1' = '2'
            '3' = '4'
         }

         # Act & Assert
         { $cloudEvent | Set-CloudEventXmlData -Data $htData -AttributesKeysInElementAttributes $false} | `
         Should -Throw '*Input Hashtable must have single root key*'
      }
   }
}
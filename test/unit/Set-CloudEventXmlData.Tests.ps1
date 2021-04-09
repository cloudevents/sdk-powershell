# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Set-CloudEventXmlData Function Tests" {
   Context "Sets Xml Data" {
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
# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Read-CloudEventXmlData Function Tests" {
   Context "Extracts Xml Data from CloudEvent" {
      It 'Extracts hashtable from CloudEvent with xml data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $xmlData = "<a>b</a>"
         $expectedHtData = @{'a' = 'b'}

         $cloudEvent = $cloudEvent | Add-CloudEventData -Data $xmlData -DataContentType 'application/xml'

         # Act
         $actual = $cloudEvent | Read-CloudEventXmlData -ConvertMode 'SkipAttributes'

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.a | Should -Be 'b'
      }

      It 'Expects error when CloudEvent data is not xml' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $cloudEvent = $cloudEvent | Add-CloudEventData -Data "test" -DataContentType 'application/text'
         $pre

         # Act
         { $cloudEvent | Read-CloudEventXmlData -ConvertMode 'SkipAttributes' -ErrorAction Stop } | `
         Should -Throw "*Cloud Event '$($cloudEvent.Id)' has no xml data*"

      }

      It 'Extracts hashtable from CloudEvent with xml data with depth 4' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $xmlData = '<l1><l2><l3><l4>wow</l4></l3></l2></l1>'
         $expectedHtData = @{
            'l1' = @{
               'l2' = @{
                  'l3' = @{
                     'l4' = 'wow'
                  }
               }
            }
         }

         $cloudEvent = $cloudEvent | Add-CloudEventData -Data $xmlData -DataContentType 'application/xml'

         # Act
         $actual = $cloudEvent | Read-CloudEventXmlData -ConvertMode 'SkipAttributes'

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.l1.l2.l3.l4 | Should -Be 'wow'
      }
   }
}
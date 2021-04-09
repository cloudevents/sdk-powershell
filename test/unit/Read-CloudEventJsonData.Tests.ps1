# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Read-CloudEventJsonData Function Tests" {
   Context "Extracts Json Data from CloudEvent" {
      It 'Extracts hashtable from CloudEvent with json data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedHtData = @{'a' = 'b'}

         $cloudEvent = $cloudEvent | Add-CloudEventJsonData -Data $expectedHtData

         # Act
         $actual = $cloudEvent | Read-CloudEventJsonData

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.a | Should -Be 'b'
      }

      It 'Expects error when CloudEvent data is not json' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $cloudEvent = $cloudEvent | Add-CloudEventData -Data "test" -DataContentType 'application/text'
         $pre

         # Act
         { $cloudEvent | Read-CloudEventJsonData -ErrorAction Stop } | `
         Should -Throw "*Cloud Event '$($cloudEvent.Id)' has no json data*"

      }

      It 'Extracts hashtable from CloudEvent with json data with depth 4' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedHtData = @{
            'l1' = @{
               'l2' = @{
                  'l3' = @{
                     'l4' = 'wow'
                  }
               }
            }
         }

         $cloudEvent = $cloudEvent | Add-CloudEventJsonData -Data $expectedHtData -Depth 4

         # Act
         $actual = $cloudEvent | Read-CloudEventJsonData -Depth 4

         # Assert
         $actual | Should -Not -Be $null
         $actual -is [hashtable] | Should -Be $true
         $actual.l1.l2.l3.l4 | Should -Be 'wow'
      }
   }
}
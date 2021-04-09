# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Set-CloudEventJsonData Function Tests" {
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
         $actual = $cloudEvent | Set-CloudEventJsonData -Data $htData

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/json'
         $actual.Data | Should -Be $expectedJson
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
# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

Describe "Read-CloudEventData Function Tests" {
   Context "Extracts Data from CloudEvent" {
      It 'Reads xml text data' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'


         $expectedData = '<much wow="xml"/>'
         $expectedDataContentType = 'text/xml'

         $cloudEvent = $cloudEvent | Add-CloudEventData -Data $expectedData -DataContentType $expectedDataContentType

         # Act
         $actual = $cloudEvent | Read-CloudEventData

         # Assert
         $actual | Should -Not -Be $null
         $actual | Should -Be $expectedData
      }
   }
}
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
         $actual.Data | Should -Be $expectedData
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
         Should -Throw "*The parameter 'contentType' cannot be an empty string*"
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
         Should -Throw "*The parameter 'contentType' cannot be an empty string*"
      }
   }
}
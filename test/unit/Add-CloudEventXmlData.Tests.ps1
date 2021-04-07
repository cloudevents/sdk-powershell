Describe "Add-CloudEventXmlData Function Tests" {
   Context "Adds Xml Data" {
      It 'Adds xml data with depth 1' {
         # Arrange
         $cloudEvent = New-CloudEvent `
                        -Id ([Guid]::NewGuid()) `
                        -Type test `
                        -Source 'urn:test'

         $expectedXml = '<a>b</a>'

         $htData = @{'a' = 'b'}

         # Act
         $actual = $cloudEvent | Add-CloudEventXmlData -Data $htData -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/xml'
         $actual.Data | Should -Be $expectedXml
      }

      It 'Adds xml data with depth 4' {
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
         $actual = $cloudEvent | Add-CloudEventXmlData -Data $htData -AttributesKeysInElementAttributes $false

         # Assert
         $actual | Should -Not -Be $null
         $actual.DataContentType.ToString() | Should -Be 'application/xml'
         $actual.Data | Should -Be $expectedXml
      }

      It 'Should throw when no single root key hashtable is passed to the Add-CloudEventXmlData Data parameter' {
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
         { $cloudEvent | Add-CloudEventXmlData -Data $htData -AttributesKeysInElementAttributes $false} | `
         Should -Throw '*Input Hashtable must have single root key*'
      }
   }
}
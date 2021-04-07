Describe "New-CloudEvent Function Tests" {
   Context "Create CloudEvent Object" {
      It 'Create CloudEvent with required parameters only' {
         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedId = ([Guid]::NewGuid().ToString())

         # Act
         $actual = New-CloudEvent `
                  -Id $expectedId `
                  -Type $expectedType `
                  -Source $expectedSource

         # Assert
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.Id | Should -Be $expectedId
      }

      It 'Create CloudEvent with all possible parameters' {
         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedId  = 'test-id-1'
         $expectedTime  = Get-Date -Year 2021 -Month 1 -Day 18 -Hour 12 -Minute 30 -Second 0

         # Act
         $actual = New-CloudEvent `
                  -Type $expectedType `
                  -Source $expectedSource `
                  -Id $expectedId `
                  -Time $expectedTime

         # Assert
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.Id | Should -Be $expectedId
         $actual.Time | Should -Be $expectedTime
      }
   }
}
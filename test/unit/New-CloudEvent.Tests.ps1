# **************************************************************************
#  Copyright (c) Cloud Native Foundation.
#  SPDX-License-Identifier: Apache-2.0
# **************************************************************************

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
         $actual.DataSchema | Should -BeNullOrEmpty
      }

      It 'Create CloudEvent with all possible parameters' {
         # Arrange
         $expectedType = 'test'
         $expectedSource  = 'urn:test'
         $expectedId  = 'test-id-1'
         $expectedTime  = Get-Date -Year 2021 -Month 1 -Day 18 -Hour 12 -Minute 30 -Second 0
         $expectedDataSchema = 'https://example.com/schema.json'

         # Act
         $actual = New-CloudEvent `
                  -Type $expectedType `
                  -Source $expectedSource `
                  -Id $expectedId `
                  -Time $expectedTime `
                  -DataSchema $expectedDataSchema

         # Assert
         $actual | Should -Not -Be $null
         $actual.Type | Should -Be $expectedType
         $actual.Source | Should -Be $expectedSource
         $actual.Id | Should -Be $expectedId
         $actual.Time | Should -Be $expectedTime
         $actual.DataSchema | Should -BeOfType ([System.Uri])
         $actual.DataSchema | Should -Be $expectedDataSchema
      }

      It 'Rejects invalid DataSchema values' -TestCases @(
         @{ DataSchema = $null }
         @{ DataSchema = '' }
         @{ DataSchema = 'schema.json' }
         @{ DataSchema = 'http://[invalid' }
      ) {
         param($DataSchema)

         { New-CloudEvent -Type test -Source 'urn:test' -Id 'test-id' -DataSchema $DataSchema } |
            Should -Throw
      }
   }
}
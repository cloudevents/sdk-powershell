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

      It 'Creates CloudEvents from properties and generates per-event defaults' {
         $records = @(
            [pscustomobject]@{ Type = 'test.one'; Source = 'urn:test:one' }
            [pscustomobject]@{ Type = 'test.two'; Source = 'urn:test:two' }
         )
         $before = Get-Date

         $actual = @($records | New-CloudEvent)

         $after = Get-Date
         $actual.Count | Should -Be 2
         $actual[0].Type | Should -Be 'test.one'
         $actual[0].Source | Should -Be 'urn:test:one'
         $actual[1].Type | Should -Be 'test.two'
         $actual[1].Source | Should -Be 'urn:test:two'
         [Guid]::Parse($actual[0].Id) | Should -Not -BeNullOrEmpty
         [Guid]::Parse($actual[1].Id) | Should -Not -BeNullOrEmpty
         $actual[0].Id | Should -Not -Be $actual[1].Id
         $actual[0].Time | Should -BeGreaterOrEqual $before
         $actual[0].Time | Should -BeLessOrEqual $after
         $actual[1].Time | Should -BeGreaterOrEqual $before
         $actual[1].Time | Should -BeLessOrEqual $after
      }

      It 'Binds explicit Id, Time, and DataSchema pipeline properties' {
         $expectedTime = [DateTime]'2025-02-03T04:05:06'
         $record = [pscustomobject]@{
            Type = 'test'
            Source = 'urn:test'
            Id = 'property-id'
            Time = $expectedTime
            DataSchema = 'https://example.com/schema.json'
         }

         $actual = $record | New-CloudEvent

         $actual.Id | Should -Be 'property-id'
         $actual.Time | Should -Be $expectedTime
         $actual.DataSchema | Should -Be 'https://example.com/schema.json'
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
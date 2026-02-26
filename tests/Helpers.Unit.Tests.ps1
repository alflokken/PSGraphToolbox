#Requires -Module Pester
<#
.SYNOPSIS
    Unit tests for helper and utility functions.
.DESCRIPTION
    [AI-GENERATED] This file was generated using Claude Opus 4.5.
    
    Tests pure functions that don't require Graph API connections.
    These tests can run offline and should be fast.
.NOTES
    Run with: Invoke-Pester -Path .\tests\Helpers.Unit.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modulePath = Join-Path $PSScriptRoot "..\PsGraphToolbox.psd1"
    Import-Module $modulePath -Force -ErrorAction Stop
}

#region Split-ArrayIntoChunks Tests
Describe 'Split-ArrayIntoChunks' {
    
    It 'Should split array into correct chunk sizes' {
        $items = 1..50
        $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 20
        
        $chunks.Count | Should -Be 3
        $chunks[0].Count | Should -Be 20
        $chunks[1].Count | Should -Be 20
        $chunks[2].Count | Should -Be 10
    }

    It 'Should return single chunk when array is smaller than chunk size' {
        $items = 1..5
        $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 20
        
        $chunks.Count | Should -Be 1
        $chunks[0].Count | Should -Be 5
    }

    It 'Should handle empty array' {
        $chunks = Split-ArrayIntoChunks -Enumerable @() -ChunkSize 20
        $chunks.Count | Should -Be 0
    }

    It 'Should handle exact chunk size multiple' {
        $items = 1..40
        $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 20
        
        $chunks.Count | Should -Be 2
        $chunks[0].Count | Should -Be 20
        $chunks[1].Count | Should -Be 20
    }
}
#endregion

#region ConvertTo-HashTable Tests
Describe 'ConvertTo-HashTable' {
    
    It 'Should convert array of objects to hashtable keyed by id' {
        $objects = @(
            [PSCustomObject]@{ id = 'a'; name = 'First' }
            [PSCustomObject]@{ id = 'b'; name = 'Second' }
            [PSCustomObject]@{ id = 'c'; name = 'Third' }
        )
        
        $ht = $objects | ConvertTo-HashTable
        
        $ht.Count | Should -Be 3
        $ht['a'].name | Should -Be 'First'
        $ht['b'].name | Should -Be 'Second'
        $ht['c'].name | Should -Be 'Third'
    }

    It 'Should use custom key property' {
        $objects = @(
            [PSCustomObject]@{ userId = 'user1'; displayName = 'John' }
            [PSCustomObject]@{ userId = 'user2'; displayName = 'Jane' }
        )
        
        $ht = $objects | ConvertTo-HashTable -keyProperty 'userId'
        
        $ht['user1'].displayName | Should -Be 'John'
        $ht['user2'].displayName | Should -Be 'Jane'
    }

    It 'Should throw when key property does not exist' {
        $objects = @([PSCustomObject]@{ name = 'Test' })
        
        { $objects | ConvertTo-HashTable -keyProperty 'id' } | Should -Throw 
    }

    It 'Should handle single object' {
        $obj = [PSCustomObject]@{ id = 'single'; value = 42 }
        
        $ht = $obj | ConvertTo-HashTable
        
        $ht.Count | Should -Be 1
        $ht['single'].value | Should -Be 42
    }
}
#endregion

#region New-GtRequestUri Tests
Describe 'New-GtRequestUri' {
    
    It 'Should build simple resource path' {
        $uri = New-GtRequestUri -resourcePath "users"
        $uri | Should -Be "v1.0/users"
    }

    It 'Should add select parameter' {
        $uri = New-GtRequestUri -resourcePath "users" -select "id,displayName"
        $uri | Should -Be "v1.0/users?`$select=id,displayName"
    }

    It 'Should URL-encode filter parameter' {
        $uri = New-GtRequestUri -resourcePath "users" -filter "displayName eq 'John Doe'"
        $uri | Should -eq "v1.0/users?`$filter=displayName%20eq%20'John%20Doe'"
    }

    It 'Should use beta API version when specified' {
        $uri = New-GtRequestUri -resourcePath "users" -apiVersion "beta"
        $uri | Should -Be "beta/users"
    }

    It 'Should strip version prefix from resourcePath if included' {
        $uri = New-GtRequestUri -resourcePath "v1.0/users" -apiVersion "v1.0"
        $uri | Should -Be "v1.0/users"
    }

    It 'Should combine multiple OData parameters' {
        $uri = New-GtRequestUri -resourcePath "users" -select "id" -top 10 -count
        
        $uri | Should -Match "\`$select=id"
        $uri | Should -Match "\`$top=10"
        $uri | Should -Match "\`$count=true"
    }

    It 'Should URL-encode search parameter' {
        $uri = New-GtRequestUri -resourcePath "users" -search '"displayName:John"'
        $uri | Should -Match "\`$search="
    }

    It 'Should URL-encode expand parameter' {
        $uri = New-GtRequestUri -resourcePath "users" -expand "manager(`$select=displayName)"
        $uri | Should -Match "\`$expand="
    }
}
#endregion

#region isValidGuid Tests (extended)
Describe 'isValidGuid' {
    
    It 'Should validate standard GUID formats' {
        '00000000-0000-0000-0000-000000000000' | isValidGuid | Should -BeTrue
        'ffffffff-ffff-ffff-ffff-ffffffffffff' | isValidGuid | Should -BeTrue
        'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' | isValidGuid | Should -BeTrue
    }

    It 'Should reject invalid formats' {
        'not-a-guid' | isValidGuid | Should -BeFalse
        '' | isValidGuid | Should -BeFalse
        '00000000-0000-0000' | isValidGuid | Should -BeFalse
        '{00000000-0000-0000-0000-000000000000}' | isValidGuid | Should -BeFalse  # braces not supported
    }

    It 'Should work with pipeline of GUIDs' {
        $guids = @(
            '11111111-1111-1111-1111-111111111111',
            '22222222-2222-2222-2222-222222222222'
        )
        $results = $guids | isValidGuid
        $results | Should -Not -Contain $false
    }
}
#endregion

#region isValidUserPrincipalName Tests (extended)
Describe 'isValidUserPrincipalName' {
    
    It 'Should validate common UPN formats' {
        'user@contoso.com' | isValidUserPrincipalName | Should -BeTrue
        'first.last@contoso.com' | isValidUserPrincipalName | Should -BeTrue
        'user123@sub.domain.com' | isValidUserPrincipalName | Should -BeTrue
        'user-name@my-company.co.uk' | isValidUserPrincipalName | Should -BeTrue
    }

    It 'Should reject invalid UPN formats' {
        'user' | isValidUserPrincipalName | Should -BeFalse
        '@contoso.com' | isValidUserPrincipalName | Should -BeFalse
        'user@' | isValidUserPrincipalName | Should -BeFalse
        'user@contoso' | isValidUserPrincipalName | Should -BeFalse
        '' | isValidUserPrincipalName | Should -BeFalse
    }

    It 'Should reject GUID as UPN' {
        '00000000-0000-0000-0000-000000000000' | isValidUserPrincipalName | Should -BeFalse
    }
}
#endregion

#region Get-IdFromInputObject Tests (extended)
Describe 'Get-IdFromInputObject' {
    
    Context 'GUID extraction' {
        It 'Should extract GUID from string' {
            $result = Get-IdFromInputObject '11111111-1111-1111-1111-111111111111'
            $result.id | Should -Be '11111111-1111-1111-1111-111111111111'
            $result.type | Should -Be 'guid'
        }

        It 'Should extract GUID from object with id property' {
            $obj = [PSCustomObject]@{ id = '22222222-2222-2222-2222-222222222222' }
            $result = Get-IdFromInputObject $obj
            $result.type | Should -Be 'guid'
        }
    }

    Context 'UPN extraction' {
        It 'Should extract UPN from string' {
            $result = Get-IdFromInputObject 'user@contoso.com'
            $result.id | Should -Be 'user@contoso.com'
            $result.type | Should -Be 'upn'
        }

        It 'Should extract UPN from object with userPrincipalName property' {
            $obj = [PSCustomObject]@{ userPrincipalName = 'jane@contoso.com' }
            $result = Get-IdFromInputObject $obj
            $result.id | Should -Be 'jane@contoso.com'
            $result.type | Should -Be 'upn'
        }
    }

    Context 'objectIdOnly switch' {
        It 'Should accept GUID with objectIdOnly' {
            $result = Get-IdFromInputObject '33333333-3333-3333-3333-333333333333' -objectIdOnly
            $result.type | Should -Be 'guid'
        }

        It 'Should reject UPN with objectIdOnly' {
            { Get-IdFromInputObject 'user@contoso.com' -objectIdOnly } | Should -Throw
        }
    }

    Context 'AllowRawString switch' {
        It 'Should accept raw string with AllowRawString' {
            $result = Get-IdFromInputObject 'some-display-name' -AllowRawString
            $result.id | Should -Be 'some-display-name'
            $result.type | Should -Be 'string'
        }
    }

    Context 'Error handling' {
        It 'Should throw for invalid string without AllowRawString' {
            { Get-IdFromInputObject 'invalid-string' } | Should -Throw "*not a valid GUID or UserPrincipalName*"
        }

        It 'Should throw for object without id or userPrincipalName' {
            $obj = [PSCustomObject]@{ displayName = 'Test' }
            { Get-IdFromInputObject $obj } | Should -Throw "*Unsupported input*"
        }
    }
}
#endregion

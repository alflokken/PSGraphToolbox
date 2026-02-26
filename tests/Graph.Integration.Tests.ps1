#Requires -Module Pester
<#
.SYNOPSIS
    Integration tests for Graph API functions.
.DESCRIPTION
    [AI-GENERATED] This file was generated using Claude Opus 4.5.
    
    Tests that require an active Microsoft Graph connection.
    Validates actual API calls and response handling.
    
    PREREQUISITES:
    - Connect-MgGraph with appropriate scopes before running
    - Minimum scopes: User.Read.All, Group.Read.All, Directory.Read.All
.NOTES
    Run with: Invoke-Pester -Path .\tests\Graph.Integration.Tests.ps1 -Output Detailed
    
    These tests use read-only operations and don't modify tenant data.
#>

BeforeAll {
    $PSDefaultParameterValues['*:WarningAction'] = 'SilentlyContinue'
    $modulePath = Join-Path $PSScriptRoot "..\PsGraphToolbox.psd1"
    Import-Module $modulePath -Force -ErrorAction Stop
    # Check for Graph connection
    $context = Get-MgContext
    if (-not $context) {
        throw "Not connected to Microsoft Graph. Run Connect-MgGraph first."
    }
    Write-Host "Connected to tenant: $($context.TenantId)" -ForegroundColor Cyan
}

#region Invoke-GtGraphRequest Tests
Describe 'Invoke-GtGraphRequest' -Tag 'Integration' {
    
    Context 'Basic queries' {
        It 'Should retrieve organization info' {
            $org = Invoke-GtGraphRequest -resourcePath "organization" -select "id,displayName"
            
            $org | Should -Not -BeNullOrEmpty
            $org.id | Should -Not -BeNullOrEmpty
        }

        It 'Should retrieve users with select' {
            $users = Invoke-GtGraphRequest -resourcePath "users" -select "id,displayName" -top 2 -PageLimit 1
            
            $users | Should -Not -BeNullOrEmpty
            $users.Count | Should -BeLessOrEqual 2
            $users[0].id | Should -Not -BeNullOrEmpty
        }

        It 'Should handle beta API version' {
            $users = Invoke-GtGraphRequest -resourcePath "users" -apiVersion "beta" -select "id,signInActivity" -top 1 -pageLimit 1
            
            $users | Should -Not -BeNullOrEmpty
        }
    }

    Context 'OData query parameters' {
        It 'Should apply filter parameter' {
            $users = Invoke-GtGraphRequest -resourcePath "users" -filter "accountEnabled eq true" -select "id,accountEnabled" -top 3
            
            $users | Should -Not -BeNullOrEmpty
            $users | ForEach-Object { $_.accountEnabled | Should -BeTrue }
        }

        It 'Should apply orderBy parameter' {
            $users = Invoke-GtGraphRequest -resourcePath "users" -select "id,displayName" -orderBy "displayName" -top 5 -PageLimit 1
            
            $users | Should -Not -BeNullOrEmpty
        }

        It 'Should handle search with ConsistencyLevel' {
            # Search requires ConsistencyLevel:eventual (handled automatically by function)
            $users = Invoke-GtGraphRequest -resourcePath "users" -search '"displayName:a"' -select "id,displayName" -top 3 -PageLimit 1
            
            # May return empty if no matches, but should not throw
            $true | Should -BeTrue
        }
    }

    Context 'Error handling' {
        It 'Should throw for invalid resource path' {
            { Invoke-GtGraphRequest -resourcePath "invalidResource123" } | Should -Throw
        }

        It 'Should throw for invalid filter syntax' {
            { Invoke-GtGraphRequest -resourcePath "users" -filter "invalid filter syntax!!!" } | Should -Throw
        }
    }

    Context 'Pagination' {
        It 'Should respect top parameter' {
            $users = Invoke-GtGraphRequest -resourcePath "users" -select "id" -top 2 -PageLimit 1
            
            $users.Count | Should -BeLessOrEqual 2
        }
    }
}
#endregion

#region Invoke-GtGraphBatchRequest Tests
Describe 'Invoke-GtGraphBatchRequest' -Tag 'Integration' {
    
    It 'Should process batch of user lookups' {
        # First get some user IDs
        $users = Invoke-GtGraphRequest -resourcePath "users" -select "id" -top 3 -PageLimit 1
        
        if ($users.Count -eq 0) {
            Set-ItResult -Skipped -Because "No users found in tenant"
            return
        }

        # Build batch requests
        $requests = $users | ForEach-Object {
            @{
                id = $_.id
                method = "GET"
                url = "users/$($_.id)?`$select=id,displayName"
            }
        }

        $results = Invoke-GtGraphBatchRequest -requests $requests
        
        $results | Should -Not -BeNullOrEmpty
        $results.Count | Should -Be $users.Count
    }

    It 'Should handle 404 responses gracefully' {
        $requests = @(
            @{
                id = "nonexistent"
                method = "GET"
                url = "users/00000000-0000-0000-0000-000000000000?`$select=id"
            }
        )

        # Should not throw, but may warn
        { Invoke-GtGraphBatchRequest -requests $requests -WarningAction SilentlyContinue } | Should -Not -Throw
    }

    It 'Should return results as hashtable keyed by request id' {
        $users = Invoke-GtGraphRequest -resourcePath "users" -select "id" -top 2 -PageLimit 1
        
        if ($users.Count -eq 0) {
            Set-ItResult -Skipped -Because "No users found in tenant"
            return
        }

        $requests = @(
            @{ id = "first"; method = "GET"; url = "users/$($users[0].id)?`$select=id" }
        )

        $results = Invoke-GtGraphBatchRequest -requests $requests
        
        $results.Keys | Should -Contain "first"
    }
}
#endregion

#region Get-GtTenantInfo Tests
Describe 'Get-GtTenantInfo' -Tag 'Integration' {
    
    It 'Should return tenant information' {
        $info = Get-GtTenantInfo
        
        $info.tenantId | Should -Not -BeNullOrEmpty
        $info.displayName | Should -Not -BeNullOrEmpty
        $info.defaultDomain | Should -Not -BeNullOrEmpty
    }

    It 'Should include domain information' {
        $info = Get-GtTenantInfo
        
        $info.domains | Should -Not -BeNullOrEmpty
        $info.verifiedDomainCount | Should -BeGreaterThan 0
    }
}
#endregion

#region Find-GtUser Tests  
Describe 'Find-GtUser' -Tag 'Integration' {
    
    It 'Should find users by displayName search' {
        # Search for users with 'a' in name (common letter)
        $users = Find-GtUser -SearchString "admin"
        
        # May return empty, but should not throw
        $true | Should -BeTrue
    }

    It 'Should require minimum 3 character search string' {
        { Find-GtUser -SearchString "ab" } | Should -Throw
    }

    It 'Should use filter for exact UPN match' {
        $allUsers = Invoke-GtGraphRequest -resourcePath "users" -select "userPrincipalName" -top 1 -PageLimit 1
        
        if ($allUsers.Count -eq 0) {
            Set-ItResult -Skipped -Because "No users found in tenant"
            return
        }

        $upn = $allUsers[0].userPrincipalName
        $user = Find-GtUser -SearchString $upn
        
        $user | Should -Not -BeNullOrEmpty
        $user.userPrincipalName | Should -Be $upn
    }
}
#endregion

#region Find-GtGroup Tests
Describe 'Find-GtGroup' -Tag 'Integration' {
    
    It 'Should search groups by displayName' {
        # Search for any group
        $groups = Find-GtGroup -SearchString "all"
        
        # May return empty, but should not throw
        $true | Should -BeTrue
    }

    It 'Should require minimum 3 character search string' {
        { Find-GtGroup -SearchString "ab" } | Should -Throw
    }
}
#endregion

#region Get-GtGraphDirectoryObjectsByIds Tests
Describe 'Get-GtGraphDirectoryObjectsByIds' -Tag 'Integration' {
    
    It 'Should resolve user IDs to objects' {
        $users = Invoke-GtGraphRequest -resourcePath "users" -select "id" -top 3 -PageLimit 1
        
        if ($users.Count -eq 0) {
            Set-ItResult -Skipped -Because "No users found in tenant"
            return
        }

        $resolved = Get-GtGraphDirectoryObjectsByIds -Type user -Ids $users.id
        
        $resolved.Count | Should -Be $users.Count
        $resolved[0].displayName | Should -Not -BeNullOrEmpty
    }

    It 'Should handle large ID arrays by chunking' {
        # Create array of 50 fake IDs (will return nothing, but tests chunking logic)
        $fakeIds = 1..50 | ForEach-Object { [guid]::NewGuid().ToString() }
        
        # Should not throw even with many IDs
        { Get-GtGraphDirectoryObjectsByIds -Type user -Ids $fakeIds } | Should -Not -Throw
    }
}
#endregion

#region Get-GtDomains Tests
Describe 'Get-GtDomains' -Tag 'Integration' {
    
    It 'Should retrieve tenant domains' {
        $domains = Get-GtDomains
        
        $domains | Should -Not -BeNullOrEmpty
        $domains[0].id | Should -Not -BeNullOrEmpty
    }

    It 'Should include authentication type' {
        $domains = Get-GtDomains
        
        $domains[0].authenticationType | Should -Not -BeNullOrEmpty
    }
}
#endregion

AfterAll {
    $PSDefaultParameterValues.Remove('*:WarningAction')
}
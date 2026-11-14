#Requires -Module Pester
<#
.SYNOPSIS
    Core unit tests for PSGraphToolbox foundational functions.
.DESCRIPTION
    [AI-GENERATED] This file was generated using Claude Opus 4.5.
    
    Tests for helpers and core functions that are fundamental to the toolkit:
    - isValidGuid
    - isValidUserPrincipalName  
    - Get-IdFromInputObject
    - New-GtRequestUri
    - Invoke-GtGraphRequest (mocked)
    - Invoke-GtGraphBatchRequest (mocked)
.NOTES
    Run with: Invoke-Pester -Path .\tests\Core.Tests.ps1 -Output Detailed
#>

BeforeAll {
    # Import the module - adjust path as needed
    $modulePath = Join-Path $PSScriptRoot "..\PsGraphToolbox.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -ErrorAction Stop
    }
    else {
        throw "Module not found at $modulePath"
    }
}

#region isValidGuid Tests
Describe 'isValidGuid' {
    Context 'Valid GUIDs' {
        It 'Should return true for uppercase GUID' {
            'A1B2C3D4-E5F6-7890-ABCD-EF1234567890' | isValidGuid | Should -BeTrue
        }
        It 'Should return true for lowercase GUID' {
            'a1b2c3d4-e5f6-7890-abcd-ef1234567890' | isValidGuid | Should -BeTrue
        }
    }
    
    Context 'Invalid GUIDs' {
        It 'Should return false for empty string' {
            '' | isValidGuid | Should -BeFalse
        }
        It 'Should return false for non-GUID string' {
            'not-a-guid' | isValidGuid | Should -BeFalse
        }
        It 'Should return false for GUID with wrong segment lengths' {
            '0000000-0000-0000-0000-000000000000' | isValidGuid | Should -BeFalse
        }
        It 'Should return false for GUID with invalid characters' {
            'GGGGGGGG-GGGG-GGGG-GGGG-GGGGGGGGGGGG' | isValidGuid | Should -BeFalse
        }
        It 'Should return false for email address' {
            'user@contoso.com' | isValidGuid | Should -BeFalse
        }
        It 'Should return false for partial GUID' {
            '00000000-0000-0000' | isValidGuid | Should -BeFalse
        }
    }
    
    Context 'Pipeline input' {
        It 'Should process multiple GUIDs via pipeline' {
            $guids = @(
                '00000000-0000-0000-0000-000000000000',
                '11111111-1111-1111-1111-111111111111'
            )
            $results = $guids | isValidGuid
            $results | Should -HaveCount 2
            $results | Should -BeTrue
        }
    }
}
#endregion

#region isValidUserPrincipalName Tests
Describe 'isValidUserPrincipalName' {
    Context 'Valid UPNs' {
        It 'Should return true for standard UPN' {
            'user@contoso.com' | isValidUserPrincipalName | Should -BeTrue
        }
        It 'Should return true for UPN with subdomain' {
            'user@mail.contoso.com' | isValidUserPrincipalName | Should -BeTrue
        }
        It 'Should return true for UPN with numbers' {
            'user123@contoso.com' | isValidUserPrincipalName | Should -BeTrue
        }
        It 'Should return true for UPN with dots in local part' {
            'first.last@contoso.com' | isValidUserPrincipalName | Should -BeTrue
        }
        It 'Should return true for UPN with hyphen in domain' {
            'user@my-company.com' | isValidUserPrincipalName | Should -BeTrue
        }
    }
    Context 'Invalid UPNs' {
        It 'Should return false for empty string' {
            '' | isValidUserPrincipalName | Should -BeFalse
        }
        It 'Should return false for string without @' {
            'usercontoso.com' | isValidUserPrincipalName | Should -BeFalse
        }
        It 'Should return false for string with multiple @' {
            'user@@contoso.com' | isValidUserPrincipalName | Should -BeFalse
        }
        It 'Should return false for GUID' {
            '00000000-0000-0000-0000-000000000000' | isValidUserPrincipalName | Should -BeFalse
        }
        It 'Should return false for domain without TLD' {
            'user@contoso' | isValidUserPrincipalName | Should -BeFalse
        }
        It 'Should return false for missing local part' {
            '@contoso.com' | isValidUserPrincipalName | Should -BeFalse
        }
    }
    Context 'Pipeline input' {
        It 'Should process multiple UPNs via pipeline' {
            $upns = @('user1@contoso.com', 'user2@contoso.com')
            $results = $upns | isValidUserPrincipalName
            $results | Should -HaveCount 2
            $results | Should -BeTrue
        }
    }
}
#endregion

#region Get-IdFromInputObject Tests
Describe 'Get-IdFromInputObject' {
    Context 'String input' {
        It 'Should extract GUID from string' {
            $result = Get-IdFromInputObject -inputObject '00000000-0000-0000-0000-000000000000'
            $result.id | Should -Be '00000000-0000-0000-0000-000000000000'
            $result.type | Should -Be 'guid'
        }
        
        It 'Should extract UPN from string' {
            $result = Get-IdFromInputObject -inputObject 'user@contoso.com'
            $result.id | Should -Be 'user@contoso.com'
            $result.type | Should -Be 'upn'
        }
    }
    Context 'Object with id property' {
        It 'Should extract GUID from object with id property' {
            $obj = [PSCustomObject]@{ id = '00000000-0000-0000-0000-000000000000'; displayName = 'Test User' }
            $result = Get-IdFromInputObject -inputObject $obj
            $result.id | Should -Be '00000000-0000-0000-0000-000000000000'
            $result.type | Should -Be 'guid'
        }
    }
    Context 'Object with userPrincipalName property' {
        It 'Should extract UPN from object with userPrincipalName property' {
            $obj = [PSCustomObject]@{ userPrincipalName = 'user@contoso.com'; displayName = 'Test User' }
            $result = Get-IdFromInputObject -inputObject $obj
            $result.id | Should -Be 'user@contoso.com'
            $result.type | Should -Be 'upn'
        }
        It 'Should prefer id over userPrincipalName when both present' {
            $obj = [PSCustomObject]@{ 
                id = '00000000-0000-0000-0000-000000000000'
                userPrincipalName = 'user@contoso.com'
            }
            $result = Get-IdFromInputObject -inputObject $obj
            $result.id | Should -Be '00000000-0000-0000-0000-000000000000'
            $result.type | Should -Be 'guid'
        }
    }
    
    Context 'objectIdOnly switch' {
        It 'Should succeed with GUID when objectIdOnly is set' {
            $result = Get-IdFromInputObject -inputObject '00000000-0000-0000-0000-000000000000' -objectIdOnly
            $result.id | Should -Be '00000000-0000-0000-0000-000000000000'
            $result.type | Should -Be 'guid'
        }
        
        It 'Should throw for UPN when objectIdOnly is set' {
            { Get-IdFromInputObject -inputObject 'user@contoso.com' -objectIdOnly } | Should -Throw "*not a valid objectId*"
        }
    }
    
    Context 'Error handling' {
        It 'Should throw for null input' {
            { Get-IdFromInputObject -inputObject $null } | Should -Throw
        }
        
        It 'Should throw for invalid identifier' {
            { Get-IdFromInputObject -inputObject 'invalid-string' } | Should -Throw "*not a valid GUID or UserPrincipalName*"
        }
        
        It 'Should throw for object without id or userPrincipalName' {
            $obj = [PSCustomObject]@{ displayName = 'Test'; email = 'test@test.com' }
            { Get-IdFromInputObject -inputObject $obj } | Should -Throw "*Unsupported input*"
        }
    }
    
    Context 'Pipeline input' {
        It 'Should process multiple objects via pipeline' {
            $objects = @(
                [PSCustomObject]@{ id = '00000000-0000-0000-0000-000000000000' },
                [PSCustomObject]@{ id = '11111111-1111-1111-1111-111111111111' }
            )
            $results = $objects | Get-IdFromInputObject
            $results | Should -HaveCount 2
            $results[0].id | Should -Be '00000000-0000-0000-0000-000000000000'
            $results[1].id | Should -Be '11111111-1111-1111-1111-111111111111'
        }
    }
    
    Context 'Alias' {
        It 'Should work with idFromInputObject alias' {
            $result = idFromInputObject '00000000-0000-0000-0000-000000000000'
            $result.id | Should -Be '00000000-0000-0000-0000-000000000000'
        }
    }
}
#endregion

#region New-GtRequestUri Tests
Describe 'New-GtRequestUri' {
    Context 'Basic URI construction' {
        It 'Should construct basic v1.0 URI' {
            $uri = New-GtRequestUri -resourcePath 'users'
            $uri | Should -Be 'v1.0/users'
        }
        
        It 'Should construct beta URI' {
            $uri = New-GtRequestUri -resourcePath 'users' -apiVersion 'beta'
            $uri | Should -Be 'beta/users'
        }
        
        It 'Should handle nested resource paths' {
            $uri = New-GtRequestUri -resourcePath 'users/00000000-0000-0000-0000-000000000000/memberOf'
            $uri | Should -Be 'v1.0/users/00000000-0000-0000-0000-000000000000/memberOf'
        }
    }
    
    Context 'OData query parameters' {
        It 'Should add $select parameter' {
            $uri = New-GtRequestUri -resourcePath 'users' -select 'id,displayName'
            $uri | Should -Be 'v1.0/users?$select=id,displayName'
        }
        
        It 'Should add $filter parameter with URL encoding' {
            $uri = New-GtRequestUri -resourcePath 'users' -filter "displayName eq 'Test User'"
            $uri | Should -Match '\$filter='
            $uri | Should -Match 'displayName%20eq%20'
        }
        
        It 'Should add $top parameter' {
            $uri = New-GtRequestUri -resourcePath 'users' -top 10
            $uri | Should -Be 'v1.0/users?$top=10'
        }
        
        It 'Should add $count parameter' {
            $uri = New-GtRequestUri -resourcePath 'users' -count
            $uri | Should -Be 'v1.0/users?$count=true'
        }
        
        It 'Should add $search parameter with URL encoding' {
            $uri = New-GtRequestUri -resourcePath 'users' -search '"displayName:John"'
            $uri | Should -Match '\$search='
            $uri | Should -Match '%22displayName'
        }
        
        It 'Should add $orderby parameter' {
            $uri = New-GtRequestUri -resourcePath 'users' -orderBy 'displayName desc'
            $uri | Should -Match '\$orderby='
        }
        
        It 'Should add $expand parameter' {
            $uri = New-GtRequestUri -resourcePath 'users' -expand 'manager'
            $uri | Should -Match '\$expand='
        }
    }
    
    Context 'Multiple parameters' {
        It 'Should combine multiple OData parameters' {
            $uri = New-GtRequestUri -resourcePath 'users' -select 'id,displayName' -filter "accountEnabled eq true" -top 50
            $uri | Should -Match '\$select=id,displayName'
            $uri | Should -Match '\$filter='
            $uri | Should -Match '\$top=50'
            $uri | Should -Match '&'  # Parameters joined with &
        }
    }
    
    Context 'Version prefix handling' {
        It 'Should strip v1.0 prefix from resourcePath' {
            $uri = New-GtRequestUri -resourcePath 'v1.0/users'
            $uri | Should -Be 'v1.0/users'
        }
        
        It 'Should strip beta prefix and warn when apiVersion conflicts' {
            # Resource path indicates beta, apiVersion is v1.0 - should use beta
            $uri = New-GtRequestUri -resourcePath 'beta/users' -apiVersion 'v1.0' -WarningAction SilentlyContinue
            $uri | Should -Be 'beta/users'
        }
        
        It 'Should handle https://graph.microsoft.com prefix' {
            $uri = New-GtRequestUri -resourcePath 'https://graph.microsoft.com/v1.0/users'
            $uri | Should -Be 'v1.0/users'
        }
    }
    
    Context 'Real-world examples' {
        It 'Should construct sign-in logs query' {
            $uri = New-GtRequestUri -resourcePath 'auditLogs/signIns' -apiVersion 'beta' -filter "createdDateTime ge 2024-01-01T00:00:00Z" -top 1000
            $uri | Should -Match 'beta/auditLogs/signIns'
            $uri | Should -Match '\$filter='
            $uri | Should -Match '\$top=1000'
        }
        
        It 'Should construct users query with expand' {
            $uri = New-GtRequestUri -resourcePath 'users' -select 'id,displayName,userPrincipalName' -expand 'manager($select=displayName)'
            $uri | Should -Match '\$select=id,displayName,userPrincipalName'
            $uri | Should -Match '\$expand='
        }
    }
}
#endregion

#region Invoke-GtGraphRequest Tests (Mocked)
Describe 'Invoke-GtGraphRequest' {
    BeforeAll {
        # Mock the Graph connection check
        Mock Get-MgContext { return @{ TenantId = 'test-tenant' } } -ModuleName PsGraphToolbox
        Mock Connect-MgGraph { } -ModuleName PsGraphToolbox
    }
    
    Context 'Single resource response' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    id = '00000000-0000-0000-0000-000000000000'
                    displayName = 'Test User'
                    userPrincipalName = 'test@contoso.com'
                }
            } -ModuleName PsGraphToolbox
        }
        
        It 'Should return single object for non-collection response' {
            $result = Invoke-GtGraphRequest -resourcePath 'users/00000000-0000-0000-0000-000000000000'
            $result.id | Should -Be '00000000-0000-0000-0000-000000000000'
            $result.displayName | Should -Be 'Test User'
        }
    }
    
    Context 'Collection response' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ id = '1'; displayName = 'User 1' },
                        [PSCustomObject]@{ id = '2'; displayName = 'User 2' }
                    )
                }
            } -ModuleName PsGraphToolbox
        }
        
        It 'Should return array of objects for collection response' {
            $result = Invoke-GtGraphRequest -resourcePath 'users'
            $result | Should -HaveCount 2
            $result[0].displayName | Should -Be 'User 1'
            $result[1].displayName | Should -Be 'User 2'
        }
    }
    
    Context 'Paginated response' {
        BeforeEach {
            $script:callCount = 0
            Mock Invoke-MgGraphRequest {
                $script:callCount++
                if ($script:callCount -eq 1) {
                    return [PSCustomObject]@{
                        value = @([PSCustomObject]@{ id = '1' })
                        '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=abc'
                    }
                }
                else {
                    return [PSCustomObject]@{
                        value = @([PSCustomObject]@{ id = '2' })
                    }
                }
            } -ModuleName PsGraphToolbox
        }
        
        It 'Should follow pagination and combine results' {
            $result = Invoke-GtGraphRequest -resourcePath 'users'
            $result | Should -HaveCount 2
            Should -Invoke Invoke-MgGraphRequest -Times 2 -ModuleName PsGraphToolbox
        }
    }
    
    Context 'Delta response' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @([PSCustomObject]@{ id = '1' })
                    '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=xyz'
                }
            } -ModuleName PsGraphToolbox
        }
        
        It 'Should wrap delta response with deltaLink and dateRetrieved' {
            $result = Invoke-GtGraphRequest -resourcePath 'users/delta'
            $result.value | Should -HaveCount 1
            $result.deltaLink | Should -Not -BeNullOrEmpty
            $result.dateRetrieved | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'ConsistencyLevel header' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @()
                    '@odata.count' = 0
                }
            } -ModuleName PsGraphToolbox -Verifiable
        }
        
        It 'Should add ConsistencyLevel header when using $count' {
            Invoke-GtGraphRequest -resourcePath 'users' -count
            Should -Invoke Invoke-MgGraphRequest -ModuleName PsGraphToolbox -ParameterFilter {
                $Headers -and $Headers['ConsistencyLevel'] -eq 'eventual'
            }
        }
        
        It 'Should add ConsistencyLevel header when using $search' {
            Invoke-GtGraphRequest -resourcePath 'users' -search '"displayName:test"'
            Should -Invoke Invoke-MgGraphRequest -ModuleName PsGraphToolbox -ParameterFilter {
                $Headers -and $Headers['ConsistencyLevel'] -eq 'eventual'
            }
        }
    }
    
    Context 'API version parameter' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = @() }
            } -ModuleName PsGraphToolbox
        }
        
        It 'Should use v1.0 by default' {
            Invoke-GtGraphRequest -resourcePath 'users'
            Should -Invoke Invoke-MgGraphRequest -ModuleName PsGraphToolbox -ParameterFilter {
                $Uri -match '^v1\.0/'
            }
        }
        
        It 'Should use beta when specified' {
            Invoke-GtGraphRequest -resourcePath 'users' -apiVersion 'beta'
            Should -Invoke Invoke-MgGraphRequest -ModuleName PsGraphToolbox -ParameterFilter {
                $Uri -match '^beta/'
            }
        }
    }
    
    Context 'Page limit' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @([PSCustomObject]@{ id = '1' })
                    '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=abc'
                }
            } -ModuleName PsGraphToolbox
        }
        
        It 'Should stop at pageLimit and warn' {
            $result = Invoke-GtGraphRequest -resourcePath 'users' -pageLimit 2 -WarningAction SilentlyContinue
            Should -Invoke Invoke-MgGraphRequest -Times 2 -ModuleName PsGraphToolbox
        }
    }

    Context 'DateTime conversion (UTC to local)' {
        BeforeAll {
            # Kind=Utc reference instant and its expected local-time equivalent (timezone-independent).
            $script:utcInstant = (Get-Date '2024-01-15T12:00:00Z').ToUniversalTime()
            $script:expectedLocalInstant = $script:utcInstant.ToLocalTime()
        }

        It 'Should convert dateTime on a single-resource (flat) response to local time' {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    id = '00000000-0000-0000-0000-000000000000'
                    createdDateTime = (Get-Date '2024-01-15T12:00:00Z').ToUniversalTime()
                }
            } -ModuleName PsGraphToolbox
            $result = Invoke-GtGraphRequest -resourcePath 'users/00000000-0000-0000-0000-000000000000'
            $result.createdDateTime | Should -Be $expectedLocalInstant
            $result.createdDateTime.Kind | Should -Be 'Local'
        }

        It 'Should convert dateTime values in a collection response to local time' {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{ id = '1'; createdDateTime = (Get-Date '2024-01-15T12:00:00Z').ToUniversalTime() },
                        [PSCustomObject]@{ id = '2'; createdDateTime = (Get-Date '2024-01-15T12:00:00Z').ToUniversalTime() }
                    )
                }
            } -ModuleName PsGraphToolbox
            $result = Invoke-GtGraphRequest -resourcePath 'users'
            $result[0].createdDateTime | Should -Be $expectedLocalInstant
            $result[1].createdDateTime.Kind | Should -Be 'Local'
        }

        It 'Should convert nested dateTime values to local time' {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @(
                        [PSCustomObject]@{
                            id = '1'
                            signInActivity = [PSCustomObject]@{ lastSignInDateTime = (Get-Date '2024-01-15T12:00:00Z').ToUniversalTime() }
                        }
                    )
                }
            } -ModuleName PsGraphToolbox
            $result = Invoke-GtGraphRequest -resourcePath 'users'
            $result[0].signInActivity.lastSignInDateTime | Should -Be $expectedLocalInstant
            $result[0].signInActivity.lastSignInDateTime.Kind | Should -Be 'Local'
        }

        It 'Should convert dateTime values inside a delta response to local time' {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    value = @([PSCustomObject]@{ id = '1'; createdDateTime = (Get-Date '2024-01-15T12:00:00Z').ToUniversalTime() })
                    '@odata.deltaLink' = 'https://graph.microsoft.com/v1.0/users/delta?$deltatoken=xyz'
                }
            } -ModuleName PsGraphToolbox
            $result = Invoke-GtGraphRequest -resourcePath 'users/delta'
            $result.value[0].createdDateTime | Should -Be $expectedLocalInstant
            $result.value[0].createdDateTime.Kind | Should -Be 'Local'
        }
    }
}
#endregion

#region Invoke-GtGraphBatchRequest Tests (Mocked)
Describe 'Invoke-GtGraphBatchRequest' {
    BeforeAll {
        Mock Get-MgContext { return @{ TenantId = 'test-tenant' } } -ModuleName PsGraphToolbox
        Mock Connect-MgGraph { } -ModuleName PsGraphToolbox
    }

    Context 'Paged collection response (@odata.nextLink)' {
        BeforeEach {
            # $batch call: first page with nextLink
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    responses = @(
                        [PSCustomObject]@{
                            id     = 'paged'
                            status = 200
                            body   = [PSCustomObject]@{
                                value = @([PSCustomObject]@{ id = '1' })
                                '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=abc'
                            }
                        }
                    )
                }
            } -ModuleName PsGraphToolbox -ParameterFilter { $Method -eq 'POST' }

            # nextLink call: last page
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{ value = @([PSCustomObject]@{ id = '2' }) }
            } -ModuleName PsGraphToolbox -ParameterFilter { $Uri -match 'skiptoken' }

            Mock Write-Warning { } -ModuleName PsGraphToolbox

            $requests = @( @{ id = 'paged'; method = 'GET'; url = 'users?$top=1' } )
        }

        It 'Should follow nextLink and combine pages' {
            $results = Invoke-GtGraphBatchRequest -Requests $requests
            $ids = @($results['paged']).id
            $ids | Should -HaveCount 2
            $ids[0] | Should -Be '1'
            $ids[1] | Should -Be '2'
            Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ModuleName PsGraphToolbox -ParameterFilter { $Uri -match 'skiptoken' }
        }

        It 'Should return only the first page and warn when PageLimit is 1' {
            $results = Invoke-GtGraphBatchRequest -Requests $requests -PageLimit 1
            @($results['paged']) | Should -HaveCount 1
            Should -Invoke Invoke-MgGraphRequest -Times 0 -Exactly -ModuleName PsGraphToolbox -ParameterFilter { $Uri -match 'skiptoken' }
            Should -Invoke Write-Warning -Times 1 -Exactly -ModuleName PsGraphToolbox
        }

        It 'Should return both pages without a warning when PageLimit is 2' {
            $results = Invoke-GtGraphBatchRequest -Requests $requests -PageLimit 2
            @($results['paged']).id | Should -Be @('1', '2')
            Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ModuleName PsGraphToolbox -ParameterFilter { $Uri -match 'skiptoken' }
            Should -Invoke Write-Warning -Times 0 -Exactly -ModuleName PsGraphToolbox
        }

        It 'Should forward request headers to the next page' {
            $requests[0].headers = @{ ConsistencyLevel = 'eventual' }
            $null = Invoke-GtGraphBatchRequest -Requests $requests
            Should -Invoke Invoke-MgGraphRequest -Times 1 -Exactly -ModuleName PsGraphToolbox -ParameterFilter {
                $Uri -match 'skiptoken' -and $Headers -and $Headers['ConsistencyLevel'] -eq 'eventual'
            }
        }
    }

    Context 'Single resource response' {
        BeforeEach {
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    responses = @(
                        [PSCustomObject]@{ id = 'single'; status = 200; body = [PSCustomObject]@{ id = '1'; displayName = 'User 1' } }
                    )
                }
            } -ModuleName PsGraphToolbox -ParameterFilter { $Method -eq 'POST' }
        }

        It 'Should return the object unchanged' {
            $results = Invoke-GtGraphBatchRequest -Requests @( @{ id = 'single'; method = 'GET'; url = 'users/1' } )
            $results['single'].displayName | Should -Be 'User 1'
        }
    }

    Context 'Failed and throttled sub-requests' {
        BeforeEach {
            Mock Start-Sleep { } -ModuleName PsGraphToolbox
            Mock Get-Random { return 0 } -ModuleName PsGraphToolbox
            Mock Write-Warning { } -ModuleName PsGraphToolbox
            $global:GtBatchTestCalls = 0
            $global:GtBatchTestStatus = $null
            $global:GtBatchTestRetryAfter = $null
            $requests = @(
                @{ id = 'ok'; method = 'GET'; url = 'users/1' },
                @{ id = 'bad'; method = 'GET'; url = 'users/2' }
            )
            # 'ok' always succeeds; 'bad' returns $GtBatchTestStatus (for the first $GtBatchTestFailCalls calls when set, else always)
            Mock Invoke-MgGraphRequest {
                $global:GtBatchTestCalls++
                $sent = @(($Body | ConvertFrom-Json).requests)
                $responses = foreach ( $r in $sent ) {
                    if ( $r.id -eq 'ok' ) { [PSCustomObject]@{ id = 'ok'; status = 200; body = [PSCustomObject]@{ id = '1' } } }
                    elseif ( $global:GtBatchTestFailCalls -and $global:GtBatchTestCalls -gt $global:GtBatchTestFailCalls ) { [PSCustomObject]@{ id = 'bad'; status = 200; body = [PSCustomObject]@{ id = '2' } } }
                    else {
                        $headers = if ( $global:GtBatchTestRetryAfter ) { [PSCustomObject]@{ 'retry-after' = $global:GtBatchTestRetryAfter } } else { [PSCustomObject]@{} }
                        [PSCustomObject]@{ id = 'bad'; status = $global:GtBatchTestStatus; headers = $headers; body = [PSCustomObject]@{ error = [PSCustomObject]@{ code = 'Test_Code'; message = 'test message' } } }
                    }
                }
                return [PSCustomObject]@{ responses = @($responses) }
            } -ModuleName PsGraphToolbox -ParameterFilter { $Method -eq 'POST' }
        }
        AfterEach {
            Remove-Variable GtBatchTestCalls, GtBatchTestStatus, GtBatchTestRetryAfter, GtBatchTestFailCalls -Scope Global -ErrorAction SilentlyContinue
        }

        It 'Should keep successful responses and report a non-retryable failure as a non-terminating error' {
            $global:GtBatchTestStatus = 403
            $results = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable batchErrors
            $results['ok'].id | Should -Be '1'
            $results.ContainsKey('bad') | Should -BeFalse
            @($batchErrors) | Should -HaveCount 1
            $batchErrors[0].TargetObject.id | Should -Be 'bad'
            $batchErrors[0].FullyQualifiedErrorId | Should -Match 'GraphBatch\.403\.Test_Code'
            $batchErrors[0].Exception.Message | Should -Match 'test message'
            $global:GtBatchTestCalls | Should -Be 1
        }

        It 'Should throw when -ErrorAction Stop is used' {
            $global:GtBatchTestStatus = 403
            { Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction Stop } | Should -Throw
        }

        It 'Should not retry a 500' {
            $global:GtBatchTestStatus = 500
            $null = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable batchErrors
            @($batchErrors) | Should -HaveCount 1
            $global:GtBatchTestCalls | Should -Be 1
            Should -Invoke Start-Sleep -Times 0 -Exactly -ModuleName PsGraphToolbox
        }

        It 'Should retry a 503 and return the result without errors' {
            $global:GtBatchTestStatus = 503
            $global:GtBatchTestFailCalls = 1
            $results = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable batchErrors
            $results['bad'].id | Should -Be '2'
            $results['ok'].id | Should -Be '1'
            $batchErrors | Should -BeNullOrEmpty
            $global:GtBatchTestCalls | Should -Be 2
        }

        It 'Should wait for the retry-after value when given' {
            $global:GtBatchTestStatus = 429
            $global:GtBatchTestRetryAfter = '3'
            $global:GtBatchTestFailCalls = 1
            $null = Invoke-GtGraphBatchRequest -Requests $requests
            Should -Invoke Start-Sleep -Times 3 -Exactly -ModuleName PsGraphToolbox
        }

        It 'Should back off exponentially when retry-after is missing and stop at MaxRetries' {
            $global:GtBatchTestStatus = 429
            $results = Invoke-GtGraphBatchRequest -Requests $requests -MaxRetries 2 -ErrorAction SilentlyContinue -ErrorVariable batchErrors
            $results.ContainsKey('bad') | Should -BeFalse
            $results['ok'].id | Should -Be '1'
            @($batchErrors) | Should -HaveCount 1
            $batchErrors[0].TargetObject.id | Should -Be 'bad'
            $batchErrors[0].FullyQualifiedErrorId | Should -Match 'ThrottledRetriesExhausted'
            # rounds 0..2 run (3 batch calls); waits before rounds 1 and 2 are 2s and 4s, none after the last round
            $global:GtBatchTestCalls | Should -Be 3
            Should -Invoke Start-Sleep -Times 6 -Exactly -ModuleName PsGraphToolbox
        }

        It 'Should still warn on 404 without writing an error' {
            $global:GtBatchTestStatus = 404
            $results = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable batchErrors
            $results.ContainsKey('bad') | Should -BeFalse
            $batchErrors | Should -BeNullOrEmpty
            Should -Invoke Write-Warning -Times 1 -Exactly -ModuleName PsGraphToolbox
        }
    }

    Context 'Failing nextLink page' {
        BeforeEach {
            Mock Write-Warning { } -ModuleName PsGraphToolbox
            Mock Invoke-MgGraphRequest {
                return [PSCustomObject]@{
                    responses = @(
                        [PSCustomObject]@{ id = 'ok'; status = 200; body = [PSCustomObject]@{ id = '1' } },
                        [PSCustomObject]@{
                            id = 'paged'; status = 200
                            body = [PSCustomObject]@{
                                value = @([PSCustomObject]@{ id = '1' })
                                '@odata.nextLink' = 'https://graph.microsoft.com/v1.0/users?$skiptoken=abc'
                            }
                        }
                    )
                }
            } -ModuleName PsGraphToolbox -ParameterFilter { $Method -eq 'POST' }
            Mock Invoke-MgGraphRequest { throw 'page failed' } -ModuleName PsGraphToolbox -ParameterFilter { $Uri -match 'skiptoken' }
        }

        It 'Should report the paged request as failed and keep the others' {
            $requests = @( @{ id = 'ok'; method = 'GET'; url = 'users/1' }, @{ id = 'paged'; method = 'GET'; url = 'users?$top=1' } )
            $results = Invoke-GtGraphBatchRequest -Requests $requests -ErrorAction SilentlyContinue -ErrorVariable allErrors
            # ErrorVariable also holds errors caught inside the nested paging call
            $batchErrors = @( $allErrors | Where-Object { $_.FullyQualifiedErrorId -like 'GraphBatch.*' } )
            $results['ok'].id | Should -Be '1'
            $results.ContainsKey('paged') | Should -BeFalse
            $batchErrors | Should -HaveCount 1
            $batchErrors[0].TargetObject.id | Should -Be 'paged'
            $batchErrors[0].FullyQualifiedErrorId | Should -Match 'PageRetrievalFailed'
        }
    }
}
#endregion

#region Split-ArrayIntoChunks Tests
Describe 'Split-ArrayIntoChunks' {
    Context 'Basic chunking' {
        It 'Should split array into chunks of specified size' {
            $items = 1..10
            $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 3
            $chunks | Should -HaveCount 4
            $chunks[0] | Should -HaveCount 3
            $chunks[3] | Should -HaveCount 1
        }
        
        It 'Should return single chunk when array smaller than chunk size' {
            $items = 1..5
            $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 10
            $chunks | Should -HaveCount 1
            $chunks[0] | Should -HaveCount 5
        }
        
        It 'Should handle empty array' {
            $items = @()
            $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 5
            $chunks | Should -HaveCount 0
        }
        
        It 'Should handle chunk size of 1' {
            $items = 1..3
            $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 1
            $chunks | Should -HaveCount 3
        }
    }
    
    Context 'Batch processing scenario (chunk size 20)' {
        It 'Should correctly chunk for Graph batch requests' {
            $items = 1..45
            $chunks = Split-ArrayIntoChunks -Enumerable $items -ChunkSize 20
            $chunks | Should -HaveCount 3
            $chunks[0] | Should -HaveCount 20
            $chunks[1] | Should -HaveCount 20
            $chunks[2] | Should -HaveCount 5
        }
    }
}
#endregion

AfterAll {
    # Cleanup - remove the module
    Remove-Module PsGraphToolbox -ErrorAction SilentlyContinue
}

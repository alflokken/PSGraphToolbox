function Invoke-GtPimRoleSelfActivation {
    <#
    .SYNOPSIS
    Self-activates a PIM eligible directory role.

    .DESCRIPTION
    Activates a Privileged Identity Management (PIM) eligible role assignment for the 
    current signed-in user (resolved via /me, so a delegated sign-in is required). The activation
    is tenant-wide (directory scope '/') and starts immediately. After activation, you may need to reconnect
    to Microsoft Graph to obtain a fresh token with updated role claims (wids); a warning about this is always written.
    
    NOTE: Windows Token Broker caches access tokens persistently. After PIM activation,
    use 'Connect-MgGraph -ContextScope Process' to force a fresh token acquisition with
    current role claims. See: https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference
    
    Requires scopes: RoleAssignmentSchedule.ReadWrite.Directory

    .PARAMETER Role
    Predefined (commonly used) built-in role to activate. Valid values: GlobalReader, GlobalAdmin, PrivilegedRoleAdmin, PrivilegedAuthenticationAdmin, AuthenticationAdmin, AuthenticationPolicyAdmin,
    ConditionalAccessAdmin, SecurityAdmin, SecurityOperator, SecurityReader, UserAdmin, HelpdeskAdmin, GroupsAdmin, ApplicationAdmin, 'Cloud Application Administrator', HybridIdentityAdmin,
    IdentityGovernanceAdmin, IntuneAdmin, ExchangeAdmin, SharePointAdmin, TeamsAdmin, ComplianceAdmin.

    Defaults to GlobalReader, so running the function without parameters activates Global Reader. For any other role, use -RoleDefinitionId.

    .PARAMETER RoleDefinitionId
    The GUID of the role definition to activate. Use this for roles not in the predefined list.

    .PARAMETER Justification
    Business justification for the activation. Default: "PIM Self Activation"

    .PARAMETER DurationInHours
    How long the role should remain active, 1-24 hours. Default: 8 hours.

    .OUTPUTS
    The created roleAssignmentScheduleRequest returned by Graph (hashtable), with dateTime values converted to local time.

    .EXAMPLE
    Invoke-GtPimRoleSelfActivation -Role GlobalReader
    Activates the Global Reader role for 8 hours.

    .EXAMPLE
    Invoke-GtPimRoleSelfActivation -Role GlobalAdmin -Justification "Emergency admin task" -DurationInHours 2
    Activates Global Administrator for 2 hours with a custom justification.

    .EXAMPLE
    Invoke-GtPimRoleSelfActivation -RoleDefinitionId "62e90394-69f5-4237-9190-012177145e10"
    Activates a role by its definition ID.

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md
    #>
    [CmdletBinding()]
    param( 
        [Parameter(ParameterSetName = 'ByRoleName')] 
        [ValidateSet(
            'GlobalReader', 'GlobalAdmin', 'PrivilegedRoleAdmin', 'PrivilegedAuthenticationAdmin', 'AuthenticationAdmin', 'AuthenticationPolicyAdmin', 'ConditionalAccessAdmin',
            'SecurityAdmin', 'SecurityOperator', 'SecurityReader', 'UserAdmin', 'HelpdeskAdmin', 'GroupsAdmin', 'ApplicationAdmin', 'CloudAppAdmin',
            'HybridIdentityAdmin', 'IdentityGovernanceAdmin', 'IntuneAdmin', 'ExchangeAdmin', 'SharePointAdmin', 'TeamsAdmin', 'ComplianceAdmin'
        )]
        [string]$Role = "GlobalReader",

        [Parameter(Mandatory, ParameterSetName = 'ByRoleId')]
        [guid]$RoleDefinitionId,

        [Parameter()]
        [string]$Justification = "PIM Self Activation",

        [Parameter()]
        [ValidateRange(1, 24)]
        [int]$DurationInHours = 8
    )

    $currentUserId = Invoke-GtGraphRequest "me" -Select id -Verbose:$false | Select-Object -ExpandProperty id

    # Resolve role name to role definition ID
    if ($PSCmdlet.ParameterSetName -eq 'ByRoleName') {
        # built-in role template IDs (identical in all tenants)
        $roleDefinitionIdMap = @{
            "GlobalReader"                    = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
            "GlobalAdmin"                     = "62e90394-69f5-4237-9190-012177145e10"
            "PrivilegedRoleAdmin"             = "e8611ab8-c189-46e8-94e1-60213ab1f814"
            "PrivilegedAuthenticationAdmin"   = "7be44c8a-adaf-4e2a-84d6-ab2649e08a13"
            "AuthenticationAdmin"             = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
            "AuthenticationPolicyAdmin"       = "0526716b-113d-4c15-b2c8-68e3c22b9f80"
            "ConditionalAccessAdmin"          = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
            "SecurityAdmin"                   = "194ae4cb-b126-40b2-bd5b-6091b380977d"
            "SecurityOperator"                = "5f2222b1-57c3-48ba-8ad5-d4759f1fde6f"
            "SecurityReader"                  = "5d6b6bb7-de71-4623-b4af-96380a352509"
            "UserAdmin"                       = "fe930be7-5e62-47db-91af-98c3a49a38b1"
            "HelpdeskAdmin"                   = "729827e3-9c14-49f7-bb1b-9608f156bbb8"
            "GroupsAdmin"                     = "fdd7a751-b60b-444a-984c-02652fe8fa1c"
            "ApplicationAdmin"                = "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3"
            "CloudAppAdmin"                   = "158c047a-c907-4556-b7ef-446551a6b5f7"
            "HybridIdentityAdmin"             = "8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2"
            "IdentityGovernanceAdmin"         = "45d8d3c5-c802-45c6-b32a-1d70b5e1e86e"
            "IntuneAdmin"                     = "3a2c62db-5318-420d-8d74-23affee5d9d5"
            "ExchangeAdmin"                   = "29232cdf-9323-42fd-ade2-1d097af3e4de"
            "SharePointAdmin"                 = "f28a1f50-f6e7-4571-818b-6a12f2af6b6c"
            "TeamsAdmin"                      = "69091246-20e8-4a56-aa4d-066075b2a7a8"
            "ComplianceAdmin"                 = "17315797-102d-40b4-93e0-432062caca18"
        }
        $targetRoleId = $roleDefinitionIdMap[$Role]
        $roleName = $Role
    }
    else { 
        $targetRoleId = $RoleDefinitionId.ToString()
        $roleName = $targetRoleId
    }

    # Build activation request payload
    $activationRequest = @{
        PrincipalId      = $currentUserId
        RoleDefinitionId = $targetRoleId
        Justification    = $Justification
        DirectoryScopeId = "/"
        Action           = "SelfActivate"
        ScheduleInfo     = @{
            StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            Expiration    = @{
                Type     = "AfterDuration"
                Duration = "PT${DurationInHours}H"
            }
        }
    }

    Write-GtVerbose "Requesting PIM activation for role '$roleName' (ID: $targetRoleId) for user $currentUserId"
    
    try { $result = Invoke-MgGraphRequest -Method POST -Uri "v1.0/roleManagement/directory/roleAssignmentScheduleRequests" -Body ($activationRequest | ConvertTo-Json) -ContentType "application/json" }
    catch { throw $_ }

    # Output success message with token refresh guidance
    Write-GtVerbose "PIM role '$roleName' assignmentRequest sent with duration: $DurationInHours hour(s)."
    Write-Warning "Your current access token may not include the new role claims (wids). To refresh your token with updated permissions, run 'Connect-MgGraph -ContextScope Process'"

    # convert dateTime values (UTC -> local) recursively, including nested hashtables
    return (ConvertTo-GtLocalDateTime -InputObject $result)
}
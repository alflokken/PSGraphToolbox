function Invoke-GtPimRoleSelfActivation {
    <#
    .SYNOPSIS
    Self-activates a PIM eligible directory role.

    .DESCRIPTION
    Activates a Privileged Identity Management (PIM) eligible role assignment for the 
    current signed-in user. After activation, you may need to reconnect to Microsoft Graph
    to obtain a fresh token with updated role claims (wids).
    
    NOTE: Windows Token Broker caches access tokens persistently. After PIM activation,
    use 'Connect-MgGraph -ContextScope Process' to force a fresh token acquisition with
    current role claims. See: https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference
    
    Requires scopes: RoleAssignmentSchedule.ReadWrite.Directory

    .PARAMETER Role
    Predefined role to activate. Valid values: GlobalReader, GlobalAdmin, IntuneAdmin, 
    ConditionalAccessAdmin, AuthenticationAdmin.

    .PARAMETER RoleDefinitionId
    The GUID of the role definition to activate. Use this for roles not in the predefined list.

    .PARAMETER Justification
    Business justification for the activation. Default: "PIM Self Activation"

    .PARAMETER DurationInHours
    How long the role should remain active. Default: 8 hours.

    .EXAMPLE
    Invoke-GtPimRoleSelfActivation -Role GlobalReader
    # Activates GlobalReader role for 8 hours

    .EXAMPLE
    Invoke-GtPimRoleSelfActivation -Role GlobalAdmin -Justification "Emergency admin task" -DurationInHours 2
    # Activates GlobalAdmin for 2 hours with custom justification

    .EXAMPLE
    Invoke-GtPimRoleSelfActivation -RoleDefinitionId "62e90394-69f5-4237-9190-012177145e10"
    # Activates a role by its definition ID

    .LINK
    https://github.com/alflokken/PSGraphToolbox/blob/main/docs/roleManagement/Invoke-GtPimRoleSelfActivation.md
    #>
    [CmdletBinding()]
    param( 
        [Parameter(ParameterSetName = 'ByRoleName')] 
        [ValidateSet('GlobalReader', 'GlobalAdmin', 'IntuneAdmin', 'ConditionalAccessAdmin', 'AuthenticationAdmin')]
        [string]$Role = "GlobalReader",

        [Parameter(Mandatory, ParameterSetName = 'ByRoleId')]
        [guid]$RoleDefinitionId,

        [Parameter()]
        [string]$Justification = "PIM Self Activation",

        [Parameter()]
        [ValidateRange(1, 24)]
        [int]$DurationInHours = 8
    )

    if (-not (Get-MgContext)) { throw "No Microsoft Graph context found. Please connect using Connect-MgGraph." }
    
    $currentUserId = Invoke-GtGraphRequest "me" -Select id -Verbose:$false | Select-Object -ExpandProperty id

    # Resolve role name to role definition ID
    if ($PSCmdlet.ParameterSetName -eq 'ByRoleName') {
        $roleDefinitionIdMap = @{
            "GlobalReader"           = "f2ef992c-3afb-46b9-b7cf-a126ee74c451"
            "GlobalAdmin"            = "62e90394-69f5-4237-9190-012177145e10"
            "IntuneAdmin"            = "3a2c62db-5318-420d-8d74-23affee5d9d5"
            "ConditionalAccessAdmin" = "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9"
            "AuthenticationAdmin"    = "c4e39bd9-1100-46d3-8c65-fb160da0071f"
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

    Write-Verbose "Requesting PIM activation for role '$roleName' (ID: $targetRoleId) for user $currentUserId"
    
    try { $result = Invoke-MgGraphRequest -Method POST -Uri "v1.0/roleManagement/directory/roleAssignmentScheduleRequests" -Body ($activationRequest | ConvertTo-Json) -ContentType "application/json" }
    catch { throw $_ }

    # Output success message with token refresh guidance
    Write-Verbose "PIM role '$roleName' assignmentRequest sent with duration: $DurationInHours hour(s)."
    Write-Warning "Your current access token may not include the new role claims (wids). To refresh your token with updated permissions, run 'Connect-MgGraph -ContextScope Process'"

    return $result
}
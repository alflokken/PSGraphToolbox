function Get-GtAgentUsers{
    Invoke-GtGraphRequest "/beta/users/microsoft.graph.agentUser" -Select "id,userPrincipalName,displayName,accountEnabled,userType,createdDateTime" -Expand "manager(`$select=userPrincipalName)"
}
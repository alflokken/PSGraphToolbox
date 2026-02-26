<# wids-pim-refresh
Windows Token Broker caches access tokens persistently, when PIM roles are activated after the initial token is issued, subsequent Connect-MgGraph calls return the cached token lacking updated role claims (wids), causing 403 errors.
https://learn.microsoft.com/en-us/entra/identity-platform/access-token-claims-reference

These access tokens are served without re-validating against Azure AD. Disconnect-MgGraph + Connect-MgGraph does NOT force token refresh - it reuses cached token with stale role claims from original issue time.
(token iat timestamp remains unchanged across reconnects, cached token missing wids claim for newly activated PIM roles, cached tokens are located at $env:LOCALAPPDATA\Packages\Microsoft.AAD.BrokerPlug*\AC\TokenBroker\accounts\*.tbaccpt)

Using ContextScope Process bypasses persistent Token Broker cache, forcing fresh token acquisition from Azure AD with current role claims.
#>

Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
Connect-MgGraph -ContextScope Process -NoWelcome
#$newToken = Invoke-GraphRequest -Uri "/v1.0/me" -OutputType HttpResponseMessage
#Connect-MgGraph -AccessToken ($newToken.RequestMessage.Headers.Authorization.Parameter | ConvertTo-SecureString -AsPlainText -Force) -NoWelcome
write-host -ForegroundColor Green "Graph connection reset with fresh token."
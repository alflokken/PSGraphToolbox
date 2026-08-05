

<p align="center">
  <img width="300" height="189" src="/docs/img/aiSlop_psgtLogo.png">
</p>

<h1 align="center">PowerShell Graph Toolbox</h1>

<p align="center">
  <em>Herramientas ligeras de Microsoft Graph para entornos restringidos</em>
</p>

<p align="center">
  <a href="#quick-start">Inicio Rápido</a> •
  <a href="#features">Características</a> •
  <a href="/docs/">Documentación</a> •
  <a href="#contributing">Contribuir</a>
</p>

---

Colección de funciones de PowerShell construidas alrededor de `Invoke-GtGraphRequest`, un envoltorio para `Invoke-MgGraphRequest` que maneja la paginación y los parámetros de consulta OData automáticamente.

**Por qué existe esto:** A menudo trabajo en entornos restringidos con el Modo de Lenguaje Restringido y PowerShell 5.1, donde se requieren dependencias mínimas. La única dependencia es `Microsoft.Graph.Authentication`. Estas herramientas simplifican las consultas delta, el agrupamiento por lotes y las operaciones comunes de Graph y Entra ID.

---

## Inicio Rápido

```powershell

# Instalar el módulo
Install-Module -Name PsGraphToolbox -Scope CurrentUser

# Buscar usuarios
Find-GtUser "Vincent"

# Generar un informe HTML sobre las asignaciones de roles de Entra ID
Get-GtDirectoryRoleMemberReport
```

---

## Características

### Núcleo

<details>
<summary><b>Invoke-GtGraphRequest</b> - Consultas estilo Graph Explorer desde PowerShell</summary>

Función principal para llamadas a la API de Graph. Admite parámetros OData, paginación automática y establece automáticamente el encabezado ConsistencyLevel para consultas de búsqueda.

```powershell
# Consulta simple
Invoke-GtGraphRequest -resourcePath "me"

# Con parámetros OData
Invoke-GtGraphRequest -resourcePath "users" -filter "accountEnabled eq true" -select "displayName" -top 3 -PageLimit 1 

# Búsqueda (el encabezado ConsistencyLevel se añade automáticamente)
Invoke-GtGraphRequest -resourcePath "users" -search '"displayName:john"' -select "id,displayName"

# API Beta
Invoke-GtGraphRequest -resourcePath "users" -select "id,displayName,signInActivity" -apiVersion beta

# La paginación es automática
$allUsers = Invoke-GtGraphRequest -resourcePath "users" -select "id,displayName"
$allUsers.Count  # Devuelve todos los usuarios, no solo la primera página
```

</details>

<details>
<summary><b>Invoke-GtGraphBatchRequest</b> - Agrupar varias llamadas a la API</summary>

* Divide automáticamente las solicitudes en lotes de 20 (límite de la API de Graph)
* Respeta los encabezados Retry-After para el control de frecuencia (esperando y reintentando las solicitudes fallidas)
* Escribe el progreso en la consola con recuentos de solicitudes y tiempos
* Devuelve una tabla hash de resultados claveada por ID de solicitud para un acceso fácil

```powershell
# Preparar varias solicitudes:
$requests = foreach ( $id in $users.id ) {
     @{
        id     = $id
        method = "GET"
        url    = "users/$id/authentication/methods"
    }
}

# Ejecutar solicitud por lotes
$results = Invoke-GtGraphBatchRequest -Requests $requests

# Acceder a los resultados por ID de solicitud (las claves de la tabla hash coinciden con la propiedad 'id' de cada solicitud)
$results["request-id-here"]

# Recorrer todos los resultados
$results.GetEnumerator()
```

</details>

<details>
<summary><b>Sync-GtGraphResourceDelta</b> - Sincronizar recursos de Graph utilizando consultas delta con seguimiento persistente del estado</summary>

Para más detalles y ejemplos, consulta mi publicación en el blog [Consultas Delta de Microsoft Graph en PowerShell](https://alflokken.github.io/posts/graph-delta-queries/).

```powershell
$syncParams = @{
    ResourcePath     = 'users/delta'
    SelectProperties = 'id,userPrincipalName,accountEnabled,displayName'
    StoragePath      = '.\userDeltaState.json'
}

# Sincronización inicial
$result = Sync-GtGraphResourceDelta @syncParams

# Las llamadas posteriores solo obtienen los cambios
$result = Sync-GtGraphResourceDelta @syncParams

# Acceder a los resultados
$result.CurrentState.value

# Registro de cambios desde la última sincronización
$result.ChangeLog 
```

</details>

### Informes

Informes HTML con estilo Bootstrap con búsqueda, ordenación y paginación.

| Informe | Captura de pantalla | Comando | Descripción |
|--------|---------|-------------|:----------:|
| **Credenciales de aplicación** | [📷](docs/img/htmlReport_appCreds.png) | Secretos y certificados con fecha de expiración | `Get-GtApplicationCredentialReport` |
| **Roles del directorio** | [📷](docs/img/htmlReport_roles.png) | Asignaciones de roles + elegibilidad de PIM | `Get-GtDirectoryRoleMemberReport` | 
| **Acceso condicional** | [📷](docs/img/htmlReport_capol.png) | Políticas de Acceso Condicional con GUIDs resueltos | `Get-GtConditionalAccessPolicyReport` |
| **Certificados SAML** | | Expiración del certificado de firma SAML | `Get-GtSamlCertificateReport` |
| **Genérico** | | Cualquier objeto de PowerShell a HTML | `Export-GtHtmlReport` |

```powershell
# Generar un informe
Get-GtConditionalAccessPolicyReport -outputType html

# Enviar cualquier dato a HTML mediante pipeline
Invoke-GtGraphRequest -resourcePath "users" -select "displayName,mail" -PageLimit 1  | Export-GtHtmlReport
```

### Usuarios y Grupos

<details>
<summary><b>Buscar y recuperar usuarios</b></summary>

```powershell
# Buscar por nombre para mostrar (coincidencia parcial)
Find-GtUser "john"
# Devuelve: id, displayName, userPrincipalName, accountEnabled, mobilePhone, createdDateTime, lastPasswordChangeDateTime

# Obtener usuario por UPN o ObjectId
Get-GtUser "john.doe@zavainc.com"

# Compatible con pipelines
Find-GtUser "john doe" | Get-GtUserAuthenticationMethods -MethodType fido2Methods
```

</details>

<details>
<summary><b>Buscar y gestionar grupos</b></summary>

```powershell
# Buscar grupos
Find-GtGroup "Sales"
# Devuelve: id, displayName, description, createdDateTime, groupTypes, mailEnabled, securityEnabled

# Obtener miembros del grupo
Find-GtGroup "Sales" | Get-GtGroupMembers

# Agregar miembro (acepta UPNs, GUIDs u objetos)
Add-GtMembersToGroup -Group "Sales Team" -Members "john.doe@zavainc.com"

# Agregar varios miembros en lotes (maneja automáticamente el agrupamiento para listas grandes)
Add-GtMembersToGroup -Group "Sales Team" -Members $addMembers

# Eliminar miembro(s)
Remove-GtMembersFromGroup -Group "Sales Team" -Members $addMembers[0]
```

</details>

### Seguridad y Auditoría

<details>
<summary><b>Registros de inicio de sesión</b></summary>

```powershell
# Obtener registros de inicio de sesión de usuario (por defecto, hoy desde las 05:00)
Get-GtUserSignIns -InputObject "john.doe@zavainc.com"
# Columnas de salida: dateTime, correlationId, userPrincipalName, status, application, 
#                 authMethod_0, authMethod_1, ipAddress, device, client, browser,
#                 compliantDevice, successfulCAPs, failedCAPs, resultType

# Pipeline: buscar inicios de sesión fallidos
Find-GtUser "admin" | Get-GtUserSignIns | Where-Object { $_.status -eq "Failed" }
```

</details>

<details>
<summary><b>Métodos de autenticación y pases de acceso temporales</b></summary>

```powershell
# Ver métodos de autenticación registrados
Get-GtUserAuthenticationMethods -InputObject "john.doe@zavainc.com"
# Devuelve objetos completos de métodos de autenticación desde la API de Graph
# Propiedades comunes: @odata.type, id, displayName, createdDateTime (varía según el tipo de método)

# Ver claves de seguridad FIDO2 registradas
$user | Get-GtUserAuthenticationMethods -MethodType fido2Methods

# Generar un pase de acceso temporal
New-GtUserTemporaryAccessPass $user -LifetimeInMinutes 60 -IsUsableOnce
# Devuelve: userId, temporaryAccessPass, lifetimeInMinutes, isUsableOnce, startDateTime, methodUsabilityReason
```

</details>

<details>
<summary><b>Revocación de sesión</b></summary>

```powershell
Revoke-GtUserSession -InputObject "john.doe@zavainc.com"
# Devuelve: userId, success (True/False), timestamp
```

</details>

<details>
<summary><b>Registros de auditoría</b></summary>

```powershell
# Obtener registros de auditoría para un usuario (iniciados o destino, últimos 30 días)
Get-GtAuditLogsByObjectId "john.doe@zavainc.com"
# Salida: activityDateTime, activityDisplayName, result, targetResourceUser, 
#         targetResourceGroup, initiatedBy, category, loggedByService, resultReason

# Obtener activaciones de roles de PIM
Get-GtAuditLogsPimActivations -StartDate (Get-Date).AddDays(-30)
# Salida: activityDateTime, principalId, userPrincipalName, roleId, justification
```

</details>

<details>
<summary><b>Asignaciones de roles de PIM</b></summary>

```powershell
# Obtener asignaciones de PIM del usuario actual
Get-GtPimRoleAssignments
# Salida: principalId, userPrincipalName, roleDisplayName, roleId, state, scheduleEnd, Status, MemberType

# Filtrar por estado
Get-GtPimRoleAssignments -State Eligible

# Autoactivar un rol
Invoke-GtPimRoleSelfActivation -Role GlobalReader -DurationInHours 2 -Justification "Audit task"
# Devuelve: id, completedDateTime, createdDateTime, status, justification
```

</details>

### Dispositivos y Dominios

<details>
<summary><b>Operaciones de dispositivo</b></summary>

```powershell
# Buscar dispositivos por nombre para mostrar
Find-GtDevice "macbook"
# Salida: id, deviceId, displayName, operatingSystem, operatingSystemVersion, accountEnabled,
#         approximateLastSignInDateTime, createdDateTime, isManaged, isCompliant, profileType,
#         registrationDateTime, trustType, enrollmentType, managementType, deviceModel

# Obtener dispositivo con información del propietario
Get-GtDevice "12345678-1234-1234-1234-123456789012"
# Incluye: registeredOwners, groupMembership

# Dispositivos propiedad del usuario
Get-GtUserOwnedDevices "john.doe@zavainc.com"
```

</details>

<details>
<summary><b>Información de dominio e inquilino</b></summary>

```powershell
# Obtener todos los dominios
Get-GtDomains
# Salida: id, authenticationType, isVerified (+ detalles de federación si aplica)

# Búsqueda de inquilino por dominio (no requiere autenticación, usa metadatos públicos)
Get-GtTenantIdFromDomainName -DomainName "zavainc.com"
# Devuelve: domainName, tenantId

# Búsqueda inversa de inquilino (requiere autenticación, usa la API de Graph)
Get-GtTenantInformationByTenantId "6babcaad-604b-40ac-a9d7-9fd97c0b779f"

# Información del inquilino actual
Get-GtTenantInfo
# Devuelve: tenantId, displayName, tenantType, countryCode, createdDateTime,
#          defaultDomain, initialDomain, verifiedDomainCount, domains
```

</details>

---

## Contribuir

Este es un kit de herramientas personal compartido públicamente. Las contribuciones son bienvenidas, con expectativas realistas:

- **Errores** - Se abordarán según la gravedad y la disponibilidad personal
- **Solicitudes de funciones** - Pueden no alinearse con mis necesidades. Bifurca (fork) y personaliza según sea necesario.
- **Solicitudes de extracción (Pull requests)** - Sigue los patrones en [.github/copilot-instructions.md](.github/copilot-instructions.md)

Consulta [IDEAS.md](IDEAS.md) para posibles funciones futuras.

---

<sub>**Aviso sobre IA**<br> Los archivos de ayuda se generan automáticamente. Parte del código puede estar asistido por IA. `Export-GtHtmlReport` está completamente generado por IA, como se indica en su archivo de ayuda. El logotipo también está generado por IA (obviamente).</sub>

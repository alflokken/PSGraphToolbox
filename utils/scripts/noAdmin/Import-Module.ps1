$env:PSModulePath = "C:\Modules;$env:PSModulePath"
$modules = @(
    "Microsoft.Graph.Authentication"
)
$modules | %{ Save-Module -Name $_ -Path "C:\Modules" }

Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
$modules | %{ Import-Module -Name $_ -Force -ErrorAction Stop }
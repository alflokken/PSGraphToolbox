# Install dotnet sdk without admin rights
Invoke-WebRequest -Uri https://dot.net/v1/dotnet-install.ps1 -OutFile dotnet-install.ps1
#.\dotnet-install.ps1 -Channel 9.0.1xx -InstallDir "$env:USERPROFILE\dotnet"
.\dotnet-install.ps1 -Channel LTS -InstallDir "$env:USERPROFILE\dotnet"
# Add dotnet to PATH 
$env:Path = "$env:USERPROFILE\dotnet\;" + $env:Path
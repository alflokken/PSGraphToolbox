@echo off
set DOTNET_ROOT=%USERPROFILE%\dotnet
set PATH=%DOTNET_ROOT%;%PATH%
start "" "%LOCALAPPDATA%\Programs\Microsoft VS Code\Code.exe" "%USERPROFILE%"
Start-BitsTransfer -Source "https://aka.ms/installazurecliwindowszipx64" -Destination "$env:TEMP\azurecli.zip"
mkdir "$env:USERPROFILE\azure-cli" | Out-Null
tar -xf "$env:TEMP\azurecli.zip" -C "$env:USERPROFILE\azure-cli"
$env:Path = "$env:USERPROFILE\azure-cli\bin;" + $env:Path

az --version
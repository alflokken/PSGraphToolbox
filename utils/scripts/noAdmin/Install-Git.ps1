# download and extract PortableGit
# https://github.com/git-for-windows/git/releases

$env:Path = "C:\Users\PA017613\Downloads\PortableGit\bin;" + $env:Path

<#
git config --global user.name {userName}
git config --global user.email {emailAddress}
git config --global core.sshCommand "C:/Windows/System32/OpenSSH/ssh.exe"
ssh-keygen -t ed25519 -C {emailAddress}
#>
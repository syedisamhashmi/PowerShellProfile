[CmdletBinding()]
param(
  [switch]$forceInstall
)

if ($MyInvocation.InvocationName -ne ".") {
  $tools_repo_path = "$PSScriptRoot/../..";
  . $tools_repo_path/powershell/functions/prepend_path.ps1 "$PSScriptRoot/functions"
}

# Add install preferences if not present

$config = get_or_create_config_key "UserPreferences.ToolsPath"
$tools_install_path = $config.UserPreferences.ToolsPath

# llvm installation
prepend_path "$tools_install_path/llvm"
prepend_path "$tools_install_path/llvm/bin"
$isToolInstalled = Get-Command clang-format -errorAction SilentlyContinue
if (-not $forceInstall -and $isToolInstalled) {
  Write-Verbose "llvm installed, nice!"
  if (Test-Path -PathType Leaf "$tools_install_path/llvm.tar.xz")
  {
    Remove-Item -Force -Path "$tools_install_path/llvm.tar.xz"
  }
  if (Test-Path -PathType Leaf "$tools_install_path/llvm.tar")
  {
    Remove-Item -Force -Path "$tools_install_path/llvm.tar"
  }
}
else {
  Write-Debug "llvm not installed or force install"

  $config = get_or_create_config_key "InstallPreferences.RejectedLlvm"
  if (
    $forceInstall -or 
    ($config.InstallPreferences.RejectedLlvm -eq $null) -or 
    (-not $config.InstallPreferences.RejectedLlvm)
  )
  {
    $toolInstallDecision = yes_no_prompt `
      -title "Install ``llvm`` to your tools?" `
      -description "You have not installed llvm. This is necessary for certain tools. Install it?" `
      -yes "Install llvm" `
      -no "I will accept responsibility for installing it on my own...";
    # They are cool with me installing it.
    if ($toolInstallDecision -eq 0) {
      $config = get_or_create_config_key "InstallPreferences.Rejectedllvm" $false
      
      $isTarInstalled = Get-Command tar -errorAction SilentlyContinue
      if (-not $isTarInstalled)
      {
        Write-Host "Can not install `llvm` at this time, ``tar` is not installed, please install and try again."
        return 0;
      }
      $is7zInstalled = Get-Command 7z -errorAction SilentlyContinue
      if (-not $is7zInstalled)
      {
        ./install_7zip.ps1
      }

      Invoke-WebRequest -Uri https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.7/clang+llvm-18.1.7-x86_64-pc-windows-msvc.tar.xz -OutFile "$tools_install_path/llvm.tar.xz"
      Invoke-Expression "$tools_install_path/7z/7z.exe e `"$tools_install_path/llvm.tar.xz`" -o`"$tools_install_path`""
      tar -xf "$tools_install_path/llvm.tar" -C "$tools_install_path"
      Rename-Item -Path "$tools_install_path/clang+llvm-18.1.7-x86_64-pc-windows-msvc" -NewName "llvm"
      Write-Host "llvm installed, I will clean up leftover downloads next time instead of right now to prevent a usage race"
    }
    # They will install on their own, document and never ask again.
    if ($toolInstallDecision -eq 1) {
      $config = get_or_create_config_key "InstallPreferences.RejectedLlvm" $true
    }
  } else {
    Write-Debug "NOT asking to install llvm, they rejected previously"
  }
}

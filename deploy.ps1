$ErrorActionPreference = "Stop"

if ($env:APPVEYOR_REPO_BRANCH -ne "master") { 
    Write-Host "Skipping deploy as not master branch"
    return
}

if ($env:ShouldDeploy -ne "True") { 
    Write-Host "Skipping deploy as ShouldDeploy is not set to True"
    return
}

& .\create-artifact.ps1

Update-ModuleManifest -Path .\ParTech.SimpleInstallScripts\ParTech.SimpleInstallScripts.psd1 -ModuleVersion $Env:APPVEYOR_BUILD_VERSION

Publish-Module -Path .\ParTech.SimpleInstallScripts -NugetAPIKey $Env:PSGalleryApiKey -Verbose
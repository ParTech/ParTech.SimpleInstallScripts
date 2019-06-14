param(
    [Parameter(Mandatory)] [string] $Topology,
    [Parameter(Mandatory)] [string] $Prefix,
    [Parameter(Mandatory)] [string] $SiteFolder,
    [Parameter(Mandatory)] [string] $SiteUrl,
    [Parameter(Mandatory)] [string] $DownloadBase,
    [Parameter(Mandatory)] [string] $DownloadFolder,
    [Parameter(Mandatory)] [string] $SqlAdminPassword
)

if ($Env:APPVEYOR_REPO_COMMIT_MESSAGE -like '*[[skip test]]*') {
    Write-Host "Skipping tests due to commit message" -ForegroundColor Magenta
    return
}

if ($env:APPVEYOR_REPO_BRANCH -eq "master") { 
    Write-Host "Skipping test as master branch"
    return
}

$ErrorActionPreference = "Stop"

.\create-artifact.ps1

Import-Module .\ParTech.SimpleInstallScripts\ParTech.SimpleInstallScripts.psd1

Try {
    # Ensure that the scripts can be run from anywhere, not just the checkout directory
    Push-Location C:\
    Invoke-Expression "Install-Sitecore$($Topology) $Prefix -SqlAdminPassword $SqlAdminPassword -DoInstallPrerequisites"
} Finally {
    Pop-Location
}

Try {
    Push-Location $PSScriptRoot
    Install-SitecoreConfiguration .\PackageInstaller.json -Package "Sitecore PowerShell Extensions-5.0.zip" -SiteFolder $SiteFolder -DownloadBase $DownloadBase -DownloadFolder $DownloadFolder -SiteUrl $SiteUrl
} Finally {
    Pop-Location
}
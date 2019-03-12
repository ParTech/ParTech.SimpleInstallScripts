param(
    [Parameter(Mandatory=$true)] [string] $Topology,
    [Parameter(Mandatory=$true)] [string] $Prefix,
    [Parameter(Mandatory=$true)] [string] $SiteFolder,
    [Parameter(Mandatory=$true)] [string] $SiteUrl,
    [Parameter(Mandatory=$true)] [string] $DownloadBase,
    [Parameter(Mandatory=$true)] [string] $DownloadFolder,
    [Parameter(Mandatory=$true)] [string] $SqlAdminPassword
)

Write-Host "Commit message: $($Env:APPVEYOR_REPO_COMMIT_MESSAGE)"
if ($Env:APPVEYOR_REPO_COMMIT_MESSAGE -like '*[[skip test]]*') {
    Write-Host "Skipping tests due to commit message" -ForegroundColor Magenta
    return
}

$ErrorActionPreference = "Stop"
Import-Module .\ParTech.SimpleInstallScripts.psd1
Invoke-Expression "Install-Sitecore$($Topology) $Prefix -SqlAdminPassword $SqlAdminPassword -DoInstallPrerequisites"
Install-SitecoreConfiguration .\PackageInstaller.json -Package "Sitecore PowerShell Extensions-5.0.zip" -SiteFolder $SiteFolder -DownloadBase $DownloadBase -DownloadFolder $DownloadFolder -SiteUrl $SiteUrl
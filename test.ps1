param(
    [Parameter(Mandatory)] [string] $Prefix,
    [Parameter(Mandatory)] [string] $SitecoreVersion,
    [Parameter(Mandatory)] [string] $DownloadBase,
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
    
    Install-Sitecore91 -Prefix $Prefix `
                      -SitecoreVersion $SitecoreVersion `
                      -DownloadBase $DownloadBase `
                      -SqlServer . `
                      -SqlAdminUser sa `
                      -SqlAdminPassword $SqlAdminPassword `
                      -DoInstallPrerequisites `
                      -Packages @("Sitecore PowerShell Extensions-5.0.zip") `
                      -DoSitecorePublish
                      #-DoRebuildLinkDatabases `
                      #-DoRebuildSearchIndexes `
                      #-DoDeployMarketingDefinitions
} Finally {
    Pop-Location
}
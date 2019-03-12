Set-StrictMode -Version 2.0

Function Install-SitecorePackageInstallerTask {
    param(
        [Parameter(Mandatory=$true)] [string] $SiteFolder
    )

    Write-Information "Installing Sitecore Package Installer" -Tag 'PackageInstall'
    $source = Resolve-Path "PackageInstaller.asmx"
    $dest = Join-Path $SiteFolder "PackageInstaller.asmx"
    Copy-Item -Path $source -Destination $dest
}

Function Remove-SitecorePackageInstallerTask {
    param(
        [Parameter(Mandatory=$true)] [string] $SiteFolder
    )

    Write-Information "Deleting Sitecore Package Installer" -Tag 'PackageInstall'
    $installerPath = Join-Path $SiteFolder "PackageInstaller.asmx"
    Remove-Item -Path $installerPath -ErrorAction SilentlyContinue
}

Function Install-SitecorePackageTask {
    param(
        [Parameter(Mandatory=$true)] [string] $SiteUrl,
        [Parameter(Mandatory=$true)] [string] $PackagePath
    )

    Write-Information "Installing Package $PackagePath" -Tag 'PackageInstall'
    $webURI = "$siteURL/PackageInstaller.asmx?WSDL"

    Write-Information "Url $webURI" -Tag 'PackageInstall'

    # Warmup
    try {
        $warmup = Invoke-WebRequest $webURI -TimeoutSec 600 -ErrorAction SilentlyContinue
        $warmup.Content | Out-Null
    }
    catch { Write-Host "Warmup returned error" }

    # Do the install here
    $proxy = New-WebServiceProxy -uri $webURI
    $proxy.Timeout = 1800000
    $proxy.InstallPackage($PackagePath)
}

Register-SitecoreInstallExtension -Command Install-SitecorePackageInstallerTask -As InstallSitecorePackageInstaller -Type Task
Register-SitecoreInstallExtension -Command Remove-SitecorePackageInstallerTask -As RemoveSitecorePackageInstaller -Type Task
Register-SitecoreInstallExtension -Command Install-SitecorePackageTask -As InstallSitecorePackage -Type Task
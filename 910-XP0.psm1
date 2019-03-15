Set-StrictMode -Version 2.0

Function Install-Sitecore910XP0 (
    [string] [Parameter(Mandatory)] [string] $Prefix, # The Prefix that will be used on SOLR, Website and Database instances.
    [string] $SitecoreAdminPassword = "b", # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    [string] $SCInstallRoot = "C:\Downloads\9.1.0", # The root folder with the license file and WDP files.
    [string] $XConnectSiteName = "$prefix.xconnect.local", # The name for the XConnect service.
    [string] $SitecoreSiteName = "$Prefix.dev.local", # The Sitecore site instance name.
    [string] $IdentityServerSiteName = "$Prefix.identityserver.local", # Identity Server site name
    [string] $LicenseFile = "$SCInstallRoot\license.xml", # The Path to the license file
    [string] $SolrHost = "solr", # The hostname of the Solr server
    [string] $SolrPort = "8983", # The port of the Solr server
    [string] $SolrUrl = "https://$($SolrHost):$($SolrPort)/solr", # The Url of the Solr service
    [string] $SolrVersion = "7.2.1", # Solr version
    [string] $SolrService = "Solr-$SolrVersion", # The Name of the Solr Service.
    [string] $SolrRoot = "C:\solr\$SolrService", # The Folder that Solr has been installed in
    [string] $SqlServer = ".", # The DNS name or IP of the SQL Instance.
    [string] $SqlAdminUser = "sa", # A SQL user with sysadmin privileges.
    [string] $SqlAdminPassword = "12345", # The password for $SQLAdminUser.
    [string] $PasswordRecoveryUrl = "http://$SitecoreSiteName", # The Identity Server password recovery URL, this should be the URL of the CM Instance
    [string] $SitecoreIdentityAuthority = "https://$IdentityServerSiteName", # The URL of the Identity Authority
    [string] $XConnectCollectionService = "https://$XConnectSiteName", # The URL of the XconnectService
    [string] $ClientSecret = "SIF-Default", # The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
    [string] $AllowedCorsOrigins = "http://$SitecoreSiteName", # Pipe-separated list of instances (URIs) that are allowed to login via Sitecore Identity.
    [string] $DownloadBase = $Env:DownloadBase,
    [switch] $DoUninstall, # Uninstalls Sitecore instead of installing
    [switch] $DoInstallPrerequisites # Install SIF, Solr, etc.
)
{
    Invoke-DownloadPackages $DownloadBase `
                      $SCInstallRoot `
                      "Sitecore 9.1.0 rev. 001564 (WDP XP0 packages).zip" `
                      "XP0 Configuration files 9.1.0 rev. 001564.zip"
   
    $singleDeveloperParams = @{
        Path = "$SCInstallRoot\XP0-SingleDeveloper.json"
        SqlServer = $SqlServer
        SqlAdminUser = $SqlAdminUser
        SqlAdminPassword = $SqlAdminPassword
        SitecoreAdminPassword = $SitecoreAdminPassword
        SolrUrl = $SolrUrl
        SolrRoot = $SolrRoot
        SolrService = $SolrService
        Prefix = $Prefix
        XConnectCertificateName = $XConnectSiteName
        IdentityServerCertificateName = $IdentityServerSiteName
        IdentityServerSiteName = $IdentityServerSiteName
        LicenseFile = $LicenseFile
        XConnectPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp0xconnect.scwdp.zip").FullName
        SitecorePackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_single.scwdp.zip").FullName
        IdentityServerPackage = (Get-ChildItem "$SCInstallRoot\Sitecore.IdentityServer 2.0.0 rev. * (OnPrem)_identityserver.scwdp.zip").FullName
        XConnectSiteName = $XConnectSiteName
        SitecoreSitename = $SitecoreSiteName
        PasswordRecoveryUrl = $PasswordRecoveryUrl
        SitecoreIdentityAuthority = $SitecoreIdentityAuthority
        XConnectCollectionService = $XConnectCollectionService
        ClientSecret = $ClientSecret
        AllowedCorsOrigins = $AllowedCorsOrigins
    }

    If ($DoInstallPrerequisites) {
        Try {
            Push-Location $PSScriptRoot
            Install-AllPrerequisites -SCInstallRoot $SCInstallRoot -DownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort
            Enable-ContainedDatabaseAuthentication -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword
        } Finally {
            Pop-Location
        }
    }

    Try {
        Push-Location $SCInstallRoot

        If ($DoUninstall) {
            Uninstall-SitecoreConfiguration @singleDeveloperParams *>&1 | Tee-Object XP0-SingleDeveloper-Uninstall.log
        } else {
            Install-SitecoreConfiguration @singleDeveloperParams *>&1 | Tee-Object XP0-SingleDeveloper.log
        }
    } Finally {
        Pop-Location
    }
}
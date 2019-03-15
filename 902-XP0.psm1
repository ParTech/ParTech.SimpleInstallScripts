Set-StrictMode -Version 2.0

Function Install-Sitecore902XP0 (
    [string] [Parameter(Mandatory)] [string] $Prefix, # The Prefix that will be used on SOLR, Website and Database instances.
    [string] $SitecoreAdminPassword = "b", # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    [string] $SCInstallRoot = "C:\Downloads\9.0.2", # The root folder with the license file and WDP files.
    [string] $XConnectSiteName = "$prefix.xconnect.local", # The name for the XConnect service.
    [string] $SitecoreSiteName = "$Prefix.dev.local", # The Sitecore site instance name.
    [string] $IdentityServerSiteName = "$Prefix.identityserver.local", # Identity Server site name
    [string] $LicenseFile = "$SCInstallRoot\license.xml", # The Path to the license file
    [string] $SolrHost = "solr", # The hostname of the Solr server
    [string] $SolrPort = "8983", # The port of the Solr server
    [string] $SolrUrl = "https://$($SolrHost):$($SolrPort)/solr", # The Url of the Solr service
    [string] $SolrVersion = "6.6.2", # Solr version
    [string] $SolrService = "Solr-$SolrVersion", # The Name of the Solr Service.
    [string] $SolrRoot = "C:\solr\$SolrService", # The Folder that Solr has been installed in
    [string] $SqlServer = ".", # The DNS name or IP of the SQL Instance.
    [string] $SqlAdminUser = "sa", # A SQL user with sysadmin privileges.
    [string] $SqlAdminPassword = "12345", # The password for $SQLAdminUser.
    [string] $PasswordRecoveryUrl = "http://$SitecoreSiteName", # The Identity Server password recovery URL, this should be the URL of the CM Instance
    [string] $ClientSecret = "SIF-Default", # The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
    [string] $DownloadBase = $Env:DownloadBase,
    [switch] $DoInstallPrerequisites, # Install SIF, Solr, etc.
    [string] $SifVersion = "1.2.1" # Version of SIF that should be installed and/or used
)
{
    Invoke-DownloadPackages $DownloadBase `
                      $SCInstallRoot `
                      "Sitecore 9.0.2 rev. 180604 (WDP XP0 packages).zip" `
                      "XP0 Configuration files 9.0.2 rev. 180604.zip"
   
    If ($DoInstallPrerequisites) {
        Try {
            Push-Location $PSScriptRoot

            # 9.0.2 doesn't ship with Prerequisites.json so needs to be stored separately
            Invoke-DownloadIfNeeded "$DownloadBase/Prerequisites.json" "$SCInstallRoot\Prerequisites.json"

            Install-AllPrerequisites -SCInstallRoot $SCInstallRoot -DownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort
            Enable-ContainedDatabaseAuthentication -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword       

            # Only SIF 2.0 installs the prerequisites, now remove it and install 1.2.1 instead
            Remove-Module SitecoreInstallFramework
            Install-SitecoreInstallationFramework -Version $SifVersion            
        } Finally {
            Pop-Location
        }
    }

    Remove-Module SitecoreInstallFramework -ErrorAction SilentlyContinue
    Import-Module -Name SitecoreInstallFramework -Force -RequiredVersion $SifVersion

    Try {
        Push-Location $SCInstallRoot

        $params = @{
            Path = "$SCInstallRoot\xconnect-createcert.json"
            CertificateName = $XConnectSiteName
            RootCertFileName = "SIF121Root"
        }
        Install-SitecoreConfiguration @params

        $params = @{
            Path = "$SCInstallRoot\xconnect-solr.json"
            SolrUrl = $SolrUrl
            SolrRoot = $SolrRoot
            SolrService = $SolrService
            CorePrefix = $Prefix
        }

        Install-SitecoreConfiguration @params

        $params = @{
            Path = "$SCInstallRoot\xconnect-xp0.json"
            Package = (Get-ChildItem "$SCInstallRoot\Sitecore 9.0.2 rev. * (OnPrem)_xp0xconnect.scwdp.zip").FullName
            LicenseFile = $LicenseFile
            SiteName = $XConnectSiteName
            XConnectCert = $XConnectSiteName
            SqlDbPrefix = $Prefix
            SolrCorePrefix = $Prefix
            SqlServer = $sqlServer
            SqlAdminUser = $SqlAdminUser
            SqlAdminPassword = $SqlAdminPassword
            SolrUrl = $SolrUrl
        }
        Install-SitecoreConfiguration @params

        $params = @{
            Path = "$SCInstallRoot\sitecore-solr.json"
            SolrUrl = $SolrUrl
            SolrRoot = $SolrRoot
            SolrService = $SolrService
            CorePrefix = $Prefix
        }

        Install-SitecoreConfiguration @params

        $params = @{
            Path = "$SCInstallRoot\sitecore-xp0.json"
            Package = (Get-ChildItem "$SCInstallRoot\Sitecore 9.0.2 rev. * (OnPrem)_single.scwdp.zip").FullName
            LicenseFile = $LicenseFile
            SiteName = $SitecoreSiteName
            XConnectCert = $XConnectSiteName
            SqlDbPrefix = $Prefix
            SolrCorePrefix = $Prefix
            SqlServer = $sqlServer
            SqlAdminUser = $SqlAdminUser
            SqlAdminPassword = $SqlAdminPassword
            SolrUrl = $SolrUrl
            SitecoreAdminPassword = $SitecoreAdminPassword
        }
        Install-SitecoreConfiguration @params
    } Finally {
        Pop-Location

        # Put the latest version of SIF back
        Remove-Module SitecoreInstallFramework
        Install-SitecoreInstallationFramework        
    }
}
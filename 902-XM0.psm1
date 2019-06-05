Set-StrictMode -Version 2.0

Function Install-Sitecore902XM0 (
    [string] [Parameter(Mandatory)] [string] $Prefix, # The Prefix that will be used on SOLR, Website and Database instances.
    [string] $SitecoreAdminPassword = "b", # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    [string] $SCInstallRoot = "C:\Downloads\9.0.2", # The root folder with the license file and WDP files.
    [string] $SitecoreSiteName = "$Prefix.dev.local", # The Sitecore site instance name.

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
    [string] $DownloadBase = $Env:DownloadBase,
    [switch] $DoInstallPrerequisites, # Install SIF, Solr, etc.
    [string] $SifVersion = "1.2.1" # Version of SIF that should be installed and/or used
)
{
    Invoke-DownloadPackages $DownloadBase `
                      $SCInstallRoot `
                      "Sitecore 9.0.2 rev. 180604 (WDP XM1 packages).zip" `
                      "XM1 Configuration files 9.0.2 rev. 180604.zip"
   
    If ($DoInstallPrerequisites) {
        Try {
            Push-Location $PSScriptRoot

            # 9.0.2 doesn't ship with Prerequisites.json so needs to be stored separately
            Invoke-DownloadIfNeeded "$DownloadBase/Prerequisites.json" "$SCInstallRoot\Prerequisites.json"

            Install-AllPrerequisites -SCInstallRoot $SCInstallRoot -DownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort `
                                 -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword

            # Only SIF 2.0 installs the prerequisites, now remove it and install 1.2.1 instead
            Remove-Module SitecoreInstallFramework
            Install-SitecoreInstallFramework -Version $SifVersion
        } Finally {
            Pop-Location
        }
    }

    Remove-Module SitecoreInstallFramework -ErrorAction SilentlyContinue
    Import-Module -Name SitecoreInstallFramework -Force -RequiredVersion $SifVersion

    Try {
        Push-Location $SCInstallRoot

        $params = @{
            Path = "$SCInstallRoot\sitecore-solr.json"
            SolrUrl = $SolrUrl
            SolrRoot = $SolrRoot
            SolrService = $SolrService
            CorePrefix = $Prefix
        }

        Install-SitecoreConfiguration @params

        $params = @{
            Path = "$SCInstallRoot\sitecore-XM1-cm.json"
            Package = (Get-ChildItem "$SCInstallRoot\Sitecore 9.0.2 rev. 180604 (OnPrem)_cm.scwdp.zip").FullName
            LicenseFile = $LicenseFile
            SiteName = $SitecoreSiteName
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
        Remove-Module SitecoreInstallFramework -ErrorAction SilentlyContinue
        Install-SitecoreInstallFramework
    }
    
    Install-SitecoreConfiguration "$PSScriptRoot\SetRole.json" -SiteName $SitecoreSiteName -Role Standalone
}
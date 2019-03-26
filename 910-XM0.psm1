Set-StrictMode -Version 2.0

Function Install-Sitecore910XM0 (
    [Parameter(Mandatory)] [string] $Prefix, # The Prefix that will be used on SOLR, Website and Database instances.
    [string] $SitecoreAdminPassword = "b", # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    [string] $SCInstallRoot = "C:\Downloads\9.1.0", # The root folder with the license file and WDP files.
    [string] $SitecoreContentManagementSitename = "$Prefix.dev.local", # The name for the Sitecore Content Management server.
    [string] $SitecoreContentDeliverySitename = "$Prefix.cd.local", # The name for the Sitecore Content Delivery server.
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
    [string] $PasswordRecoveryUrl = "http://$SitecoreContentManagementSitename", # The Identity Server password recovery URL, this should be the URL of the CM Instance
    [string] $SitecoreIdentityAuthority = "https://$IdentityServerSiteName", # The URL of the Identity Authority
    [string] $ClientSecret = "SIF-Default", # The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
    [string] $AllowedCorsOrigins = "https://$SitecoreContentManagementSitename", # Pipe-separated list of instances (URIs) that are allowed to login via Sitecore Identity.
    [string] $DownloadBase = $Env:DownloadBase,
    [switch] $DoUninstall, # Uninstalls Sitecore instead of installing
    [switch] $DoInstallPrerequisites # Install SIF, Solr, etc.
)
{
    Invoke-DownloadPackages $DownloadBase `
                      $SCInstallRoot `
                      "Sitecore 9.1.0 rev. 001564 (WDP XM1 packages).zip" `
                      "XM1 Configuration files 9.1.0 rev. 001564.zip"

    # Remove the SitecoreCD include
    $json = Get-Content -Path "$SCInstallRoot\XM1-SingleDeveloper.json" -Raw | ConvertFrom-Json
    $json.Includes.PSObject.Properties.Remove("SitecoreCD")
    $json | ConvertTo-Json -Depth 100 | Set-Content -Path "$SCInstallRoot\XM0-SingleDeveloper.json" -Force
 
    $singleDeveloperParams = @{
        Path = "$SCInstallRoot\XM0-SingleDeveloper.json"
        SqlServer = $SqlServer
        SqlAdminUser = $SqlAdminUser
        SqlAdminPassword = $SqlAdminPassword
        SitecoreAdminPassword = $SitecoreAdminPassword
        SolrUrl = $SolrUrl
        SolrRoot = $SolrRoot
        SolrService = $SolrService
        Prefix = $Prefix
        IdentityServerCertificateName = $IdentityServerSiteName
        IdentityServerSiteName = $IdentityServerSiteName
        LicenseFile = $LicenseFile
        SiteCoreContentManagementPackage = (Get-ChildItem "$SCInstallRoot\Sitecore XM 9.1.0 rev. * (OnPrem)_cm.scwdp.zip").FullName
        SitecoreContentDeliveryPackage = (Get-ChildItem "$SCInstallRoot\Sitecore XM 9.1.0 rev. * (OnPrem)_cd.scwdp.zip").FullName
        IdentityServerPackage = (Get-ChildItem "$SCInstallRoot\Sitecore.IdentityServer 2.0.0 rev. * (OnPrem)_identityserver.scwdp.zip").FullName
        SitecoreContentManagementSitename = $SitecoreContentManagementSitename
        SitecoreContentDeliverySitename = $SitecoreContentDeliverySitename
        PasswordRecoveryUrl = $PasswordRecoveryUrl
        SitecoreIdentityAuthority = $SitecoreIdentityAuthority
        ClientSecret = $ClientSecret
        AllowedCorsOrigins = $AllowedCorsOrigins
    }

    If ($DoInstallPrerequisites) {
        Install-AllPrerequisites -SCInstallRoot $SCInstallRoot -DownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort `
                                 -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword
    }

    Install-SitecoreWrapper "910-XM0" $singleDeveloperParams $SCInstallRoot -DoUninstall:$DoUninstall
    Install-SitecoreConfiguration "$PSScriptRoot\SetRole.json" -SiteName $SitecoreContentManagementSitename -Role Standalone
}
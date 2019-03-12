Set-StrictMode -Version 2.0

Function Install-Sitecore910XP1 (
    [Parameter(Mandatory=$true)]  [string]   $Prefix, # The Prefix that will be used on SOLR, Website and Database instances.
    [Parameter(Mandatory=$false)] [string]   $SitecoreAdminPassword = "b", # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    [Parameter(Mandatory=$false)] [string]   $SCInstallRoot = "C:\Downloads\9.1.0", # The root folder with the license file and WDP files.
    [Parameter(Mandatory=$false)] [string]   $ContentDeliverySiteName = "$prefix.cd.local", # The name for the Content Delivery site.
    [Parameter(Mandatory=$false)] [string]   $ContentManagementSiteName = "$prefix.cm.local", # The name for the Content Management site.
    [Parameter(Mandatory=$false)] [string]   $ReportingSiteName = "$prefix.rep.local", # The name for the Reporting site.
    [Parameter(Mandatory=$false)] [string]   $ProcessingSiteName = "$prefix.prc.local", # The name for the Processing site.
    [Parameter(Mandatory=$false)] [string]   $ReferenceDateSiteName = "$prefix.refdata.local", # The name for the Reference Data site.
    [Parameter(Mandatory=$false)] [string]   $IdentityServerSiteName = "$Prefix.identityserver.local", # Identity Server site name
    [Parameter(Mandatory=$false)] [string]   $XP1MarketingAutomationSiteName = "$Prefix.ma.local", # The name for the Marketing Automation site.
    [Parameter(Mandatory=$false)] [string]   $XP1MarketingAutomationReportingSiteName = "$prefix.mareporting.local", # The name for the Marketing Automation reporting site.
    [Parameter(Mandatory=$false)] [string]   $XP1ClientCertificateName = "$prefix.xconnect_client", # The name for the XConnect site url.
    [Parameter(Mandatory=$false)] [string]   $XP1CollectionSitename = "$prefix.collection.local", # The name for the XConnect collection site.
    [Parameter(Mandatory=$false)] [string]   $XP1CollectionSearchSitename = "$prefix.search.local", # The name for the search site.
    [Parameter(Mandatory=$false)] [string]   $XP1CortexProcessingSitename = "$prefix.processingEngine.local", # The name for the XConnect processing engine service.
    [Parameter(Mandatory=$false)] [string]   $XP1CortexReportingSitename = "$prefix.reporting.local", # The name for the XConnect reporting service.
    [Parameter(Mandatory=$false)] [string]   $XConnectCollectionSearchService = "https://$XP1CollectionSearchSitename", # The URL for the XConnect Search Service.
    [Parameter(Mandatory=$false)] [string]   $XConnectCollectionService = "https://$XP1CollectionSitename", # The URL for the XConnect Collection Service.
    [Parameter(Mandatory=$false)] [string]   $XConnectReferenceDataService = "https://$ReferenceDateSiteName", # The URL of the XConnect Reference Data service
    [Parameter(Mandatory=$false)] [string]   $ProcessingService = "https://$ProcessingSiteName", # The URL of the processing service
    [Parameter(Mandatory=$false)] [string]   $ReportingService = "https://$ReportingSiteName", # The URL of the reporting service
    [Parameter(Mandatory=$false)] [string]   $CortexReportingService = "https://$XP1CortexReportingSitename", # The URL of the Cortex Reporting Service
    [Parameter(Mandatory=$false)] [string]   $MarketingAutomationOperationsService = "https://$XP1MarketingAutomationSiteName", # The URL of the Marketing Automaton Service
    [Parameter(Mandatory=$false)] [string]   $MarketingAutomationReportingService = "https://$XP1MarketingAutomationReportingSiteName", # The URL of the Marteting Automation Reporting Service
    [Parameter(Mandatory=$false)] [string]   $MachineLearningServerUrl = "http://admin:Test123!@QA-MMLS-01-DK1.dk.sitecore.net:12800", # The URL of the Machine Learning server
    [Parameter(Mandatory=$false)] [string]   $LicenseFile = "$SCInstallRoot\license.xml", # The Path to the license file
    [Parameter(Mandatory=$false)] [string]   $SolrHost = "solr", # The hostname of the Solr server
    [Parameter(Mandatory=$false)] [string]   $SolrPort = "8983", # The port of the Solr server
    [Parameter(Mandatory=$false)] [string]   $SolrUrl = "https://$($SolrHost):$($SolrPort)/solr", # The Url of the Solr service
    [Parameter(Mandatory=$false)] [string]   $SolrVersion = "7.2.1", # Solr version
    [Parameter(Mandatory=$false)] [string]   $SolrService = "Solr-$SolrVersion", # The Name of the Solr Service.
    [Parameter(Mandatory=$false)] [string]   $SolrRoot = "C:\solr\$SolrService", # The Folder that Solr has been installed in
    [Parameter(Mandatory=$false)] [string]   $SqlServer = ".", # The DNS name or IP of the SQL Instance.
    [Parameter(Mandatory=$false)] [string]   $SqlAdminUser = "sa", # A SQL user with sysadmin privileges.
    [Parameter(Mandatory=$false)] [string]   $SqlAdminPassword = "12345", # The password for $SQLAdminUser.
    [Parameter(Mandatory=$false)] [string]   $PasswordRecoveryUrl = "https://$ContentManagementSiteName", # The Identity Server password recovery URL, this should be the URL of the CM Instance
    [Parameter(Mandatory=$false)] [string]   $SitecoreIdentityAuthority = "https://$IdentityServerSiteName", # The URL of the Identity Authority
    [Parameter(Mandatory=$false)] [string]   $ClientSecret = "SIF-Default", # The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
    [Parameter(Mandatory=$false)] [string]   $AllowedCorsOrigins = "https://$ContentManagementSiteName", # Pipe-separated list of instances (URIs) that are allowed to login via Sitecore Identity.
    [Parameter(Mandatory=$false)] [string]   $DownloadBase = $Env:DownloadBase,
    [Parameter(Mandatory=$false)] [switch]   $DoUninstall = $false, # Uninstalls Sitecore instead of installing
    [Parameter(Mandatory=$false)] [switch]   $DoInstallPrerequisites = $false # Do not install SIF, Solr, etc.
)
{
    Invoke-DownloadPackages $DownloadBase `
                      $SCInstallRoot `
                      "Sitecore 9.1.0 rev. 001564 (WDP XP1 packages).zip" `
                      "XP1 Configuration files 9.1.0 rev. 001564.zip"
   
    $XP1Parameters = @{
        Path = "$SCInstallRoot\XP1-SingleDeveloper.json"
        CertificateName = $XP1ClientCertificateName
        SitecoreAdminPassword = $SitecoreAdminPassword
        LicenseFile = $LicenseFile
        SolrUrl = $SolrUrl
        SolrRoot = $SolrRoot
        SolrService = $SolrService
        Prefix = $Prefix
        SqlServer = $SqlServer
        SqlAdminUser = $SqlAdminUser
        SqlAdminPassword = $SqlAdminPassword
        IdentityServerCertificateName = $IdentityServerSiteName
        IdentityServerSiteName = $IdentityServerSiteName
        XP1CollectionSearchSitename = $XP1CollectionSearchSitename
        XP1MarketingAutomationSitename = $XP1MarketingAutomationSiteName
        XP1MarketingAutomationReportingSitename = $XP1MarketingAutomationReportingSiteName
        XP1ReferenceDataSitename = $ReferenceDateSiteName
        XP1CortexProcessingSitename = $XP1CortexProcessingSitename
        XP1CortexReportingSitename = $XP1CortexReportingSitename
        XP1CollectionSitename = $XP1CollectionSitename
        SitecoreXP1CDSitename = $ContentDeliverySiteName
        SitecoreXP1CMSitename = $ContentManagementSiteName
        SitecoreXP1RepSitename = $ReportingSiteName
        SitecoreXP1PrcSitename = $ProcessingSiteName
        XConnectCollectionService = $XConnectCollectionService
        XConnectReferenceDataService = $XConnectReferenceDataService
        XConnectCollectionSearchService = $XConnectCollectionSearchService
        MarketingAutomationOperationsService = $MarketingAutomationOperationsService
        MarketingAutomationReportingService = $MarketingAutomationReportingService
        CortexReportingService = $CortexReportingService
        MachineLearningServerUrl = $MachineLearningServerUrl
        SitecoreIdentityAuthority = $SitecoreIdentityAuthority
        ProcessingService = $ProcessingService
        ReportingService = $ReportingService
        XP1CollectionPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1collection.scwdp.zip").FullName
        XP1CollectionSearchPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1collectionsearch.scwdp.zip").FullName
        XP1CortexProcessingPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1cortexprocessing.scwdp.zip").FullName
        XP1MarketingAutomationPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1marketingautomation.scwdp.zip").FullName
        XP1MarketingAutomationReportingPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1marketingautomationreporting.scwdp.zip").FullName
        XP1ReferenceDataPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1referencedata.scwdp.zip").FullName
        XP1CortexReportingPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_xp1cortexreporting.scwdp.zip").FullName
        SitecoreXP1CDPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_cd.scwdp.zip").FullName
        SitecoreXP1CMPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_cm.scwdp.zip").FullName
        SitecoreXP1RepPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_rep.scwdp.zip").FullName
        SitecoreXP1PrcPackage = (Get-ChildItem "$SCInstallRoot\Sitecore 9.1.0 rev. * (OnPrem)_prc.scwdp.zip").FullName
        IdentityServerPackage = (Get-ChildItem "$SCInstallRoot\Sitecore.IdentityServer 2.0.0 rev. * (OnPrem)_identityserver.scwdp.zip").FullName
        PasswordRecoveryUrl = $PasswordRecoveryUrl
        ClientSecret = $ClientSecret
        AllowedCorsOrigins = $AllowedCorsOrigins
    }

    If ($DoInstallPrerequisites) {
        Install-AllPrerequisites -SCInstallRoot $SCInstallRoot -DownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort
        Enable-ContainedDatabaseAuthentication -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword
    }

    Push-Location $SCInstallRoot

    Try {
        If ($DoUninstall) {
            Uninstall-SitecoreConfiguration @XP1Parameters *>&1 | Tee-Object XP1-SingleDeveloper-Uninstall.log
        } else {
            Install-SitecoreConfiguration @XP1Parameters *>&1 | Tee-Object XP1-SingleDeveloper.log
        }
    } Finally {
        Pop-Location
    }
}
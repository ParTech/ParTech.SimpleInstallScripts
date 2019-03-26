Set-StrictMode -Version 2.0

Function Install-Sitecore910XP1 (
    [string] [Parameter(Mandatory)] [string] $Prefix, # The Prefix that will be used on SOLR, Website and Database instances.
    [string] $SitecoreAdminPassword = "b", # The Password for the Sitecore Admin User. This will be regenerated if left on the default.
    [string] $SCInstallRoot = "C:\Downloads\9.1.0", # The root folder with the license file and WDP files.
    [string] $ContentDeliverySiteName = "$prefix.cd.local", # The name for the Content Delivery site.
    [string] $ContentManagementSiteName = "$prefix.cm.local", # The name for the Content Management site.
    [string] $ReportingSiteName = "$prefix.rep.local", # The name for the Reporting site.
    [string] $ProcessingSiteName = "$prefix.prc.local", # The name for the Processing site.
    [string] $ReferenceDateSiteName = "$prefix.refdata.local", # The name for the Reference Data site.
    [string] $IdentityServerSiteName = "$Prefix.identityserver.local", # Identity Server site name
    [string] $XP1MarketingAutomationSiteName = "$Prefix.ma.local", # The name for the Marketing Automation site.
    [string] $XP1MarketingAutomationReportingSiteName = "$prefix.mareporting.local", # The name for the Marketing Automation reporting site.
    [string] $XP1ClientCertificateName = "$prefix.xconnect_client", # The name for the XConnect site url.
    [string] $XP1CollectionSitename = "$prefix.collection.local", # The name for the XConnect collection site.
    [string] $XP1CollectionSearchSitename = "$prefix.search.local", # The name for the search site.
    [string] $XP1CortexProcessingSitename = "$prefix.processingEngine.local", # The name for the XConnect processing engine service.
    [string] $XP1CortexReportingSitename = "$prefix.reporting.local", # The name for the XConnect reporting service.
    [string] $XConnectCollectionSearchService = "https://$XP1CollectionSearchSitename", # The URL for the XConnect Search Service.
    [string] $XConnectCollectionService = "https://$XP1CollectionSitename", # The URL for the XConnect Collection Service.
    [string] $XConnectReferenceDataService = "https://$ReferenceDateSiteName", # The URL of the XConnect Reference Data service
    [string] $ProcessingService = "https://$ProcessingSiteName", # The URL of the processing service
    [string] $ReportingService = "https://$ReportingSiteName", # The URL of the reporting service
    [string] $CortexReportingService = "https://$XP1CortexReportingSitename", # The URL of the Cortex Reporting Service
    [string] $MarketingAutomationOperationsService = "https://$XP1MarketingAutomationSiteName", # The URL of the Marketing Automaton Service
    [string] $MarketingAutomationReportingService = "https://$XP1MarketingAutomationReportingSiteName", # The URL of the Marteting Automation Reporting Service
    [string] $MachineLearningServerUrl = "http://admin:Test123!@QA-MMLS-01-DK1.dk.sitecore.net:12800", # The URL of the Machine Learning server
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
    [string] $PasswordRecoveryUrl = "https://$ContentManagementSiteName", # The Identity Server password recovery URL, this should be the URL of the CM Instance
    [string] $SitecoreIdentityAuthority = "https://$IdentityServerSiteName", # The URL of the Identity Authority
    [string] $ClientSecret = "SIF-Default", # The random string key used for establishing connection with IdentityService. This will be regenerated if left on the default.
    [string] $AllowedCorsOrigins = "https://$ContentManagementSiteName", # Pipe-separated list of instances (URIs) that are allowed to login via Sitecore Identity.
    [string] $DownloadBase = $Env:DownloadBase,
    [switch] $DoUninstall, # Uninstalls Sitecore instead of installing
    [switch] $DoInstallPrerequisites # Install SIF, Solr, etc.
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
        Install-AllPrerequisites -SCInstallRoot $SCInstallRoot -DownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort `
                                 -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword
    }

    Install-SitecoreWrapper "910-XP1" $XP1Parameters $SCInstallRoot -DoUninstall:$DoUninstall
}
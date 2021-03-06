# Simple Install Scripts

This module installs Sitecore 9 and its prerequisites on [AppVeyor](https://www.appveyor.com), or any other *standalone* development workstation. This is not suitable for production.

[![Build status](https://ci.appveyor.com/api/projects/status/jqfrchxsv6dpvtx5/branch/master?svg=true)](https://ci.appveyor.com/project/steviemcg/partech-simpleinstallscripts/branch/master)

## Before you start

- SQL Server 2016 (Express is OK) must already be installed, and the sa account enabled
- The Sitecore assets (scwdp file, license.xml) must be uploaded to a central repository, or already be available in the Download directory.

## How to consume this module

    Install-Module ParTech.SimpleInstallScripts
    
    Install-Sitecore92 -Prefix YourSiteName `
                       -SitecoreVersion 920XP0 `
                       -DoInstallPrerequisites `
                       -DownloadBase "https://file-repository/sitecore-assets" `
                       -SqlServer .\SQLEXPRESS `
                       -SqlAdminUser sa `
                       -SqlAdminPassword 12345 `
                       -Packages @("Sitecore.PowerShell.Extensions-5.1.zip") `
                       -DoSitecorePublish `
                       -DoRebuildLinkDatabases `
                       -DoRebuildSearchIndexes `
                       -DoDeployMarketingDefinitions

### DoInstallPrerequisites

* Registers the Sitecore PowerShell Gallery
* Installs the latest supported version of the Sitecore Installation Framework
* Installs the standard prerequisites (delivered by Sitecore's prerequisites.json)
* Installs the correct version of Solr

### Install-Sitecore92

This downloads the Sitecore zip files from your private repository if necessary, and extracts them. Since Sitecore 9.1, sample PowerShell scripts are supplied which pair up with sample json configurations. This module simply takes those samples and converts them to parameters, and executes them as is.

### Customizing the configurations

If you require changes to the sample configurations, then this module probably isn't for you. However, if you think your customization is useful to the others in the community, please suggest it by creating an issue in Github, or even better submit a pull request 🤗

### Installing a .zip or .update package

This module supports installing zip and update packages by copying the `SimpleInstallScriptsProxy.asmx` agent to the Content Management server and executing the appropriate Sitecore method. The agent is removed again when done.

### Storing Sitecore assets online

This module expects the following assets to be available online in the `DownloadBase`:

* WDP packages, for example **Sitecore 9.1.0 rev. 001564 (WDP XM1 packages).zip**
* **license.xml**
* **nssm-2.24.zip** for running Solr (during testing https://nssm.cc was regularly unavailable)
* Modules that you would like to install, such as **Sitecore.PowerShell.Extensions-5.1.zip**

If you prefer not to host the Sitecore assets online, simply ensure they are already in the specified download folder. You can then set a fake `DownloadBase` because it won't be used if the files already exist.

## Authors
[@steviemcgill](https://twitter.com/steviemcgill), [@jermdavis](https://twitter.com/jermdavis), [@TEldblom](https://twitter.com/TEldblom)

## Contributing

Pull Requests are **very** welcome.
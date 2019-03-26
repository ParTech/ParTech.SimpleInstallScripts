Set-StrictMode -Version 2.0

Function Invoke-EnsureAdmin() {
    $elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    if ($elevated -eq $false)
    {
        throw "Please run this script as an administrator"
    }
}

Function Register-SitecoreGallery() {
    Get-PSRepository -Name "SitecoreGallery" -ErrorVariable ev1 -ErrorAction SilentlyContinue | out-null
    If ($null -eq $ev1 -or $ev1.count -eq 0)
    {
      return
    }
    
    Get-PackageProvider -Name Nuget -ForceBootstrap
    Register-PSRepository -Name "SitecoreGallery" `
                          -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2" `
                          -InstallationPolicy Trusted | Out-Null

    Write-Host "PowerShell repository `"SitecoreGallery`" has been registered." -ForegroundColor Green
}

Function Install-SitecoreInstallFramework(
    [string] $Version
) {
    Register-SitecoreGallery

    if (!$Version) {
        [array] $sifModules = Find-Module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery"
        $latestSIFModule = $sifModules[-1]
        $Version = $latestSIFModule.Version.ToString()
    }

    Install-Module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery" -Force -Scope AllUsers -SkipPublisherCheck -AllowClobber -RequiredVersion $Version
}

Function Enable-ModernSecurityProtocols() {
    Write-Host "Enabling modern security protocols..." -foregroundcolor "green"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
}

Function Install-SifPrerequisites(
    [Parameter(Mandatory)] [string] $SCInstallRoot
) {
    Write-Host "================= Installing Prerequisites =================" -foregroundcolor "green"
    $config = Resolve-Path "$SCInstallRoot\Prerequisites.json"
    Install-SitecoreConfiguration $config
}

Function Install-Solr(
    [Parameter(Mandatory)] [string] $SCInstallRoot,
    [Parameter(Mandatory)] [string] $NSSMDownloadBase,
    [Parameter(Mandatory)] [string] $SolrVersion,
    [Parameter(Mandatory)] [string] $SolrHost,
    [Parameter(Mandatory)] [string] $SolrPort
) {
    Write-Host "================= Installing Solr Server =================" -foregroundcolor "green"
    
    Try {
        Push-Location $PSScriptRoot
        $config = Resolve-Path "$PSScriptRoot\SolrServer.json"
        Install-SitecoreConfiguration $config -DownloadFolder $SCInstallRoot -NSSMDownloadBase $NSSMDownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort
    } Finally {
        Pop-Location
    }
}

Function Install-AllPrerequisites(
    [Parameter(Mandatory)] [string] $SCInstallRoot,
    [Parameter(Mandatory)] [string] $DownloadBase,
    [Parameter(Mandatory)] [string] $SolrVersion,
    [Parameter(Mandatory)] [string] $SolrHost,
    [Parameter(Mandatory)] [string] $SolrPort,
    [Parameter(Mandatory)] [string] $SqlServer,
    [Parameter(Mandatory)] [string] $SqlAdminUser,
    [Parameter(Mandatory)] [string] $SqlAdminPassword,
    [string] $SifVersion    
) {
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()

    Invoke-EnsureAdmin
    Install-SitecoreInstallFramework -Version $SifVersion
    Install-SifPrerequisites -SCInstallRoot $SCInstallRoot
    Install-Solr -SCInstallRoot $SCInstallRoot -NSSMDownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort
    Enable-ContainedDatabaseAuthentication -SqlServer $SqlServer -SqlAdminUser $SqlAdminUser -SqlAdminPassword $SqlAdminPassword

    Write-Host "Successfully setup environment (time: $($elapsed.Elapsed.ToString()))"
}

Function Invoke-DownloadPackages (
    [Parameter(Mandatory)] [string] $DownloadBase,
    [Parameter(Mandatory)] [string] $SCInstallRoot,
    [Parameter(Mandatory)] [string] $PackagesName,
    [Parameter(Mandatory)] [string] $ConfigFilesName
) {
    Write-Output "Downloading packages..."
    New-Item -ItemType Directory -Force -Path $SCInstallRoot

    $PackagesUrl = "$DownloadBase/$PackagesName"
    $PackagesZip = "$SCInstallRoot\$PackagesName"
    Invoke-DownloadIfNeeded $PackagesUrl $PackagesZip
    Expand-Archive $PackagesZip -DestinationPath $SCInstallRoot -Force
    
    $ConfigFilesZip = "$SCInstallRoot\$ConfigFilesName"
    Expand-Archive $ConfigFilesZip -DestinationPath $SCInstallRoot -Force

    Invoke-DownloadIfNeeded "$DownloadBase/license.xml" "$SCInstallRoot\license.xml"
}

Function Enable-ContainedDatabaseAuthentication
(
    [string] $SqlServer = ".", # The DNS name or IP of the SQL Instance.
    [string] $SqlAdminUser = "sa", # A SQL user with sysadmin privileges.
    [string] $SqlAdminPassword = "12345" # The password for $SQLAdminUser.
)
{
    sqlcmd -S $SqlServer -U $SqlAdminUser -P $SqlAdminPassword -h-1 -Q "sp_configure 'contained database authentication', 1; RECONFIGURE;"
}

Function Invoke-DownloadIfNeeded
(
    [Parameter(Mandatory)][string]$source,
    [Parameter(Mandatory)][string]$target
)
{
    Write-Host "Invoke-DownloadIfNeeded to $target"
    if (Test-Path $target) {
        Write-Debug "Already exists"
        return
    }
    
    $client = (New-Object System.Net.WebClient)
    $client.DownloadFile($source, $target)
}

Function Install-SitecoreWrapper (
    [Parameter(Mandatory)] [string] $Name,    
    [Parameter(Mandatory)] [Hashtable] $Params,
    [Parameter(Mandatory)] [string] $SCInstallRoot,
    [switch] $DoUninstall # Uninstalls Sitecore instead of installing    
) 
{
    Try {
        Push-Location $SCInstallRoot

        If ($DoUninstall) {
            Uninstall-SitecoreConfiguration @params *>&1 | Tee-Object "$($name)-Uninstall.log"
        } else {
            Install-SitecoreConfiguration @params *>&1 | Tee-Object "$($name).log"
        }
    } Finally {
        Pop-Location
    }
}
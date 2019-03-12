Set-StrictMode -Version 2.0

Function Invoke-EnsureAdmin() {
    $elevated = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
    if ($elevated -eq $false)
    {
        throw "Please run this script as an administrator"
    }
}

Function Register-SitecoreGallery() {
    Get-PackageProvider -Name Nuget -ForceBootstrap
    Register-PSRepository -Name "SitecoreGallery" `
                          -SourceLocation "https://sitecore.myget.org/F/sc-powershell/api/v2" `
                          -InstallationPolicy Trusted | Out-Null

    Write-Host ("PowerShell repository `"SitecoreGallery`" has been registered.") -ForegroundColor Green
}

Function Install-SitecoreInstallationFramework(
    [Parameter(Mandatory=$false)] [string] $Version
) {
    if ($null -eq $Version) {
        [array] $sifModules = Find-Module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery"
        $latestSIFModule = $sifModules[-1]
        $Version = $latestSIFModule.Version.ToString()
    }

    Install-Module -Name "SitecoreInstallFramework" -Repository "SitecoreGallery" -Force -Scope AllUsers -SkipPublisherCheck -AllowClobber -RequiredVersion $Version | Out-Null
}

Function Enable-ModernSecurityProtocols() {
    Write-Host "Enabling modern security protocols..." -foregroundcolor "green"
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
}

Function Install-SifPrerequisites(
    [Parameter(Mandatory=$true)] [string] $SCInstallRoot
) {
    Write-Host "================= Installing Prerequisites =================" -foregroundcolor "green"
    $config = Resolve-Path "$SCInstallRoot\Prerequisites.json"
    Install-SitecoreConfiguration $config
}

Function Install-Solr(
    [Parameter(Mandatory=$true)] [string] $SCInstallRoot,
    [Parameter(Mandatory=$true)] [string] $NSSMDownloadBase,
    [Parameter(Mandatory=$true)] [string] $SolrVersion,
    [Parameter(Mandatory=$true)] [string] $SolrHost,
    [Parameter(Mandatory=$true)] [string] $SolrPort
) {
    Write-Host "================= Installing Solr Server =================" -foregroundcolor "green"
    
    $config = Resolve-Path "$PSScriptRoot\SolrServer.json"
    Install-SitecoreConfiguration $config -DownloadFolder $SCInstallRoot -NSSMDownloadBase $NSSMDownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort
}

Function Install-AllPrerequisites(
    [Parameter(Mandatory=$true)] [string] $SCInstallRoot,
    [Parameter(Mandatory=$true)] [string] $DownloadBase,
    [Parameter(Mandatory=$true)] [string] $SolrVersion,
    [Parameter(Mandatory=$true)] [string] $SolrHost,
    [Parameter(Mandatory=$true)] [string] $SolrPort,
    [Parameter(Mandatory=$false)][string] $SifVersion    
) {
    $elapsed = [System.Diagnostics.Stopwatch]::StartNew()

    Invoke-EnsureAdmin
    Register-SitecoreGallery
    Install-SitecoreInstallationFramework -Version $SifVersion
    Install-SifPrerequisites -SCInstallRoot $SCInstallRoot
    Install-Solr -SCInstallRoot $SCInstallRoot -NSSMDownloadBase $DownloadBase -SolrVersion $SolrVersion -SolrHost $SolrHost -SolrPort $SolrPort

    Write-Host "Successfully setup environment (time: $($elapsed.Elapsed.ToString()))"
}

Function Invoke-DownloadPackages (
    [Parameter(Mandatory=$true)] [string] $DownloadBase,
    [Parameter(Mandatory=$true)] [string] $SCInstallRoot,
    [Parameter(Mandatory=$true)] [string] $PackagesName,
    [Parameter(Mandatory=$true)] [string] $ConfigFilesName
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
    [Parameter(Mandatory=$false)] [string]   $SqlServer = ".", # The DNS name or IP of the SQL Instance.
    [Parameter(Mandatory=$false)] [string]   $SqlAdminUser = "sa", # A SQL user with sysadmin privileges.
    [Parameter(Mandatory=$false)] [string]   $SqlAdminPassword = "12345" # The password for $SQLAdminUser.
)
{
    sqlcmd -S $SqlServer -U $SqlAdminUser -P $SqlAdminPassword -h-1 -Q "sp_configure 'contained database authentication', 1; RECONFIGURE;"
}

Function Invoke-DownloadIfNeeded
(
    [Parameter(Mandatory=$true)][string]$source,
    [Parameter(Mandatory=$true)][string]$target
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
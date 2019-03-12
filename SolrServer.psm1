#
# If necessary, download a file and unzip it to the specified location
#
function downloadAndUnzipIfRequired
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    Param(
        [string]$toolName,
        [string]$toolFolder,
        [string]$toolZip,
        [string]$toolSourceFile,
        [string]$installRoot
    )

    if(!(Test-Path -Path $toolFolder))
    {
        if(!(Test-Path -Path $toolZip))
        {
            Write-Information -Message $toolSourceFile -Tag "Downloading $toolName"
            if($pscmdlet.ShouldProcess("$toolSourceFile", "Download source file"))
            {
                Start-BitsTransfer -Source $toolSourceFile -Destination $toolZip
            }
        }
        else
        {
            Write-Information -Message $toolZip -Tag "$toolName already downloaded"
        }

        Write-Information -Message $targetFile -Tag "Extracting $toolName"
        if($pscmdlet.ShouldProcess("$toolZip", "Extract archive file"))
        {
            Expand-Archive $toolZip -DestinationPath $installRoot -Force
        }
    }
    else
    {
        Write-Information -Message $toolFolder -Tag "$toolName folder already exists - skipping"
    }
}

#
# Download and unzip the appropriate version of NSSM if it's not already in place
#
function Invoke-EnsureNSSMTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$downloadFolder,

        [parameter(Mandatory=$true)]
        [string]$nssmVersion,

        [parameter(Mandatory=$true)]
        [string]$nssmSourcePackage,
        
        [parameter(Mandatory=$true)]
        [string]$installFolder
    )

    PROCESS
    {
        $targetFile = "$installFolder\nssm-$nssmVersion"
        $nssmZip = "$downloadFolder\nssm-$nssmVersion.zip"

        Write-Information -Message "$nssmVersion" -Tag "Ensuring NSSM installed"

        downloadAndUnzipIfRequired "NSSM" $targetFile $nssmZip $nssmSourcePackage $installFolder
    }
}

#
# Download and unzip the appropriate version of Solr if it's not already in place
#
function Invoke-EnsureSolrTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$downloadFolder,

        [parameter(Mandatory=$true)]
        [string]$solrVersion,

        [parameter(Mandatory=$true)]
        [string]$solrSourcePackage,
        
        [parameter(Mandatory=$true)]
        [string]$installFolder
    )

    PROCESS
    {
        $targetFile = "$installFolder\solr-$solrVersion"
        $solrZip = "$downloadFolder\solr-$solrVersion.zip"

        Write-Information -Message "$solrVersion" -Tag "Ensuring Solr installed"

        downloadAndUnzipIfRequired "Solr" $targetFile $solrZip $solrSourcePackage $installFolder
    }
}

#
# Process the configuration changes necessary for Solr to run
#
function Invoke-ConfigureSolrTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)]
        [string]$solrHost,
        [parameter(Mandatory=$true)]
        [string]$solrRoot,
        [parameter(Mandatory=$true)]
        [string]$certificateStore
    )

    PROCESS
    {
        Write-Information -Message "HTTPS" -Tag "Configuring Solr for HTTPS access"
    
        $solrConfig = "$solrRoot\bin\solr.in.cmd"
        if(!(Test-Path -Path "$solrConfig.old"))
        {
            if($pscmdlet.ShouldProcess("$solrConfig", "Rewriting Solr config file for HTTPS"))
            {
                $cfg = Get-Content $solrConfig
                Rename-Item $solrConfig "$solrRoot\bin\solr.in.cmd.old"
                $newCfg = $cfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_KEY_STORE=$certificateStore" }
                $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_KEY_STORE_PASSWORD=secret", "set SOLR_SSL_KEY_STORE_PASSWORD=secret" }
                $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE=etc/solr-ssl.keystore.jks", "set SOLR_SSL_TRUST_STORE=$certificateStore" }
                $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_SSL_TRUST_STORE_PASSWORD=secret", "set SOLR_SSL_TRUST_STORE_PASSWORD=secret" }
                $newCfg = $newCfg | ForEach-Object { $_ -replace "REM set SOLR_HOST=192.168.1.1", "set SOLR_HOST=$solrHost" }
                $newCfg | Set-Content $solrConfig
            }

            Write-Information -Message "$solrConfig" -Tag "Solr config updated for HTTPS access"
        }
        else
        {
            Write-Information -Message "$solrConfig" -Tag "Solr config already updated for HTTPS access - skipping"
        }
    }
}

#
# Ensure that a service exists to run the specified version of Solr
#
function Invoke-EnsureSolrServiceTask
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [parameter(Mandatory=$true)] [string]$solrName,
        [parameter(Mandatory=$true)] [string]$installFolder,
        [parameter(Mandatory=$true)] [string]$nssmVersion,
        [parameter(Mandatory=$true)] [string]$solrRoot,
        [parameter(Mandatory=$true)] [string]$solrPort
    )

    PROCESS
    {
        $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
        if(!($svc))
        {
            Write-Information -Message "$solrName" -Tag "Installing Solr service"

            if($pscmdlet.ShouldProcess("$solrName", "Install Solr service using NSSM"))
            {
                &"$installFolder\nssm-$nssmVersion\win64\nssm.exe" install "$solrName" "$solrRoot\bin\solr.cmd" "-f" "-p $solrPort"
            }

            $svc = Get-Service "$solrName" -ErrorAction SilentlyContinue
        }
        else
        {
            Write-Information -Message "$solrName" -Tag "Solr service already installed - skipping"
        }

        if($svc.Status -ne "Running")
        {
            Write-Information -Message "$solrName" -Tag "Starting Solr service"

            if($pscmdlet.ShouldProcess("$solrName", "Starting Solr service"))
            {
                Start-Service "$solrName"
            }
        }
        else
        {
            Write-Information -Message "$solrName" -Tag "Solr service already started - skipping"
        }
    }
}

Register-SitecoreInstallExtension -Command Invoke-EnsureNSSMTask -As EnsureNssm -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureSolrTask -As EnsureSolr -Type Task
Register-SitecoreInstallExtension -Command Invoke-ConfigureSolrTask -As ConfigureSolr -Type Task
Register-SitecoreInstallExtension -Command Invoke-EnsureSolrServiceTask -As EnsureSolrService -Type Task
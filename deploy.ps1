if ($env:APPVEYOR -eq "True" -and $env:APPVEYOR_REPO_BRANCH -ne "master") { return }
#if ($env:APPVEYOR_JOB_NUMBER -ne 5) { return }

Write-Host $env:APPVEYOR_JOB_NAME
return
Remove-Item -Recurse ParTech.SimpleInstallScripts -ErrorAction SilentlyContinue
New-Item ParTech.SimpleInstallScripts -ItemType "directory"

Copy-Item -Path *.psd1 -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.psm1 -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.json -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.asmx -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.md -Destination ParTech.SimpleInstallScripts
Copy-Item -Path LICENSE -Destination ParTech.SimpleInstallScripts

Update-ModuleManifest -Path .\ParTech.SimpleInstallScripts\ParTech.SimpleInstallScripts.psd1 -ModuleVersion $Env:APPVEYOR_BUILD_VERSION

Publish-Module -Path .\ParTech.SimpleInstallScripts -NugetAPIKey $Env:PSGalleryApiKey -Verbose
Remove-Item -Recurse ParTech.SimpleInstallScripts -ErrorAction SilentlyContinue
New-Item ParTech.SimpleInstallScripts -ItemType "directory"

Copy-Item -Path *.psd1 -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.psm1 -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.json -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.asmx -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.md -Destination ParTech.SimpleInstallScripts
Copy-Item -Path *.dll -Destination ParTech.SimpleInstallScripts
Copy-Item -Path LICENSE -Destination ParTech.SimpleInstallScripts
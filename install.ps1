$TARGETDIR="c:\windows\openedr"
$DOWNLOADDIR="$env:TEMP\openedr"
$OPENEDRFILENAME='openedr.msi'
$NXLOGFILENAME="nxlog-ce.msi"
$SYSMONFILENAME="sysmon.zip"
$OSQUERYFILENAME="osquery.msi"

$NET46FILENAME="NDP46-KB3045557-x86-x64-AllOS-ENU.exe"
$openEdrInstallerURL='https://github.com/jymcheong/openedrClient/blob/master/OpenEDR.msi?raw=true'
$nxlogInstallerURL='https://github.com/jymcheong/openedrClient/blob/master/nxlog-ce-2.10.2150.msi?raw=true'
$sysmonInstallerURL='https://github.com/jymcheong/openedrClient/blob/master/SysmonV11.10-78E640D1C0002A97E9D2D9AB528D7BBA3A350E978D7F619F78859C3D68A85F25.zip?raw=true'
$net46InstallerURL='https://download.microsoft.com/download/C/3/A/C3A5200B-D33C-47E9-9D70-2F7C65DAAD94/NDP46-KB3045557-x86-x64-AllOS-ENU.exe'
$osqueryInstallerURL='https://pkg.osquery.io/windows/osquery-4.1.2.msi'

# System.Net.WebClient will fail to download if remote site has TLS1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$OPENEDR_SHA256_HASH='0CD1BABE8215E07B526CF370C60388DD91DC9BDDEB0932683F1A10C352AFF92E'
$NXLOG_SHA256_HASH='DCDDD2297C4FAD9FDEAA36276D58317A7EA1EFCD6851F89215A7231CDA6BA266'
$SYSMON_SHA256_HASH='78E640D1C0002A97E9D2D9AB528D7BBA3A350E978D7F619F78859C3D68A85F25'
$NET46_SHA256_HASH='B21D33135E67E3486B154B11F7961D8E1CFD7A603267FB60FEBB4A6FEAB5CF87'
$OSQUERY_SHA256_HASH='376398B110DAD560167B0915598A50551B902AD46BB420BAD297FAA6D56659EE'

# Create a location to download the files to
New-Item -ItemType Directory -Force -Path $DOWNLOADDIR | Out-Null

$wc = [System.Net.WebClient]::new()
Write-Host 'Downloading OpenEDR...'
$wc.DownloadFile($openEdrInstallerURL, "$DOWNLOADDIR\$OPENEDRFILENAME")
$FileHash = Get-FileHash -Path "$DOWNLOADDIR\$OPENEDRFILENAME"
if($FileHash.Hash -ne $OPENEDR_SHA256_HASH) { Write-Host 'Checksum failed!'; exit } 

Write-Host 'Downloading Nxlog-CE...'
$wc.DownloadFile($nxlogInstallerURL, "$DOWNLOADDIR\$NXLOGFILENAME")
$FileHash = Get-FileHash -Path "$DOWNLOADDIR\$NXLOGFILENAME"
if($FileHash.Hash -ne $NXLOG_SHA256_HASH) { Write-Host 'Checksum failed!'; exit } 

Write-Host 'Downloading Sysmon...'
$wc.DownloadFile($sysmonInstallerURL, "$DOWNLOADDIR\$SYSMONFILENAME")
$FileHash = Get-FileHash -Path "$DOWNLOADDIR\$SYSMONFILENAME"
if($FileHash.Hash -ne $SYSMON_SHA256_HASH) { Write-Host 'Checksum failed!'; exit } 
Write-Host 'Extracting Sysmon...'
Get-ChildItem "$DOWNLOADDIR\$SYSMONFILENAME" | Expand-Archive -Force -DestinationPath $DOWNLOADDIR

Write-Host 'Downloading OSQuery...'
$wc.DownloadFile($osqueryInstallerURL, "$DOWNLOADDIR\$OSQUERYFILENAME")
$FileHash = Get-FileHash -Path "$DOWNLOADDIR\$OSQUERYFILENAME"
if($FileHash.Hash -ne $OSQUERY_SHA256_HASH) { Write-Host 'Checksum failed!'; exit } 

if(Test-Path $TARGETDIR) {
    IEX $wc.DownloadString('https://raw.githubusercontent.com/jymcheong/openedrClient/master/uninstall.ps1')
}

Set-Location $DOWNLOADDIR
Write-Output "Installing OpenEDR..."
Start-Process -FilePath "$env:comspec" -Verb runAs -Wait -ArgumentList "/c msiexec /i $OPENEDRFILENAME TARGETDIR=$TARGETDIR /qb /L*V OPENEDRinstall.log"
Write-Output "Installing NXLOG-CE..."
Start-Process -FilePath "$env:comspec" -Verb runAs -Wait -ArgumentList "/c msiexec /i $NXLOGFILENAME INSTALLDIR=$TARGETDIR\nxlog /qb /L*V NXLOGinstall.log"
Write-Output "Installing Sysmon..."
Start-Process -FilePath "$env:comspec" -Verb runAs -Wait -ArgumentList "/c sysmon.exe -accepteula -i $TARGETDIR\installers\smconfig.xml"
Write-Output "Installing OSQuery...."
Start-Process -FilePath "$env:comspec" -Verb runAs -Wait -ArgumentList "/c msiexec /i $OSQUERYFILENAME /qb /L*V OSQUERYinstall.log"

if($SFTPCONFURL) {
    $wc.DownloadFile($FTPCONFURL, "$TARGETDIR\sftpconf.zip")    
}

Set-Location "$TARGETDIR\installers"
((Get-Content -path DFPM.xml -Raw) -replace 'TARGETDIR',$TARGETDIR) | Set-Content -Path DFPM.xml
((Get-Content -path UploadSchtasks.xml -Raw) -replace 'TARGETDIR',$TARGETDIR) | Set-Content -Path UploadSchtasks.xml
((Get-Content -path uatSchedTask.xml -Raw) -replace 'UATPATH',"$TARGETDIR\uat.exe") | Set-Content -Path uatSchedTask.xml
((Get-Content -path nxlog.conf -Raw) -replace 'TARGETDIR',"$TARGETDIR\") | Set-Content -Path "$TARGETDIR\nxlog\conf\nxlog.conf"
((Get-Content -path OSQBSchtask.xml -Raw) -replace 'TARGETDIR',$TARGETDIR) | Set-Content -Path OSQBSchtask.xml

schtasks /Create /TN "UAT" /XML "uatSchedTask.xml"
schtasks /Create /TN "UATupload" /XML "UploadSchtasks.xml"
schtasks /Create /TN "DFPM" /XML "DFPM.xml"
schtasks /Create /TN "OSQB" /XML "OSQBSchtask.xml"

#Turn on Powershell ScriptBlockLogging
New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -Force

# Check .NET 4.6
$net46 = $false
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -recurse |
Get-ItemProperty -name Version,Release -EA 0 | ForEach-Object { if($_.Release -ge 393295) { $net46 = $true}}
if($net46 -eq $false) {
    Write-Output "Downloading .NET 4.6 Standalone Installer..."
    $wc.DownloadFile($net46InstallerURL, "$DOWNLOADDIR\$NET46FILENAME")
    $FileHash = Get-FileHash -Path "$DOWNLOADDIR\$NET46FILENAME"
    if($FileHash.Hash -ne $NET46_SHA256_HASH) { Write-Host 'Checksum failed!'; exit } 
    Write-Output "Installing .NET 4.6..."
    Start-Process -FilePath "$env:comspec" -Verb runAs -Wait -ArgumentList "/c $DOWNLOADDIR\$NET46FILENAME"
}

# Start agents
schtasks /Run /TN "UATupload"
schtasks /Run /TN "DFPM"
schtasks /Run /TN "OSQB"

# Start log rotation
$scpath = $env:WinDir + "\system32\sc.exe"
Start-Process -FilePath $scpath -Verb runAs -Wait -ArgumentList "start nxlog"
Write-Output "Started Nxlog service!"

# Notify user
Add-Type -AssemblyName System.Windows.Forms
$global:balmsg = New-Object System.Windows.Forms.NotifyIcon
$path = (Get-Process -id $pid).Path
$balmsg.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)
$balmsg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
$balmsg.BalloonTipText = 'OpenEDR installation completed! System will reboot in 5 mins!'
$balmsg.BalloonTipTitle = "Attention $Env:USERNAME"
$balmsg.Visible = $true
$balmsg.ShowBalloonTip(20000)

shutdown /r /t 300

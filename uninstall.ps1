Write-Host "Searching for existing Sysmon...."
If (Get-WmiObject -Class Win32_Service -Filter "Name='Sysmon'") {
    Write-Host "Uninstalling Sysmon..."
    Start-Process -FilePath "Sysmon.exe" -Wait -ArgumentList "-u"
}
If (Get-WmiObject -Class Win32_Service -Filter "Name='Sysmon64'") {
    Write-Host "Uninstalling Sysmon64..."
    Start-Process -FilePath "Sysmon64.exe" -Wait -ArgumentList "-u"
}

Write-Host "Searching for existing Nxlog-CE..."
$app = Get-WmiObject Win32_Product -filter "Name='NXLog-CE'"
if($app) { 
    Write-Host "Uninstalling Nxlog-CE..."
    $app.uninstall() 
}

echo "Searching for existing OSQuery...."
$application = Get-WmiObject Win32_Product -filter "Name='osquery'"
if($application) { 
    echo "Uninstalling existing OSQuery..."
    $application.uninstall()
}

Write-Host "Searching for existing OpenEDR (aka DataFusion)..."
$app = Get-WmiObject Win32_Product -filter "Name='DataFusion'"
if($app) { 
    Write-Host "Uninstalling DataFusion..."
    $app.uninstall() 
}

Stop-Process -erroraction 'silentlycontinue' -Force -Name "uat" | Out-Null
Stop-Process -erroraction 'silentlycontinue' -Force -Name "dpfm" | Out-Null
Stop-Process -erroraction 'silentlycontinue' -Force -Name "upload" | Out-Null
Stop-Process -erroraction 'silentlycontinue' -Force -Name "osquerybroker" | Out-Null

schtasks /Delete /TN "UAT" /F 
schtasks /Delete /TN "UATupload" /F  
schtasks /Delete /TN "DFPM" /F  
schtasks /Delete /TN "OSQB" /F
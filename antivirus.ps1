 $antivirusProducts = Get-WmiObject -Namespace "root\SecurityCenter2" -Class AntiVirusProduct

$metrics = @()
foreach ($av in $antivirusProducts) {
    $status = if ($av.productState -match "^3") { 1 } else { 0 }  # If productState starts with "3", it's active
    $metrics += "windows_antivirus_status{name=`"$($av.displayName)`"} $status"
}

if ($metrics.Count -gt 0) {
    $metrics -join "`n" | Out-File -Encoding ASCII  "C:\Program Files\windows_exporter\textfile_inputs\antivirus_status.prom "
} else {
    "windows_antivirus_status{name=`"None`"} 0" | Out-File -Encoding ASCII "C:\Program Files\windows_exporter\textfile_inputs\antivirus_status.prom"
} 

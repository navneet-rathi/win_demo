 # Define log file for debugging
 $logFile = "C:\metrics\password_age_debug.log"
 $passwordMetricsFile = "C:\Program Files\windows_exporter\textfile_inputs\password_age.prom"
 
 # Start logging
 "=== Running password_age.ps1 ===" | Out-File -Append -Encoding UTF8 $logFile
 "Timestamp: $(Get-Date)" | Out-File -Append -Encoding UTF8 $logFile
 
 # Get all local users reliably
 $users = net user | Select-String -NotMatch "^(User accounts|-----|The command completed successfully)" | ForEach-Object { $_.ToString().Trim() }| Where-Object { $_ -ne "" }
 
 # Flatten multi-column output into a single list
 $users = $users -join " " -split "\s+"
 
 # Log detected users
 "Detected Users: { $($users -join ', ') }" | Out-File -Append -Encoding UTF8 $logFile
 
 $metrics = @()
 
 foreach ($user in $users) {
     "Processing user: {${user}}" | Out-File -Append -Encoding UTF8 $logFile
     
     # Get full user info
     try {
         $userInfo = net user "$user" 2>&1  # Capture errors
         if (-not $userInfo) {
             "Error: Failed to retrieve user info for {${user}}" | Out-File -Append -Encoding UTF8 $logFile
             continue
         }
     } catch {
         "Exception: $_" | Out-File -Append -Encoding UTF8 $logFile
         continue
     }
 
     # Find the "Password last set" line
     $passwordLastSetLine = $userInfo | Select-String "Password last set"
     
     if ($passwordLastSetLine) {
         "Raw password last set output for {${user}}: {${passwordLastSetLine}}" | Out-File -Append -Encoding UTF8 $logFile
 
         # Extract the date part from the output
         $lastSetDateStr = ($passwordLastSetLine -split "\s{2,}" | Select-Object -Last 1).Trim()
         "Extracted Date String for {${user}}: {${lastSetDateStr}}" | Out-File -Append -Encoding UTF8 $logFile
 
         # Convert to datetime, handle cases where password is never set
         try {
             if ($lastSetDateStr -match "Never") {
                 $lastSetDate = $null  # Handle "Never" case
             } else {
                 $lastSetDate = [datetime]::ParseExact($lastSetDateStr, "M/d/yyyy h:mm:ss tt", $null)
             }
         } catch {
             "Date parsing failed for {${user}}. Error: $_" | Out-File -Append -Encoding UTF8 $logFile
             $lastSetDate = $null
         }
 
         if ($lastSetDate) {
             # Calculate password age in seconds
             $passwordAge = (New-TimeSpan -Start $lastSetDate -End (Get-Date)).TotalSeconds
         } else {
             $passwordAge = 0  # If password is never set, set it as 0
         }
 
         "Final Password Age for ${user}: ${passwordAge} seconds" | Out-File -Append -Encoding UTF8 $logFile
         $metrics += "windows_user_password_age{name=`"${user}`"} ${passwordAge}"
     } else {
         "No 'Password last set' found for `"${user}`". Skipping." | Out-File -Append -Encoding UTF8 $logFile
     }
 }
 
 # Ensure Prometheus gets data
 if ($metrics.Count -gt 0) {
     $metrics -join "`n" | Out-File -Encoding ASCII $passwordMetricsFile
     "Metrics successfully written to {${passwordMetricsFile}}" | Out-File -Append -Encoding UTF8 $logFile
 } else {
     "windows_user_password_age{name= `"None`" } 0" | Out-File -Encoding ASCII $passwordMetricsFile
     "No valid password ages found. Writing default metric." | Out-File -Append -Encoding UTF8 $logFile
 }
 
 "=== Script Execution Complete ===`n" | Out-File -Append -Encoding UTF8 $logFile
  
 
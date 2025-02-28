 ### Tested with powershell 7 as power shell 5.1 does not support skip cert check 
 $FolderPath = "C:\Users\nrathi\Desktop\navneet"
 $LogFile = "C:\temp\file_check.log"
 $Interval = 60  # Time in seconds before checking again
 
 # Red Hat Ansible Automation Platform (AAP) API Details
 $ApiUrl = "http://192.168.1.14:5000/endpoint"
 
 while ($true) {
     Write-Host "🔄 Checking for new files in folder..."
 
     $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
     $Files = Get-ChildItem -Path $FolderPath -File
 
     if ($Files.Count -gt 0) {
         $Message = "$Timestamp ✅ New file(s) detected in: $FolderPath"
         Write-Host $Message
         Add-Content -Path $LogFile -Value $Message       
         Write-Host "🚀 Triggering Ansible AAP Job..."
 $headers = @{
 
     "Content-Type"  = "application/json"
 }
 
  $body = @{
     "message" = "file present"
         } | ConvertTo-Json -Depth 10 
 
         try {
             $Response = Invoke-RestMethod -Uri $ApiUrl -Method Post -Headers $headers  -Body $body
             Write-Host "✅ Ansible AAP Job Triggered Successfully!"
             Add-Content -Path $LogFile -Value "$Timestamp ✅ Ansible AAP Job Triggered Successfully!"
             #Move-Item -Path "C:\Users\nrathi\Desktop\navneet\*" -Destination "C:\Users\nrathi\Desktop\nrathi\" 
             Start-Sleep -Seconds $Interval 
 
         } catch {
             Write-Host "❌ Failed to trigger Ansible AAP Job!"
             Add-Content -Path $LogFile -Value "$Timestamp ❌ Failed to trigger Ansible AAP Job!"
         }
 
         # Exit script after Ansible job runs (optional)
         #exit
     } else {
         $Message = "$Timestamp ❌ No new files in: $FolderPath"
         Write-Host $Message
         Add-Content -Path $LogFile -Value $Message
     }
 
      # Wait 1 second before checking again
      Start-Sleep -Seconds 2
 } 
 
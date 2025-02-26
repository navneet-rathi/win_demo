$FolderPath = "C:\Users\nrathi\Desktop\navneet"
$LogFile = "C:\temp\file_check.log"
$Interval = 1  # Time in seconds before checking again

# Red Hat Ansible Automation Platform (AAP) API Details
$AAP_URL = "https://192.168.1.14/api/controller/v2/job_templates/27/launch/"
$AAP_USERNAME = "admin"
$AAP_PASSWORD = "primod123"

# Ignore SSL certificate validation
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

while ($true) {
    Write-Host "🔄 Checking for new files in folder..."

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Files = Get-ChildItem -Path $FolderPath -File

    if ($Files.Count -gt 0) {
        $Message = "$Timestamp ✅ New file(s) detected in: $FolderPath"
        Write-Host $Message
        Add-Content -Path $LogFile -Value $Message

        # Invoke Ansible AAP Job
        Write-Host "🚀 Triggering Ansible AAP Job..."

        $Headers = @{
            "Content-Type" = "application/json"
        }
        $Body = @{} | ConvertTo-Json
        $Creds = "$AAP_USERNAME`:$AAP_PASSWORD"
        $EncodedCreds = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($Creds))
        $AuthHeader = @{ Authorization = "Basic $EncodedCreds" }

        try {
            $Response = Invoke-RestMethod -Uri $AAP_URL -Method Post -Headers $Headers -Body $Body -Headers $AuthHeader -SkipCertificateCheck
            Write-Host "✅ Ansible AAP Job Triggered Successfully!"
            Add-Content -Path $LogFile -Value "$Timestamp ✅ Ansible AAP Job Triggered Successfully!"
        } catch {
            Write-Host "❌ Failed to trigger Ansible AAP Job!"
            Add-Content -Path $LogFile -Value "$Timestamp ❌ Failed to trigger Ansible AAP Job!"
        }

        # Exit script after Ansible job runs (optional)
        exit
    } else {
        $Message = "$Timestamp ❌ No new files in: $FolderPath"
        Write-Host $Message
        Add-Content -Path $LogFile -Value $Message
    }

    Start-Sleep -Seconds $Interval  # Wait 1 second before checking again
}
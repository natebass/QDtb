# Define your payload as a PowerShell object
$payload = @{
    status = "exampleValue"
    nested     = @{
        status = "resolved_model"
        reason = 0
    }
}

# Convert to JSON
$json = $payload | ConvertTo-Json -Depth 5

# Send POST request
$response = Invoke-RestMethod -Uri "https://app-lbe-web.vercel.app/auth" `
    -Method Post `
    -Body $json `
    -ContentType "application/json"

# Inspect response
$response
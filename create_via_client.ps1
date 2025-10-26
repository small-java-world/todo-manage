Set-Location D:\todo-manage\todo-api-client-sample

$Env:API_URL = 'http://localhost:8000'

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Create requirement via client
Write-Host "Creating requirement via client..."
$ReqOutput = python client.py req-create --title "Win要件" --desc "PowerShell"
Write-Host $ReqOutput

# Extract requirement ID from the first requirement we created
$RequirementId = Get-Content ..\logs\requirement_id.txt
Write-Host "`nUsing requirement ID: $RequirementId"

# Create task via client
Write-Host "`nCreating task via client..."
$TaskOutput = python client.py task-create --title "Win子タスク" --parent $RequirementId --type task
Write-Host $TaskOutput

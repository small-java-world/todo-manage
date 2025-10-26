Set-Location D:\todo-manage\todo-api-client-sample

$Env:API_URL = 'http://localhost:8000'

# Activate virtual environment
.\.venv\Scripts\Activate.ps1

# Run health check
Write-Host "Running health check..."
python client.py health | Tee-Object ..\logs\client-health.log

# Run list command
Write-Host "`nRunning list command..."
python client.py list --status in_progress --limit 5 | Tee-Object ..\logs\client-list.log

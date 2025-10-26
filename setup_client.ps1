Set-Location D:\todo-manage\todo-api-client-sample

$Env:API_URL = 'http://localhost:8000'
Write-Host "Setting API_URL to: $Env:API_URL"

# Create virtual environment
python -m venv .venv
Write-Host "Virtual environment created"

# Activate and install requirements
.\.venv\Scripts\Activate.ps1
Write-Host "Virtual environment activated"

pip install -r requirements.txt
Write-Host "Requirements installed"

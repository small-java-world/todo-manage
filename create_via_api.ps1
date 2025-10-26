$Env:API_URL = 'http://localhost:8000'

# Create a new requirement via API
Write-Host "Creating requirement 'Win要件' via API..."
$Req = Invoke-RestMethod `
  -Uri "$Env:API_URL/tasks/requirements/" `
  -Method Post `
  -ContentType 'application/json' `
  -Body (@{ title = 'Win要件'; description = 'PowerShell' } | ConvertTo-Json)

Write-Host "Created requirement with ID: $($Req.id), hierarchical_id: $($Req.hierarchical_id)"

# Get the first requirement ID
$RequirementId = Get-Content D:\todo-manage\logs\requirement_id.txt
Write-Host "`nUsing original requirement ID: $RequirementId for task parent"

# Create a task under the first requirement
Write-Host "`nCreating task 'Win子タスク' via API..."
$Task = Invoke-RestMethod `
  -Uri "$Env:API_URL/tasks/" `
  -Method Post `
  -ContentType 'application/json' `
  -Body (@{ title = 'Win子タスク'; parent_id = [int]$RequirementId; type = 'task' } | ConvertTo-Json)

Write-Host "Created task with ID: $($Task.id), hierarchical_id: $($Task.hierarchical_id)"

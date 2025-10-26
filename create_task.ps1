$RequirementId = Get-Content D:\todo-manage\logs\requirement_id.txt

$Task = Invoke-RestMethod `
  -Uri http://localhost:8000/tasks/ `
  -Method Post `
  -ContentType 'application/json' `
  -Body (@{ title = 'Windowsタスク'; type = 'task'; parent_id = [int]$RequirementId } | ConvertTo-Json)

Write-Host "Task created with ID: $($Task.id)"
$Task | ConvertTo-Json

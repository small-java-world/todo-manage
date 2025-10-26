$Requirement = Invoke-RestMethod `
  -Uri http://localhost:8000/tasks/requirements/ `
  -Method Post `
  -ContentType 'application/json' `
  -Body (@{ title = 'Windows検証用要件'; description = 'Hyper-V backend' } | ConvertTo-Json)

$Requirement.id | Tee-Object -FilePath D:\todo-manage\logs\requirement_id.txt
Write-Host "Requirement created with ID: $($Requirement.id)"
$Requirement | ConvertTo-Json

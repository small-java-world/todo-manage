$ApiUrl = 'http://localhost:8000'

Write-Host "Fetching all tasks from server..."
$AllTasks = Invoke-RestMethod -Uri "$ApiUrl/tasks/" -Method Get

Write-Host "`nTotal tasks found: $($AllTasks.Count)"
Write-Host "`nTasks:"
$AllTasks | ForEach-Object {
    Write-Host "  - ID: $($_.id), Type: $($_.type), Title: $($_.title), HID: $($_.hierarchical_id)"
}

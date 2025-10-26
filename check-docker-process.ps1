Get-Process | Where-Object { $_.ProcessName -eq 'Docker Desktop' } | Select-Object ProcessName, Id, StartTime

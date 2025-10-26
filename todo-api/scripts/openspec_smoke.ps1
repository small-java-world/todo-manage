#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"

# Config
$API_URL = if ($env:API_URL) { $env:API_URL.TrimEnd('/') } else { "http://localhost:8000" }

Write-Host "[INFO] API_URL=$API_URL"

function Invoke-JsonPost {
  param(
    [string]$Path,
    [hashtable]$Body
  )
  $url = "$API_URL$Path"
  $json = $Body | ConvertTo-Json -Depth 10
  return Invoke-RestMethod -Method Post -Uri $url -ContentType 'application/json' -Body $json
}

try {
  # 1) Create requirement
  $req = Invoke-JsonPost -Path "/tasks/requirements/" -Body @{ title = "ログイン要件 (smoke)"; description = "" }
  $reqId = [int]$req.id
  Write-Host "[OK] requirement id=$reqId"

  # 2) Create task under requirement
  $task = Invoke-JsonPost -Path "/tasks/" -Body @{ title = "ログインAPI (smoke)"; type = "task"; parent_id = $reqId; description = "" }
  $hid = [string]$task.hierarchical_id
  if (-not $hid) { throw "hierarchical_id missing" }
  Write-Host "[OK] task HID=$hid"

  # 3) Save OpenSpec
  $yaml = @"
version: "0.1"
id: "$hid"
title: "ログインAPI"
acceptance_criteria:
  - id: "AC-001"
    text: "正しい資格情報で200を返す"
scenarios:
  - id: "SCN-001"
    name: "成功シナリオ"
    steps:
      - request: { method: POST, path: "/login" }
        expect:  { status: 200 }
"@

  $save = Invoke-JsonPost -Path "/storage/openspec/$hid" -Body @{ content = $yaml }
  Write-Host "[OK] OpenSpec saved uri=$($save.openspec_uri) sha256=$($save.cas_sha256)"

  # 4) Validate
  $validate = Invoke-RestMethod -Method Post -Uri "$API_URL/storage/openspec/$hid/validate"
  if (-not $validate.valid) { throw "OpenSpec invalid: $($validate | ConvertTo-Json -Depth 10)" }
  Write-Host "[OK] OpenSpec validated"

  # 5) Generate tests (sync)
  $gen = Invoke-RestMethod -Method Post -Uri "$API_URL/storage/openspec/$hid/generate-tests"
  Write-Host "[OK] Generated tests trigger: $($gen.message)"

  # 6) Verify artifacts link
  $arts = Invoke-RestMethod -Method Get -Uri "$API_URL/artifacts/tasks/$hid/artifacts"
  $hasSpec = @($arts | Where-Object { $_.role -eq 'spec' }).Count -gt 0
  $hasTest = @($arts | Where-Object { $_.role -eq 'test' }).Count -gt 0
  if (-not $hasSpec) { throw "No spec artifact linked" }
  if (-not $hasTest) { throw "No test artifact linked" }
  Write-Host "[OK] Artifacts linked (spec & test)"

  Write-Host "[SUCCESS] OpenSpec smoke passed for HID=$hid"
  exit 0
}
catch {
  Write-Error "[FAIL] $_"
  exit 1
}



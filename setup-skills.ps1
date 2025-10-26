$ROOT   = "D:\todo-manage"
$API    = Join-Path $ROOT "todo-api"
$SKILLS = Join-Path $ROOT "todo-api-skills"
$TARGET = Join-Path $API  ".claude\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    $SourcePath = Join-Path $SKILLS $_
    $DestPath = Join-Path $TARGET $_
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
}

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $API "AGENTS.md")

Write-Host "todo-api への Skill 配置が完了しました"

# todo-api-client-sample への配置
$CLIENT = Join-Path $ROOT "todo-api-client-sample"
$TARGET = Join-Path $CLIENT ".claude\skills"

New-Item -ItemType Directory -Force $TARGET | Out-Null

"api.task-listing.minimal-v1",
"architecture.id-allocation.counters-v1",
"ops.review.evidence-v1",
"tdd.red-case.write-v1" | ForEach-Object {
    $SourcePath = Join-Path $SKILLS $_
    $DestPath = Join-Path $TARGET $_
    Copy-Item -Path $SourcePath -Destination $DestPath -Recurse -Force
}

Copy-Item -Force (Join-Path $SKILLS "AGENTS.md") (Join-Path $CLIENT "AGENTS.md")

Write-Host "todo-api-client-sample への Skill 配置が完了しました"

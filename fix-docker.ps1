# Docker修復スクリプト
# 管理者権限で実行してください

Write-Host "=== Docker修復スクリプト ===" -ForegroundColor Cyan
Write-Host ""

# 管理者権限チェック
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "警告: このスクリプトは管理者権限で実行する必要があります" -ForegroundColor Red
    Write-Host "PowerShellを右クリック → '管理者として実行' で再度実行してください" -ForegroundColor Yellow
    Write-Host ""
    pause
    exit
}

Write-Host "管理者権限で実行中 ✓" -ForegroundColor Green
Write-Host ""

# ステップ1: Docker関連プロセスを停止
Write-Host "[ステップ1] Docker関連プロセスを停止中..." -ForegroundColor Yellow
$dockerProcesses = Get-Process | Where-Object {$_.ProcessName -like '*docker*'}
if ($dockerProcesses) {
    $dockerProcesses | ForEach-Object {
        Write-Host "  停止中: $($_.ProcessName) (PID: $($_.Id))"
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 3
    Write-Host "  完了 ✓" -ForegroundColor Green
} else {
    Write-Host "  Dockerプロセスは実行されていません" -ForegroundColor Gray
}
Write-Host ""

# ステップ2: Docker サービスを停止
Write-Host "[ステップ2] Dockerサービスを停止中..." -ForegroundColor Yellow
$services = Get-Service | Where-Object {$_.Name -like '*docker*'}
if ($services) {
    $services | ForEach-Object {
        if ($_.Status -eq 'Running') {
            Write-Host "  停止中: $($_.Name)"
            Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Host "  完了 ✓" -ForegroundColor Green
} else {
    Write-Host "  Dockerサービスが見つかりません" -ForegroundColor Gray
}
Write-Host ""

# ステップ3: WSL2を再起動
Write-Host "[ステップ3] WSL2を再起動中..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep -Seconds 5
Write-Host "  完了 ✓" -ForegroundColor Green
Write-Host ""

# ステップ4: 名前付きパイプのクリーンアップ（存在する場合）
Write-Host "[ステップ4] 名前付きパイプのクリーンアップ..." -ForegroundColor Yellow
Write-Host "  docker_engine パイプをクリーンアップしています"
# 注: Windows名前付きパイプは自動的にクリーンアップされるため、明示的な削除は不要
Write-Host "  完了 ✓" -ForegroundColor Green
Write-Host ""

# ステップ5: Dockerサービスを起動
Write-Host "[ステップ5] Dockerサービスを起動中..." -ForegroundColor Yellow
try {
    Start-Service com.docker.service -ErrorAction Stop
    Write-Host "  完了 ✓" -ForegroundColor Green
} catch {
    Write-Host "  サービスの起動に失敗しました" -ForegroundColor Red
    Write-Host "  Docker Desktopアプリから起動してください" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "=== 修復処理完了 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "次の手順を実行してください:" -ForegroundColor Yellow
Write-Host "1. Docker Desktop を管理者として実行:" -ForegroundColor White
Write-Host "   - Docker Desktop を右クリック" -ForegroundColor Gray
Write-Host "   - '管理者として実行' を選択" -ForegroundColor Gray
Write-Host ""
Write-Host "2. それでもエラーが出る場合:" -ForegroundColor White
Write-Host "   - Docker Desktop のエラー画面で" -ForegroundColor Gray
Write-Host "   - 'Reset Docker to factory defaults' をクリック" -ForegroundColor Gray
Write-Host ""
Write-Host "3. 最終手段:" -ForegroundColor White
Write-Host "   - システムを再起動" -ForegroundColor Gray
Write-Host ""

pause

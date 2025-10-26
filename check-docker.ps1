# Docker診断スクリプト

Write-Host "=== Docker診断レポート ===" -ForegroundColor Cyan
Write-Host ""

# 1. Dockerバージョン
Write-Host "[1] Dockerバージョン確認" -ForegroundColor Yellow
try {
    docker --version
} catch {
    Write-Host "エラー: Dockerコマンドが見つかりません" -ForegroundColor Red
}
Write-Host ""

# 2. Docker デーモン接続テスト
Write-Host "[2] Dockerデーモン接続テスト" -ForegroundColor Yellow
try {
    docker ps 2>&1 | Out-String
} catch {
    Write-Host "Dockerデーモンに接続できません" -ForegroundColor Red
}
Write-Host ""

# 3. Dockerサービス状態
Write-Host "[3] Dockerサービス状態" -ForegroundColor Yellow
try {
    Get-Service | Where-Object {$_.Name -like '*docker*'} | Format-Table -AutoSize
} catch {
    Write-Host "サービス情報を取得できません" -ForegroundColor Red
}
Write-Host ""

# 4. Docker Desktopプロセス確認
Write-Host "[4] Docker Desktopプロセス" -ForegroundColor Yellow
$dockerProcesses = Get-Process | Where-Object {$_.ProcessName -like '*docker*'}
if ($dockerProcesses) {
    $dockerProcesses | Format-Table ProcessName, Id, CPU, WorkingSet -AutoSize
} else {
    Write-Host "Docker関連のプロセスが見つかりません" -ForegroundColor Red
}
Write-Host ""

# 5. WSL2状態確認
Write-Host "[5] WSL2状態" -ForegroundColor Yellow
try {
    wsl --status
} catch {
    Write-Host "WSLコマンドが実行できません" -ForegroundColor Red
}
Write-Host ""

# 6. WSL2ディストリビューション一覧
Write-Host "[6] WSL2ディストリビューション" -ForegroundColor Yellow
try {
    wsl --list --verbose
} catch {
    Write-Host "WSLディストリビューション情報を取得できません" -ForegroundColor Red
}
Write-Host ""

# 7. Hyper-V状態確認
Write-Host "[7] Hyper-V機能状態" -ForegroundColor Yellow
try {
    $hyperv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
    Write-Host "Hyper-V: $($hyperv.State)"
} catch {
    Write-Host "Hyper-V情報を取得できません (要管理者権限)" -ForegroundColor Red
}
Write-Host ""

# 8. 仮想マシンプラットフォーム確認
Write-Host "[8] 仮想マシンプラットフォーム" -ForegroundColor Yellow
try {
    $vmp = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    Write-Host "仮想マシンプラットフォーム: $($vmp.State)"
} catch {
    Write-Host "仮想マシンプラットフォーム情報を取得できません (要管理者権限)" -ForegroundColor Red
}
Write-Host ""

# 9. Docker Desktop実行ファイル確認
Write-Host "[9] Docker Desktop実行ファイル" -ForegroundColor Yellow
$dockerDesktopPaths = @(
    "C:\Program Files\Docker\Docker\Docker Desktop.exe",
    "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
)
foreach ($path in $dockerDesktopPaths) {
    if (Test-Path $path) {
        Write-Host "✓ 存在: $path" -ForegroundColor Green
    } else {
        Write-Host "✗ 見つかりません: $path" -ForegroundColor Red
    }
}
Write-Host ""

# 10. 推奨アクション
Write-Host "=== 推奨アクション ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "【問題】" -ForegroundColor Red
Write-Host "  com.docker.service が停止しています (STATE: 1 STOPPED)" -ForegroundColor White
Write-Host ""
Write-Host "【解決方法】" -ForegroundColor Green
Write-Host ""
Write-Host "方法1: Docker Desktopを起動" -ForegroundColor Yellow
Write-Host "  1. スタートメニューから 'Docker Desktop' を検索" -ForegroundColor White
Write-Host "  2. Docker Desktop をクリックして起動" -ForegroundColor White
Write-Host "  3. タスクバーにDockerアイコンが表示されるまで待つ" -ForegroundColor White
Write-Host ""
Write-Host "方法2: サービスを手動で起動 (管理者権限必要)" -ForegroundColor Yellow
Write-Host "  1. PowerShellを管理者として実行" -ForegroundColor White
Write-Host "  2. 以下のコマンドを実行:" -ForegroundColor White
Write-Host "     Start-Service com.docker.service" -ForegroundColor Cyan
Write-Host ""
Write-Host "方法3: WSL2を再起動してからDocker Desktopを起動" -ForegroundColor Yellow
Write-Host "  1. PowerShellで以下を実行:" -ForegroundColor White
Write-Host "     wsl --shutdown" -ForegroundColor Cyan
Write-Host "  2. Docker Desktopを起動" -ForegroundColor White
Write-Host ""
Write-Host "方法4: システムを再起動" -ForegroundColor Yellow
Write-Host "  最もシンプルで確実な方法です" -ForegroundColor White
Write-Host ""

Write-Host "=== 診断完了 ===" -ForegroundColor Cyan

# Run all integration tests on Android
Write-Host "Running integration tests on Android Emulator..." -ForegroundColor Green

# Check if Flutter is available
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check if Android device/emulator is available
$devices = flutter devices 2>&1 | Out-String
if ($devices -notmatch "android-x64|android-arm64|emulator-\d+") {
    Write-Host "Error: No Android device or emulator found." -ForegroundColor Red
    Write-Host "Please start an Android emulator first:" -ForegroundColor Yellow
    Write-Host "  1. Open Android Studio" -ForegroundColor Cyan
    Write-Host "  2. Start an emulator from AVD Manager" -ForegroundColor Cyan
    Write-Host "  Or run: flutter emulators --launch <emulator_id>" -ForegroundColor Cyan
    Write-Host "`nAvailable devices:" -ForegroundColor Yellow
    Write-Host $devices
    exit 1
}

Write-Host "Found Android emulator!" -ForegroundColor Green

# Run pub get to ensure dependencies are installed
Write-Host "`nInstalling dependencies..." -ForegroundColor Cyan
flutter pub get

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to install dependencies" -ForegroundColor Red
    exit 1
}

# Run all integration tests using flutter drive for Android
Write-Host "`nRunning all integration tests..." -ForegroundColor Cyan

# Get list of test files
$testFiles = Get-ChildItem -Path "*.dart" | Where-Object { $_.Name -ne "test_driver.dart" }

$allPassed = $true
foreach ($file in $testFiles) {
    Write-Host "`nRunning $($file.Name)..." -ForegroundColor Cyan
    flutter test $file.FullName
    if ($LASTEXITCODE -ne 0) {
        $allPassed = $false
        Write-Host "Failed: $($file.Name)" -ForegroundColor Red
    } else {
        Write-Host "Passed: $($file.Name)" -ForegroundColor Green
    }
}

if (-not $allPassed) {
    exit 1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nAll tests passed successfully!" -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed. Check the output above." -ForegroundColor Red
    exit 1
}

# Run individual test files on Android
param(
    [string]$TestFile = "all"
)

Write-Host "Running integration tests on Android Emulator..." -ForegroundColor Green

# Check Flutter
if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Error: Flutter is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Install dependencies
Write-Host "`nInstalling dependencies..." -ForegroundColor Cyan
flutter pub get

$testFiles = @{
    "app" = "app_test.dart"
    "profile" = "profile_flow_test.dart"
    "validation" = "validation_test.dart"
    "darkmode" = "dark_mode_test.dart"
}

if ($TestFile -eq "all") {
    Write-Host "`nRunning all tests..." -ForegroundColor Cyan
    $allTestFiles = Get-ChildItem -Path "*.dart" | Where-Object { $_.Name -ne "test_driver.dart" }
    foreach ($file in $allTestFiles) {
        Write-Host "`nRunning $($file.Name)..." -ForegroundColor Cyan
        flutter test $file.FullName
    }
} elseif ($testFiles.ContainsKey($TestFile.ToLower())) {
    $file = $testFiles[$TestFile.ToLower()]
    Write-Host "`nRunning $file..." -ForegroundColor Cyan
    flutter test $file --verbose
} else {
    Write-Host "`nAvailable tests:" -ForegroundColor Yellow
    Write-Host "  app        - Basic app tests"
    Write-Host "  profile    - Profile creation flow tests"
    Write-Host "  validation - Form validation tests"
    Write-Host "  darkmode   - Dark mode tests"
    Write-Host "  all        - All tests (default)"
    Write-Host "`nUsage: .\run_test.ps1 [test_name]" -ForegroundColor Cyan
    Write-Host "Example: .\run_test.ps1 validation" -ForegroundColor Cyan
    exit 1
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nTests passed!" -ForegroundColor Green
} else {
    Write-Host "`nTests failed!" -ForegroundColor Red
    exit 1
}

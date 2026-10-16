# APK de RELEASE apontando para a URL HTTPS definida em env/prod.json.
# Antes: troque a URL em env/prod.json (e em ApiConfig.productionUrl) pela sua URL https.
#
#   powershell -ExecutionPolicy Bypass -File .\scripts\apk-release.ps1
Set-Location (Join-Path $PSScriptRoot "..")
flutter pub get
flutter build apk --release --dart-define-from-file=env/prod.json
if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "Pronto: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
}

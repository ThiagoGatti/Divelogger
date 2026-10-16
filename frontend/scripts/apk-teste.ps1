# APK de TESTE (debug) apontando para o backend na AWS por HTTP.
# Use enquanto o servidor ainda não tem HTTPS. NÃO publique este APK.
#
# Como usar (PowerShell, dentro da pasta frontend):
#   powershell -ExecutionPolicy Bypass -File .\scripts\apk-teste.ps1
#
# Por que pelo terminal? O menu "Build > Flutter > Build APK" do Android Studio não passa
# --dart-define-from-file, então o app sairia sem saber a URL do servidor.
Set-Location (Join-Path $PSScriptRoot "..")
flutter pub get
flutter build apk --debug --dart-define-from-file=env/aws-http.json
if ($LASTEXITCODE -eq 0) {
  Write-Host ""
  Write-Host "Pronto: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
  Write-Host "Envie esse arquivo para o celular (cabo, Drive ou WhatsApp) e instale."
}

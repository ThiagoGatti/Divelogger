# Execute na RAIZ do projeto (pasta que contém "backend" e "frontend"):
#   powershell -ExecutionPolicy Bypass -File .\REMOVER-ARQUIVOS-ANTIGOS.ps1
# Remove arquivos que foram SUBSTITUÍDOS. Se ficarem no projeto, o build do backend falha.
$files = @(
  "backend/src/main/java/com/log/diverr/diver/divelogs/usecases/CreateDiveLogUseCase.java",
  "backend/src/main/java/com/log/diverr/diver/divesites/usecases/CreateDiveSiteUseCase.java",
  "frontend/lib/features/home/presentation/wave_bottom_bar.dart"
)
foreach ($f in $files) {
  if (Test-Path $f) { Remove-Item $f -Force; Write-Host "Removido: $f" }
  else { Write-Host "Já não existe: $f" }
}

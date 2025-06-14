# Configurando projeto de microsserviços...
Write-Host "🚀 Configurando projeto de microsserviços..."

# Criar estrutura de diretórios
Write-Host "📁 Criando estrutura de pastas..."
$folders = @(
    'eureka-server/src/main/java/com/logistics/eureka',
    'eureka-server/src/main/resources',
    'auth-service/src/main/java/com/logistics/auth',
    'auth-service/src/main/resources',
    'orders-service/src/main/java/com/logistics/orders',
    'orders-service/src/main/resources',
    'tracking-service/src/main/java/com/logistics/tracking',
    'tracking-service/src/main/resources',
    'api-gateway/src/main/java/com/logistics/gateway',
    'api-gateway/src/main/resources',
    'scripts',
    'logs'
)
foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
}

Write-Host "✅ Estrutura criada com sucesso!"
Write-Host ""
Write-Host "📋 Próximos passos:"
Write-Host "1. Baixe os projetos do Spring Initializr"
Write-Host "2. Extraia cada projeto na pasta correspondente"
Write-Host "3. Execute build-all.ps1 para compilar"
Write-Host "4. Execute run-local.ps1 para iniciar"
Write-Host ""
Pause

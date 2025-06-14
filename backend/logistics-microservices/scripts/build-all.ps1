# Build All Microservices - PowerShell Script
# Encoding: UTF-8

# Configurar encoding para suportar caracteres especiais
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Navegar para o diretório raiz do projeto
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
Set-Location $rootPath

Write-Host "Diretório atual: $(Get-Location)" -ForegroundColor Cyan
Write-Host "[BUILD] Compilando todos os microsserviços..." -ForegroundColor Yellow
Write-Host ""

# Função para verificar se um comando foi executado com sucesso
function Test-CommandSuccess {
    param($ExitCode, $ServiceName)
    if ($ExitCode -ne 0) {
        Write-Host "[ERRO] Erro ao compilar $ServiceName" -ForegroundColor Red
        Write-Host "Pressione qualquer tecla para sair..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

# Verificar se Maven está instalado
Write-Host "Verificando Maven..." -ForegroundColor Cyan
try {
    $mavenVersion = & mvn -version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Maven não encontrado"
    }
    Write-Host "[OK] Maven encontrado!" -ForegroundColor Green
} catch {
    Write-Host "[ERRO] Maven não encontrado! Instale o Apache Maven primeiro." -ForegroundColor Red
    Write-Host "Pressione qualquer tecla para sair..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}
Write-Host ""

# Lista de serviços para compilar
$services = @(
    @{Name = "Eureka Server"; Directory = "eureka-server"; Icon = "[EUREKA]"},
    @{Name = "Auth Service"; Directory = "auth-service"; Icon = "[AUTH]"},
    @{Name = "Orders Service"; Directory = "orders-service"; Icon = "[ORDERS]"},
    @{Name = "Tracking Service"; Directory = "tracking-service"; Icon = "[TRACKING]"},
    @{Name = "API Gateway"; Directory = "api-gateway"; Icon = "[GATEWAY]"}
)

# Compilar cada serviço
foreach ($service in $services) {
    Write-Host "$($service.Icon) Compilando $($service.Name)..." -ForegroundColor Yellow
    
    # Verificar se o diretório existe
    if (-not (Test-Path $service.Directory)) {
        Write-Host "[ERRO] Diretório $($service.Directory) não encontrado!" -ForegroundColor Red
        Write-Host "Pressione qualquer tecla para sair..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
    
    # Navegar para o diretório do serviço
    Write-Host "   Entrando em: $($service.Directory)" -ForegroundColor Gray
    Set-Location $service.Directory
    
    # Executar Maven
    Write-Host "   Executando: mvn clean package -DskipTests" -ForegroundColor Gray
    try {
        & mvn clean package -DskipTests
        Test-CommandSuccess $LASTEXITCODE $service.Name
        Write-Host "[OK] $($service.Name) compilado com sucesso!" -ForegroundColor Green
    } catch {
        Write-Host "[ERRO] Erro ao compilar $($service.Name)" -ForegroundColor Red
        Set-Location $rootPath
        Write-Host "Pressione qualquer tecla para sair..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
    
    # Voltar para o diretório raiz
    Set-Location $rootPath
    Write-Host ""
}

Write-Host "[SUCESSO] Todos os serviços compilados com sucesso!" -ForegroundColor Green
Write-Host ""
Write-Host "Pressione qualquer tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
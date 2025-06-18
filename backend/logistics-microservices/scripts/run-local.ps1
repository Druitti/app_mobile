# Iniciando Sistema de Microsserviços para Logística
Write-Host "[START] Iniciando Sistema de Microsserviços para Logística" -ForegroundColor Yellow
Write-Host "=====================================================" -ForegroundColor Yellow
Write-Host ""

# Verificar Java
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Java não encontrado! Instale OpenJDK 17+" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Verificar Maven
if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Maven não encontrado! Instale Apache Maven" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Verificar Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "[ERRO] Docker não está rodando! Inicie o Docker Desktop" -ForegroundColor Red
    Read-Host "Pressione Enter para sair"
    exit 1
}

# Navegar para o diretório raiz do projeto
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent $scriptPath
Set-Location $rootPath

# Criar pasta de logs se não existir
if (-not (Test-Path "logs")) { 
    New-Item -ItemType Directory -Path "logs" | Out-Null 
    Write-Host "[INFO] Pasta de logs criada" -ForegroundColor Green
}

Write-Host "[DOCKER] Iniciando infraestrutura..." -ForegroundColor Cyan

# Parar containers existentes primeiro
Write-Host "[DOCKER] Parando containers existentes..." -ForegroundColor Yellow
try {
    docker stop postgres-logistics rabbitmq-logistics 2>$null | Out-Null
    docker rm postgres-logistics rabbitmq-logistics 2>$null | Out-Null
} catch {
    Write-Host "[INFO] Nenhum container anterior encontrado" -ForegroundColor Gray
}

# Iniciar PostgreSQL
Write-Host "[POSTGRES] Iniciando PostgreSQL..." -ForegroundColor Blue
try {
    $postgresResult = docker run -d --name postgres-logistics `
        -e POSTGRES_DB=logistics_db `
        -e POSTGRES_USER=postgres `
        -e POSTGRES_PASSWORD=postgres `
        -p 5432:5432 `
        postgres:15-alpine
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] PostgreSQL container iniciado: $postgresResult" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Falha ao iniciar PostgreSQL" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERRO] Erro ao iniciar PostgreSQL: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Iniciar RabbitMQ
Write-Host "[RABBITMQ] Iniciando RabbitMQ..." -ForegroundColor Blue
try {
    $rabbitmqResult = docker run -d --name rabbitmq-logistics `
        -e RABBITMQ_DEFAULT_USER=guest `
        -e RABBITMQ_DEFAULT_PASS=guest `
        -p 5672:5672 `
        -p 15672:15672 `
        rabbitmq:3-management-alpine
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] RabbitMQ container iniciado: $rabbitmqResult" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Falha ao iniciar RabbitMQ" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERRO] Erro ao iniciar RabbitMQ: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Aguardar e verificar se PostgreSQL está pronto
Write-Host "[WAIT] Aguardando PostgreSQL ficar pronto..." -ForegroundColor Yellow
$maxAttempts = 30
$attempt = 0

do {
    $attempt++
    Start-Sleep -Seconds 2
    
    try {
        $pgReady = docker exec postgres-logistics pg_isready -U postgres -d logistics_db 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] PostgreSQL está pronto!" -ForegroundColor Green
            break
        }
    } catch {
        # Continuar tentando
    }
    
    if ($attempt -eq $maxAttempts) {
        Write-Host "[ERRO] PostgreSQL não ficou pronto em tempo hábil" -ForegroundColor Red
        Write-Host "[DEBUG] Verificando logs do PostgreSQL:" -ForegroundColor Yellow
        docker logs postgres-logistics --tail 10
        exit 1
    }
    
    Write-Host "[WAIT] Tentativa $attempt/$maxAttempts - PostgreSQL ainda não está pronto..." -ForegroundColor Gray
} while ($true)

# Aguardar e verificar se RabbitMQ está pronto
Write-Host "[WAIT] Aguardando RabbitMQ ficar pronto..." -ForegroundColor Yellow
$attempt = 0

do {
    $attempt++
    Start-Sleep -Seconds 2
    
    try {
        $rabbitmqReady = docker exec rabbitmq-logistics rabbitmq-diagnostics ping 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] RabbitMQ está pronto!" -ForegroundColor Green
            break
        }
    } catch {
        # Continuar tentando
    }
    
    if ($attempt -eq 15) {
        Write-Host "[ERRO] RabbitMQ não ficou pronto em tempo hábil" -ForegroundColor Red
        Write-Host "[DEBUG] Verificando logs do RabbitMQ:" -ForegroundColor Yellow
        docker logs rabbitmq-logistics --tail 10
        exit 1
    }
    
    Write-Host "[WAIT] Tentativa $attempt/15 - RabbitMQ ainda não está pronto..." -ForegroundColor Gray
} while ($true)

# Verificar conectividade do banco
Write-Host "[TEST] Testando conectividade do PostgreSQL..." -ForegroundColor Yellow
try {
    $testConnection = docker exec postgres-logistics psql -U postgres -d logistics_db -c "SELECT 1;" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK] Conectividade do PostgreSQL confirmada!" -ForegroundColor Green
    } else {
        Write-Host "[ERRO] Não foi possível conectar ao PostgreSQL" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERRO] Erro ao testar conectividade: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ INFRAESTRUTURA PRONTA! Iniciando microsserviços..." -ForegroundColor Green
Write-Host ""

# Função para iniciar serviço com verificação
function Start-MicroService {
    param(
        [string]$ServiceName,
        [string]$ServicePath,
        [string]$LogColor,
        [int]$WaitSeconds
    )
    
    Write-Host "[$($ServiceName.ToUpper())] Iniciando $ServiceName..." -ForegroundColor $LogColor
    
    if (Test-Path $ServicePath) {
        # Compilar primeiro para verificar se há erros
        Set-Location $ServicePath
        Write-Host "[$($ServiceName.ToUpper())] Compilando $ServiceName..." -ForegroundColor Gray
        
        $compileResult = mvn clean compile -q 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[$($ServiceName.ToUpper())] ERRO na compilação:" -ForegroundColor Red
            Write-Host $compileResult -ForegroundColor Red
            Set-Location $rootPath
            return $false
        }
        
        Write-Host "[$($ServiceName.ToUpper())] Compilação OK. Iniciando serviço..." -ForegroundColor Green
        
        # Iniciar o serviço
        $logFile = "../logs/$ServicePath.log"
        Start-Process powershell -ArgumentList "-NoExit", "-Command", "mvn spring-boot:run 2>&1 | Tee-Object -FilePath '$logFile'" -WindowStyle Minimized
        
        Set-Location $rootPath
        
        Write-Host "[WAIT] Aguardando $ServiceName ($WaitSeconds segundos)..." -ForegroundColor Gray
        Start-Sleep -Seconds $WaitSeconds
        
        return $true
    } else {
        Write-Host "[$($ServiceName.ToUpper())] ERRO: Diretório $ServicePath não encontrado!" -ForegroundColor Red
        return $false
    }
}

# Iniciar serviços em ordem
$services = @(
    @{Name="Eureka Server"; Path="eureka-server"; Color="Magenta"; Wait=5},
    @{Name="Auth Service"; Path="auth-service"; Color="Green"; Wait=5},
    @{Name="Orders Service"; Path="orders-service"; Color="Blue"; Wait=5},
    @{Name="Tracking Service"; Path="tracking-service"; Color="DarkYellow"; Wait=5},
    @{Name="API Gateway"; Path="api-gateway"; Color="Cyan"; Wait=5}
)

foreach ($service in $services) {
    $success = Start-MicroService -ServiceName $service.Name -ServicePath $service.Path -LogColor $service.Color -WaitSeconds $service.Wait
    
    if (-not $success) {
        Write-Host "[ERRO] Falha ao iniciar $($service.Name). Parando execução." -ForegroundColor Red
        
        # Parar containers se houver falha
        Write-Host "[CLEANUP] Parando containers..." -ForegroundColor Yellow
        docker stop postgres-logistics rabbitmq-logistics 2>$null | Out-Null
        docker rm postgres-logistics rabbitmq-logistics 2>$null | Out-Null
        
        Read-Host "Pressione Enter para sair"
        exit 1
    }
}

Write-Host ""
Write-Host "[SUCESSO] SISTEMA INICIADO COM SUCESSO!" -ForegroundColor Green
Write-Host "===============================" -ForegroundColor Green
Write-Host ""
Write-Host "[INFO] Dashboards e APIs:" -ForegroundColor White
Write-Host "  API Gateway:         http://localhost:8080" -ForegroundColor White
Write-Host "  Eureka Dashboard:    http://localhost:8761" -ForegroundColor White
Write-Host "  RabbitMQ Management: http://localhost:15672 (guest/guest)" -ForegroundColor White
Write-Host ""

# Testar conectividade dos serviços
Write-Host "[TEST] Testando conectividade dos serviços..." -ForegroundColor Yellow

$testUrls = @(
    @{Name="Eureka"; Url="http://localhost:8761/actuator/health"},
    @{Name="API Gateway"; Url="http://localhost:8080/actuator/health"}
)

foreach ($test in $testUrls) {
    try {
        $response = Invoke-WebRequest -Uri $test.Url -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "[OK] $($test.Name) está respondendo!" -ForegroundColor Green
        } else {
            Write-Host "[AVISO] $($test.Name) retornou status: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[AVISO] $($test.Name) ainda não está pronto. Isso é normal." -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "[INFO] Status dos containers:" -ForegroundColor Cyan
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=logistics"

Write-Host ""
Write-Host "[INFO] Logs dos serviços em: ./logs/" -ForegroundColor Cyan
Write-Host "[INFO] Para monitorar logs: Get-Content logs\\<servico>.log -Tail 10 -Wait" -ForegroundColor Cyan
Write-Host "[INFO] Para parar: stop-all.ps1" -ForegroundColor Cyan
Write-Host ""
Read-Host "Pressione Enter para continuar"
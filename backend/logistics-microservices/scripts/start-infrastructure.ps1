# Iniciando infraestrutura (PostgreSQL + RabbitMQ)...
Write-Host "🐳 Iniciando infraestrutura (PostgreSQL + RabbitMQ)..."

# Verificar se Docker está rodando
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker não está rodando! Inicie o Docker Desktop primeiro."
    Pause
    exit 1
}

Write-Host "📊 Iniciando PostgreSQL..."
docker run -d --name postgres-logistics -e POSTGRES_DB=logistics_db -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:15-alpine
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ PostgreSQL pode já estar rodando..."
} else {
    Write-Host "✅ PostgreSQL iniciado"
}

Write-Host "🐰 Iniciando RabbitMQ..."
docker run -d --name rabbitmq-logistics -e RABBITMQ_DEFAULT_USER=guest -e RABBITMQ_DEFAULT_PASS=guest -p 5672:5672 -p 15672:15672 rabbitmq:3-management-alpine
if ($LASTEXITCODE -ne 0) {
    Write-Host "⚠️ RabbitMQ pode já estar rodando..."
} else {
    Write-Host "✅ RabbitMQ iniciado"
}

Write-Host ""
Write-Host "⏳ Aguardando serviços inicializarem..."
Start-Sleep -Seconds 15

Write-Host ""
Write-Host "🎉 Infraestrutura iniciada!"
Write-Host "📊 PostgreSQL: localhost:5432"
Write-Host "🐰 RabbitMQ Management: http://localhost:15672 (guest/guest)"
Write-Host ""
Pause

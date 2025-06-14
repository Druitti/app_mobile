# LOGISTICS MICROSERVICES - QUICK START
Write-Host "\n🚀 LOGISTICS MICROSERVICES - QUICK START"
Write-Host "========================
================="
Write-Host ""

# Verificar dependências
Write-Host "🔍 Verificando dependências..."

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Java 17+ não encontrado"
    Write-Host "   Baixe em: https://adoptium.net/"
    Pause
    exit 1
}
Write-Host "✅ Java encontrado"

if (-not (Get-Command mvn -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Maven não encontrado"
    Write-Host "   Baixe em: https://maven.apache.org/download.cgi"
    Pause
    exit 1
}
Write-Host "✅ Maven encontrado"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Docker não encontrado ou não está rodando"
    Write-Host "   Baixe Docker Desktop: https://www.docker.com/products/docker-desktop"
    Pause
    exit 1
}
Write-Host "✅ Docker encontrado"

Write-Host ""
Write-Host "📋 Como você quer executar o sistema?"
Write-Host ""
Write-Host "1) 🏠 Local (Maven + Docker para DB)"
Write-Host "2) 🐳 Docker Compose (Tudo containerizado)"
Write-Host "3) 🔨 Apenas compilar os projetos"
Write-Host "4) 🧹 Limpar ambiente"
Write-Host "5) 📊 Monitorar serviços"
Write-Host ""
$choice = Read-Host "Escolha uma opção (1-5)"

switch ($choice) {
    '1' {
        Write-Host "\n🏠 Executando localmente..."
        & ./build-all.ps1
        if ($LASTEXITCODE -ne 0) { exit 1 }
        & ./run-local.ps1
    }
    '2' {
        Write-Host "\n🐳 Executando com Docker Compose..."
        & ./docker-run.ps1
    }
    '3' {
        Write-Host "\n🔨 Compilando projetos..."
        & ./build-all.ps1
    }
    '4' {
        Write-Host "\n🧹 Limpando ambiente..."
        & ./cleanup.ps1
    }
    '5' {
        Write-Host "\n📊 Iniciando monitor..."
        & ./monitor.ps1
    }
    Default {
        Write-Host "❌ Opção inválida"
        Pause
        exit 1
    }
}

Write-Host "\n🎉 Operação concluída!"
Write-Host ""
Write-Host "📚 Documentação: README.md"
Write-Host "🧪 Para testar: test-services.ps1"
Write-Host "📊 Para monitorar: monitor.ps1"
Write-Host "🛑 Para parar: stop-all.ps1"
Write-Host ""
Pause

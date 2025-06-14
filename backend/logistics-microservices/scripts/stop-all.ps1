# Parando todos os serviços...
Write-Host "Parando todos os serviços..."

Write-Host "Parando processos Java (Maven)..."
Get-Process java,javaw -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Parando containers Docker..."
docker stop postgres-logistics,rabbitmq-logistics | Out-Null
# Remover containers
Start-Sleep -Seconds 2
docker rm postgres-logistics,rabbitmq-logistics | Out-Null

Write-Host "Limpando processos"
Start-Sleep -Seconds 3


Pause


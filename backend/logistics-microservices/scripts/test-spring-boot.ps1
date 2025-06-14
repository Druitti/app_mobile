# test-spring-boot-simple.ps1 - Versao simples sem emojis

Clear-Host
Write-Host "EXECUTANDO TESTES SPRING BOOT" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Navegar para o diretorio raiz se estivermos em scripts/
if (Test-Path "..\eureka-server") {
    Set-Location ..
}

$services = @("eureka-server", "auth-service", "orders-service", "tracking-service", "api-gateway")
$testResults = @()

foreach ($service in $services) {
    if (Test-Path $service) {
        Write-Host ""
        Write-Host "[INFO] Testando $service..." -ForegroundColor Yellow
        Write-Host "================================" -ForegroundColor Yellow
        
        Set-Location $service
        
        # Verificar se existem testes
        $testPath = "src\test\java"
        if (Test-Path $testPath) {
            $testFiles = Get-ChildItem -Path $testPath -Recurse -Filter "*.java"
            Write-Host "[INFO] Encontrados $($testFiles.Count) arquivos de teste" -ForegroundColor Gray
            
            foreach ($testFile in $testFiles) {
                Write-Host "       $($testFile.Name)" -ForegroundColor Gray
            }
        } else {
            Write-Host "[AVISO] Pasta de testes nao encontrada: $testPath" -ForegroundColor Yellow
        }
        
        try {
            Write-Host "[INFO] Executando testes..." -ForegroundColor Blue
            
            # Comando Maven simples - sem profiles
            $testOutput = cmd /c "mvn test" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] $service - TODOS OS TESTES PASSARAM" -ForegroundColor Green
                
                # Extrair informacoes dos testes
                $testInfo = $testOutput | Select-String "Tests run:"
                if ($testInfo) {
                    Write-Host "[INFO] $testInfo" -ForegroundColor Cyan
                }
                
                $testResults += @{
                    Service = $service
                    Status = "PASSOU"
                    TestCount = if ($testInfo) { ($testInfo -split "Tests run: ")[1] -split "," | Select-Object -First 1 } else { "N/A" }
                    Output = $testOutput
                }
            } else {
                Write-Host "[ERRO] $service - TESTES FALHARAM" -ForegroundColor Red
                Write-Host ""
                Write-Host "[DETALHES] Saida do erro:" -ForegroundColor Red
                
                # Mostrar apenas erros relevantes
                $errorLines = $testOutput | Where-Object { 
                    $_ -match "FAILURE|ERROR|Failed|Exception|\[ERROR\]" -and 
                    $_ -notmatch "To see the full stack trace|For more information" 
                }
                
                if ($errorLines) {
                    $errorLines | Select-Object -First 10 | ForEach-Object { 
                        Write-Host "         $_" -ForegroundColor Red 
                    }
                } else {
                    # Se nao encontrou erros especificos, mostrar as ultimas linhas
                    $testOutput | Select-Object -Last 5 | ForEach-Object { 
                        Write-Host "         $_" -ForegroundColor Red 
                    }
                }
                
                $testResults += @{
                    Service = $service
                    Status = "FALHOU"
                    TestCount = "N/A"
                    Output = $testOutput
                }
            }
        } catch {
            Write-Host "[ERRO] $service - ERRO NA EXECUCAO: $($_.Exception.Message)" -ForegroundColor Red
            $testResults += @{
                Service = $service
                Status = "ERRO"
                TestCount = "N/A"
                Output = $_.Exception.Message
            }
        }
        
        Set-Location ..
    } else {
        Write-Host "[AVISO] Servico $service nao encontrado" -ForegroundColor Yellow
        $testResults += @{
            Service = $service
            Status = "NAO ENCONTRADO"
            TestCount = "N/A"
            Output = ""
        }
    }
}

# Resumo final
Write-Host ""
Write-Host "RESUMO DOS TESTES:" -ForegroundColor Cyan
Write-Host "==================" -ForegroundColor Cyan

$totalServices = $testResults.Count
$passedServices = ($testResults | Where-Object { $_.Status -eq "PASSOU" }).Count
$failedServices = ($testResults | Where-Object { $_.Status -eq "FALHOU" }).Count
$errorServices = ($testResults | Where-Object { $_.Status -eq "ERRO" }).Count

Write-Host ""
Write-Host "[ESTATISTICAS]" -ForegroundColor White
Write-Host "   Total de servicos: $totalServices" -ForegroundColor Gray
Write-Host "   Testes passaram: $passedServices" -ForegroundColor Green
Write-Host "   Testes falharam: $failedServices" -ForegroundColor Red
Write-Host "   Erros de execucao: $errorServices" -ForegroundColor Red

Write-Host ""
Write-Host "[RESULTADOS POR SERVICO]" -ForegroundColor White

foreach ($result in $testResults) {
    $status = switch ($result.Status) {
        "PASSOU" { "[OK]" }
        "FALHOU" { "[FALHA]" }
        "ERRO" { "[ERRO]" }
        "NAO ENCONTRADO" { "[NAO ENCONTRADO]" }
    }
    
    $color = switch ($result.Status) {
        "PASSOU" { "Green" }
        "FALHOU" { "Red" }
        "ERRO" { "Red" }
        "NAO ENCONTRADO" { "Yellow" }
    }
    
    $testCount = if ($result.TestCount -ne "N/A") { " ($($result.TestCount) testes)" } else { "" }
    Write-Host "   $status $($result.Service)$testCount" -ForegroundColor $color
}

Write-Host ""

# Comandos uteis
Write-Host "[COMANDOS UTEIS]" -ForegroundColor Cyan
Write-Host "================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para executar testes de um servico especifico:" -ForegroundColor Yellow
Write-Host "   cd auth-service" -ForegroundColor White
Write-Host "   mvn test" -ForegroundColor White
Write-Host ""
Write-Host "Para executar teste especifico:" -ForegroundColor Yellow
Write-Host "   mvn test -Dtest=AuthControllerTest" -ForegroundColor White
Write-Host ""
Write-Host "Para executar testes com mais detalhes:" -ForegroundColor Yellow
Write-Host "   mvn test -X" -ForegroundColor White
Write-Host ""
Write-Host "Para pular testes na compilacao:" -ForegroundColor Yellow
Write-Host "   mvn clean package -DskipTests" -ForegroundColor White

Write-Host ""

if ($passedServices -eq $totalServices) {
    Write-Host "[SUCESSO] TODOS OS TESTES PASSARAM!" -ForegroundColor Green
} elseif ($passedServices -gt 0) {
    Write-Host "[AVISO] Alguns testes passaram, outros falharam." -ForegroundColor Yellow
} else {
    Write-Host "[ERRO] Todos os testes falharam." -ForegroundColor Red
}

Write-Host ""
Read-Host "Pressione Enter para continuar"
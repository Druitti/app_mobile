# 🚀 Sistema de Microsserviços para Logística

Sistema completo de microsserviços desenvolvido com **Spring Boot**, **Eureka Server**, **PostgreSQL**, **RabbitMQ** e **JWT Authentication** para gerenciamento de entregas e rastreamento em tempo real.

## 📋 Índice

- [Arquitetura do Sistema](#️-arquitetura-do-sistema)
- [Funcionalidades](#-funcionalidades)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)
- [Pré-requisitos](#-pré-requisitos)
- [Instalação e Configuração](#-instalação-e-configuração)
- [Como Executar](#-como-executar)
- [Scripts Disponíveis](#-scripts-disponíveis)
- [Testes](#-testes)
- [APIs e Endpoints](#-apis-e-endpoints)
- [Monitoramento](#-monitoramento)
- [Troubleshooting](#-troubleshooting)
- [Estrutura do Projeto](#-estrutura-do-projeto)

## 🏗️ Arquitetura do Sistema

```
┌─────────────────┐    ┌─────────────────┐
│   Cliente/App   │ -> │   API Gateway   │ (Porta 8080)
└─────────────────┘    └─────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │  Eureka Server    │ (Porta 8761)
                    │ (Service Discovery)│
                    └─────────┬─────────┘
                              │
            ┌─────────────────┼─────────────────┐
            │                 │                 │
    ┌───────▼───────┐ ┌──────▼──────┐ ┌────────▼────────┐
    │ Auth Service  │ │Orders Service│ │Tracking Service │ (Portas Dinâmicas)
    │     (JWT)     │ │   (CRUD +    │ │  (Geolocation)  │
    │               │ │   Routes)    │ │                 │
    └───────┬───────┘ └──────┬──────┘ └────────┬────────┘
            │                │                 │
            └────────────────┼─────────────────┘
                             │
                ┌────────────▼────────────┐
                │ PostgreSQL (5432)      │
                │ RabbitMQ (5672/15672)  │
                └─────────────────────────┘
```

## 🎯 Funcionalidades

### 🔐 **Authentication Service**
- Registro e login de usuários (Cliente, Motorista, Admin)
- Autenticação JWT com refresh tokens
- Validação de tokens centralizada
- Criptografia de senhas com BCrypt
- Controle de acesso por roles

### 📦 **Orders Service**
- CRUD completo de pedidos
- Cálculo de rotas otimizadas (OpenStreetMap + OSRM)
- Estados de pedido (Pendente, Aceito, Em Rota, Entregue, Cancelado)
- Atribuição automática de motoristas
- Eventos assíncronos via RabbitMQ
- Estimativa de tempo e distância

### 📍 **Tracking Service**
- Rastreamento em tempo real via GPS
- Histórico completo de localizações
- Cálculo de distâncias (Fórmula de Haversine)
- Reverse geocoding automático
- Busca por entregas próximas
- Notificações de proximidade do destino

### 🌐 **API Gateway**
- Roteamento inteligente com load balancing
- Autenticação centralizada
- Rate limiting e CORS configurado
- Roteamento por roles (Admin, Driver, Customer)
- Health checks integrados

### 📡 **Eureka Server**
- Service Discovery automático
- Dashboard de monitoramento
- Load balancing entre instâncias
- Health checks dos serviços

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Versão | Uso |
|------------|---------|-----|
| **Java** | 17+ | Linguagem base |
| **Spring Boot** | 3.2.0 | Framework principal |
| **Spring Cloud** | 2023.0.0 | Microsserviços |
| **Eureka Server** | - | Service Discovery |
| **Spring Gateway** | - | API Gateway |
| **PostgreSQL** | 15 | Banco de dados |
| **RabbitMQ** | 3-management | Message Broker |
| **JWT** | 0.11.5 | Autenticação |
| **Docker** | - | Containerização |
| **Maven** | 3.8+ | Gerenciamento de dependências |

## 📋 Pré-requisitos

### Software Necessário:
- ✅ **Java 17+** ([Download OpenJDK](https://adoptium.net/))
- ✅ **Maven 3.8+** ([Download Maven](https://maven.apache.org/download.cgi))
- ✅ **Docker Desktop** ([Download Docker](https://www.docker.com/products/docker-desktop))
- ✅ **Git** ([Download Git](https://git-scm.com/download/win))

### Verificar Instalação:
```powershell
java -version
mvn -version
docker version
git --version
```

## 🚀 Instalação e Configuração

### 1. **Clonar o Repositório**
```powershell
git clone https://github.com/Druitti/app_mobile.git
cd backend
cd logistics-microservices
```

### 2. **Estrutura de Projeto Spring Initializr**

Cada serviço foi criado no **Spring Initializr** com as seguintes configurações:

| Serviço | Group | Artifact | Dependencies |
|---------|-------|----------|--------------|
| **eureka-server** | com.logistics | eureka-server | Eureka Server |
| **auth-service** | com.logistics | auth-service | Web, JPA, Security, Validation, PostgreSQL, Eureka Client |
| **orders-service** | com.logistics | orders-service | Web, JPA, Validation, RabbitMQ, PostgreSQL, Eureka Client |
| **tracking-service** | com.logistics | tracking-service | Web, JPA, Validation, RabbitMQ, PostgreSQL, Eureka Client |
| **api-gateway** | com.logistics | api-gateway | Gateway, Eureka Client, Actuator |

### 3. **Configurar Dependências Especiais**

**JWT no Auth Service** (`auth-service/pom.xml`):
```xml
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-api</artifactId>
    <version>0.11.5</version>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-impl</artifactId>
    <version>0.11.5</version>
    <scope>runtime</scope>
</dependency>
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt-jackson</artifactId>
    <version>0.11.5</version>
    <scope>runtime</scope>
</dependency>
```

## 🎮 Como Executar

### **Opção 1: Execução Automática (Recomendado)**

```powershell
# Início rápido - escolha interativa
.\scripts\quick-start.ps1

# Escolha a opção:
# 1) Local (Maven + Docker para DB)
# 2) Docker Compose (Tudo containerizado)
# 3) Apenas compilar
```

### **Opção 2: Execução Manual Passo a Passo**

```powershell
# 1. Compilar todos os serviços
.\scripts\build-all.ps1

# 2. Iniciar infraestrutura (PostgreSQL + RabbitMQ)
.\scripts\start-infrastructure.ps1

# 3. Executar todos os microsserviços
.\scripts\run-local.ps1
```


### **Ordem de Inicialização**

O sistema inicia automaticamente na seguinte ordem:
1. **PostgreSQL** e **RabbitMQ** (infraestrutura)
2. **Eureka Server** (service discovery)
3. **Auth Service** (autenticação)
4. **Orders Service** (pedidos)
5. **Tracking Service** (rastreamento)
6. **API Gateway** (roteamento)

## 📜 Scripts Disponíveis

### 🚀 **Scripts de Execução**

| Script | Descrição | Uso |
|--------|-----------|-----|
| `quick-start.ps1` | **Início rápido interativo** | Escolha como executar o sistema |
| `run-local.ps1` | **Execução local completa** | Inicia todos os serviços localmente |
| `docker-run.ps1` | **Execução com Docker** | Inicia tudo com Docker Compose |

### 🔨 **Scripts de Build**

| Script | Descrição | Comando |
|--------|-----------|---------|
| `build-all.ps1` | **Compilar todos os serviços** | `.\scripts\build-all.ps1` |
| `start-infrastructure.ps1` | **Construir imagens Docker** | `.\scripts\start-infrastructure.ps1` |

### 🧪 **Scripts de Teste**

| Script | Descrição | O que Testa |
|--------|-----------|-------------|
| `test-spring-boot-simple.ps1` | **Testes unitários Spring** | Controllers e Services |


### 🛑 **Scripts de Controle**

| Script | Descrição | Ação |
|--------|-----------|------|
| `stop-all.ps1` | **Parar tudo** | Para todos os serviços e containers |

## Teste das API´s com swagger

Após rodar um microserviço específico, basta conferir no log de run a porta que esta sendo utilizada. 
Acesse pelo link http://localhost:[PORTA]/swagger-ui/index.html#/

## 🧪 Testes

### **1. Testes de API (Recomendado)**

```powershell
# Teste completo das rotas HTTP
.\scripts\test-api-routes.ps1
```

**O que testa:**
- ✅ Health checks do sistema
- ✅ Registro e login de usuários
- ✅ Validação de tokens JWT
- ✅ CRUD de pedidos
- ✅ Cálculo de rotas
- ✅ Rastreamento GPS
- ✅ Histórico de localizações

### **2. Testes Unitários Spring Boot**

```powershell
# Testes dos controllers
.\scripts\test-spring-boot-simple.ps1

# Teste de um serviço específico
cd auth-service
mvn test
cd ..
```

### **3. Testes Manuais**

```powershell
# Teste rápido de conectividade
Invoke-RestMethod -Uri "http://localhost:8080/api/gateway/health"

# Verificar Eureka Dashboard
Start-Process "http://localhost:8761"
```

## 🔗 APIs e Endpoints

### **Base URL:** `http://localhost:8080`

### 🔐 **Autenticação**

| Método | Endpoint | Descrição | Body |
|--------|----------|-----------|------|
| `POST` | `/api/auth/register` | Registrar usuário | `{"email", "password", "userType", "firstName", "lastName"}` |
| `POST` | `/api/auth/login` | Login | `{"email", "password"}` |
| `POST` | `/api/auth/validate` | Validar token | `?token=JWT_TOKEN` |

### 📦 **Pedidos** (Requer Token)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `GET` | `/api/orders` | Listar todos os pedidos |
| `POST` | `/api/orders` | Criar novo pedido |
| `GET` | `/api/orders/{id}` | Buscar pedido por ID |
| `GET` | `/api/orders/customer/{id}` | Pedidos de um cliente |
| `GET` | `/api/orders/status/{status}` | Pedidos por status |
| `PUT` | `/api/orders/{id}/status` | Atualizar status |
| `PUT` | `/api/orders/{id}/assign-driver` | Atribuir motorista |
| `DELETE` | `/api/orders/{id}` | Cancelar pedido |

### 📍 **Rastreamento** (Requer Token)

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| `POST` | `/api/tracking/location` | Atualizar localização |
| `GET` | `/api/tracking/order/{id}/current` | Localização atual |
| `GET` | `/api/tracking/order/{id}/history` | Histórico de localizações |
| `GET` | `/api/tracking/driver/{id}/current` | Localização do motorista |
| `GET` | `/api/tracking/nearby` | Entregas próximas |

### **Exemplo de Uso:**

```powershell
# 1. Registrar usuário
$user = @{
    email = "customer@test.com"
    password = "123456"
    userType = "CUSTOMER"
    firstName = "João"
    lastName = "Silva"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/auth/register" -Method Post -Body $user -ContentType "application/json"

# 2. Fazer login
$login = @{
    email = "customer@test.com"
    password = "123456"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -Body $login -ContentType "application/json"
$token = $response.token

# 3. Criar pedido
$headers = @{ "Authorization" = "Bearer $token" }
$order = @{
    customerId = 1
    originAddress = "Centro, Belo Horizonte, MG"
    destinationAddress = "Savassi, Belo Horizonte, MG"
    cargoType = "Documentos"
    description = "Entrega importante"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8080/api/orders" -Method Post -Headers $headers -Body $order -ContentType "application/json"
```

## 📊 Monitoramento

### **URLs de Monitoramento:**

| Serviço | URL | Descrição |
|---------|-----|-----------|
| **API Gateway** | http://localhost:8080 | Entrada principal |
| **Eureka Dashboard** | http://localhost:8761 | Serviços registrados |
| **RabbitMQ Management** | http://localhost:15672 | Filas e mensagens (guest/guest) |

### **Health Checks:**

```powershell
# API Gateway
Invoke-RestMethod -Uri "http://localhost:8080/api/gateway/health"

# Eureka Server
Invoke-RestMethod -Uri "http://localhost:8761/actuator/health"
```




### **Status dos Containers:**

```powershell
# Status Docker
docker ps --filter "name=logistics"

# Logs dos containers
docker logs postgres-logistics
docker logs rabbitmq-logistics
```

## 🚨 Troubleshooting

### **Problemas Comuns e Soluções:**

#### **1. "Java não encontrado"**
```powershell
# Instalar OpenJDK 17+
# Configurar JAVA_HOME
# Adicionar ao PATH
```

#### **2. "Maven não encontrado"**
```powershell
# Baixar Apache Maven
# Configurar M2_HOME
# Adicionar bin ao PATH
```

#### **3. "Docker não está rodando"**
```powershell
# Iniciar Docker Desktop
# Verificar se serviços estão rodando:
docker version
```

#### **4. "Porta já em uso"**
```powershell
# Ver processo usando a porta
netstat -ano | findstr :8080

# Matar processo
taskkill /PID <PID> /F
```

#### **5. "Falha na conexão com PostgreSQL"**
```powershell
# Verificar se container está rodando
docker ps | findstr postgres

# Verificar logs
docker logs postgres-logistics

# Reiniciar container
docker restart postgres-logistics
```

#### **6. "Serviços não se registram no Eureka"**
```powershell
# Aguardar 30-60 segundos
# Verificar se Eureka está acessível
Invoke-WebRequest http://localhost:8761

# Verificar logs dos serviços
Get-Content logs\*.log | Select-String "eureka"
```

### **Reset Completo:**

```powershell
# Para e limpa tudo
.\scripts\stop-all.ps1


# Inicia do zero
.\scripts\quick-start.ps1
```




## 📁 Estrutura do Projeto

```
logistics-microservices/
├── eureka-server/                 # Service Discovery
│   ├── src/main/java/com/logistics/eureka/
│   │   └── EurekaServerApplication.java
│   ├── src/main/resources/
│   │   └── application.yml
│   ├── src/test/java/              # Testes unitários
│   ├── pom.xml
│   └── Dockerfile
├── auth-service/                   # Autenticação JWT
│   ├── src/main/java/com/logistics/auth/
│   │   ├── AuthServiceApplication.java
│   │   ├── model/User.java
│   │   ├── dto/                    # LoginRequest, RegisterRequest, AuthResponse
│   │   ├── repository/UserRepository.java
│   │   ├── service/                # JwtService, AuthService
│   │   ├── controller/AuthController.java
│   │   ├── config/SecurityConfig.java
│   │   └── Dockerfile
│   ├── src/test/java/              # Testes de controller
│   └── pom.xml (com dependências JWT)
├── orders-service/                 # CRUD de Pedidos + Rotas
│   ├── src/main/java/com/logistics/orders/
│   │   ├── OrdersServiceApplication.java
│   │   ├── model/Order.java
│   │   ├── dto/                    # CreateOrderRequest, RouteResponse
│   │   ├── repository/OrderRepository.java
│   │   ├── service/                # OrderService, RouteService
│   │   ├── controller/OrderController.java
│   │   ├── config/RabbitConfig.java
│   │   └──DockerFile
│   └── src/test/java/
├── tracking-service/               # Rastreamento GPS
│   ├── src/main/java/com/logistics/tracking/
│   │   ├── TrackingServiceApplication.java
│   │   ├── model/Location.java
│   │   ├── dto/LocationUpdateRequest.java
│   │   ├── repository/LocationRepository.java
│   │   ├── service/                # TrackingService, GeoService
│   │   ├── controller/TrackingController.java
│   │   ├── config/RabbitConfig.java
│   │   └── DockerFile
│   └── src/test/java/
├── api-gateway/                    # Roteamento + Auth Centralizada
│   ├── src/main/java/com/logistics/gateway/
│   │   ├── ApiGatewayApplication.java
│   │   ├── config/                 # GatewayConfig, WebClientConfig
│   │   ├── filter/AuthenticationGatewayFilterFactory.java
│   │   ├── controller/GatewayController.java
│   │   └── DockerFile
│   └── src/test/java/
├── scripts/                        # Scripts de automação
│   ├── quick-start.ps1             # Início rápido
│   ├── build-all.ps1               # Compilação
│   ├── run-local.ps1               # Execução local
│   ├── docker-run.ps1              # Execução Docker
│   ├── test-spring-boot.ps1        # Testes 
│   ├── stop-all.ps1                # Parar tudo
├── logs/                           # Logs dos serviços (criado automaticamente)
│   ├── eureka.log
│   ├── auth.log
│   ├── orders.log
│   ├── tracking.log
│   └── gateway.log
├── docker-compose.yml              # Container orchestration
└── README.md                       # Esta documentação
```
 



## 📞 Suporte

Para suporte ou dúvidas:

1. **Verifique o troubleshooting** nesta documentação
2. **Execute o diagnóstico:** `.\scripts\debug-connection.ps1`
3. **Consulte os logs:** pasta `logs/`

---


### 🚀 **Quick Start Summary:**

```powershell
# Clone e execute:
git clone https://github.com/Druitti/app_mobile.git
cd backend
cd logistics-microservices
.\scripts\quick-start.ps1

# Aguarde alguns minutos e acesse:
# 🌐 http://localhost:8080 (API Gateway)
# 📡 http://localhost:8761 (Eureka Dashboard)  
# 🐰 http://localhost:15672 (RabbitMQ Management)
```

**Sistema pronto para uso em poucos minutos!** 🎉
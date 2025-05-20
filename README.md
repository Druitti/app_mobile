# App de Rastreamento de Entregas

Aplicativo móvel desenvolvido em Flutter para rastreamento de entregas, com interfaces para clientes e motoristas.

## Funcionalidades

### Interface do Cliente
- Rastreamento em tempo real das encomendas
- Histórico de pedidos
- Notificações push sobre status da entrega

### Interface do Motorista
- Visualização e aceitação de entregas
- Navegação e otimização de rotas
- Atualização do status da entrega com foto da assinatura

### Recursos Técnicos
- Armazenamento local com SQLite
- Sincronização com backend
- Geolocalização para rastreamento
- Notificações push
- Tema claro/escuro
- Modo offline

## Requisitos

- Flutter SDK >= 3.4.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code
- Dispositivo Android/iOS ou emulador

## Instalação

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/app-entregas.git
cd app-entregas
```

2. Instale as dependências:
```bash
flutter pub get
```

3. Configure as variáveis de ambiente:
- Crie um arquivo `.env` na raiz do projeto
- Adicione suas chaves de API:
```
GOOGLE_MAPS_API_KEY=sua_chave_aqui
FIREBASE_SERVER_KEY=sua_chave_aqui
```

4. Execute o aplicativo:
```bash
flutter run
```

## Configuração do Firebase

1. Crie um projeto no Firebase Console
2. Adicione um aplicativo Android/iOS
3. Baixe o arquivo de configuração:
   - Android: `google-services.json` em `android/app/`
   - iOS: `GoogleService-Info.plist` em `ios/Runner/`

## Estrutura do Projeto

```
lib/
  ├── models/         # Classes de modelo
  ├── screens/        # Telas do aplicativo
  │   ├── cliente/    # Interface do cliente
  │   ├── motorista/  # Interface do motorista
  │   └── configuracoes/
  ├── services/       # Serviços (API, banco de dados, etc)
  ├── widgets/        # Widgets reutilizáveis
  └── main.dart       # Ponto de entrada
```

## Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## Licença

- Atualização do status da entrega com o uso da câmera
3. Armazenamento local de dados (SQLite) para funcionamento offline
4. Sincronização de dados com o backend quando online
5. Geolocalização para rastreamento de veículos e cálculo de rotas
## Requisitos Obrigatórios
A aplicação deve conter os seguintes elementos:
### Uso da Câmera e GPS
- O Motorista deve ser capaz de tirar foto da entrega assinada pelo cliente.
- A localização atual do usuário deve ser capturada no momento da foto.
- Deverá ser utilizado o serviço de Mapa e GPS do motorista para rastrear a
entrega.
### Armazenamento com SQLite
- O sistema deve armazenar localmente dados da entrega e última localização.
- Deve haver uma tela que lista os pedidos entreues.
### Uso de Shared Preferences
- O aplicativo deve permitir salvar configurações do usuário, como tema
claro/escuro e preferências de exibição.
- As configurações devem ser persistentes entre sessões.
### Notificações Push
- O sistema do cliente deve ter permissão para exibir notificações push do status
da entrega.
### Tratamento de Erros
- Deve implementar estratégias de tratamento de erro, incluindo:
- Tratamento de falhas na requisição da API (ex.: falta de internet, erro no
servidor).
- Tratamento de permissões negadas pelo usuário para câmera ou localização.
- Tratamento de falhas no armazenamento de dados (SQLite e Shared Preferences).
## Requisitos Técnicos
- O projeto deve ser desenvolvido em **Flutter**.
- Deve utilizar **Dart** como linguagem principal.
- As bibliotecas recomendadas incluem:
- `http` para consumo de APIs.
- `camera` para uso da câmera.
- `shared_preferences` para armazenamento de configurações.
- `sqflite` para banco de dados SQLite.
- `geolocator` e `google_maps_flutter` para uso do GPS.
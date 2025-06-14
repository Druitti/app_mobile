import 'package:app_mobile/common/utils/constants.dart';
import 'package:app_mobile/debug/database_service_debug.dart';
import 'package:app_mobile/main.dart';
import 'package:app_mobile/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  bool _isDarkMode = false;
  bool _notificacoesAtivas = true;
  bool _rastreamentoAtivo = true;

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  Future<void> _carregarConfiguracoes() async {
    final isDarkMode = await _databaseService.buscarConfiguracao('isDarkMode');
    final notificacoes = await _databaseService.buscarConfiguracao('notificacoes');
    final rastreamento = await _databaseService.buscarConfiguracao('rastreamento');

    setState(() {
      _isDarkMode = isDarkMode == 'true';
      _notificacoesAtivas = notificacoes != 'false';
      _rastreamentoAtivo = rastreamento != 'false';
    });
  }

  Future<void> _salvarConfiguracao(String chave, String valor) async {
    await _databaseService.salvarConfiguracao(chave, valor);
  }

  @override
  Widget build(BuildContext context) {
    final isMotorista = context.watch<UserTypeProvider>().isMotorista;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
          // Seção de Perfil
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                isMotorista ? Icons.drive_eta : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(isMotorista ? 'Perfil de Motorista' : 'Perfil de Cliente'),
            subtitle: Text(isMotorista 
              ? 'Configurações específicas para motoristas' 
              : 'Configurações específicas para clientes'
            ),
          ),
          const Divider(),
          
          // Configurações gerais
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Configurações Gerais',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          SwitchListTile(
            title: const Text('Tema Escuro'),
            subtitle: const Text('Ativar modo escuro'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
              _salvarConfiguracao('isDarkMode', value.toString());
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
          
          const Divider(),
          
          SwitchListTile(
            title: const Text('Notificações'),
            subtitle: const Text('Receber notificações de status'),
            value: _notificacoesAtivas,
            onChanged: (bool value) {
              setState(() {
                _notificacoesAtivas = value;
              });
              _salvarConfiguracao('notificacoes', value.toString());
            },
          ),
          
          // Configurações específicas para motoristas ou clientes
          if (isMotorista) ...[
            const Divider(),
            SwitchListTile(
              title: const Text('Compartilhar Localização'),
              subtitle: const Text('Permitir compartilhamento de localização em tempo real'),
              value: _rastreamentoAtivo,
              onChanged: (bool value) {
                setState(() {
                  _rastreamentoAtivo = value;
                });
                _salvarConfiguracao('rastreamento', value.toString());
              },
            ),
          ] else ...[
            const Divider(),
            SwitchListTile(
              title: const Text('Rastreamento'),
              subtitle: const Text('Ativar rastreamento em tempo real'),
              value: _rastreamentoAtivo,
              onChanged: (bool value) {
                setState(() {
                  _rastreamentoAtivo = value;
                });
                _salvarConfiguracao('rastreamento', value.toString());
              },
            ),
          ],
          
          const Divider(),
          
          // Opções avançadas
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Opções Avançadas',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          ListTile(
            title: const Text('Alternar Tipo de Usuário'),
            subtitle: const Text('Mudar entre cliente e motorista'),
            trailing: const Icon(Icons.sync),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Alternar Tipo de Usuário'),
                  content: Text(
                    isMotorista 
                      ? 'Deseja mudar para o modo Cliente?' 
                      : 'Deseja mudar para o modo Motorista?'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<UserTypeProvider>().toggleUserType();
                        // Navegar para a tela home apropriada
                        Navigator.pushReplacementNamed(
                          context, 
                          context.read<UserTypeProvider>().isMotorista 
                            ? '/driver_home' 
                            : '/client_home'
                        );
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Divider(),
          
          ListTile(
            title: const Text('Limpar Dados'),
            subtitle: const Text('Remover todos os dados locais'),
            trailing: const Icon(Icons.delete_forever),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Limpar Dados'),
                  content: const Text(
                    'Tem certeza que deseja remover todos os dados locais? Esta ação não pode ser desfeita.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Implementar limpeza de dados
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dados locais removidos')),
                        );
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          const Divider(),
          
          // Sobre
          ListTile(
            title: const Text('Sobre'),
            subtitle: const Text('Versão 1.0.0'),
            trailing: const Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: appTitle,
                applicationVersion: '1.0.0',
                applicationIcon: const FlutterLogo(size: 64),
                children: const [
                  Text(
                    'Aplicativo de rastreamento de entregas desenvolvido em Flutter.',
                  ),
                ],
              );
            },
          ),
          
          // Logout
          const Divider(),
         
          
          
          ListTile(
            title: const Text('Sair do Aplicativo'),
            trailing: const Icon(Icons.exit_to_app),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sair'),
                  content: const Text('Deseja sair do aplicativo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      child: const Text('Confirmar'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
           ListTile(
        title: const Text('Diagnóstico do Banco de Dados'),
        subtitle: const Text('Ferramentas para desenvolvedores'),
        leading: const Icon(Icons.storage),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DatabaseDiagnosticScreen()),
          );
        },
      ),
        ],
      ),
    );
  }
  }
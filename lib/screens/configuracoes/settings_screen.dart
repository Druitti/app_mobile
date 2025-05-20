import 'package:app_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        children: [
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
            title: const Text('Sobre'),
            subtitle: const Text('Versão 1.0.0'),
            trailing: const Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'App de Entregas',
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
        ],
      ),
    );
  }
} 
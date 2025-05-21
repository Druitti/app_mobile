import 'package:app_mobile/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';



class DatabaseDiagnosticScreen extends StatelessWidget {
  const DatabaseDiagnosticScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico do Banco de Dados')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ferramentas de Diagnóstico e Reparo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().diagnosticarBancoDados();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Diagnóstico concluído. Verifique o console.')),
                );
              },
              child: const Text('Diagnosticar Banco de Dados'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().corrigirBancoDados();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tentativa de correção concluída. Verifique o console.')),
                );
              },
              child: const Text('Tentar Corrigir Banco de Dados'),
            ),
            const SizedBox(height: 10),
            
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                // Mostrar diálogo de confirmação
                bool confirmacao = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Atenção!'),
                    content: const Text(
                      'Esta ação irá apagar TODOS os dados do banco. '
                      'Esta operação não pode ser desfeita!\n\n'
                      'Tem certeza que deseja continuar?'
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      TextButton(
                        child: const Text('Sim, recriar banco'),
                        onPressed: () => Navigator.of(context).pop(true),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (confirmacao) {
                  await DatabaseService().recriaBancoDados();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Banco de dados recriado com sucesso!')),
                    );
                  }
                }
              },
              child: const Text('RECRIAR BANCO DE DADOS'),
            ),
            
            const SizedBox(height: 30),
            const Text(
              'Informações do Banco',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            FutureBuilder<String>(
              future: getDatabasesPath().then((path) => join(path, 'entregas.db')),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                  return Text('Caminho do banco: ${snapshot.data}');
                }
                return const Text('Carregando caminho do banco...');
              },
            ),
          ],
        ),
      ),
    );
  }
}
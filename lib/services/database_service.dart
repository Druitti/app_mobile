import 'package:app_mobile/services/notification_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
   Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'entregas.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

 Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Verificar se a coluna descricao já existe
      var tableInfo = await db.rawQuery("PRAGMA table_info(entregas)");
      bool hasDescricao = false;
      
      for (var column in tableInfo) {
        if (column['name'] == 'descricao') {
          hasDescricao = true;
          break;
        }
      }
      
      // Adicionar a coluna apenas se ela não existir
      if (!hasDescricao) {
        try {
          await db.execute('ALTER TABLE entregas ADD COLUMN descricao TEXT');
          print("Coluna 'descricao' adicionada com sucesso");
        } catch (e) {
          print("Erro ao adicionar coluna 'descricao': $e");
        }
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de Entregas
    await db.execute('''
      CREATE TABLE entregas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT,
        descricao TEXT,
        status TEXT,
        data_criacao TEXT,
        data_atualizacao TEXT,
        latitude REAL,
        longitude REAL,
        foto_assinatura TEXT,
        observacoes TEXT,
        endereco TEXT
      )
    ''');

    // Tabela de Histórico de Entregas (adicionado)
    await db.execute('''
      CREATE TABLE historico_entregas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entrega_id INTEGER,
        status_anterior TEXT,
        status_novo TEXT,
        data_mudanca TEXT NOT NULL,
        FOREIGN KEY (entrega_id) REFERENCES entregas (id)
      )
    ''');

    // Tabela de Configurações
    await db.execute('''
      CREATE TABLE configuracoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chave TEXT NOT NULL UNIQUE,
        valor TEXT NOT NULL
      )
    ''');
  }
  Future<void> diagnosticarBancoDados() async {
  try {
    final db = await database;
    print("\n======= DIAGNÓSTICO DO BANCO DE DADOS =======");
    
    // Verificar quais tabelas existem
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    print("Tabelas existentes: ${tables.map((t) => t['name']).toList()}");
    
    // Se a tabela entregas existir, verificar sua estrutura
    if (tables.any((t) => t['name'] == 'entregas')) {
      var colunas = await db.rawQuery("PRAGMA table_info(entregas)");
      print("\nColunas da tabela entregas:");
      colunas.forEach((col) => print("${col['cid']}: ${col['name']} (${col['type']})"));
      
      // Verificar especificamente se a coluna 'descricao' existe
      bool temDescricao = colunas.any((col) => col['name'] == 'descricao');
      print("\nColuna 'descricao' existe? $temDescricao");
    }
    
    print("======= FIM DO DIAGNÓSTICO =======\n");
  } catch (e) {
    print("Erro durante o diagnóstico: $e");
  }
}

// Para corrigir o banco de dados adicionando a coluna faltante
Future<void> corrigirBancoDados() async {
  try {
    final db = await database;
    print("\n======= TENTANDO CORRIGIR O BANCO DE DADOS =======");
    
    // Verificar se a tabela entregas existe
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='entregas'");
    if (tables.isEmpty) {
      print("Tabela entregas não encontrada! Criando tabela...");
      await _onCreate(db, 1);
      print("Tabela entregas criada com sucesso!");
      return;
    }
    
    // Verificar se a coluna descricao já existe
    var colunas = await db.rawQuery("PRAGMA table_info(entregas)");
    bool temDescricao = colunas.any((col) => col['name'] == 'descricao');
    
    if (!temDescricao) {
      print("Coluna 'descricao' não existe. Adicionando...");
      try {
        await db.execute('ALTER TABLE entregas ADD COLUMN descricao TEXT');
        print("Coluna 'descricao' adicionada com sucesso!");
      } catch (e) {
        print("Erro ao adicionar coluna: $e");
      }
    } else {
      print("Coluna 'descricao' já existe. Não é necessário corrigir.");
    }
    
    print("======= FIM DA CORREÇÃO =======\n");
  } catch (e) {
    print("Erro durante a correção: $e");
  }
}

// Para recriar o banco de dados do zero (cuidado: perde todos os dados)
Future<void> recriaBancoDados() async {
  try {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    String path = join(await getDatabasesPath(), 'entregas.db');
    print("Apagando banco de dados em: $path");
    await deleteDatabase(path);
    print("Banco de dados apagado com sucesso!");
    
    // Força a recriação do banco ao acessá-lo novamente
    await database;
    print("Banco de dados recriado com sucesso!");
  } catch (e) {
    print("Erro ao recriar banco de dados: $e");
  }
}

  // O restante do seu código permanece igual...
  // Métodos para Entregas
  Future<int> inserirEntrega(Map<String, dynamic> entrega) async {
    final db = await database;
    
    // Garantir que todos os campos obrigatórios estejam presentes
    final Map<String, dynamic> entregaCompleta = {
      'codigo': entrega['codigo'] ?? 'ENT_${DateTime.now().millisecondsSinceEpoch}',
      'descricao': entrega['descricao'] ?? entrega['description'] ?? 'Nova Entrega',
      'status': entrega['status'] ?? 'Pendente',
      'data_criacao': entrega['data_criacao'] ?? DateTime.now().toIso8601String(),
      'data_atualizacao': entrega['data_atualizacao'] ?? DateTime.now().toIso8601String(),
      'latitude': entrega['latitude'],
      'longitude': entrega['longitude'],
      'foto_assinatura': entrega['foto_assinatura'] ?? entrega['photoPath'],
      'observacoes': entrega['observacoes'] ?? '',
      'endereco': entrega['endereco'] ?? entrega['deliveryAddress'] ?? 'Endereço não especificado',
    };
    
    return await db.insert('entregas', entregaCompleta);
  }

// Método para atualizar uma entrega existente
Future<int> atualizarEntrega(String codigo, Map<String, dynamic> novosDados) async {
  final db = await database;
  
  // Buscar entrega existente
  final List<Map<String, dynamic>> entregas = await db.query(
    'entregas',
    where: 'codigo = ?',
    whereArgs: [codigo],
    limit: 1,
  );
  
  if (entregas.isEmpty) {
    // Entrega não encontrada
    return 0;
  }
  
  // ID da entrega no banco
  final int id = entregas.first['id'];
  
  // Atualizar data de atualização
  novosDados['data_atualizacao'] = DateTime.now().toIso8601String();
  
  // Se estiver alterando o status, registrar no histórico
  final String statusAtual = entregas.first['status'];
  final String? novoStatus = novosDados['status'];
  
  if (novoStatus != null && novoStatus != statusAtual) {
    // Registrar mudança de status no histórico
    await db.insert('historico_entregas', {
      'entrega_id': id,
      'status_anterior': statusAtual,
      'status_novo': novoStatus,
      'data_mudanca': DateTime.now().toIso8601String(),
    });
     await PushNotificationService().notifyOrderStatusChange(
      orderId: codigo,
      status: novoStatus,
    );
  }
  
  
  // Atualizar entrega
  return await db.update(
    'entregas',
    novosDados,
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Método para listar entregas com formatação para o app 
Future<List<Map<String, dynamic>>> listarEntregasParaApp() async {
  final db = await database;
  final List<Map<String, dynamic>> entregas = await db.query('entregas', orderBy: 'data_criacao DESC');
  
  // Converter para formato esperado pelo app
  return entregas.map((entrega) {
    return {
      'id': entrega['codigo'],
      'description': entrega['descricao'] ?? 'Entrega #${entrega['codigo']}',
      'status': entrega['status'],
      'estimatedDelivery': entrega['data_atualizacao'],
      'driverName': 'Motorista Designado', // Poderíamos buscar o motorista no banco futuro
      'deliveryAddress': entrega['endereco'],
      'latitude': entrega['latitude'],
      'longitude': entrega['longitude'],
      'photoPath': entrega['foto_assinatura'],
      'timestamp': entrega['data_criacao'],
      'observacoes': entrega['observacoes'],
    };
  }).toList();
}

// Método para buscar o histórico completo de uma entrega
Future<List<Map<String, dynamic>>> buscarHistoricoEntrega(String codigo) async {
  final db = await database;
  
  // Primeiro buscar a entrega para obter o ID
  final List<Map<String, dynamic>> entregas = await db.query(
    'entregas',
    where: 'codigo = ?',
    whereArgs: [codigo],
    limit: 1,
  );
  
  if (entregas.isEmpty) {
    return [];
  }
  
  final int entregaId = entregas.first['id'];
  
  // Buscar histórico relacionado à entrega
  return await db.query(
    'historico_entregas',
    where: 'entrega_id = ?',
    whereArgs: [entregaId],
    orderBy: 'data_mudanca DESC',
  );
}

  Future<List<Map<String, dynamic>>> listarEntregas() async {
    final db = await database;
    return await db.query('entregas', orderBy: 'data_criacao DESC');
  }
    Future<List<Map<String, dynamic>>> listarHistoricoEntregas() async {
    final db = await database;
    return await db.query(
      'historico_entregas', 
      orderBy: 'data_mudanca DESC'
    );
  }

 Future<Map<String, dynamic>?> buscarEntrega(String id) async {
  try {
    final db = await database;
    
    // Buscar primeiro nas entregas ativas
    final List<Map<String, dynamic>> entregas = await db.query(
      'entregas',
      where: 'codigo = ? OR id = ?',  // Busca por código ou id
      whereArgs: [id, id],
      limit: 1,
    );
    
    if (entregas.isNotEmpty) {
      return _converterParaFormatoDaAPI(entregas.first);
    }
    
    // Se não encontrar nas entregas ativas, buscar no histórico
    final List<Map<String, dynamic>> historico = await db.query(
      'historico_entregas',
      where: 'entrega_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (historico.isNotEmpty) {
      // Buscar a entrega relacionada ao histórico
      final List<Map<String, dynamic>> entregaRelacionada = await db.query(
        'entregas',
        where: 'id = ?',
        whereArgs: [historico.first['entrega_id']],
        limit: 1,
      );
      
      if (entregaRelacionada.isNotEmpty) {
        return _converterParaFormatoDaAPI(entregaRelacionada.first);
      }
    }
    
    // Se não encontrar nada, fornecer dados simulados
    return _dadosSimulados(id);
  } catch (e) {
    print('Erro ao buscar entrega: $e');
    // Retornar dados simulados em caso de erro
    return _dadosSimulados(id);
  }
}

// Converte dados do banco em formato esperado pela API/tela
Map<String, dynamic> _converterParaFormatoDaAPI(Map<String, dynamic> dadosBanco) {
  return {
    'id': dadosBanco['codigo'] ?? dadosBanco['id'].toString(),
    'description': 'Entrega #${dadosBanco['codigo'] ?? dadosBanco['id']}',
    'status': dadosBanco['status'] ?? 'Em trânsito',
    'estimatedDelivery': dadosBanco['data_atualizacao'] ?? DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'driverName': 'Motorista Designado',
    'latitude': dadosBanco['latitude'],
    'longitude': dadosBanco['longitude'],
    'endereco': 'Endereço da entrega',
    'observacoes': dadosBanco['observacoes'],
  };
}

// Dados simulados para quando não encontrar a entrega
Map<String, dynamic> _dadosSimulados(String id) {
  return {
    'id': id,
    'description': 'Entrega #$id',
    'status': 'Em Trânsito',
    'estimatedDelivery': DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
    'driverName': 'João Motorista',
    'latitude': -23.550,
    'longitude': -46.633,
    'endereco': 'Av. Paulista, 1000 - São Paulo',
    'observacoes': 'Entregar na portaria.',
  };
}

  // Método para atualizar status de uma entrega
  Future<bool> atualizarStatusEntrega(String id, String novoStatus) async {
    // Em um app real, você enviaria esta atualização para o servidor
    await Future.delayed(const Duration(milliseconds: 500));
    return true; // Simula sucesso
  }


 Future<int> deletarEntrega(String codigo) async {
  final db = await database;
  
  // Primeiro buscar o ID interno da entrega pelo código
  final List<Map<String, dynamic>> entregas = await db.query(
    'entregas',
    columns: ['id'],
    where: 'codigo = ?',
    whereArgs: [codigo],
    limit: 1,
  );
  
  // Se não encontrar a entrega, retorna 0 (nenhuma linha afetada)
  if (entregas.isEmpty) {
    print('Entrega com código $codigo não encontrada');
    return 0;
  }
  
  // Pega o ID interno
  final int id = entregas.first['id'];
  
  // Agora exclui usando o ID interno
  return await db.delete(
    'entregas',
    where: 'id = ?',
    whereArgs: [id],
  );
}

  // Métodos para Configurações
  Future<void> salvarConfiguracao(String chave, String valor) async {
    final db = await database;
    await db.insert(
      'configuracoes',
      {'chave': chave, 'valor': valor},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> buscarConfiguracao(String chave) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'configuracoes',
      where: 'chave = ?',
      whereArgs: [chave],
    );
    if (maps.isNotEmpty) {
      return maps.first['valor'] as String;
    }
    return null;
  }
} 
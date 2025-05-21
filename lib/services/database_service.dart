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

  Future<void> _onCreate(Database db, int version) async {
  // Tabela de Entregas
  await db.execute('''
    CREATE TABLE entregas(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      codigo TEXT NOT NULL,
      status TEXT NOT NULL,
      data_criacao TEXT NOT NULL,
      data_atualizacao TEXT NOT NULL,
      latitude REAL,
      longitude REAL,
      foto_assinatura TEXT,
      observacoes TEXT
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
  // Métodos para Entregas
  Future<int> inserirEntrega(Map<String, dynamic> entrega) async {
    final db = await database;
    return await db.insert('entregas', entrega);
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


  Future<int> deletarEntrega(int id) async {
    final db = await database;
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
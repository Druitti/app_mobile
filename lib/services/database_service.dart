import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

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

  Future<Map<String, dynamic>?> buscarEntrega(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'entregas',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  Future<int> atualizarEntrega(Map<String, dynamic> entrega) async {
    final db = await database;
    return await db.update(
      'entregas',
      entrega,
      where: 'id = ?',
      whereArgs: [entrega['id']],
    );
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
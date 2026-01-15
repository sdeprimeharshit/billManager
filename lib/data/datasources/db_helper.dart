import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  static Database? _database;

  factory DBHelper() => _instance;

  DBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final documentsDirectory = await getApplicationSupportDirectory();
    final path = join(documentsDirectory.path, 'bill_manager.db');

    return await openDatabase(
      path,
      version: 4, // Upgraded to version 4
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE invoice_items ADD COLUMN item_name TEXT');
          await db.execute('ALTER TABLE invoice_items ADD COLUMN hsn TEXT');
        }
        if (oldVersion < 3) {
          // Check if status column exists before adding
          var tableInfo = await db.rawQuery('PRAGMA table_info(invoices)');
          bool statusExists = tableInfo.any((column) => column['name'] == 'status');
          if (!statusExists) {
            await db.execute('ALTER TABLE invoices ADD COLUMN status TEXT DEFAULT "Active"');
          }
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE deleted_invoice_numbers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_number TEXT NOT NULL UNIQUE,
              deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        gstin TEXT,
        phone TEXT,
        email TEXT,
        bank_details TEXT,
        state TEXT,
        state_code TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        gstin TEXT,
        phone TEXT,
        email TEXT,
        state TEXT,
        state_code TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hsn TEXT,
        unit TEXT,
        price REAL,
        gst_rate REAL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        date TEXT NOT NULL,
        customer_id INTEGER,
        total_amount REAL,
        taxable_amount REAL,
        total_gst REAL,
        is_inter_state INTEGER,
        notes TEXT,
        status TEXT DEFAULT "Active",
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        item_id INTEGER,
        item_name TEXT,
        hsn TEXT,
        quantity REAL,
        price REAL,
        gst_rate REAL,
        gst_amount REAL,
        total REAL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (item_id) REFERENCES items (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tax_breakups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER,
        gst_rate REAL,
        taxable_value REAL,
        cgst REAL,
        sgst REAL,
        igst REAL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE deleted_invoice_numbers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }
}

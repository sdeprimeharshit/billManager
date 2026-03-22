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
      version: 8, // Upgraded to version 8 for Default Terms
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnSafely(db, 'invoice_items', 'item_name', 'TEXT');
          await _addColumnSafely(db, 'invoice_items', 'hsn', 'TEXT');
        }
        if (oldVersion < 3) {
          await _addColumnSafely(db, 'invoices', 'status', 'TEXT DEFAULT "draft"');
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS deleted_invoice_numbers (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_number TEXT NOT NULL UNIQUE,
              deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');
        }
        if (oldVersion < 5) {
          await db.execute("UPDATE invoices SET status = 'draft' WHERE status = 'Active'");
        }
        if (oldVersion < 6) {
          await _addColumnSafely(db, 'invoices', 'shipping_name', 'TEXT');
          await _addColumnSafely(db, 'invoices', 'shipping_address', 'TEXT');
          await _addColumnSafely(db, 'invoices', 'shipping_gstin', 'TEXT');
          await _addColumnSafely(db, 'invoices', 'is_same_as_billing', 'INTEGER DEFAULT 1');
        }
        if (oldVersion < 7) {
          await _addColumnSafely(db, 'invoices', 'transporter_name', 'TEXT');
          await _addColumnSafely(db, 'invoices', 'vehicle_number', 'TEXT');
          await _addColumnSafely(db, 'invoices', 'gr_number', 'TEXT');
          await _addColumnSafely(db, 'invoices', 'eway_bill_number', 'TEXT');
        }
        if (oldVersion < 8) {
          await _addColumnSafely(db, 'company_profile', 'default_terms', 'TEXT');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Helper to add a column only if it doesn't already exist
  Future<void> _addColumnSafely(Database db, String tableName, String columnName, String type) async {
    var tableInfo = await db.rawQuery('PRAGMA table_info($tableName)');
    bool exists = tableInfo.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute('ALTER TABLE $tableName ADD COLUMN $columnName $type');
    }
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
        state_code TEXT,
        default_terms TEXT
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
        status TEXT DEFAULT "draft",
        shipping_name TEXT,
        shipping_address TEXT,
        shipping_gstin TEXT,
        is_same_as_billing INTEGER DEFAULT 1,
        transporter_name TEXT,
        vehicle_number TEXT,
        gr_number TEXT,
        eway_bill_number TEXT,
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
      CREATE TABLE IF NOT EXISTS deleted_invoice_numbers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }
}

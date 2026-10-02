import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // Initialize SQLite for Windows
    sqfliteFfiInit();

    final databaseFactory = databaseFactoryFfi;

    final databasePath = await databaseFactory.getDatabasesPath();
    final path = join(databasePath, 'small_business.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,

        onCreate: (db, version) async {
          await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

          await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        customer_id INTEGER NOT NULL,
        invoice_date TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        tax_percent REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        grand_total REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'Draft',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

          await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL
      )
    ''');
        },

        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
        CREATE TABLE invoices (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_number TEXT NOT NULL UNIQUE,
          customer_id INTEGER NOT NULL,
          invoice_date TEXT NOT NULL,
          subtotal REAL NOT NULL,
          discount REAL NOT NULL DEFAULT 0,
          tax_percent REAL NOT NULL DEFAULT 0,
          tax_amount REAL NOT NULL DEFAULT 0,
          grand_total REAL NOT NULL,
          status TEXT NOT NULL DEFAULT 'Draft',
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');

            await db.execute('''
        CREATE TABLE invoice_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          invoice_id INTEGER NOT NULL,
          description TEXT NOT NULL,
          quantity REAL NOT NULL,
          unit_price REAL NOT NULL,
          total REAL NOT NULL
        )
      ''');
          }

          if (oldVersion < 3) {
            await db.execute('''
    CREATE TABLE payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_id INTEGER NOT NULL,
      amount REAL NOT NULL,
      payment_date TEXT NOT NULL,
      payment_method TEXT NOT NULL,
      note TEXT,
      created_at TEXT NOT NULL
    )
  ''');
          }
        },
      ),
    );
  }

  // Add customer
  static Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;

    return await db.insert('customers', customer);
  }

  // Get all customers
  static Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;

    return await db.query('customers', orderBy: 'id DESC');
  }

  // Update customer
  static Future<int> updateCustomer(
    int id,
    Map<String, dynamic> customer,
  ) async {
    final db = await database;

    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete customer
  static Future<int> deleteCustomer(int id) async {
    final db = await database;

    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // Update only the status of an existing invoice
  static Future<void> updateInvoiceStatus(int invoiceId, String status) async {
    final db = await database;

    await db.update(
      'invoices',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  // Check if phone number already exists
  static Future<bool> customerPhoneExists(
    String phone, {
    int? excludeId,
  }) async {
    final db = await database;

    String where = 'phone = ?';
    List<Object?> whereArgs = [phone];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Check if email already exists
  static Future<bool> customerEmailExists(
    String email, {
    int? excludeId,
  }) async {
    final db = await database;

    String where = 'email = ?';
    List<Object?> whereArgs = [email];

    if (excludeId != null) {
      where += ' AND id != ?';
      whereArgs.add(excludeId);
    }

    final result = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return result.isNotEmpty;
  }

  // Insert invoice
  static Future<int> insertInvoice(Map<String, dynamic> invoice) async {
    final db = await database;

    return await db.insert('invoices', invoice);
  }

  // Insert invoice item
  static Future<int> insertInvoiceItem(Map<String, dynamic> item) async {
    final db = await database;

    return await db.insert('invoice_items', item);
  }

  // Get all invoices
  static Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT
      invoices.*,
      customers.name AS customer_name,
      customers.phone AS customer_phone
    FROM invoices
    LEFT JOIN customers
      ON invoices.customer_id = customers.id
    ORDER BY invoices.id DESC
  ''');
  }

  // Get invoice items
  static Future<List<Map<String, dynamic>>> getInvoiceItems(
    int invoiceId,
  ) async {
    final db = await database;

    return await db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
  }

  // Save invoice and invoice items as one transaction
  static Future<int> saveInvoiceWithItems({
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Insert invoice
      final invoiceId = await txn.insert('invoices', invoice);

      // Insert invoice items
      for (final item in items) {
        await txn.insert('invoice_items', {...item, 'invoice_id': invoiceId});
      }

      return invoiceId;
    });
  }

  //delete invoice
  static Future<void> deleteInvoice(int invoiceId) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      await txn.delete('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    });
  }

  //update invoice

  static Future<void> updateInvoiceWithItems({
    required int invoiceId,
    required Map<String, dynamic> invoice,
    required List<Map<String, dynamic>> items,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.update(
        'invoices',
        invoice,
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      await txn.delete(
        'invoice_items',
        where: 'invoice_id = ?',
        whereArgs: [invoiceId],
      );

      for (final item in items) {
        await txn.insert('invoice_items', {...item, 'invoice_id': invoiceId});
      }
    });
  }

  // Add a new payment for an invoice
  static Future<int> insertPayment(Map<String, dynamic> payment) async {
    final db = await database;

    return await db.insert('payments', payment);
  }

  // Get all payments belonging to one invoice
  static Future<List<Map<String, dynamic>>> getInvoicePayments(
    int invoiceId,
  ) async {
    final db = await database;

    return await db.query(
      'payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'payment_date DESC, id DESC',
    );
  }

  // Get the total amount already paid for an invoice
  static Future<double> getInvoicePaidAmount(int invoiceId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(amount), 0) AS total_paid
    FROM payments
    WHERE invoice_id = ?
  ''',
      [invoiceId],
    );

    return (result.first['total_paid'] as num).toDouble();
  }

  // Delete a payment
  static Future<void> deletePayment(int paymentId) async {
    final db = await database;

    await db.delete('payments', where: 'id = ?', whereArgs: [paymentId]);
  }
}

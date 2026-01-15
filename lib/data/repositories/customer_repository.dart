import '../datasources/db_helper.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<List<CustomerModel>> getCustomers() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => CustomerModel.fromMap(maps[i]));
  }

  Future<int> insertCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    return await db.insert('customers', customer.toMap());
  }

  Future<int> updateCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    return await db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

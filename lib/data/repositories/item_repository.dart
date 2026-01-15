import '../datasources/db_helper.dart';
import '../models/item_model.dart';

class ItemRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<List<ItemModel>> getItems() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('items', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => ItemModel.fromMap(maps[i]));
  }

  Future<int> insertItem(ItemModel item) async {
    final db = await _dbHelper.database;
    return await db.insert('items', item.toMap());
  }

  Future<int> updateItem(ItemModel item) async {
    final db = await _dbHelper.database;
    return await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deleteItem(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

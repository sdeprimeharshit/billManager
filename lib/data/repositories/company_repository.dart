import '../datasources/db_helper.dart';
import '../models/company_model.dart';

class CompanyRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<CompanyModel?> getCompanyProfile() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('company_profile', limit: 1);
    if (maps.isEmpty) return null;
    return CompanyModel.fromMap(maps.first);
  }

  Future<int> saveCompanyProfile(CompanyModel company) async {
    final db = await _dbHelper.database;
    final existing = await getCompanyProfile();
    
    if (existing == null) {
      return await db.insert('company_profile', company.toMap());
    } else {
      return await db.update(
        'company_profile',
        company.toMap(),
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }
  }
}

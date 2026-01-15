import 'package:sqflite/sqflite.dart';
import '../datasources/db_helper.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/tax_breakup.dart';

class InvoiceRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> saveInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      final invoiceMap = {
        'invoice_number': invoice.invoiceNumber,
        'date': invoice.date.toIso8601String(),
        'customer_id': invoice.customerId,
        'total_amount': invoice.totalAmount,
        'taxable_amount': invoice.totalTaxableAmount,
        'total_gst': invoice.totalGst,
        'is_inter_state': invoice.isInterState ? 1 : 0,
        'notes': invoice.notes,
      };

      int invoiceId;
      if (invoice.id != null) {
        invoiceId = int.parse(invoice.id!);
        await txn.update('invoices', invoiceMap, where: 'id = ?', whereArgs: [invoiceId]);
        await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
        await txn.delete('tax_breakups', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      } else {
        invoiceId = await txn.insert('invoices', invoiceMap);
      }

      for (var item in invoice.items) {
        await txn.insert('invoice_items', {
          'invoice_id': invoiceId,
          'item_name': item.itemName,
          'hsn': item.hsn,
          'quantity': item.quantity,
          'price': item.price,
          'gst_rate': item.gstRate,
          'gst_amount': item.gstAmount,
          'total': item.total,
        });
      }

      for (var breakup in invoice.taxBreakups) {
        await txn.insert('tax_breakups', {
          'invoice_id': invoiceId,
          'gst_rate': breakup.gstRate,
          'taxable_value': breakup.taxableValue,
          'cgst': breakup.cgst,
          'sgst': breakup.sgst,
          'igst': breakup.igst,
        });
      }

      return invoiceId;
    });
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT invoices.*, customers.name as customer_name 
      FROM invoices 
      JOIN customers ON invoices.customer_id = customers.id 
      ORDER BY date DESC
    ''');
  }

  Future<Invoice?> getFullInvoice(int id) async {
    final db = await _dbHelper.database;
    
    final invMaps = await db.query('invoices', where: 'id = ?', whereArgs: [id]);
    if (invMaps.isEmpty) return null;
    final invMap = invMaps.first;

    final itemMaps = await db.query('invoice_items', where: 'invoice_id = ?', whereArgs: [id]);
    final breakupMaps = await db.query('tax_breakups', where: 'invoice_id = ?', whereArgs: [id]);

    final items = itemMaps.map((m) => InvoiceItem(
      itemName: m['item_name'] as String,
      hsn: m['hsn'] as String?,
      quantity: (m['quantity'] as num).toDouble(),
      price: (m['price'] as num).toDouble(),
      gstRate: (m['gst_rate'] as num).toDouble(),
    )).toList();

    final breakups = breakupMaps.map((m) => TaxBreakup(
      gstRate: (m['gst_rate'] as num).toDouble(),
      taxableValue: (m['taxable_value'] as num).toDouble(),
      cgst: (m['cgst'] as num).toDouble(),
      sgst: (m['sgst'] as num).toDouble(),
      igst: (m['igst'] as num).toDouble(),
    )).toList();

    return Invoice(
      id: id.toString(),
      invoiceNumber: invMap['invoice_number'] as String,
      date: DateTime.parse(invMap['date'] as String),
      customerId: invMap['customer_id'] as int,
      items: items,
      taxBreakups: breakups,
      totalTaxableAmount: (invMap['taxable_amount'] as num).toDouble(),
      totalGst: (invMap['total_gst'] as num).toDouble(),
      totalAmount: (invMap['total_amount'] as num).toDouble(),
      isInterState: invMap['is_inter_state'] == 1,
      notes: invMap['notes'] as String?,
    );
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _dbHelper.database;
    await db.update('invoices', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    await db.delete('invoices', where: 'id = ?', whereArgs: [id]);
  }

  Future<String> getNextInvoiceNumber() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return 'INV-${(count + 1).toString().padLeft(4, '0')}';
  }
}

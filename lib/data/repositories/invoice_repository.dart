import 'package:sqflite/sqflite.dart';
import '../datasources/db_helper.dart';
import '../../domain/entities/invoice.dart';

class InvoiceRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<int> saveInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    
    return await db.transaction((txn) async {
      final invoiceId = await txn.insert('invoices', {
        'invoice_number': invoice.invoiceNumber,
        'date': invoice.date.toIso8601String(),
        'customer_id': invoice.customerId,
        'total_amount': invoice.totalAmount,
        'taxable_amount': invoice.totalTaxableAmount,
        'total_gst': invoice.totalGst,
        'is_inter_state': invoice.isInterState ? 1 : 0,
        'notes': invoice.notes,
      });

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

  Future<String> getNextInvoiceNumber() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
    int count = Sqflite.firstIntValue(result) ?? 0;
    return 'INV-${(count + 1).toString().padLeft(4, '0')}';
  }
}

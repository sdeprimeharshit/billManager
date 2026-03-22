import 'package:sqflite/sqflite.dart';
import '../datasources/db_helper.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/entities/tax_breakup.dart';

class InvoiceRepository {
  final DBHelper _dbHelper = DBHelper();

  Future<bool> isInvoiceNumberExists(String invoiceNumber, {String? excludeId}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> result;
    if (excludeId != null) {
      result = await db.query('invoices', 
        where: 'invoice_number = ? AND id != ?', 
        whereArgs: [invoiceNumber, int.parse(excludeId)]);
    } else {
      result = await db.query('invoices', 
        where: 'invoice_number = ?', 
        whereArgs: [invoiceNumber]);
    }
    return result.isNotEmpty;
  }

  Future<int> saveInvoice(Invoice invoice) async {
    final db = await _dbHelper.database;
    
    // Check for duplicate number
    if (await isInvoiceNumberExists(invoice.invoiceNumber, excludeId: invoice.id)) {
      throw Exception('Invoice number ${invoice.invoiceNumber} already exists.');
    }

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
        'status': invoice.status,
        'shipping_name': invoice.shippingName,
        'shipping_address': invoice.shippingAddress,
        'shipping_gstin': invoice.shippingGstin,
        'is_same_as_billing': invoice.isSameAsBilling ? 1 : 0,
        'transporter_name': invoice.transporterName,
        'vehicle_number': invoice.vehicleNumber,
        'gr_number': invoice.grNumber,
        'eway_bill_number': invoice.ewayBillNumber,
      };

      int invoiceId;
      if (invoice.id != null) {
        invoiceId = int.parse(invoice.id!);
        await txn.update('invoices', invoiceMap, where: 'id = ?', whereArgs: [invoiceId]);
        await txn.delete('invoice_items', where: 'invoice_id = ?', whereArgs: [invoiceId]);
        await txn.delete('tax_breakups', where: 'invoice_id = ?', whereArgs: [invoiceId]);
      } else {
        invoiceId = await txn.insert('invoices', invoiceMap);
        await txn.delete('deleted_invoice_numbers', where: 'invoice_number = ?', whereArgs: [invoice.invoiceNumber]);
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
      status: invMap['status'] as String? ?? 'draft',
      shippingName: invMap['shipping_name'] as String?,
      shippingAddress: invMap['shipping_address'] as String?,
      shippingGstin: invMap['shipping_gstin'] as String?,
      isSameAsBilling: invMap['is_same_as_billing'] == 1,
      transporterName: invMap['transporter_name'] as String?,
      vehicleNumber: invMap['vehicle_number'] as String?,
      grNumber: invMap['gr_number'] as String?,
      ewayBillNumber: invMap['eway_bill_number'] as String?,
    );
  }

  Future<void> updateStatus(int id, String status) async {
    final db = await _dbHelper.database;
    await db.update('invoices', {'status': status}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteInvoice(int id) async {
    final db = await _dbHelper.database;
    
    await db.transaction((txn) async {
      final maps = await txn.query('invoices', columns: ['invoice_number'], where: 'id = ?', whereArgs: [id]);
      if (maps.isNotEmpty) {
        final invoiceNumber = maps.first['invoice_number'] as String;
        await txn.insert('deleted_invoice_numbers', {'invoice_number': invoiceNumber});
      }
      
      await txn.delete('invoices', where: 'id = ?', whereArgs: [id]);
    });
  }

  String _getFinancialYear() {
    final now = DateTime.now();
    int startYear;
    int endYear;

    if (now.month >= 4) {
      startYear = now.year;
      endYear = now.year + 1;
    } else {
      startYear = now.year - 1;
      endYear = now.year;
    }

    // Format: 2526 (from 2025-2026)
    return "${startYear.toString().substring(2)}${endYear.toString().substring(2)}";
  }

  Future<String> getNextInvoiceNumber() async {
    final db = await _dbHelper.database;
    final fyPrefix = _getFinancialYear();
    final constant = "GE";
    final prefix = "$fyPrefix$constant";

    // 1. Check for deleted invoice numbers in the current format
    final deleted = await db.query(
      'deleted_invoice_numbers', 
      where: 'invoice_number LIKE ?', 
      whereArgs: ['$prefix%'],
      orderBy: 'invoice_number ASC', 
      limit: 1
    );
    
    if (deleted.isNotEmpty) {
      return deleted.first['invoice_number'] as String;
    }

    // 2. Find the maximum serial number for the current FY
    final result = await db.query(
      'invoices', 
      columns: ['invoice_number'], 
      where: 'invoice_number LIKE ?', 
      whereArgs: ['$prefix%']
    );

    int maxSerial = 0;
    for (var row in result) {
      String fullNumber = row['invoice_number'] as String;
      // Extract serial from "2526GE0001" -> "0001"
      String serialStr = fullNumber.replaceFirst(prefix, "");
      int? serial = int.tryParse(serialStr);
      if (serial != null && serial > maxSerial) {
        maxSerial = serial;
      }
    }
    
    final nextSerial = (maxSerial + 1).toString().padLeft(4, '0');
    return "$prefix$nextSerial";
  }
}

import 'invoice_item.dart';
import 'tax_breakup.dart';

class Invoice {
  final String? id;
  final String invoiceNumber;
  final DateTime date;
  final int customerId;
  final List<InvoiceItem> items;
  final List<TaxBreakup> taxBreakups;
  final double totalTaxableAmount;
  final double totalGst;
  final double totalAmount;
  final bool isInterState;
  final String? notes;
  final String status; // draft, issued, cancelled
  
  // Shipping Fields
  final String? shippingName;
  final String? shippingAddress;
  final String? shippingGstin;
  final bool isSameAsBilling;

  // Transport Details (Optional)
  final String? transporterName;
  final String? vehicleNumber;
  final String? grNumber;
  final String? ewayBillNumber;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.date,
    required this.customerId,
    required this.items,
    required this.taxBreakups,
    required this.totalTaxableAmount,
    required this.totalGst,
    required this.totalAmount,
    required this.isInterState,
    this.notes,
    this.status = 'draft',
    this.shippingName,
    this.shippingAddress,
    this.shippingGstin,
    this.isSameAsBilling = true,
    this.transporterName,
    this.vehicleNumber,
    this.grNumber,
    this.ewayBillNumber,
  });
}

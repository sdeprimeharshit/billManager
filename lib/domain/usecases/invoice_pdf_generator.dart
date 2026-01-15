import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../entities/invoice.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/company_model.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> generate(
    Invoice invoice,
    CustomerModel customer,
    CompanyModel company,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MMM-yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(company, invoice, dateFormat),
          pw.SizedBox(height: 20),
          _buildAddressSection(company, customer),
          pw.SizedBox(height: 20),
          _buildInvoiceItemsTable(invoice),
          pw.SizedBox(height: 20),
          _buildTaxBreakupTable(invoice),
          pw.SizedBox(height: 20),
          _buildSummaryAndNotes(invoice, company),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(CompanyModel company, Invoice invoice, DateFormat df) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(company.name, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('GSTIN: ${company.gstin ?? "N/A"}'),
            pw.Text(company.phone ?? ""),
            pw.Text(company.email ?? ""),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('TAX INVOICE', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue600)),
            pw.SizedBox(height: 8),
            pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Date: ${df.format(invoice.date)}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildAddressSection(CompanyModel company, CustomerModel customer) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Details of Supplier (Seller)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Divider(thickness: 0.5),
              pw.Text(company.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(company.address ?? ""),
              pw.Text('State: ${company.state ?? ""} (${company.stateCode ?? ""})'),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Details of Receiver (Buyer)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Divider(thickness: 0.5),
              pw.Text(customer.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(customer.address ?? ""),
              pw.Text('GSTIN: ${customer.gstin ?? "N/A"}'),
              pw.Text('State: ${customer.state ?? ""} (${customer.stateCode ?? ""})'),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceItemsTable(Invoice invoice) {
    final headers = ['#', 'Description', 'HSN/SAC', 'Qty', 'Unit Price', 'GST %', 'Total'];

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: List.generate(invoice.items.length, (index) {
        final item = invoice.items[index];
        return [
          '${index + 1}',
          item.itemName,
          item.hsn ?? "",
          item.quantity.toString(),
          item.price.toStringAsFixed(2),
          '${item.gstRate}%',
          item.total.toStringAsFixed(2),
        ];
      }),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellHeight: 25,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
        4: pw.Alignment.centerRight,
        5: pw.Alignment.centerRight,
        6: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildTaxBreakupTable(Invoice invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('GST Tax Breakup', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: ['Rate', 'Taxable Value', 'CGST', 'SGST', 'IGST', 'Total Tax'],
          data: invoice.taxBreakups.map((b) => [
            '${b.gstRate}%',
            b.taxableValue.toStringAsFixed(2),
            b.cgst.toStringAsFixed(2),
            b.sgst.toStringAsFixed(2),
            b.igst.toStringAsFixed(2),
            b.totalTax.toStringAsFixed(2),
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
            5: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryAndNotes(Invoice invoice, CompanyModel company) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Terms & Conditions / Notes:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(invoice.notes ?? "Standard terms apply."),
              pw.SizedBox(height: 10),
              pw.Text('Bank Details:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(company.bankDetails ?? "N/A"),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildSummaryRow('Total Taxable Value', invoice.totalTaxableAmount),
              _buildSummaryRow('Total GST', invoice.totalGst),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Grand Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text('INR ${invoice.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Container(
                height: 60,
                width: double.infinity,
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
                child: pw.Center(child: pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value.toStringAsFixed(2), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}

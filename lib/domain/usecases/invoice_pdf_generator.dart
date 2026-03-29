import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../entities/invoice.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/company_model.dart';

class InvoicePdfGenerator {
  static final _indianFormat = NumberFormat.currency(locale: 'en_IN', symbol: '');

  static String _formatCurrency(double amount) {
    return _indianFormat.format(amount).trim();
  }

  static Future<Uint8List> generate(
    Invoice invoice,
    CustomerModel customer,
    CompanyModel company,
  ) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MMM-yyyy');
    
    final copyTypes = [
      'Original for Recipient',
      'Transporter Copy',
      'Supplier Copy',
    ];

    for (var copyType in copyTypes) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Container(
            height: PdfPageFormat.a4.availableHeight,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              children: [
                _buildHeader(company, invoice, dateFormat, copyType),
                _buildMetadataSection(invoice, company, dateFormat),
                _buildBillingShippingSection(invoice, customer),
                // Items section expanded to fill middle space
                pw.Expanded(child: _buildItemsSection(invoice)),
                // Bottom section will now be pushed to the end of the page
                _buildBottomSection(invoice, company),
              ],
            ),
          ),
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildHeader(CompanyModel company, Invoice invoice, DateFormat df, String copyType) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Tax Invoice', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('|| RADHEY RADHEY ||', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('($copyType)', style: const pw.TextStyle(fontSize: 7)),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(company.name.toUpperCase(), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text(company.address ?? "", style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('GSTIN: ${company.gstin ?? "N/A"}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Contact: ${company.phone ?? ""} | Email: ${company.email ?? ""}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildMetadataSection(Invoice invoice, CompanyModel company, DateFormat df) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                children: [
                  _metaRow('Invoice No', invoice.invoiceNumber),
                  _metaRow('Invoice Date', df.format(invoice.date)),
                  _metaRow('State', company.state ?? ""),
                  _metaRow('State Code', company.stateCode ?? ""),
                ],
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Column(
                children: [
                  _metaRow('Transporter', invoice.transporterName ?? "-"),
                  _metaRow('Vehicle No', invoice.vehicleNumber ?? "-"),
                  _metaRow('G/R No', invoice.grNumber ?? "-"),
                  _metaRow('E-Way Bill No', invoice.ewayBillNumber ?? "-"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(1),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 70, child: pw.Text('$label :', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
          pw.Expanded(child: pw.Text(value, style: const pw.TextStyle(fontSize: 8))),
        ],
      ),
    );
  }

  static pw.Widget _buildBillingShippingSection(Invoice invoice, CustomerModel billing) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(width: 1))),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(2),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                    ),
                    child: pw.Text(' Details of Receiver | Billed to:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(billing.name.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(billing.address ?? "", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('GSTIN: ${billing.gstin ?? ""}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('State: ${billing.state ?? ""} | Code: ${billing.stateCode ?? ""}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(2),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    border: pw.Border(bottom: pw.BorderSide(width: 0.5)),
                  ),
                  child: pw.Text(' Details of Consignee | Shipped to:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (invoice.isSameAsBilling) ...[
                        pw.Text(billing.name.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(billing.address ?? "", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('GSTIN: ${billing.gstin ?? ""}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('State: ${billing.state ?? ""} | Code: ${billing.stateCode ?? ""}', style: const pw.TextStyle(fontSize: 8)),
                      ] else ...[
                        pw.Text((invoice.shippingName ?? "").toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        pw.Text(invoice.shippingAddress ?? "", style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('GSTIN: ${invoice.shippingGstin ?? ""}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsSection(Invoice invoice) {
    const int fixedRows=50;
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(width: 1),
        left: pw.BorderSide(width: 1),
        right: pw.BorderSide(width: 1)),
      ),
      child: pw.TableHelper.fromTextArray(
        border: const pw.TableBorder(
          verticalInside: pw.BorderSide(width: 1),
        ),
        headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        cellStyle: const pw.TextStyle(fontSize: 8),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200,
          border: pw.Border(bottom: pw.BorderSide(width: 1), left: pw.BorderSide(width: 1), right: pw.BorderSide(width: 1))),
        columnWidths: {
          0: const pw.FixedColumnWidth(32),
          1: const pw.FixedColumnWidth(190),
          2: const pw.FixedColumnWidth(60),
          3: const pw.FixedColumnWidth(40),
          4: const pw.FixedColumnWidth(40),
          5: const pw.FixedColumnWidth(60),
          6: const pw.FixedColumnWidth(50),
          7: const pw.FixedColumnWidth(70),
        },
        headers: ['S.No.', 'Description of Goods', 'HSN Code', 'UOM', 'Qty', 'Rate', 'GST%', 'Taxable Amount'],
        data: List.generate(fixedRows, (index) {
          if(index < invoice.items.length) {
            final item = invoice.items[index];
            return [
              '${index + 1}',
              item.itemName,
              item.hsn ?? "",
              "Nos",
              item.quantity.toString(),
              _formatCurrency(item.price),
              '${item.gstRate}%',
              _formatCurrency(item.taxableValue),
            ];
          }
          else{
            return [
              '',
              '',
              '',
              '',
              '',
              '',
              '',
              '',
            ];
          }
        }),
        cellAlignments: {
          0: pw.Alignment.center,
          1: pw.Alignment.centerLeft,
          2: pw.Alignment.center,
          3: pw.Alignment.center,
          4: pw.Alignment.centerRight,
          5: pw.Alignment.centerRight,
          6: pw.Alignment.centerRight,
          7: pw.Alignment.centerRight,
        },
      ),
    );
  }

  static pw.Widget _buildBottomSection(Invoice invoice, CompanyModel company) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _buildSummarySection(invoice, company),
        _buildFooter(invoice, company),
      ],
    );
  }

  static pw.Widget _buildSummarySection(Invoice invoice, CompanyModel company) {
    return pw.Container(
      decoration: const pw.BoxDecoration(border: pw.Border(
          bottom: pw.BorderSide(width: 1),
      )
      ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 5,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(4),
                  decoration: const pw.BoxDecoration(border: pw.Border(right: pw.BorderSide(width: 1))),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bank Details:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      pw.Text(company.bankDetails ?? "N/A", style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 10),
                      pw.Text('Total Amount in words:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text('INR ${NumberToWords.convert(invoice.totalAmount)} Only', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1))),
                  child: pw.Column(
                    children: [
                      _summaryRow('Taxable Amount', invoice.totalTaxableAmount),
                      ...invoice.taxBreakups.expand((b) {
                        if (invoice.isInterState) {
                          return [_summaryRow('IGST @ ${b.gstRate}%', b.igst)];
                        } else {
                          return [
                            _summaryRow('CGST @ ${b.gstRate / 2}%', b.cgst),
                            _summaryRow('SGST @ ${b.gstRate / 2}%', b.sgst),
                          ];
                        }
                      }),
                      _summaryRow('Total GST', invoice.totalGst),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(width: 1)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                            pw.Text('INR ${_formatCurrency(invoice.totalAmount)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  )
                )
              ),
            ],
          )
    );
  }

  static pw.Widget _summaryRow(String label, double value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.fromLTRB(4, 2, 4, 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(_formatCurrency(value), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(Invoice invoice, CompanyModel company) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Terms and Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                pw.Text(invoice.notes ?? company.defaultTerms ?? "1. Goods once sold will not be taken back.\n2. Interest @ 18% will be charged if payment not made on time.", style: const pw.TextStyle(fontSize: 7)),
              ],
            ),
          ),
          pw.Spacer(),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('For ${company.name.toUpperCase()}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 30),
              pw.Container(width: 100, decoration: const pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(width: 0.5)))),
              pw.Text('Authorized Signatory', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

class NumberToWords {
  static const _ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
  static const _tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

  static String convert(double amount) {
    if (amount == 0) return "Zero";
    int val = amount.floor();
    String words = _convertInteger(val);

    int paisa = ((amount - val) * 100).round();
    if (paisa > 0) {
      words += " and ${_convertInteger(paisa)} Paisa";
    }
    return words;
  }

  static String _convertInteger(int n) {
    if (n == 0) return "";
    if (n < 20) return _ones[n];
    if (n < 100) return "${_tens[n ~/ 10]}${n % 10 != 0 ? " ${_ones[n % 10]}" : ""}";
    if (n < 1000) return "${_ones[n ~/ 100]} Hundred${n % 100 != 0 ? " ${_convertInteger(n % 100)}" : ""}";
    if (n < 100000) return "${_convertInteger(n ~/ 1000)} Thousand${n % 1000 != 0 ? " ${_convertInteger(n % 1000)}" : ""}";
    if (n < 10000000) return "${_convertInteger(n ~/ 100000)} Lakh${n % 100000 != 0 ? " ${_convertInteger(n % 100000)}" : ""}";
    return "${_convertInteger(n ~/ 10000000)} Crore${n % 10000000 != 0 ? " ${_convertInteger(n % 10000000)}" : ""}";
  }
}

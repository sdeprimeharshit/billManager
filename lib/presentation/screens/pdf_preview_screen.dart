import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../domain/entities/invoice.dart';
import '../../data/models/customer_model.dart';
import '../state/customer_provider.dart';
import '../state/company_provider.dart';
import '../../domain/usecases/invoice_pdf_generator.dart';

class PdfPreviewScreen extends ConsumerWidget {
  final Invoice invoice;
  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customers = ref.watch(customerListProvider).value;
    final company = ref.watch(companyProfileProvider).value;

    if (customers == null || company == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final customer = customers.firstWhere((c) => c.id == invoice.customerId);

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
      ),
      body: PdfPreview(
        pdfFileName: 'Invoice-${invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\s-]'), '_')}',
        build: (format) => InvoicePdfGenerator.generate(
          invoice,
          customer,
          company,
        ),
        canDebug: false,
      ),
    );
  }
}

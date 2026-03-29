import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import '../../domain/entities/invoice.dart';
import '../state/customer_provider.dart';
import '../state/company_provider.dart';
import '../../domain/usecases/invoice_pdf_generator.dart';

class PdfPreviewScreen extends ConsumerStatefulWidget {
  final Invoice invoice;
  const PdfPreviewScreen({super.key, required this.invoice});

  @override
  ConsumerState<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends ConsumerState<PdfPreviewScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    final customers = ref.read(customerListProvider).value;
    final company = ref.read(companyProfileProvider).value;

    if (customers != null && company != null) {
      final customer = customers.firstWhere((c) => c.id == widget.invoice.customerId);
      _pdfBytes = await InvoicePdfGenerator.generate(
        widget.invoice,
        customer,
        company,
      );
      
      _pdfController = PdfController(
        document: PdfDocument.openData(_pdfBytes!),
      );
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    
    final fileName = 'Invoice-${widget.invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
    
    // On Desktop, this opens the system "Save As" / "Share" dialog
    // which is the most reliable way to handle downloads without manual path management.
    await Printing.sharePdf(
      bytes: _pdfBytes!,
      filename: fileName,
    );
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Invoice ${widget.invoice.invoiceNumber}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_pdfController == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Invoice ${widget.invoice.invoiceNumber}')),
        body: const Center(child: Text('Failed to load PDF')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download / Save PDF',
            onPressed: _downloadPdf,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print',
            onPressed: () {
              if (_pdfBytes != null) {
                Printing.layoutPdf(onLayout: (_) => _pdfBytes!);
              }
            },
          ),
          const VerticalDivider(width: 20, indent: 15, endIndent: 15),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => _pdfController?.previousPage(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 100),
            ),
          ),
          PdfPageNumber(
            controller: _pdfController!,
            builder: (_, loadingState, page, pagesCount) => Center(
              child: Text(
                '$page / ${pagesCount ?? 0}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 18),
            onPressed: () => _pdfController?.nextPage(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 100),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.grey[200],
        child: PdfView(
          controller: _pdfController!,
        ),
      ),
    );
  }
}

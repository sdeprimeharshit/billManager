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
  String? _errorMessage;
  Uint8List? _pdfBytes;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    try {
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
      } else {
        _errorMessage = "Missing customer or company profile data.";
      }
    } catch (e) {
      _errorMessage = "Error generating or rendering PDF: $e";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfBytes == null) return;
    
    try {
      final fileName = 'Invoice-${widget.invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      await Printing.sharePdf(
        bytes: _pdfBytes!,
        filename: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save PDF: $e')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes == null) return;
    try {
      await Printing.layoutPdf(onLayout: (_) => _pdfBytes!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printing failed: $e')),
        );
      }
    }
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

    if (_errorMessage != null || _pdfController == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Invoice ${widget.invoice.invoiceNumber}')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Failed to load PDF preview',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initPdf();
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          ),
        ),
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
            onPressed: _printPdf,
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

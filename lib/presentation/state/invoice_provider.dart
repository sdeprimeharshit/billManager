import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../domain/entities/invoice.dart';

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository());

final nextInvoiceNumberProvider = FutureProvider.autoDispose<String>((ref) async {
  return await ref.watch(invoiceRepositoryProvider).getNextInvoiceNumber();
});

class InvoiceListNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final InvoiceRepository _repository;

  InvoiceListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadInvoices();
  }

  Future<void> loadInvoices() async {
    state = const AsyncValue.loading();
    try {
      final invoices = await _repository.getInvoices();
      state = AsyncValue.data(invoices);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveInvoice(Invoice invoice) async {
    try {
      await _repository.saveInvoice(invoice);
      await loadInvoices();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final invoiceListProvider = StateNotifierProvider<InvoiceListNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return InvoiceListNotifier(ref.watch(invoiceRepositoryProvider));
});

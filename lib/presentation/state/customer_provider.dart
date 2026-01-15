import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customer_repository.dart';

final customerRepositoryProvider = Provider((ref) => CustomerRepository());

final customerListProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerModel>>>((ref) {
  return CustomerNotifier(ref.watch(customerRepositoryProvider));
});

class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final CustomerRepository _repository;

  CustomerNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = const AsyncValue.loading();
    try {
      final customers = await _repository.getCustomers();
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    await _repository.insertCustomer(customer);
    await loadCustomers();
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    await _repository.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(int id) async {
    await _repository.deleteCustomer(id);
    await loadCustomers();
  }
}

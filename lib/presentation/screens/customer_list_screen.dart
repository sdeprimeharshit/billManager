import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../state/customer_provider.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showCustomerDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Customer'),
            ),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) => customers.isEmpty
            ? const Center(child: Text('No customers found. Add one to get started.'))
            : ListView.separated(
                itemCount: customers.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final customer = customers[index];
                  return ListTile(
                    title: Text(customer.name),
                    subtitle: Text('${customer.gstin ?? "No GSTIN"} | ${customer.state ?? "No State"}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showCustomerDialog(context, ref, customer: customer),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, customer),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showCustomerDialog(BuildContext context, WidgetRef ref, {CustomerModel? customer}) {
    final nameController = TextEditingController(text: customer?.name);
    final addressController = TextEditingController(text: customer?.address);
    final gstinController = TextEditingController(text: customer?.gstin);
    final phoneController = TextEditingController(text: customer?.phone);
    final emailController = TextEditingController(text: customer?.email);
    final stateController = TextEditingController(text: customer?.state);
    final stateCodeController = TextEditingController(text: customer?.stateCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Add Customer' : 'Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name*')),
              TextField(controller: gstinController, decoration: const InputDecoration(labelText: 'GSTIN')),
              TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: stateController, decoration: const InputDecoration(labelText: 'State')),
              TextField(controller: stateCodeController, decoration: const InputDecoration(labelText: 'State Code')),
              TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final newCustomer = CustomerModel(
                id: customer?.id,
                name: nameController.text,
                address: addressController.text,
                gstin: gstinController.text,
                phone: phoneController.text,
                email: emailController.text,
                state: stateController.text,
                stateCode: stateCodeController.text,
              );
              if (customer == null) {
                ref.read(customerListProvider.notifier).addCustomer(newCustomer);
              } else {
                ref.read(customerListProvider.notifier).updateCustomer(newCustomer);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(customerListProvider.notifier).deleteCustomer(customer.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

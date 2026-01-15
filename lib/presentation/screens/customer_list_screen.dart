import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../state/customer_provider.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Customers',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 24),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search by name or GSTIN...',
                    leading: const Icon(Icons.search, color: Color(0xFF64748B)),
                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                    shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
                const SizedBox(width: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showProfessionalForm(context, ref),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add New Customer', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: customersAsync.when(
        data: (customers) {
          final filtered = customers.where((c) {
            return c.name.toLowerCase().contains(_searchQuery) ||
                   (c.gstin?.toLowerCase().contains(_searchQuery) ?? false);
          }).toList();

          return filtered.isEmpty
              ? _buildEmptyState(_searchQuery.isNotEmpty)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: const Color(0xFFF1F5F9)),
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('NAME', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          DataColumn(label: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          DataColumn(label: Text('STATE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          DataColumn(label: Text('PHONE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        ],
                        rows: filtered.map((customer) {
                          return DataRow(cells: [
                            DataCell(Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                            DataCell(Text(customer.gstin ?? 'N/A')),
                            DataCell(Text(customer.state ?? 'N/A')),
                            DataCell(Text(customer.phone ?? 'N/A')),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                                  onPressed: () => _showProfessionalForm(context, ref, customer: customer),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                  onPressed: () => _confirmDelete(context, ref, customer),
                                  tooltip: 'Delete',
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearch) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(isSearch ? Icons.search_off : Icons.people_outline, size: 64, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          Text(isSearch ? 'No matches found' : 'No customers found', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(isSearch ? 'Try a different search term.' : 'Start by adding your first customer to the system.', 
            style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  void _showProfessionalForm(BuildContext context, WidgetRef ref, {CustomerModel? customer}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer?.name);
    final gstinController = TextEditingController(text: customer?.gstin);
    final phoneController = TextEditingController(text: customer?.phone);
    final emailController = TextEditingController(text: customer?.email);
    final stateController = TextEditingController(text: customer?.state);
    final stateCodeController = TextEditingController(text: customer?.stateCode);
    final addressController = TextEditingController(text: customer?.address);

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 24,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Container(
          width: 850,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.person_add_outlined, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      customer == null ? 'Register New Customer' : 'Update Customer Details',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Company Information'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(fontSize: 15),
                          decoration: _buildInputDecoration('Legal Name / Business Name *', Icons.business_outlined),
                          validator: (v) => v?.isEmpty ?? true ? 'Business name is required' : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: gstinController,
                                decoration: _buildInputDecoration('GSTIN', Icons.receipt_long_outlined).copyWith(hintText: 'e.g. 27AAAAA0000A1Z5'),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: phoneController,
                                decoration: _buildInputDecoration('Contact Number', Icons.phone_outlined).copyWith(prefixText: '+91 '),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildFormLabel('Contact & Billing Details'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: stateController,
                                decoration: _buildInputDecoration('State', Icons.map_outlined),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: TextFormField(
                                controller: stateCodeController,
                                decoration: _buildInputDecoration('State Code', Icons.numbers_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: _buildInputDecoration('Detailed Billing Address', Icons.location_on_outlined),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newCustomerData = CustomerModel(
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
                            ref.read(customerListProvider.notifier).addCustomer(newCustomerData);
                          } else {
                            ref.read(customerListProvider.notifier).updateCustomer(newCustomerData);
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        customer == null ? 'Save Customer' : 'Update Details',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildFormLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2563EB),
        letterSpacing: 1.2,
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CustomerModel customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Customer'),
        content: Text('Are you sure you want to delete "${customer.name}"? This action cannot be undone.'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_model.dart';
import '../state/item_provider.dart';

class ItemListScreen extends ConsumerWidget {
  const ItemListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Inventory Items',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _showItemForm(context, ref),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New Item', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) => items.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: const Color(0xFFF1F5F9)),
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
                      columns: const [
                        DataColumn(label: Text('ITEM NAME', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('HSN/SAC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('UNIT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('PRICE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('GST RATE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      ],
                      rows: items.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Text(item.hsn?.isEmpty ?? true ? 'N/A' : item.hsn!)),
                          DataCell(Text(item.unit)),
                          DataCell(Text('₹${item.price.toStringAsFixed(2)}')),
                          DataCell(Text('${item.gstRate}%')),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF64748B), size: 20),
                                onPressed: () => _showItemForm(context, ref, item: item),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                                onPressed: () => _confirmDelete(context, ref, item),
                                tooltip: 'Delete',
                              ),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 64, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          const Text('Inventory is empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Add products or services to start billing.', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  void _showItemForm(BuildContext context, WidgetRef ref, {ItemModel? item}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name);
    final hsnController = TextEditingController(text: item?.hsn);
    final unitController = TextEditingController(text: item?.unit ?? 'PCS');
    final priceController = TextEditingController(text: item?.price.toString());
    final gstRateController = TextEditingController(text: item?.gstRate.toString());

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 24,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        child: Container(
          width: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: Icon(Icons.inventory_2_outlined, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      item == null ? 'Add New Item' : 'Update Item Details',
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

              // Form Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Product Information'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: _buildInputDecoration('Item Description / Name *', Icons.label_outline),
                          validator: (v) => v?.isEmpty ?? true ? 'Item name is required' : null,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: hsnController,
                          decoration: _buildInputDecoration('HSN / SAC Code', Icons.tag),
                        ),
                        const SizedBox(height: 32),
                        _buildFormLabel('Pricing & Tax'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: unitController,
                                decoration: _buildInputDecoration('Unit', Icons.ad_units_outlined).copyWith(hintText: 'e.g. PCS, KG'),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: TextFormField(
                                controller: priceController,
                                decoration: _buildInputDecoration('Unit Price', Icons.currency_rupee).copyWith(prefixText: '₹'),
                                keyboardType: TextInputType.number,
                                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid price' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: gstRateController,
                          decoration: _buildInputDecoration('GST Rate', Icons.percent).copyWith(suffixText: '%'),
                          keyboardType: TextInputType.number,
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid rate' : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer
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
                          final newItemData = ItemModel(
                            id: item?.id,
                            name: nameController.text,
                            hsn: hsnController.text,
                            unit: unitController.text,
                            price: double.parse(priceController.text),
                            gstRate: double.parse(gstRateController.text),
                          );
                          if (item == null) {
                            ref.read(itemListProvider.notifier).addItem(newItemData);
                          } else {
                            ref.read(itemListProvider.notifier).updateItem(newItemData);
                          }
                          Navigator.pop(context);
                        }
                      },
                      child: Text(
                        item == null ? 'Save Item' : 'Update Details',
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

  void _confirmDelete(BuildContext context, WidgetRef ref, ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Permanently remove "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(itemListProvider.notifier).deleteItem(item.id!);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

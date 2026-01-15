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
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: () => _showItemDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            ),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) => items.isEmpty
            ? const Center(child: Text('No items found. Add one to get started.'))
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('HSN: ${item.hsn ?? "N/A"} | Price: ₹${item.price} | GST: ${item.gstRate}%'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showItemDialog(context, ref, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, ref, item),
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

  void _showItemDialog(BuildContext context, WidgetRef ref, {ItemModel? item}) {
    final nameController = TextEditingController(text: item?.name);
    final hsnController = TextEditingController(text: item?.hsn);
    final unitController = TextEditingController(text: item?.unit ?? 'PCS');
    final priceController = TextEditingController(text: item?.price.toString());
    final gstRateController = TextEditingController(text: item?.gstRate.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Item' : 'Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name*')),
            TextField(controller: hsnController, decoration: const InputDecoration(labelText: 'HSN Code')),
            Row(
              children: [
                Expanded(child: TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit (e.g. PCS, KG)'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number)),
              ],
            ),
            TextField(controller: gstRateController, decoration: const InputDecoration(labelText: 'GST Rate (%)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final newItem = ItemModel(
                id: item?.id,
                name: nameController.text,
                hsn: hsnController.text,
                unit: unitController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                gstRate: double.tryParse(gstRateController.text) ?? 0.0,
              );
              if (item == null) {
                ref.read(itemListProvider.notifier).addItem(newItem);
              } else {
                ref.read(itemListProvider.notifier).updateItem(newItem);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${item.name}?'),
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

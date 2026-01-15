import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/item_model.dart';
import '../../data/repositories/item_repository.dart';

final itemRepositoryProvider = Provider((ref) => ItemRepository());

final itemListProvider = StateNotifierProvider<ItemNotifier, AsyncValue<List<ItemModel>>>((ref) {
  return ItemNotifier(ref.watch(itemRepositoryProvider));
});

class ItemNotifier extends StateNotifier<AsyncValue<List<ItemModel>>> {
  final ItemRepository _repository;

  ItemNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = const AsyncValue.loading();
    try {
      final items = await _repository.getItems();
      state = AsyncValue.data(items);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addItem(ItemModel item) async {
    await _repository.insertItem(item);
    await loadItems();
  }

  Future<void> updateItem(ItemModel item) async {
    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _repository.deleteItem(id);
    await loadItems();
  }
}

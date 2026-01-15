import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/company_model.dart';
import '../../data/repositories/company_repository.dart';

final companyRepositoryProvider = Provider((ref) => CompanyRepository());

final companyProfileProvider = StateNotifierProvider<CompanyNotifier, AsyncValue<CompanyModel?>>((ref) {
  return CompanyNotifier(ref.watch(companyRepositoryProvider));
});

class CompanyNotifier extends StateNotifier<AsyncValue<CompanyModel?>> {
  final CompanyRepository _repository;

  CompanyNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getCompanyProfile();
      state = AsyncValue.data(profile);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveProfile(CompanyModel profile) async {
    try {
      await _repository.saveCompanyProfile(profile);
      await loadProfile();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

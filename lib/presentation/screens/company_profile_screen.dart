import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/company_model.dart';
import '../state/company_provider.dart';

class CompanyProfileScreen extends ConsumerWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(companyProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Business Profile'),
            const SizedBox(height: 24),
            profileAsync.when(
              data: (profile) => _buildProfileOverview(context, ref, profile),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Error: $err'),
            ),
            const SizedBox(height: 40),
            _buildSectionHeader('Application Settings'),
            const SizedBox(height: 24),
            _buildSettingsTile(
              Icons.info_outline,
              'Version',
              '1.0.0 (GST Build)',
              null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildProfileOverview(BuildContext context, WidgetRef ref, CompanyModel? profile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Icon(Icons.business, size: 40, color: const Color(0xFF2563EB)),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.name ?? 'Business Name Not Set',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'GSTIN: ${profile?.gstin ?? "Not Provided"}',
                        style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                      if (profile?.address != null)
                        Text(
                          profile!.address!,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showProfessionalForm(context, ref, profile: profile),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Manage Profile'),
                ),
              ],
            ),
          ),
          if (profile?.bankDetails != null && profile!.bankDetails!.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_outlined, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                      Text(profile.bankDetails!, style: const TextStyle(color: Color(0xFF64748B))),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (profile?.defaultTerms != null && profile!.defaultTerms!.isNotEmpty) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Default Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        Text(profile.defaultTerms!, style: const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Icon(icon, color: const Color(0xFF64748B)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }

  void _showProfessionalForm(BuildContext context, WidgetRef ref, {CompanyModel? profile}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: profile?.name);
    final gstinController = TextEditingController(text: profile?.gstin);
    final phoneController = TextEditingController(text: profile?.phone);
    final emailController = TextEditingController(text: profile?.email);
    final stateController = TextEditingController(text: profile?.state);
    final stateCodeController = TextEditingController(text: profile?.stateCode);
    final addressController = TextEditingController(text: profile?.address);
    final bankDetailsController = TextEditingController(text: profile?.bankDetails);
    final defaultTermsController = TextEditingController(text: profile?.defaultTerms);

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
                      child: Icon(Icons.settings_outlined, color: Colors.blue.shade600),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Business Configuration',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                        _buildFormLabel('Business Identity'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nameController,
                          decoration: _buildInputDecoration('Legal Business Name *', Icons.business),
                          validator: (v) => v?.isEmpty ?? true ? 'Business name is required' : null,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: gstinController,
                                decoration: _buildInputDecoration('GSTIN', Icons.receipt_long),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: phoneController,
                                decoration: _buildInputDecoration('Contact Number', Icons.phone).copyWith(prefixText: '+91 '),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        _buildFormLabel('Location & Tax Jurisdiction'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          decoration: _buildInputDecoration('Support Email', Icons.email_outlined),
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
                                decoration: _buildInputDecoration('State Code', Icons.numbers),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: addressController,
                          maxLines: 3,
                          decoration: _buildInputDecoration('Registered Office Address', Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 32),
                        _buildFormLabel('Financial Details'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: bankDetailsController,
                          maxLines: 3,
                          decoration: _buildInputDecoration('Bank Details (Name, Acc No, IFSC)', Icons.account_balance),
                        ),
                        const SizedBox(height: 32),
                        _buildFormLabel('Default Policy'),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: defaultTermsController,
                          maxLines: 4,
                          decoration: _buildInputDecoration('Default Terms & Conditions', Icons.description_outlined),
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
                      child: const Text('Discard', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final company = CompanyModel(
                            id: profile?.id,
                            name: nameController.text,
                            gstin: gstinController.text,
                            phone: phoneController.text,
                            email: emailController.text,
                            state: stateController.text,
                            stateCode: stateCodeController.text,
                            address: addressController.text,
                            bankDetails: bankDetailsController.text,
                            defaultTerms: defaultTermsController.text,
                          );
                          await ref.read(companyProfileProvider.notifier).saveProfile(company);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Configuration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
}

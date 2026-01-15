import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'customer_list_screen.dart';
import 'item_list_screen.dart';
import 'create_invoice_screen.dart';
import 'company_profile_screen.dart';
import '../state/invoice_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const Center(child: Text('Dashboard (Coming Soon)')),
      const InvoiceManagementScreen(),
      const CustomerListScreen(),
      const ItemListScreen(),
      const CompanyProfileScreen(),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: true,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.receipt_long),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "GST Billing",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description_outlined),
                selectedIcon: Icon(Icons.description),
                label: Text('Invoices'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_alt_outlined),
                selectedIcon: Icon(Icons.people_alt),
                label: Text('Customers'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Items'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

class InvoiceManagementScreen extends ConsumerWidget {
  const InvoiceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoiceListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Invoices',
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
              ),
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Create Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: invoicesAsync.when(
        data: (invoices) => invoices.isEmpty
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
                        DataColumn(label: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('INV #', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('CUSTOMER', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('GST', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        DataColumn(label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                      ],
                      rows: invoices.map((invoice) {
                        final date = DateTime.parse(invoice['date']);
                        return DataRow(cells: [
                          DataCell(Text(DateFormat('dd-MMM-yyyy').format(date))),
                          DataCell(Text(invoice['invoice_number'], style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(invoice['customer_name'])),
                          DataCell(Text('₹${(invoice['taxable_amount'] as num).toStringAsFixed(2)}')),
                          DataCell(Text('₹${(invoice['total_gst'] as num).toStringAsFixed(2)}')),
                          DataCell(Text('₹${(invoice['total_amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)))),
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
            child: Icon(Icons.description_outlined, size: 64, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          const Text('No invoices found', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          const Text('Create your first invoice to see it listed here.', style: TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

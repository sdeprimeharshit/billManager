import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'customer_list_screen.dart';
import 'item_list_screen.dart';
import 'create_invoice_screen.dart';
import 'company_profile_screen.dart';
import 'pdf_preview_screen.dart';
import '../state/invoice_provider.dart';
import '../state/customer_provider.dart';
import '../state/company_provider.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/invoice_pdf_generator.dart';

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

class InvoiceManagementScreen extends ConsumerStatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  ConsumerState<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends ConsumerState<InvoiceManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _downloadInvoice(Invoice invoice) async {
    try {
      final customers = ref.read(customerListProvider).value;
      final company = ref.read(companyProfileProvider).value;

      if (customers == null || company == null) {
        throw Exception("Missing data to generate PDF");
      }

      final customer = customers.firstWhere((c) => c.id == invoice.customerId);
      final pdfBytes = await InvoicePdfGenerator.generate(invoice, customer, company);
      
      final fileName = 'Invoice-${invoice.invoiceNumber.replaceAll(RegExp(r'[^\w\s-]'), '_')}.pdf';
      
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search by Invoice # or Customer...',
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CreateInvoiceScreen()),
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Create Invoice', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: invoicesAsync.when(
        data: (invoices) {
          final filtered = invoices.where((inv) {
            return inv['invoice_number'].toString().toLowerCase().contains(_searchQuery) ||
                   inv['customer_name'].toString().toLowerCase().contains(_searchQuery);
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
                          color: Colors.black.withOpacity(0.02),
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
                          DataColumn(label: Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                          DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
                        ],
                        rows: filtered.map((invoice) {
                          final date = DateTime.parse(invoice['date']);
                          final status = invoice['status'] as String? ?? 'draft';
                          final isDraft = status == 'draft';
                          final isCancelled = status == 'cancelled';
                          final invId = invoice['id'] as int;

                          return DataRow(
                            color: WidgetStateProperty.resolveWith<Color?>((states) {
                              if (isCancelled) return Colors.red.withOpacity(0.02);
                              return null;
                            }),
                            cells: [
                              DataCell(Text(DateFormat('dd-MMM-yyyy').format(date), style: TextStyle(decoration: isCancelled ? TextDecoration.lineThrough : null))),
                              DataCell(Text(invoice['invoice_number'], style: TextStyle(fontWeight: FontWeight.bold, decoration: isCancelled ? TextDecoration.lineThrough : null))),
                              DataCell(Text(invoice['customer_name'], style: TextStyle(decoration: isCancelled ? TextDecoration.lineThrough : null))),
                              DataCell(Text("₹${(invoice['total_amount'] as num).toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: isCancelled ? Colors.grey : const Color(0xFF2563EB)))),
                              DataCell(_buildStatusChip(status)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF64748B), size: 20),
                                    tooltip: 'Preview / Print',
                                    onPressed: isCancelled ? null : () async {
                                      final fullInvoice = await ref.read(invoiceListProvider.notifier).getInvoiceDetails(invId);
                                      if (fullInvoice != null && context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PdfPreviewScreen(invoice: fullInvoice)),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download_outlined, color: Color(0xFF64748B), size: 20),
                                    tooltip: 'Direct Download',
                                    onPressed: isCancelled ? null : () async {
                                      final fullInvoice = await ref.read(invoiceListProvider.notifier).getInvoiceDetails(invId);
                                      if (fullInvoice != null) {
                                        await _downloadInvoice(fullInvoice);
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(isDraft ? Icons.edit_outlined : Icons.visibility_outlined, color: const Color(0xFF64748B), size: 20),
                                    tooltip: isDraft ? 'Edit' : 'View',
                                    onPressed: () async {
                                      final fullInvoice = await ref.read(invoiceListProvider.notifier).getInvoiceDetails(invId);
                                      if (fullInvoice != null && context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => CreateInvoiceScreen(existingInvoice: fullInvoice)),
                                        );
                                      }
                                    },
                                  ),
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
                                    onSelected: (value) async {
                                      if (value == 'delete') {
                                        _confirmDelete(context, ref, invId, invoice['invoice_number']);
                                      } else if (value == 'cancel') {
                                        _confirmCancel(context, ref, invId);
                                      } else if (value == 'issue') {
                                        _confirmIssue(context, ref, invId);
                                      } else if (value == 'duplicate') {
                                        final fullInvoice = await ref.read(invoiceListProvider.notifier).getInvoiceDetails(invId);
                                        if (fullInvoice != null && context.mounted) {
                                          final duplicate = Invoice(
                                            invoiceNumber: await ref.read(nextInvoiceNumberProvider.future),
                                            date: DateTime.now(),
                                            customerId: fullInvoice.customerId,
                                            items: fullInvoice.items,
                                            taxBreakups: fullInvoice.taxBreakups,
                                            totalTaxableAmount: fullInvoice.totalTaxableAmount,
                                            totalGst: fullInvoice.totalGst,
                                            totalAmount: fullInvoice.totalAmount,
                                            isInterState: fullInvoice.isInterState,
                                            notes: fullInvoice.notes,
                                            status: 'draft',
                                          );
                                          if (context.mounted) {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => CreateInvoiceScreen(existingInvoice: duplicate)),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      if (isDraft)
                                        const PopupMenuItem(
                                          value: 'issue',
                                          child: Row(children: [Icon(Icons.send_outlined, size: 18, color: Colors.green), SizedBox(width: 8), Text('Issue Invoice')]),
                                        ),
                                      const PopupMenuItem(
                                        value: 'duplicate',
                                        child: Row(children: [Icon(Icons.copy, size: 18), SizedBox(width: 8), Text('Duplicate')]),
                                      ),
                                      if (!isCancelled)
                                        const PopupMenuItem(
                                          value: 'cancel',
                                          child: Row(children: [Icon(Icons.block, size: 18), SizedBox(width: 8), Text('Cancel Invoice')]),
                                        ),
                                      if (isDraft)
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete Permanently', style: TextStyle(color: Colors.red))]),
                                        ),
                                    ],
                                  ),
                                ],
                              )),
                            ],
                          );
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

  Widget _buildStatusChip(String status) {
    Color color = Colors.blue;
    if (status == 'issued') color = Colors.green;
    if (status == 'cancelled') color = Colors.red;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id, String number) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: Text('Invoice $number will be removed from the database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(invoiceListProvider.notifier).deleteInvoice(id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invoice?'),
        content: const Text('The invoice will be marked as Cancelled and cannot be edited.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Back')),
          TextButton(
            onPressed: () {
              ref.read(invoiceListProvider.notifier).updateStatus(id, 'cancelled');
              Navigator.pop(context);
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmIssue(BuildContext context, WidgetRef ref, int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue Invoice?'),
        content: const Text('Once issued, the invoice cannot be edited or deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(invoiceListProvider.notifier).updateStatus(id, 'issued');
              Navigator.pop(context);
            },
            child: const Text('Issue', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
        ],
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
            child: Icon(isSearch ? Icons.search_off : Icons.description_outlined, size: 64, color: Colors.blue.shade300),
          ),
          const SizedBox(height: 24),
          Text(isSearch ? 'No matches found' : 'No invoices found', 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const SizedBox(height: 8),
          Text(isSearch ? 'Try a different search term.' : 'Create your first invoice to see it listed here.', 
            style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

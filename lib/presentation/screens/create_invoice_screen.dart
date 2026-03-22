import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/item_model.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/entities/invoice_item.dart';
import '../../domain/usecases/gst_calculator.dart';
import '../state/customer_provider.dart';
import '../state/item_provider.dart';
import '../state/invoice_provider.dart';
import '../state/company_provider.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final Invoice? existingInvoice;
  const CreateInvoiceScreen({super.key, this.existingInvoice});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  CustomerModel? _selectedCustomer;
  DateTime _selectedDate = DateTime.now();
  List<InvoiceItem> _invoiceItems = [];
  bool _isInterState = false;
  final _notesController = TextEditingController();
  
  // Shipping Fields
  bool _isSameAsBilling = true;
  final _shippingNameController = TextEditingController();
  final _shippingAddressController = TextEditingController();
  final _shippingGstinController = TextEditingController();

  // Transport Details
  final _transporterController = TextEditingController();
  final _vehicleNoController = TextEditingController();
  final _grNoController = TextEditingController();
  final _ewayBillController = TextEditingController();

  bool get _isRealUpdate => widget.existingInvoice != null && widget.existingInvoice!.id != null;
  bool get _isReadOnly => widget.existingInvoice?.status == 'issued' || widget.existingInvoice?.status == 'cancelled';

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      _selectedDate = widget.existingInvoice!.date;
      _invoiceItems = List.from(widget.existingInvoice!.items);
      _isInterState = widget.existingInvoice!.isInterState;
      _notesController.text = widget.existingInvoice!.notes ?? "";
      
      _isSameAsBilling = widget.existingInvoice!.isSameAsBilling;
      _shippingNameController.text = widget.existingInvoice!.shippingName ?? "";
      _shippingAddressController.text = widget.existingInvoice!.shippingAddress ?? "";
      _shippingGstinController.text = widget.existingInvoice!.shippingGstin ?? "";

      _transporterController.text = widget.existingInvoice!.transporterName ?? "";
      _vehicleNoController.text = widget.existingInvoice!.vehicleNumber ?? "";
      _grNoController.text = widget.existingInvoice!.grNumber ?? "";
      _ewayBillController.text = widget.existingInvoice!.ewayBillNumber ?? "";
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _shippingNameController.dispose();
    _shippingAddressController.dispose();
    _shippingGstinController.dispose();
    _transporterController.dispose();
    _vehicleNoController.dispose();
    _grNoController.dispose();
    _ewayBillController.dispose();
    super.dispose();
  }

  void _syncSelectedCustomer(List<CustomerModel>? customers) {
    if (widget.existingInvoice != null && _selectedCustomer == null && customers != null) {
      final match = customers.where((c) => c.id == widget.existingInvoice!.customerId).firstOrNull;
      if (match != null) {
        setState(() {
           _selectedCustomer = match;
        });
      }
    }
  }

  void _updateShippingFromBilling() {
    if (_selectedCustomer != null) {
      _shippingNameController.text = _selectedCustomer!.name;
      _shippingAddressController.text = _selectedCustomer!.address ?? "";
      _shippingGstinController.text = _selectedCustomer!.gstin ?? "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final itemsAsync = ref.watch(itemListProvider);
    final nextInvoiceNumber = ref.watch(nextInvoiceNumberProvider);
    final companyAsync = ref.watch(companyProfileProvider);

    // Auto-populate default terms for NEW invoices when company data is available
    if (!_isRealUpdate && widget.existingInvoice == null && _notesController.text.isEmpty) {
      companyAsync.whenData((profile) {
        if (profile?.defaultTerms != null && profile!.defaultTerms!.isNotEmpty) {
          _notesController.text = profile.defaultTerms!;
        }
      });
    }

    customersAsync.whenData(_syncSelectedCustomer);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          _isReadOnly ? 'View Invoice ${widget.existingInvoice!.invoiceNumber}' : 
          (_isRealUpdate ? 'Edit Invoice ${widget.existingInvoice!.invoiceNumber}' : 'Create New Tax Invoice'), 
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: IgnorePointer(
                ignoring: _isReadOnly,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildBillingAndShipping(customersAsync)),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: Column(
                          children: [
                            _buildInvoiceMeta(nextInvoiceNumber),
                            const SizedBox(height: 24),
                            _buildTransportDetails(),
                          ],
                        )),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildItemsSection(itemsAsync),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildNotesSection()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _buildSummarySection()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(_isReadOnly ? 'Back' : 'Discard', style: const TextStyle(color: Color(0xFF64748B))),
          ),
          if (!_isReadOnly) ...[
            const SizedBox(width: 16),
            SizedBox(
              height: 56,
              width: 220,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                onPressed: _invoiceItems.isEmpty || _selectedCustomer == null ? null : _saveInvoice,
                icon: const Icon(Icons.check_circle_outline),
                label: Text(_isRealUpdate ? 'Update Invoice' : 'Save Invoice', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransportDetails() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Transport Details'),
            const SizedBox(height: 20),
            TextField(controller: _transporterController, decoration: _buildInputDecoration('Transporter Name', Icons.local_shipping_outlined)),
            const SizedBox(height: 16),
            TextField(controller: _vehicleNoController, decoration: _buildInputDecoration('Vehicle No.', Icons.tag)),
            const SizedBox(height: 16),
            TextField(controller: _grNoController, decoration: _buildInputDecoration('G/R No.', Icons.numbers)),
            const SizedBox(height: 16),
            TextField(controller: _ewayBillController, decoration: _buildInputDecoration('E-Way Bill No.', Icons.receipt_long)),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingAndShipping(AsyncValue<List<CustomerModel>> customersAsync) {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Billed To'),
                const SizedBox(height: 20),
                customersAsync.when(
                  data: (customers) => DropdownButtonFormField<CustomerModel>(
                    value: _selectedCustomer,
                    decoration: _buildInputDecoration('Select Customer', Icons.person_outline),
                    items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: _isReadOnly ? null : (val) {
                      setState(() {
                         _selectedCustomer = val;
                         // Always update the controllers so they are ready if toggle is flipped to False
                         _updateShippingFromBilling();
                      });
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading customers: $e'),
                ),
                if (_selectedCustomer != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GSTIN: ${_selectedCustomer!.gstin ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        const SizedBox(height: 4),
                        Text(_selectedCustomer!.address ?? "", style: const TextStyle(color: Color(0xFF64748B))),
                        Text('${_selectedCustomer!.state ?? ""} (${_selectedCustomer!.stateCode ?? ""})', style: const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionLabel('Shipped To'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Same as Billing', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        const SizedBox(width: 8),
                        Switch(
                          value: _isSameAsBilling,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) {
                            setState(() {
                              _isSameAsBilling = val;
                              // On every toggle, ensure shipping controllers match billing info
                              _updateShippingFromBilling();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!_isSameAsBilling) ...[
                  TextField(
                    controller: _shippingNameController,
                    decoration: _buildInputDecoration('Shipping Name', Icons.business_outlined),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shippingAddressController,
                    decoration: _buildInputDecoration('Shipping Address', Icons.location_on_outlined),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _shippingGstinController,
                    decoration: _buildInputDecoration('Shipping GSTIN', Icons.tag),
                  ),
                ] else ...[
                  if (_selectedCustomer != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFDCFCE7))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                          Text(_selectedCustomer!.address ?? "", style: const TextStyle(color: Color(0xFF166534))),
                          Text('GSTIN: ${_selectedCustomer!.gstin ?? "N/A"}', style: const TextStyle(color: Color(0xFF166534))),
                        ],
                      ),
                    )
                  else
                    const Center(child: Text('Select a customer to mirror billing details', style: TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)))),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceMeta(AsyncValue<String> nextNumber) {
    final displayNum = widget.existingInvoice?.invoiceNumber ?? nextNumber.value ?? "Loading...";
    
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Invoice Details'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice #', style: TextStyle(color: Color(0xFF64748B))),
                Text(displayNum, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _isReadOnly ? null : () async {
                final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: _buildInputDecoration('Invoice Date', Icons.calendar_today_outlined),
                child: Text(DateFormat('dd-MMM-yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: SwitchListTile(
                title: const Text('Inter-state (IGST)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                subtitle: const Text('Customer is outside your state', style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF))),
                value: _isInterState,
                onChanged: _isReadOnly ? null : (val) => setState(() => _isInterState = val ?? false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(AsyncValue<List<ItemModel>> itemsAsync) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: [
                _buildSectionLabel('Invoice Items'),
                const Spacer(),
                if (!_isReadOnly)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    onPressed: () => _addItemDialog(itemsAsync),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 32,
              columns: const [
                DataColumn(label: SizedBox(width: 300, child: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold)))),
                DataColumn(label: SizedBox(width: 100, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))), numeric: true),
                DataColumn(label: SizedBox(width: 140, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))), numeric: true),
                DataColumn(label: SizedBox(width: 100, child: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold))), numeric: true),
                DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('')), 
              ],
              rows: _invoiceItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return DataRow(cells: [
                  DataCell(Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.w500))),
                  DataCell(
                    _isReadOnly 
                    ? Text(item.quantity.toString())
                    : TextFormField(
                        initialValue: item.quantity.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                        onChanged: (val) {
                          final newVal = double.tryParse(val);
                          if (newVal != null) {
                            setState(() => _invoiceItems[idx] = item.copyWith(quantity: newVal));
                          }
                        },
                      ),
                  ),
                  DataCell(
                    _isReadOnly 
                    ? Text('₹${item.price.toStringAsFixed(2)}')
                    : TextFormField(
                        initialValue: item.price.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(prefixText: '₹', border: InputBorder.none),
                        onChanged: (val) {
                          final newVal = double.tryParse(val);
                          if (newVal != null) {
                            setState(() => _invoiceItems[idx] = item.copyWith(price: newVal));
                          }
                        },
                      ),
                  ),
                  DataCell(
                    _isReadOnly 
                    ? Text('${item.gstRate}%')
                    : TextFormField(
                        initialValue: item.gstRate.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(suffixText: '%', border: InputBorder.none),
                        onChanged: (val) {
                          final newVal = double.tryParse(val);
                          if (newVal != null) {
                            setState(() => _invoiceItems[idx] = item.copyWith(gstRate: newVal));
                          }
                        },
                      ),
                  ),
                  DataCell(Text('₹${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                  DataCell(
                    _isReadOnly 
                    ? const SizedBox.shrink() 
                    : IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), 
                        onPressed: () => setState(() => _invoiceItems.removeAt(idx))
                      )
                  ),
                ]);
              }).toList(),
            ),
          ),
          if (_invoiceItems.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Click "Add Item" to populate your invoice', style: TextStyle(color: Color(0xFF94A3B8))))),
        ],
      ),
    );
  }

  void _addItemDialog(AsyncValue<List<ItemModel>> itemsAsync) {
    ItemModel? selectedItem;
    final qtyController = TextEditingController(text: '1');
    final priceController = TextEditingController();
    final gstRateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Product to Invoice', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  itemsAsync.when(
                    data: (items) => DropdownButtonFormField<ItemModel>(
                      decoration: _buildInputDecoration('Select Product', Icons.inventory_2_outlined),
                      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.name))).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedItem = val;
                          if (val != null) {
                            priceController.text = val.price.toString();
                            gstRateController.text = val.gstRate.toString();
                          }
                        });
                      },
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(flex: 1, child: TextField(controller: qtyController, decoration: _buildInputDecoration('Quantity', Icons.add_box_outlined), keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: TextField(controller: priceController, decoration: _buildInputDecoration('Unit Price', Icons.payments_outlined).copyWith(prefixText: '₹'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: TextField(controller: gstRateController, decoration: _buildInputDecoration('GST %', Icons.percent), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B)))),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () {
                            if (selectedItem != null) {
                              setState(() {
                                _invoiceItems.add(InvoiceItem(
                                  itemName: selectedItem!.name,
                                  hsn: selectedItem!.hsn,
                                  quantity: double.tryParse(qtyController.text) ?? 1.0,
                                  price: double.tryParse(priceController.text) ?? selectedItem!.price,
                                  gstRate: double.tryParse(gstRateController.text) ?? selectedItem!.gstRate,
                                ));
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Add to List', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final taxable = GSTCalculator.calculateTotalTaxableAmount(_invoiceItems);
    final gstTotal = GSTCalculator.calculateTotalGst(_invoiceItems);
    final total = taxable + gstTotal;

    return Card(
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummaryRow('Taxable Amount', taxable, isHighlight: false),
            const SizedBox(height: 12),
            _buildSummaryRow('Total GST', gstTotal, isHighlight: false),
            const Divider(height: 32, color: Color(0xFF334155)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF38BDF8))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {required bool isHighlight}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8))),
        Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFFE2E8F0))),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('Terms / Notes'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController, 
              maxLines: 6, 
              readOnly: _isReadOnly,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                hintText: 'Enter bank details, terms of payment, or additional notes here...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                fillColor: const Color(0xFFF8FAFC),
                filled: true,
              )
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label, 
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF94A3B8)), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF2563EB))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: true,
      fillColor: Colors.white,
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB), letterSpacing: 1.2));
  }

  void _saveInvoice() async {
    final invNumber = widget.existingInvoice?.id == null 
        ? (ref.read(nextInvoiceNumberProvider).value ?? "INV-TEMP")
        : widget.existingInvoice!.invoiceNumber;

    final taxBreakup = GSTCalculator.calculateTaxBreakup(_invoiceItems, _isInterState);
    final taxable = GSTCalculator.calculateTotalTaxableAmount(_invoiceItems);
    final gstTotal = GSTCalculator.calculateTotalGst(_invoiceItems);

    final invoice = Invoice(
      id: _isRealUpdate ? widget.existingInvoice!.id : null,
      invoiceNumber: invNumber,
      date: _selectedDate,
      customerId: _selectedCustomer!.id!,
      items: _invoiceItems,
      taxBreakups: taxBreakup,
      totalTaxableAmount: taxable,
      totalGst: gstTotal,
      totalAmount: taxable + gstTotal,
      isInterState: _isInterState,
      notes: _notesController.text,
      status: 'draft',
      shippingName: _isSameAsBilling ? null : _shippingNameController.text,
      shippingAddress: _isSameAsBilling ? null : _shippingAddressController.text,
      shippingGstin: _isSameAsBilling ? null : _shippingGstinController.text,
      isSameAsBilling: _isSameAsBilling,
      transporterName: _transporterController.text,
      vehicleNumber: _vehicleNoController.text,
      grNumber: _grNoController.text,
      ewayBillNumber: _ewayBillController.text,
    );

    await ref.read(invoiceListProvider.notifier).saveInvoice(invoice);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isRealUpdate ? 'Invoice updated successfully!' : 'Invoice saved successfully!')));
      ref.invalidate(nextInvoiceNumberProvider);
      Navigator.pop(context);
    }
  }
}

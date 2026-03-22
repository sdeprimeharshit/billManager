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
        setState(() => _selectedCustomer = match);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider);
    final itemsAsync = ref.watch(itemListProvider);
    final nextInvoiceNumber = ref.watch(nextInvoiceNumberProvider);

    customersAsync.whenData(_syncSelectedCustomer);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isReadOnly ? 'View Invoice ${widget.existingInvoice!.invoiceNumber}' : 
                   (_isRealUpdate ? 'Edit Invoice ${widget.existingInvoice!.invoiceNumber}' : 'Create New Tax Invoice'), 
          style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        Expanded(flex: 3, child: _buildBillingAndShipping(customersAsync)),
                        const SizedBox(width: 32),
                        Expanded(flex: 1, child: Column(
                          children: [
                            _buildInvoiceMeta(nextInvoiceNumber),
                            const SizedBox(height: 16),
                            _buildTransportDetails(),
                          ],
                        )),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildItemsSection(itemsAsync),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildNotesSection()),
                        const SizedBox(width: 32),
                        Expanded(child: _buildSummarySection()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20)),
                  onPressed: () => Navigator.pop(context),
                  child: Text(_isReadOnly ? 'Back' : 'Discard'),
                ),
                if (!_isReadOnly) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 56,
                    width: 250,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: _invoiceItems.isEmpty || _selectedCustomer == null ? null : _saveInvoice,
                      icon: const Icon(Icons.check),
                      label: Text(_isRealUpdate ? 'Update Invoice' : 'Save Invoice'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportDetails() {
    return Card(
      elevation: 0,
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
            const SizedBox(height: 16),
            TextField(controller: _transporterController, decoration: _buildInputDecoration('Transporter Name', Icons.local_shipping_outlined)),
            const SizedBox(height: 12),
            TextField(controller: _vehicleNoController, decoration: _buildInputDecoration('Vehicle No.', Icons.tag)),
            const SizedBox(height: 12),
            TextField(controller: _grNoController, decoration: _buildInputDecoration('G/R No.', Icons.numbers)),
            const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                customersAsync.when(
                  data: (customers) => DropdownButtonFormField<CustomerModel>(
                    value: _selectedCustomer,
                    decoration: _buildInputDecoration('Select Customer', Icons.person_outline),
                    items: customers.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: _isReadOnly ? null : (val) => setState(() => _selectedCustomer = val),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error loading customers: $e'),
                ),
                if (_selectedCustomer != null) ...[
                  const SizedBox(height: 16),
                  Text('GSTIN: ${_selectedCustomer!.gstin ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_selectedCustomer!.address ?? ""),
                  Text('${_selectedCustomer!.state ?? ""} (${_selectedCustomer!.stateCode ?? ""})'),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
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
                        const Text('Same as Billing', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Switch(
                          value: _isSameAsBilling,
                          onChanged: (val) {
                            setState(() {
                              _isSameAsBilling = val;
                              if (val && _selectedCustomer != null) {
                                _shippingNameController.text = _selectedCustomer!.name;
                                _shippingAddressController.text = _selectedCustomer!.address ?? "";
                                _shippingGstinController.text = _selectedCustomer!.gstin ?? "";
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_isSameAsBilling) ...[
                  TextField(
                    controller: _shippingNameController,
                    decoration: _buildInputDecoration('Shipping Name', Icons.business_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _shippingAddressController,
                    decoration: _buildInputDecoration('Shipping Address', Icons.location_on_outlined),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _shippingGstinController,
                    decoration: _buildInputDecoration('Shipping GSTIN', Icons.tag),
                  ),
                ] else ...[
                  if (_selectedCustomer != null) ...[
                    Text(_selectedCustomer!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(_selectedCustomer!.address ?? ""),
                    Text('GSTIN: ${_selectedCustomer!.gstin ?? "N/A"}'),
                  ] else
                    const Text('Select a customer or disable "Same as Billing" to enter details.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
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
            const SizedBox(height: 16),
            Text('Number: $displayNum', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isReadOnly ? null : () async {
                final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: _buildInputDecoration('Date', Icons.calendar_today_outlined),
                child: Text(DateFormat('dd-MMM-yyyy').format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Inter-state (IGST)'),
              subtitle: const Text('Check if customer is outside your state'),
              value: _isInterState,
              onChanged: _isReadOnly ? null : (val) => setState(() => _isInterState = val ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(AsyncValue<List<ItemModel>> itemsAsync) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: Row(
              children: [
                _buildSectionLabel('Invoice Items'),
                const Spacer(),
                if (!_isReadOnly)
                  FilledButton.icon(
                    onPressed: () => _addItemDialog(itemsAsync),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
              ],
            ),
          ),
          DataTable(
            columns: const [
              DataColumn(label: Text('Item')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Price'), numeric: true),
              DataColumn(label: Text('GST %'), numeric: true),
              DataColumn(label: Text('Total'), numeric: true),
              DataColumn(label: Text('')), 
            ],
            rows: _invoiceItems.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return DataRow(cells: [
                DataCell(Text(item.itemName)),
                DataCell(Text(item.quantity.toString())),
                DataCell(Text('₹${item.price.toStringAsFixed(2)}')),
                DataCell(Text('${item.gstRate}%')),
                DataCell(Text('₹${item.total.toStringAsFixed(2)}')),
                DataCell(
                  _isReadOnly 
                  ? const SizedBox.shrink() 
                  : IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red), 
                      onPressed: () => setState(() => _invoiceItems.removeAt(idx))
                    )
                ),
              ]);
            }).toList(),
          ),
          if (_invoiceItems.isEmpty) const Padding(padding: EdgeInsets.all(32), child: Text('No items added yet.')),
        ],
      ),
    );
  }

  void _addItemDialog(AsyncValue<List<ItemModel>> itemsAsync) {
    ItemModel? selectedItem;
    final qtyController = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item to Invoice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            itemsAsync.when(
              data: (items) => DropdownButtonFormField<ItemModel>(
                decoration: const InputDecoration(labelText: 'Select Product'),
                items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.name))).toList(),
                onChanged: (val) => selectedItem = val,
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (selectedItem != null) {
                setState(() {
                  _invoiceItems.add(InvoiceItem(
                    itemName: selectedItem!.name,
                    hsn: selectedItem!.hsn,
                    quantity: double.tryParse(qtyController.text) ?? 1.0,
                    price: selectedItem!.price,
                    gstRate: selectedItem!.gstRate,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    final taxable = GSTCalculator.calculateTotalTaxableAmount(_invoiceItems);
    final gstTotal = GSTCalculator.calculateTotalGst(_invoiceItems);
    final total = taxable + gstTotal;

    return Card(
      elevation: 0,
      color: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummaryRow('Taxable Amount', taxable),
            _buildSummaryRow('Total GST', gstTotal),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
          Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Terms / Notes'),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController, 
          maxLines: 5, 
          readOnly: _isReadOnly,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Bank details, terms of payment, etc.')
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20), border: const OutlineInputBorder());
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
      shippingName: _isSameAsBilling ? _selectedCustomer!.name : _shippingNameController.text,
      shippingAddress: _isSameAsBilling ? _selectedCustomer!.address : _shippingAddressController.text,
      shippingGstin: _isSameAsBilling ? _selectedCustomer!.gstin : _shippingGstinController.text,
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

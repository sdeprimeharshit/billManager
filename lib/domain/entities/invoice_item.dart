class InvoiceItem {
  final String? id;
  final String itemName;
  final String? hsn;
  final double quantity;
  final double price; // Unit price before tax
  final double gstRate; // Percentage (e.g., 18.0)

  InvoiceItem({
    this.id,
    required this.itemName,
    this.hsn,
    required this.quantity,
    required this.price,
    required this.gstRate,
  });

  double get taxableValue => quantity * price;
  double get gstAmount => (taxableValue * gstRate) / 100;
  double get total => taxableValue + gstAmount;
}

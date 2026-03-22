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

  double get taxableValue => double.parse((quantity * price).toStringAsFixed(2));
  
  double get gstAmount => double.parse(((taxableValue * gstRate) / 100).toStringAsFixed(2));
  
  double get total => double.parse((taxableValue + gstAmount).toStringAsFixed(2));

  InvoiceItem copyWith({
    String? id,
    String? itemName,
    String? hsn,
    double? quantity,
    double? price,
    double? gstRate,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      itemName: itemName ?? this.itemName,
      hsn: hsn ?? this.hsn,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      gstRate: gstRate ?? this.gstRate,
    );
  }
}

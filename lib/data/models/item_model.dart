class ItemModel {
  final int? id;
  final String name;
  final String? hsn;
  final String unit;
  final double price;
  final double gstRate;

  ItemModel({
    this.id,
    required this.name,
    this.hsn,
    required this.unit,
    required this.price,
    required this.gstRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hsn': hsn,
      'unit': unit,
      'price': price,
      'gst_rate': gstRate,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      name: map['name'],
      hsn: map['hsn'],
      unit: map['unit'],
      price: (map['price'] as num).toDouble(),
      gstRate: (map['gst_rate'] as num).toDouble(),
    );
  }
}

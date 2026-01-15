class TaxBreakup {
  final double gstRate;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;

  TaxBreakup({
    required this.gstRate,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
  });

  double get totalTax => cgst + sgst + igst;
}

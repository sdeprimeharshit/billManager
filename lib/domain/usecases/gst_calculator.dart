import '../entities/invoice_item.dart';
import '../entities/tax_breakup.dart';

class GSTCalculator {
  static List<TaxBreakup> calculateTaxBreakup(
      List<InvoiceItem> items, bool isInterState) {
    Map<double, double> rateToTaxableValue = {};

    for (var item in items) {
      rateToTaxableValue[item.gstRate] =
          round((rateToTaxableValue[item.gstRate] ?? 0) + item.taxableValue);
    }

    return rateToTaxableValue.entries.map((entry) {
      double rate = entry.key;
      double taxableValue = entry.value;
      double totalGst = round((taxableValue * rate) / 100);

      if (isInterState) {
        return TaxBreakup(
          gstRate: rate,
          taxableValue: taxableValue,
          cgst: 0,
          sgst: 0,
          igst: totalGst,
        );
      } else {
        return TaxBreakup(
          gstRate: rate,
          taxableValue: taxableValue,
          cgst: round(totalGst / 2),
          sgst: round(totalGst / 2),
          igst: 0,
        );
      }
    }).toList();
  }

  static double calculateTotalTaxableAmount(List<InvoiceItem> items) {
    return round(items.fold(0.0, (sum, item) => sum + item.taxableValue));
  }

  static double calculateTotalGst(List<InvoiceItem> items) {
    return round(items.fold(0.0, (sum, item) => sum + item.gstAmount));
  }

  static double round(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

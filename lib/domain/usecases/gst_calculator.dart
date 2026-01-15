import '../entities/invoice_item.dart';
import '../entities/tax_breakup.dart';

class GSTCalculator {
  static List<TaxBreakup> calculateTaxBreakup(
      List<InvoiceItem> items, bool isInterState) {
    Map<double, double> rateToTaxableValue = {};

    for (var item in items) {
      rateToTaxableValue[item.gstRate] =
          (rateToTaxableValue[item.gstRate] ?? 0) + item.taxableValue;
    }

    return rateToTaxableValue.entries.map((entry) {
      double rate = entry.key;
      double taxableValue = entry.value;
      double totalGst = (taxableValue * rate) / 100;

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
          cgst: totalGst / 2,
          sgst: totalGst / 2,
          igst: 0,
        );
      }
    }).toList();
  }

  static double calculateTotalTaxableAmount(List<InvoiceItem> items) {
    return items.fold(0, (sum, item) => sum + item.taxableValue);
  }

  static double calculateTotalGst(List<InvoiceItem> items) {
    return items.fold(0, (sum, item) => sum + item.gstAmount);
  }

  static double round(double value) {
    return double.parse(value.toStringAsFixed(2));
  }
}

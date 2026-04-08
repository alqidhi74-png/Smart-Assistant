import 'package:flutter_test/flutter_test.dart';
import 'package:smart_assistant/models/invoice_model.dart';
import 'package:smart_assistant/services/invoice_nlp_extraction_service.dart';
import 'package:smart_assistant/services/text_cleaning_service.dart';

void main() {
  const sampleOcr = '''
NAMA Electricity Supply Bill
Account No: 123456789012
Invoice No: INV-88421
Invoice Date: 15/03/2025
Units Consumed (kWh): 1,245.50
Total Due: 67.200 OMR
Current Month Charges: 65.000
Number of days: 30
''';

  test('NLP extracts fields with confidence from English-only OCR text', () {
    const cleaning = TextCleaningService();
    final cleaned = cleaning.cleanAndNormalize(sampleOcr);
    const nlp = InvoiceNlpExtractionService();
    final result = nlp.extract(cleaned);

    expect(result.invoiceType.value, InvoiceType.electricity);
    expect(result.invoiceType.confidence, greaterThan(0.7));

    expect(result.accountNumber.value, '123456789012');
    expect(result.accountNumber.confidence, greaterThan(0.8));

    expect(result.invoiceNumber.value, contains('88421'));
    expect(result.totalAmount.value, closeTo(67.2, 0.01));
    expect(result.totalAmount.confidence, greaterThan(0.85));

    expect(result.consumptionValue.value, closeTo(1245.5, 0.01));
    expect(result.consumptionUnit.value, 'kWh');

    expect(result.consumptionDays.value, 30);

    final json = result.toJson();
    expect(json['total_amount'], isA<Map<String, dynamic>>());
    expect(json['total_amount']['confidence'], isNotNull);
  });
}

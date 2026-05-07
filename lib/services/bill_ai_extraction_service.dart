import 'dart:convert';
import '../models/bill_analysis.dart';
import 'openrouter_chat_service.dart';

class BillAiExtractionService {
  final OpenRouterChatService _chatService = OpenRouterChatService();

  Future<BillAnalysisResult> extractStructuredData(String rawText) async {
    const systemPrompt = '''
You are a specialist in analyzing utility bills (Electricity and Water) specifically for the Omani market (e.g., Nama, Majan, Dhofar, Oman Water, etc.).
Your task is to extract structured data from the provided raw OCR text and return ONLY a valid JSON object.

EXTRACTION RULES:
1. billType: Must be "Electricity" or "Water".
2. accountNumber: Look for "Account No" or "رقم الحساب". In Omani bills (Nama/Majan), this is usually a shorter number (around 7-10 digits). EXTREMELY IMPORTANT: Extract the number exactly as it appears. Do NOT guess or generate random numbers. If not found or illegible, return null.
3. invoiceNumber: Look for "Invoice No" or "رقم الفاتورة". In Omani bills, this is usually a very long unique number (15+ digits). Extract exactly as it appears.
4. invoiceDate: The date the bill was issued (YYYY-MM-DD).
5. totalAmount: The final amount due or total charges. Return as a number.
6. consumptionValue: Look for "Consumption", "الاستهلاك", or "units used". Return as a number.
7. consumptionUnit: "kWh" for electricity, "m3" for water.
8. billingMonthText: The readable month/year (e.g., "March 2025" or "مارس 2024").
9. billingMonthKey: The year and month in YYYY-MM format.

IMPORTANT: Do not confuse Account Number with Invoice Number. 
- Account Number is the customer identification.
- Invoice Number is the unique identifier for this specific month's bill.

JSON STRUCTURE (Return ONLY this):
{
  "billType": "...",
  "accountNumber": "...",
  "invoiceNumber": "...",
  "invoiceDate": "...",
  "totalAmount": 0.0,
  "consumptionValue": 0.0,
  "consumptionUnit": "...",
  "billingMonthText": "...",
  "billingMonthKey": "..."
}

If a field is not found, return null for that field. 
Do NOT include any explanations or markdown symbols.
''';

    try {
      final response = await _chatService.sendScopedMessage(
        systemPrompt: systemPrompt,
        userPrompt: 'Raw bill text:\n$rawText',
      );

      final cleanJson = _sanitizeJsonResponse(response);
      final Map<String, dynamic> data = jsonDecode(cleanJson);

      return BillAnalysisResult(
        rawText: rawText,
        billType: data['billType'],
        accountNumber: data['accountNumber']?.toString(),
        invoiceNumber: data['invoiceNumber']?.toString(),
        invoiceDate: data['invoiceDate'],
        totalAmount: _toDouble(data['totalAmount']),
        consumptionValue: _toDouble(data['consumptionValue']),
        consumptionUnit: data['consumptionUnit'],
        billingMonthText: data['billingMonthText'],
        billingMonthKey: data['billingMonthKey'],
      );
    } catch (e) {
      print('AI Extraction failed: $e');
      // Return a result with raw text so local NLP can be used as fallback
      return BillAnalysisResult(rawText: rawText);
    }
  }

  String _sanitizeJsonResponse(String response) {
    var s = response.trim();
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'^```json\s*'), '');
      s = s.replaceAll(RegExp(r'\s*```$'), '');
      s = s.replaceAll(RegExp(r'^```\s*'), '');
    }
    return s;
  }

  double? _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}

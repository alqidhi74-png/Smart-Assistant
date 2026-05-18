import 'package:flutter/material.dart';
import 'navbar.dart';
import '../constants/language.dart';
import '../models/bill_summary.dart';
import '../utils/bill_type_utils.dart';
import '../utils/omr_format.dart';
import '../services/openrouter_chat_service.dart';
import '../constants/api_keys.dart';

class BillDetailsPage extends StatefulWidget {
  final BillSummary bill;

  const BillDetailsPage({super.key, required this.bill});

  @override
  State<BillDetailsPage> createState() => _BillDetailsPageState();
}

class _BillDetailsPageState extends State<BillDetailsPage> {
  String? _aiSummary;
  String? _errorMessage;
  bool _isLoading = true;
  bool _didFetch = false;
  final _chatService = OpenRouterChatService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didFetch) {
      _didFetch = true;
      _fetchAiSummary();
    }
  }

  Future<void> _fetchAiSummary() async {
    try {
      final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('ar'));
      final isAr = loc.locale.languageCode == 'ar';
      
      if (ApiKeys.openRouterKey.isEmpty) {
        throw Exception(isAr ? 'مفتاح API غير موجود' : 'API Key is missing');
      }
      final systemPrompt = isAr 
        ? 'أنت مساعد ذكي خبير في تحليل فواتير الكهرباء والمياه في سلطنة عمان. قدم ملخصاً ذكياً ومختصراً جداً (3 أسطر كحد أقصى) باللغة العربية. إذا كان المبلغ والاستهلاك منخفضاً (ممتاز)، شجع المستخدم بذكاء على الاستمرار. أما إذا كان مرتفعاً بشكل غير معتاد، فقدم نصيحة واحدة سريعة عن السبب المرجح.'
        : 'You are an AI expert in analyzing utility bills in Oman. Provide a very concise smart summary (max 3 lines). If the amount and usage are low (excellent), encourage the user to keep it up. Only if it is unusually high, provide one quick tip about the likely cause.';

      final userPrompt = isAr
        ? 'الفئة: ${widget.bill.type}، المبلغ: ${widget.bill.totalAmount} ريال، الاستهلاك: ${widget.bill.consumptionValue} ${widget.bill.consumptionUnit}، التاريخ: ${widget.bill.dateText}.'
        : 'Type: ${widget.bill.type}, Amount: ${widget.bill.totalAmount} OMR, Usage: ${widget.bill.consumptionValue} ${widget.bill.consumptionUnit}, Date: ${widget.bill.dateText}.';

      final response = await _chatService.sendScopedMessage(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );

      if (mounted) {
        setState(() {
          _aiSummary = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isElectricity = BillTypeUtils.isElectricity(widget.bill.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(localizations.locale.languageCode == 'ar' ? 'تحليل الفاتورة' : 'Bill Analysis', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildAiInsightCard(localizations, isDark),
                const SizedBox(height: 10),
                _buildInfoField(localizations.billType, isElectricity ? localizations.billTypeElectricity : localizations.billTypeWater, icon: isElectricity ? Icons.bolt : Icons.water_drop),
                _buildInfoField(localizations.invoiceDate, widget.bill.dateText, icon: Icons.calendar_today_outlined),
                _buildInfoField(localizations.totalAmount, OmrFormat.amount(widget.bill.totalAmount ?? 0, localizations)),
                _buildInfoField(localizations.consumption, '${widget.bill.consumptionValue?.toStringAsFixed(0) ?? '0'} ${widget.bill.consumptionUnit ?? ''}'),
                _buildInfoField(localizations.invoiceNumberTitle, widget.bill.invoiceNumber ?? localizations.noDataFound),
                _buildInfoField(localizations.accountNumber, widget.bill.accountNumber ?? localizations.noDataFound),
                _buildInfoField(localizations.billingMonthTitle, widget.bill.billingMonthText ?? localizations.noDataFound, icon: Icons.calendar_month_outlined),
              ],
            ),
          ),
          _buildBottomAction(context, localizations),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(AppLocalizations loc, bool isDark) {
    final isAr = loc.locale.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!.withOpacity(0.4), Colors.blue[600]!.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                isAr ? 'تفسير الذكاء الاصطناعي' : 'AI Interpretation',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              if (_isLoading) ...[
                const Spacer(),
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            _buildShimmerText()
          else if (_aiSummary != null)
            Text(
              _aiSummary!,
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
            )
          else
            Text(
              _errorMessage ?? (isAr ? 'عذراً، تعذر الحصول على تحليل حالياً.' : 'Sorry, could not fetch analysis at this time.'),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: double.infinity, height: 10, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(5))),
        const SizedBox(height: 8),
        Container(width: 200, height: 10, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(5))),
      ],
    );
  }

  Widget _buildInfoField(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                if (icon != null) Icon(icon, color: Colors.blue[400], size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context, AppLocalizations loc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(color: Color(0xFF121212)),
      child: ElevatedButton.icon(
        onPressed: () {
          final isAr = loc.locale.languageCode == 'ar';
          final billDesc = isAr
              ? 'فاتورة ${widget.bill.billingMonthText ?? ''} بقيمة ${OmrFormat.amount(widget.bill.totalAmount ?? 0, loc)}'
              : '${widget.bill.billingMonthText ?? ''} bill of ${OmrFormat.amount(widget.bill.totalAmount ?? 0, loc)}';

          final prompt = isAr
              ? 'هل يمكنك شرح تفاصيل هذه الفاتورة لي؟ ($billDesc). لماذا قد تكون مرتفعة وما هي نصائحك؟'
              : 'Can you explain the details of this bill to me? ($billDesc). Why might it be high and what are your tips?';

          Navigator.pop(context); 
          UserNavBar.switchTab(2, chatbotMessage: prompt);
        },
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: Text(
          loc.locale.languageCode == 'ar' ? 'ناقش التحليل في الشات' : 'Discuss in Chat',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00B0FF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      ),
    );
  }
}

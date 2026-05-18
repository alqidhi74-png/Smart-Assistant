import 'package:flutter/material.dart';
import 'navbar.dart';
import '../constants/colors.dart';
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
      final loc = AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

      if (ApiKeys.openRouterKey.isEmpty) {
        throw Exception(loc.apiKeyMissing);
      }
      final systemPrompt = loc.aiBillAnalysisSystemPrompt();
      final userPrompt = loc.aiBillAnalysisUserPrompt(
        type: widget.bill.type,
        totalAmount: widget.bill.totalAmount,
        consumptionValue: widget.bill.consumptionValue,
        consumptionUnit: widget.bill.consumptionUnit,
        dateText: widget.bill.dateText,
      );

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
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          localizations.billAnalysisTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildAiInsightCard(localizations, isDark),
                const SizedBox(height: 10),
                _buildInfoField(localizations.billType, isElectricity ? localizations.billTypeElectricity : localizations.billTypeWater, isDark: isDark, icon: isElectricity ? Icons.bolt : Icons.water_drop),
                _buildInfoField(localizations.invoiceDate, widget.bill.dateText, isDark: isDark, icon: Icons.calendar_today_outlined),
                _buildInfoField(localizations.totalAmount, OmrFormat.amount(widget.bill.totalAmount ?? 0, localizations), isDark: isDark),
                _buildInfoField(localizations.consumption, '${widget.bill.consumptionValue?.toStringAsFixed(0) ?? '0'} ${widget.bill.consumptionUnit ?? ''}', isDark: isDark),
                _buildInfoField(localizations.invoiceNumberTitle, widget.bill.invoiceNumber ?? localizations.noDataFound, isDark: isDark),
                _buildInfoField(localizations.accountNumber, widget.bill.accountNumber ?? localizations.noDataFound, isDark: isDark),
                _buildInfoField(localizations.billingMonthTitle, widget.bill.billingMonthText ?? localizations.noDataFound, isDark: isDark, icon: Icons.calendar_month_outlined),
              ],
            ),
          ),
          _buildBottomAction(context, localizations, isDark: isDark, background: background),
        ],
      ),
    );
  }

  Widget _buildAiInsightCard(AppLocalizations loc, bool isDark) {
    final bodyText = isDark ? Colors.white : AppColors.textDark;
    final mutedBody = isDark ? Colors.white54 : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.12),
            AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                loc.aiInterpretation,
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
              style: TextStyle(color: bodyText, fontSize: 13, height: 1.5),
            )
          else
            Text(
              _errorMessage ?? loc.aiAnalysisUnavailable,
              style: TextStyle(color: mutedBody, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmerText() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerFill =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.06);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            color: shimmerFill,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 200,
          height: 10,
          decoration: BoxDecoration(
            color: shimmerFill,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoField(
    String label,
    String value, {
    required bool isDark,
    IconData? icon,
  }) {
    final labelColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final valueColor = isDark ? Colors.white : AppColors.textDark;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: labelColor, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (icon != null)
                  Icon(icon, color: AppColors.primary, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction(
    BuildContext context,
    AppLocalizations loc, {
    required bool isDark,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(color: background),
      child: ElevatedButton.icon(
        onPressed: () {
          final billDesc = loc.billDescriptionForChat(
            widget.bill.billingMonthText ?? '',
            OmrFormat.amount(widget.bill.totalAmount ?? 0, loc),
          );
          final prompt = loc.billDiscussPrompt(billDesc);

          Navigator.pop(context); 
          UserNavBar.switchTab(2, chatbotMessage: prompt);
        },
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
        label: Text(
          loc.discussAnalysisInChat,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 4,
        ),
      ),
    );
  }
}

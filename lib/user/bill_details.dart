import 'package:flutter/material.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../models/bill_summary.dart';
import '../utils/bill_type_utils.dart';
import '../utils/omr_format.dart';

class BillDetailsPage extends StatelessWidget {
  final BillSummary bill;

  const BillDetailsPage({super.key, required this.bill});

  String _localizedType(AppLocalizations loc) {
    if (BillTypeUtils.isElectricity(bill.type)) return loc.billTypeElectricity;
    if (BillTypeUtils.isWater(bill.type)) return loc.billTypeWater;
    return bill.type;
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    final consumptionHint =
        BillTypeUtils.isElectricity(bill.type)
            ? localizations.consumptionElectricityHint
            : BillTypeUtils.isWater(bill.type)
            ? localizations.consumptionWaterHint
            : '';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          localizations.analysis,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: background,
        elevation: 0,
        foregroundColor: textColor,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            children: [
              _DetailCard(
                title: localizations.billType,
                value: _localizedType(localizations),
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.invoiceDate,
                value: bill.dateText,
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.billingMonthTitle,
                value: bill.billingMonthText ?? localizations.noDataFound,
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.accountNumber,
                value: bill.accountNumber ?? localizations.noDataFound,
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.invoiceNumberTitle,
                value: bill.invoiceNumber ?? localizations.noDataFound,
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.consumption,
                value: _formatConsumption(
                  bill.consumptionValue,
                  bill.consumptionUnit,
                  consumptionHint,
                  localizations.noDataFound,
                ),
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.currentMonthCharge,
                value: _formatAmount(
                  bill.currentMonthAmount,
                  localizations.noDataFound,
                  localizations,
                ),
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.totalAmount,
                value: _formatAmount(
                  bill.totalAmount,
                  localizations.noDataFound,
                  localizations,
                ),
                mutedText: mutedText,
              ),
              _DetailCard(
                title: localizations.consumptionDaysLabel,
                value:
                    bill.consumptionDays != null
                        ? bill.consumptionDays.toString()
                        : localizations.noDataFound,
                mutedText: mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double? value, String fallback, AppLocalizations loc) {
    if (value == null) return fallback;
    return OmrFormat.amount(value, loc);
  }

  String _formatConsumption(
    double? value,
    String? unit,
    String unitHint,
    String fallback,
  ) {
    if (value == null) return fallback;
    final u = unit ?? '';
    final base =
        u.isEmpty ? value.toStringAsFixed(2) : '${value.toStringAsFixed(2)} $u';
    if (unitHint.isEmpty) return base;
    return '$base ($unitHint)';
  }
}

class _DetailCard extends StatelessWidget {
  final String title;
  final String value;
  final Color mutedText;

  const _DetailCard({
    required this.title,
    required this.value,
    required this.mutedText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : Colors.white.withValues(alpha: 0.85);
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final valueColor = isDark ? Colors.white : AppColors.textDark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: mutedText, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
                  maxLines: 8,
                ),
              ],
            );
          }
          final labelWidth = (constraints.maxWidth * 0.38).clamp(110.0, 180.0);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Text(
                  title,
                  style: TextStyle(color: mutedText, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
                  maxLines: 8,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

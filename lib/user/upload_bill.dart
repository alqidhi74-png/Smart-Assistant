import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../models/bill_analysis.dart';
import '../services/bill_analysis_service.dart';
import '../services/bill_nlp_pipeline.dart';
import '../services/category_policy_service.dart';
import '../services/image_preprocess_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_text_service.dart';
import '../utils/app_snackbar.dart';
import '../services/bill_ai_extraction_service.dart';
import '../utils/loading_overlay.dart';
import '../models/bill_summary.dart';
import '../services/bill_comparison_service.dart';
import '../data/bill_store.dart';
import '../utils/top_notification.dart';
import 'bill_review_page.dart';

class UploadBillPage extends StatefulWidget {
  const UploadBillPage({super.key});

  @override
  State<UploadBillPage> createState() => _UploadBillPageState();
}

class _UploadBillPageState extends State<UploadBillPage> {
  final ImagePicker _imagePicker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final ImagePreprocessService _imagePreprocessService =
      ImagePreprocessService();
  final PdfTextService _pdfTextService = PdfTextService();
  final BillAiExtractionService _aiExtractionService = BillAiExtractionService();
  String? _imagePath;
  bool _isProcessing = false;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (!mounted) return;
    if (result == null || result.files.isEmpty) {
      _showMessage(_localizations.noPdfSelected, isSuccess: false);
      return;
    }
    final file = result.files.single;
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      _showMessage(_localizations.pdfReadError, isSuccess: false);
      return;
    }
    final raw = file.bytes;
    if (raw == null || raw.isEmpty) {
      _showMessage(_localizations.pdfReadError, isSuccess: false);
      return;
    }
    await _processPdfBytes(Uint8List.fromList(raw));
  }

  Future<void> _processPdfBytes(Uint8List bytes) async {
    setState(() {
      _isProcessing = true;
      _imagePath = null; // No preview for PDF usually or we could extract one
    });
    if (mounted) LoadingOverlay.show(context);
    try {
      final text = _pdfTextService.extractText(bytes);
      if (!mounted) return;
      await _finalizeBillFromText(text);
    } on PdfTextException {
      if (!mounted) return;
      LoadingOverlay.hide();
      setState(() => _isProcessing = false);
      _showMessage(_localizations.pdfReadError, isSuccess: false);
    } catch (_) {
      if (!mounted) return;
      LoadingOverlay.hide();
      setState(() => _isProcessing = false);
      _showMessage(_localizations.billProcessingError, isSuccess: false);
    }
  }

  Future<void> _pickImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (image == null) {
      _showMessage(_localizations.noGalleryImageSelected, isSuccess: false);
      return;
    }
    await _processImage(image.path, image.name);
  }

  Future<void> _takeImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (image == null) {
      _showMessage(_localizations.noCameraCapture, isSuccess: false);
      return;
    }
    await _processImage(image.path, image.name);
  }

  void _showMessage(String message, {required bool isSuccess}) {
    if (isSuccess) {
      AppSnackBar.showSuccess(context, message);
    } else {
      AppSnackBar.showError(context, message);
    }
  }

  AppLocalizations get _localizations =>
      AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

  Future<void> _processImage(String path, String fileName) async {
    setState(() {
      _isProcessing = true;
      _imagePath = path;
    });
    if (mounted) LoadingOverlay.show(context);

    try {
      final variants = await _imagePreprocessService.prepareVariantsForOcr(path);
      final best = await _ocrService.extractBestTextResultFromImagePaths(
        variants,
      );
      if (kDebugMode) {
        final logs =
            best.candidates
                .map((c) => '${c.score} :: ${c.path.split('/').last}')
                .join(' | ');
        debugPrint('OCR variants: $logs');
        debugPrint('OCR selected: ${best.bestPath}');
      }
      final text = best.text;
      if (!mounted) return;
      await _finalizeBillFromText(text);
    } catch (_) {
      if (!mounted) return;
      LoadingOverlay.hide();
      setState(() => _isProcessing = false);
      _showMessage(_localizations.billProcessingError, isSuccess: false);
    }
  }

  Future<void> _finalizeBillFromText(String text) async {
    if (text.trim().isEmpty) {
      if (mounted) LoadingOverlay.hide();
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) {
        _showMessage(_localizations.noTextDetected, isSuccess: false);
      }
      return;
    }

    // Try AI Extraction first, then fallback to NLP if needed
    BillAnalysisResult analysis;
    try {
      analysis = await _aiExtractionService.extractStructuredData(text);
      // If AI failed to identify the type or amount, try NLP fallback for those specific fields
      if (analysis.billType == null || (analysis.totalAmount ?? 0) <= 0) {
        final fallback = BillNlpPipeline.analyzeBill(text);
        analysis = BillAnalysisResult(
          rawText: text,
          billType: analysis.billType ?? fallback.billType,
          accountNumber: analysis.accountNumber ?? fallback.accountNumber,
          invoiceNumber: analysis.invoiceNumber ?? fallback.invoiceNumber,
          invoiceDate: analysis.invoiceDate ?? fallback.invoiceDate,
          totalAmount: analysis.totalAmount ?? fallback.totalAmount,
          consumptionValue: analysis.consumptionValue ?? fallback.consumptionValue,
          consumptionUnit: analysis.consumptionUnit ?? fallback.consumptionUnit,
          billingMonthText: analysis.billingMonthText ?? fallback.billingMonthText,
          billingMonthKey: analysis.billingMonthKey ?? fallback.billingMonthKey,
        );
      }
    } catch (_) {
      analysis = BillNlpPipeline.analyzeBill(text);
    }

    if (!BillAnalysisService.isAcceptedUtilityBill(analysis)) {
      if (mounted) LoadingOverlay.hide();
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) {
        _showMessage(_localizations.billOnlyWaterElectricAllowed, isSuccess: false);
      }
      return;
    }
    if (!_isRelevantBill(analysis)) {
      if (mounted) LoadingOverlay.hide();
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) {
        _showMessage(_localizations.unsupportedBill, isSuccess: false);
      }
      return;
    }

    final allowedKinds = await CategoryPolicyService.fetchAllowedUtilityKinds();
    if (!mounted) return;
    if (allowedKinds == null) {
      if (mounted) LoadingOverlay.hide();
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) {
        _showMessage(_localizations.categoriesLoadError, isSuccess: false);
      }
      return;
    }
    if (allowedKinds.isEmpty) {
      if (mounted) LoadingOverlay.hide();
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) {
        _showMessage(_localizations.noUtilityCategoriesConfigured, isSuccess: false);
      }
      return;
    }
    if (!CategoryPolicyService.isBillTypeAllowedByCategories(
      analysis.billType,
      allowedKinds,
    )) {
      if (mounted) LoadingOverlay.hide();
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) {
        _showMessage(_localizations.billTypeRemovedByAdmin, isSuccess: false);
      }
      return;
    }

    if (!mounted) return;
    LoadingOverlay.hide();
    setState(() => _isProcessing = false);

    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder:
            (context) => BillReviewPage(
              analysis: analysis,
              allowedUtilityKinds: allowedKinds,
              imagePath: _imagePath,
            ),
      ),
    );
    if (!mounted) return;
    if (result != null && result is Map) {
      final status = result['status'];
      final primaryMessage =
          status == 'updated'
              ? _localizations.billUpdatedForMonth
              : _localizations.billSavedToMyBills;
      
      _showMessage(
        '$primaryMessage\n${_localizations.billSavedChartsUpdatedHint}',
        isSuccess: true,
      );

      // Comparison Logic
      _showComparisonNotification(result['billType'], result['billingMonthKey']);
    }
  }

  void _showComparisonNotification(String? type, String? monthKey) {
    if (type == null || monthKey == null) return;
    
    // Give it a small delay to ensure BillStore has updated from the saveBill call
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      
      final bills = BillStore.instance.bills.value;
      final newBill = bills.firstWhere(
        (b) => b.type.toLowerCase() == type.toLowerCase() && b.billingMonthKey == monthKey,
        orElse: () => const BillSummary(id: '', type: '', dateText: '', createdAt: 0),
      );

      if (newBill.id.isEmpty) return;

      final comparison = BillComparisonService.compareWithPreviousMonth(newBill, bills);
      if (!comparison.hasPrevious) return;

      final loc = _localizations;
      final typeLabel = comparison.type.toLowerCase() == 'water' 
          ? loc.billTypeWaterLabel 
          : loc.billTypeElectricityLabel;
      
      String msg;
      if (comparison.percentageChange < 0.1) {
        msg = loc.billComparisonEqual(typeLabel);
      } else if (comparison.isIncrease) {
        msg = loc.billComparisonIncrease(typeLabel, comparison.percentageChange.toStringAsFixed(1));
      } else {
        msg = loc.billComparisonDecrease(typeLabel, comparison.percentageChange.toStringAsFixed(1));
      }

      TopNotification.show(context, message: msg, isError: comparison.isIncrease);
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _localizations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(
          localizations.uploadBillTitle,
          style: TextStyle(color: textColor),
        ),
        backgroundColor: background,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            children: [
              _UploadOptionTile(
                icon: Icons.picture_as_pdf,
                iconColor: const Color(0xFFE53935),
                label: localizations.uploadPdf,
                cardColor: cardColor,
                borderColor: borderColor,
                onTap: _isProcessing ? () {} : _pickPdf,
              ),
              const SizedBox(height: 12),
              _UploadOptionTile(
                icon: Icons.image_outlined,
                iconColor: const Color(0xFF1E88E5),
                label: localizations.uploadPicture,
                cardColor: cardColor,
                borderColor: borderColor,
                onTap: _isProcessing ? () {} : _pickImage,
              ),
              const SizedBox(height: 12),
              _UploadOptionTile(
                icon: Icons.photo_camera_outlined,
                iconColor: const Color(0xFF43A047),
                label: localizations.takeImage,
                cardColor: cardColor,
                borderColor: borderColor,
                onTap: _isProcessing ? () {} : _takeImage,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: mutedText, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localizations.uploadBillHintLong,
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isProcessing) ...[
                const SizedBox(height: 18),
                _StatusCard(
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textColor: mutedText,
                  title: localizations.analyzingBill,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isRelevantBill(BillAnalysisResult analysis) {
    final raw = analysis.rawText.toLowerCase();
    final looksUtility =
        raw.contains('nama') ||
        raw.contains('supply.nama') ||
        raw.contains('nama supply') ||
        raw.contains('namasupply') ||
        raw.contains('oneic') ||
        raw.contains('diam') ||
        raw.contains('haya') ||
        raw.contains('majan') ||
        raw.contains('oiep') ||
        raw.contains('public authority for water') ||
        raw.contains('electricity bill') ||
        raw.contains('water services') ||
        raw.contains('tax invoice') ||
        raw.contains('epc') ||
        raw.contains('kwh') ||
        raw.contains('فاتورة');
    final hasNumeric =
        analysis.totalAmount != null ||
        analysis.consumptionValue != null ||
        analysis.currentMonthAmount != null;
    final hasIds =
        analysis.invoiceNumber != null ||
        analysis.billingMonthKey != null ||
        (analysis.accountNumber != null &&
            analysis.accountNumber!.trim().isNotEmpty);
    if (looksUtility && (hasNumeric || hasIds)) return true;
    if (analysis.billType != null && (hasNumeric || hasIds)) return true;
    return hasNumeric;
  }
}

class _UploadOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color cardColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _UploadOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.cardColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppLayout.pagePaddingH,
              vertical: AppLayout.pagePaddingV + 4,
            ),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;

  const _StatusCard({
    required this.title,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: AppLoadingIndicator(size: AppLoadingSize.inline),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(color: textColor))),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 4,
              backgroundColor: primary.withValues(alpha: 0.12),
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../core/utils.dart';
import '../constants/language.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _controller = TextEditingController();
  int _rating = 5;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : AppColors.backgroundWhite;
    final borderColor =
        isDark ? const Color(0xFF2C2C2C) : AppColors.borderLight;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(localizations.feedback),
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppLayout.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                localizations.feedbackPrompt,
                style: TextStyle(color: mutedText),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.rateYourExperience,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _RatingRow(
                      rating: _rating,
                      onChanged: (value) => setState(() => _rating = value),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.feedbackDetails,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: localizations.feedbackHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitFeedback,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: AppLoadingIndicator(
                                    size: AppLoadingSize.inline,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(localizations.sendFeedback),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final message = _controller.text.trim();
    if (message.isEmpty) {
      _showMessage(localizations.feedbackRequired, isSuccess: false);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final name = await _loadUserName(uid, user?.email);
      final ref = FirebaseDatabase.instance.ref('feedback').push();
      await ref.set({
        'userId': uid,
        'userName': name,
        'rating': _rating,
        'message': message,
        'createdAt': ServerValue.timestamp,
      });
      if (!mounted) return;
      _controller.clear();
      setState(() => _rating = 5);
      _showMessage(localizations.feedbackSent, isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      _showMessage(localizations.feedbackError, isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<String> _loadUserName(String uid, String? fallbackEmail) async {
    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/$uid/fullName').get();
      final name = snapshot.value?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    return fallbackEmail ?? 'User';
  }

  void _showMessage(String message, {required bool isSuccess}) {
    if (isSuccess) {
      AppSnackBar.showSuccess(context, message);
    } else {
      AppSnackBar.showError(context, message);
    }
  }
}

class _RatingRow extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _RatingRow({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => IconButton(
          onPressed: () => onChanged(index + 1),
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: const Color(0xFFF2C94C),
          ),
        ),
      ),
    );
  }
}

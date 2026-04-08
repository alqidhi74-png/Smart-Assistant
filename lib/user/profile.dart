import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../data/database.dart';
import '../services/multi_account_service.dart';
import '../core/utils.dart';

class ProfilePage extends StatefulWidget {
  final String? fullName;
  final String? phoneNumber;

  const ProfilePage({super.key, this.fullName, this.phoneNumber});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _displayName;
  late String _displayPhone;
  bool _editing = false;
  bool _saving = false;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _displayName =
        widget.fullName?.trim().isNotEmpty == true
            ? widget.fullName!.trim()
            : 'Abdullah';
    _displayPhone =
        widget.phoneNumber?.trim().isNotEmpty == true
            ? widget.phoneNumber!.trim()
            : '91208200';
    _nameController = TextEditingController(text: _displayName);
    _phoneController = TextEditingController(text: _displayPhone);
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _nameController.text = _displayName;
      _phoneController.text = _displayPhone;
    });
  }

  void _saveChanges() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _updateUserProfile();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loadingProfile = false);
      return;
    }

    try {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/${user.uid}').get();
      if (!snapshot.exists) {
        if (mounted) setState(() => _loadingProfile = false);
        return;
      }
      final data = snapshot.value as Map<dynamic, dynamic>;
      final name = data['fullName']?.toString() ?? _displayName;
      final phone = data['phone']?.toString() ?? _displayPhone;
      if (!mounted) return;
      setState(() {
        _displayName = name;
        _displayPhone = phone;
        _nameController.text = name;
        _phoneController.text = phone;
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _updateUserProfile() async {
    if (_saving) return;
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      AppSnackBar.showError(context, localizations.profileUpdateError);
      return;
    }

    setState(() => _saving = true);
    if (mounted) LoadingOverlay.show(context);
    try {
      final updatedName = _nameController.text.trim();
      final updatedPhone = _phoneController.text.trim();
      await Database().updateUserProfile(user.uid, {
        'fullName': updatedName,
        'phone': updatedPhone,
      });
      if (!mounted) return;
      setState(() {
        _editing = false;
        _displayName = updatedName;
        _displayPhone = updatedPhone;
      });
      await MultiAccountService.updateDisplayName(user.uid, updatedName);
      if (!mounted) return;
      AppSnackBar.showSuccess(context, localizations.profileUpdated);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, localizations.profileUpdateError);
    } finally {
      if (mounted) {
        LoadingOverlay.hide();
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;
    final headerColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFB0B0B0);
    final cardColor =
        isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0);
    final primaryText = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(localizations.profile),
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(color: primaryText),
      ),
      body: SafeArea(
        child:
            _loadingProfile
                ? const IosStyleLoading()
                : CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(onRefresh: _loadUserData),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: AppLayout.pagePadding,
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppLayout.pagePaddingH + 2),
                              decoration: BoxDecoration(
                                color: headerColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    localizations.personalInformation,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    localizations.updatePersonalDetails,
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppLayout.pagePaddingH + 6),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 32,
                                      backgroundColor:
                                          isDark
                                              ? const Color(0xFF2C2C2C)
                                              : Colors.white,
                                      child: Icon(
                                        Icons.person,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _displayName.isEmpty
                                          ? localizations.profile
                                          : _displayName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _ProfileField(
                                      label: localizations.nameLabel,
                                      controller: _nameController,
                                      enabled: _editing,
                                      validator:
                                          _editing
                                              ? (value) {
                                                if (value == null ||
                                                    value
                                                        .toString()
                                                        .trim()
                                                        .isEmpty) {
                                                  return localizations
                                                      .fullNameRequired;
                                                }
                                                if (value.trim().length > 30) {
                                                  return localizations
                                                      .fullNameMaxLength;
                                                }
                                                if (!RegExp(
                                                  r'^[a-zA-Z\s]+$',
                                                ).hasMatch(value.trim())) {
                                                  return localizations
                                                      .fullNameLettersOnly;
                                                }
                                                return null;
                                              }
                                              : null,
                                    ),
                                    const SizedBox(height: 12),
                                    _ProfileField(
                                      label: localizations.phoneNumber,
                                      controller: _phoneController,
                                      enabled: _editing,
                                      keyboardType: TextInputType.phone,
                                      validator:
                                          _editing
                                              ? (value) {
                                                if (value == null ||
                                                    value
                                                        .toString()
                                                        .trim()
                                                        .isEmpty) {
                                                  return localizations
                                                      .phoneRequired;
                                                }
                                                if (!RegExp(
                                                  r'^[79]\d{7}$',
                                                ).hasMatch(value.trim())) {
                                                  return localizations
                                                      .phoneOmani;
                                                }
                                                return null;
                                              }
                                              : null,
                                    ),
                                    const SizedBox(height: 20),
                                    if (_editing)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed:
                                                  _saving
                                                      ? null
                                                      : _cancelEditing,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppColors.error,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                minimumSize: const Size(0, 48),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(localizations.cancel),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed:
                                                  _saving ? null : _saveChanges,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF2E7D32,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                minimumSize: const Size(0, 48),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                              child: Text(
                                                localizations.saveChanges,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed:
                                              _saving ? null : _startEditing,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFFB0B0B0,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.edit,
                                            size: 16,
                                          ),
                                          label: Text(localizations.edit),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.enabled,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final fillColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFD0D0D0);
    final errorColor = AppColors.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: primaryText),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: primaryText),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            errorStyle: TextStyle(color: errorColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }
}

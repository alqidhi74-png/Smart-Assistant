import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../data/bill_store.dart';
import '../models/bill_summary.dart';
import '../services/chat_config_service.dart';
import '../services/openrouter_chat_service.dart';
import '../widgets/chat_chart.dart';

class ChatbotPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const ChatbotPage({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage>
    with SingleTickerProviderStateMixin {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _isSending = false;
  late final AnimationController _typingDotController;

  final OpenRouterChatService _chatService = OpenRouterChatService();
  final ChatConfigService _chatConfigService = ChatConfigService();
  ChatConfig _chatConfig = const ChatConfig();

  @override
  void initState() {
    super.initState();
    _typingDotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _messages.add(
      _ChatMessage(
        isFromBot: true,
        textKey: _ChatTextKey.welcome,
        timestamp: DateTime.now(),
      ),
    );
    _loadChatConfig();
  }

  Future<void> _loadChatConfig() async {
    try {
      final config = await _chatConfigService.fetchConfig();
      if (!mounted) return;
      setState(() => _chatConfig = config);
    } catch (e) {
      debugPrint('Chat config load failed: $e');
    }
  }

  @override
  void dispose() {
    _typingDotController.dispose();
    _inputFocus.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));

    setState(() {
      _isSending = true;
      _messages.add(
        _ChatMessage(isFromBot: false, text: text, timestamp: DateTime.now()),
      );
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final priorTurns = _messages.take(_messages.length - 1).map((m) {
        final resolvedText = m.text ?? _resolveText(localizations, m.textKey);
        return <String, String>{
          'role': m.isFromBot ? 'assistant' : 'user',
          'content': resolvedText,
        };
      }).toList();

      final List<Map<String, String>> limitedHistory = priorTurns.length > 10
          ? priorTurns.sublist(priorTurns.length - 10)
          : priorTurns;

      final responseText = await _chatService.sendScopedMessage(
        systemPrompt: _buildScopedSystemPrompt(text),
        userPrompt: text,
        conversationHistory: limitedHistory,
      );
      _addBotMessage(responseText);
    } catch (e) {
      debugPrint('Chat API request failed: $e');
      String errorMessage = 'AI service is unavailable now. Try again later.';
      if (e.toString().contains('API key is missing')) {
        errorMessage = 'Service Configuration Error: Please check your API settings.';
      }
      _addBotMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  String _buildScopedSystemPrompt(String userQuestion) {
    final billsSnapshot = BillStore.instance.bills.value;
    final billsContext = _buildBillsContext(billsSnapshot);
    final languageInstruction = _languageInstruction(userQuestion);
    
    // We will use the local prompt exclusively to ensure the best experience and 
    // avoid old configurations from Firebase that might be too strict.
    return '''
You are the official Smart Assistant for this utility-bill application. 
Your goal is to help users manage their electricity, water, and ANY other utility bills added by the admin (such as internet, gas, etc.), understand their consumption, and navigate the app features.

APP KNOWLEDGE BASE:
- Home Page: The main screen. It shows a "Upload New Bill" card, consumption charts, and "Smart Analytics".
- My Bills Page: Shows all your uploaded bills. You can search, sort, and filter bills here. There is NO upload button on this page.
- Uploading Bills: You must go to the HOME page and click the "Upload New Bill" card. Options include: PDF, Gallery Image, or Camera.
- Bill Analysis: After uploading, the app extracts the Account Number, Amount, Consumption (kWh/m3), and Month.
- AI Chatbot: (This is you) Answering questions about bills and providing saving tips.
- Settings: Change language, Dark Mode, profile, or logout.

STRICT OPERATING RULES:
1. FORMATTING RULES (STRICT):
   - Do NOT use Markdown symbols like (###, **, __, -, *).
   - Do NOT use bold or headers symbols.
   - Use plain text ONLY.
   - Use clear line breaks and numbering (1, 2, 3) to organize information.
   - Ensure numbers and English units (like kWh, m3) are placed carefully within the Arabic text to avoid RTL layout issues.
2. RESPONSE STYLE: 
   - Be DIRECT and HELPFUL.
   - You ARE allowed to provide general advice and tips on saving electricity and water.
3. CERTAINTY: Use the provided "Bill context" to give CONFIDENT answers.
4. DATA ANALYSIS: Only perform deep analysis if requested.
5. PERSONALITY: Be friendly and social but keep it brief.
6. WRITING QUALITY: Write clearly and professionally.
7. CONTEXT: Use the "Bill context" below for specific numbers.
8. $languageInstruction
9. Refuse unrelated topics (politics, medicine, coding) but stay friendly.

Bill context:
$billsContext
''';
  }

  String _languageInstruction(String userQuestion) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(userQuestion);
    if (hasArabic) {
      return 'Reply ONLY in Arabic. Do not provide an English translation.';
    }
    return 'Reply ONLY in English. Do not provide an Arabic translation.';
  }

  String _buildBillsContext(List<BillSummary> bills) {
    if (bills.isEmpty) {
      return 'No bills available yet.';
    }

    final buffer = StringBuffer();
    final maxBills = bills.length > 20 ? 20 : bills.length;
    for (var i = 0; i < maxBills; i++) {
      final b = bills[i];
      buffer.writeln(
        '- Bill ${i + 1}: type=${b.type}, date=${b.dateText}, '
        'total=${b.totalAmount?.toStringAsFixed(3) ?? 'N/A'}, '
        'consumption=${b.consumptionValue ?? 'N/A'} ${b.consumptionUnit ?? ''}, '
        'invoice=${b.invoiceNumber ?? 'N/A'}, account=${b.accountNumber ?? 'N/A'}, '
        'month=${b.billingMonthText ?? b.billingMonthKey ?? 'N/A'}, '
        'days=${b.consumptionDays?.toString() ?? 'N/A'}',
      );
    }
    return buffer.toString().trimRight();
  }

  void _addBotMessage(String text) {
    if (!mounted) return;
    final chartMatch = RegExp(r'\[CHART: (.*?)\]').firstMatch(text);
    Map<String, dynamic>? chartData;
    if (chartMatch != null) {
      try {
        chartData = jsonDecode(chartMatch.group(1)!);
      } catch (_) {}
    }
    setState(() {
      _messages.add(
        _ChatMessage(
          isFromBot: true,
          text: text,
          chartData: chartData,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations =
        AppLocalizations.of(context) ?? AppLocalizations(const Locale('en'));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context);
    final surface = Theme.of(context).colorScheme.surface;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;
    final chatCanvas =
        isDark ? const Color(0xFF0D1117) : const Color(0xFFE8EDF2);
    final inputFill =
        isDark ? const Color(0xFF1A2332) : const Color(0xFFF2F4F7);

    return Scaffold(
      backgroundColor: chatCanvas,
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: surface,
              elevation: 0.5,
              shadowColor: Colors.black26,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark
                              ? const Color(0xFF2A3441)
                              : AppColors.borderLight,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.18),
                          child: Icon(
                            Icons.smart_toy_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(color: surface, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.aiChatbot,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.2,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            localizations.onlineNow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 12.5,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _ChatPatternPainter(isDark: isDark)),
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(10, 12, 10, 20),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final text =
                          message.text ??
                          _resolveText(localizations, message.textKey);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MessageBubble(
                          isFromBot: message.isFromBot,
                          text: text,
                          chartData: message.chartData,
                          createdAt: message.createdAt,
                          locale: locale,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (_isSending)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: _TypingBubble(
                  controller: _typingDotController,
                  isDark: isDark,
                ),
              ),
            Material(
              color: surface,
              elevation: 8,
              shadowColor: Colors.black12,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppLayout.pagePaddingH,
                  10,
                  AppLayout.pagePaddingH,
                  MediaQuery.paddingOf(context).bottom > 0 ? 8 : 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _inputFocus,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          hintText: localizations.writeMessageHint,
                          hintStyle: TextStyle(
                            color: mutedText,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: inputFill,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _isSending ? null : _sendMessage,
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white.withValues(
                              alpha: _isSending ? 0.45 : 1,
                            ),
                            size: 22,
                          ),
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

  String _resolveText(AppLocalizations localizations, _ChatTextKey? key) {
    switch (key) {
      case _ChatTextKey.welcome:
        return localizations.chatbotWelcome;
      case _ChatTextKey.normalConsumption:
        return localizations.chatbotNormalConsumption;
      case _ChatTextKey.billHelp:
        return localizations.chatbotBillHelp;
      case _ChatTextKey.help:
        return localizations.chatbotHelp;
      case _ChatTextKey.defaultReply:
      default:
        return localizations.chatbotDefaultReply;
    }
  }
}

class _ChatMessage {
  final bool isFromBot;
  final String? text;
  final _ChatTextKey? textKey;
  final Map<String, dynamic>? chartData;
  final DateTime createdAt;

  _ChatMessage({
    required this.isFromBot,
    this.text,
    this.textKey,
    this.chartData,
    DateTime? timestamp,
  }) : createdAt = timestamp ?? DateTime.now();
}

enum _ChatTextKey { welcome, normalConsumption, billHelp, help, defaultReply }

class _MessageBubble extends StatelessWidget {
  final bool isFromBot;
  final String text;
  final Map<String, dynamic>? chartData;
  final DateTime createdAt;
  final Locale locale;

  const _MessageBubble({
    required this.isFromBot,
    required this.text,
    required this.createdAt,
    required this.locale,
    this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isFromBot
            ? (isDark ? const Color(0xFF1F2937) : Colors.white)
            : (isDark ? const Color(0xFF1A4B8C) : AppColors.primary);
    final textColor =
        isFromBot
            ? (isDark ? const Color(0xFFF3F4F6) : AppColors.textDark)
            : Colors.white;
    final timeColor =
        isFromBot
            ? (isDark ? const Color(0xFF9CA3AF) : AppColors.textSecondary)
            : Colors.white.withValues(alpha: 0.85);

    final displayText = text.replaceAll(RegExp(r'\[CHART:.*?\]'), '').trim();
    final localeId =
        locale.countryCode != null && locale.countryCode!.isNotEmpty
            ? '${locale.languageCode}_${locale.countryCode}'
            : locale.languageCode;
    final timeStr = DateFormat.jm(localeId).format(createdAt);
    final hasBody = displayText.isNotEmpty;
    if (!hasBody && chartData == null) {
      return const SizedBox.shrink();
    }

    final bubbleRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isFromBot ? 4 : 18),
      bottomRight: Radius.circular(isFromBot ? 18 : 4),
    );

    final maxBubbleW = MediaQuery.sizeOf(context).width * 0.78;
    final innerAlign =
        isFromBot ? CrossAxisAlignment.start : CrossAxisAlignment.end;

    Widget? bubble;
    if (hasBody) {
      bubble = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleW),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: bubbleRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border:
                isFromBot && !isDark
                    ? Border.all(
                      color: AppColors.borderLight.withValues(alpha: 0.6),
                    )
                    : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: innerAlign,
            children: [
              Text(
                displayText,
                textAlign: isFromBot ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  height: 1.38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                textAlign: isFromBot ? TextAlign.start : TextAlign.end,
                style: TextStyle(
                  color: timeColor,
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final userAvatar = CircleAvatar(
      radius: 15,
      backgroundColor:
          isDark ? const Color(0xFF2A3441) : AppColors.borderLight,
      child: Icon(
        Icons.person_rounded,
        size: 20,
        color: isDark ? Colors.white70 : AppColors.primary,
      ),
    );

    if (!isFromBot) {
      return Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxBubbleW),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (bubble != null) bubble,
                  if (bubble != null && chartData != null)
                    const SizedBox(height: 8),
                  if (chartData != null)
                    _ChartAttachment(chartData: chartData!, alignEnd: true),
                ],
              ),
            ),
            const SizedBox(width: 6),
            userAvatar,
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (bubble != null || chartData != null)
            CircleAvatar(
              radius: 15,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: Icon(
                Icons.smart_toy_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          if (bubble != null || chartData != null) const SizedBox(width: 6),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleW),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bubble != null) bubble,
                    if (bubble != null && chartData != null)
                      const SizedBox(height: 8),
                    if (chartData != null)
                      _ChartAttachment(chartData: chartData!, alignEnd: false),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartAttachment extends StatelessWidget {
  final Map<String, dynamic> chartData;
  final bool alignEnd;

  const _ChartAttachment({
    required this.chartData,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * 0.82;
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: SizedBox(
        width: w,
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(14),
          color: Theme.of(context).colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: ChatChart(
              type: chartData['type'] ?? 'line',
              values: List<double>.from(chartData['values'] ?? []),
              labels: List<String>.from(chartData['labels'] ?? []),
              title: chartData['title'],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  final AnimationController controller;
  final bool isDark;

  const _TypingBubble({
    required this.controller,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border:
                  !isDark
                      ? Border.all(
                        color: AppColors.borderLight.withValues(alpha: 0.6),
                      )
                      : null,
            ),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final t = (controller.value * 2 * math.pi) + (i * 0.9);
                    final scale = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t));
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.75),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatPatternPainter extends CustomPainter {
  final bool isDark;

  _ChatPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final dot =
        Paint()
          ..color =
              (isDark ? Colors.white : AppColors.primary).withValues(
                alpha: isDark ? 0.04 : 0.055,
              )
          ..isAntiAlias = true;

    const step = 22.0;
    for (var y = 0.0; y < size.height + step; y += step) {
      for (var x = 0.0; x < size.width + step; x += step) {
        canvas.drawCircle(Offset(x + (y / step % 2) * (step / 2), y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChatPatternPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

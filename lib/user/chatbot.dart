import 'package:flutter/material.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../data/bill_store.dart';
import '../models/bill_summary.dart';
import '../services/chat_config_service.dart';
import '../services/openrouter_chat_service.dart';
import '../widgets/chat_chart.dart';
import 'dart:convert';

class ChatbotPage extends StatefulWidget {
  final Function(Locale)? onLanguageChanged;
  final Locale? currentLocale;

  const ChatbotPage({super.key, this.onLanguageChanged, this.currentLocale});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final OpenRouterChatService _chatService = OpenRouterChatService();
  final ChatConfigService _chatConfigService = ChatConfigService();
  ChatConfig _chatConfig = const ChatConfig();

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(isFromBot: true, textKey: _ChatTextKey.welcome));
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(isFromBot: false, text: text));
    });
    _controller.clear();
    _scrollToBottom();

    // We will let the AI handle the scope enforcement based on the system prompt.
    // This allows for a much smarter and more natural conversation.
    
    try {
      final responseText = await _chatService.sendScopedMessage(
        systemPrompt: _buildScopedSystemPrompt(text),
        userPrompt: text,
      );
      _addBotMessage(responseText);
    } catch (e) {
      debugPrint('Chat API request failed: $e');
      _addBotMessage(
        'AI service is unavailable now. Verify OpenRouter key and try again.',
      );
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
Your goal is to help users manage their electricity and water bills, understand their consumption, and navigate the app features.

APP KNOWLEDGE BASE:
- Home Page: Shows a summary of the user's latest bills, consumption overview, and quick actions.
- My Bills Page: A full list of uploaded bills. Users can filter by "Electricity" or "Water". 
- Uploading Bills: Users can upload bills by clicking the "+" button in "My Bills". They can take a photo, pick an image from the gallery, or upload a PDF.
- Bill Analysis: Once uploaded, the app automatically extracts details like Account Number, Invoice Number, Total Amount, Consumption Value (kWh or m3), and Billing Month.
- AI Chatbot: (This is you) Answering questions and generating charts upon request.
- Settings: Users can change the language (Arabic/English), toggle Dark Mode, manage their profile, or logout.
- Charts & Trends: The app visualizes consumption data over time to help users save money.

STRICT OPERATING RULES:
1. ONLY answer questions related to:
   - User's electricity and water bills (amounts, dates, trends).
   - How to use this application (uploading, analyzing, charts, navigation).
   - General advice on reducing electricity/water consumption and saving energy.
2. If the user asks about ANY unrelated topic (politics, general knowledge, jokes, etc.), politely decline in the SAME language as the user.
3. Be EXTREMELY helpful and detailed when explaining app features. Use step-by-step instructions.
4. Use the "Bill context" provided below to answer specific questions about the user's actual numbers.
5. If specific data is missing from the "Bill context", say you don't have that record but offer general help or app guidance.
6. $languageInstruction
7. Maintain a professional, smart, and friendly assistant persona.

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
    
    Map<String, dynamic>? chartData;
    final chartMatch = RegExp(r'\[CHART: (.*?)\]').firstMatch(text);
    if (chartMatch != null) {
      try {
        chartData = jsonDecode(chartMatch.group(1)!);
      } catch (e) {
        // Ignore parsing errors
      }
    }

    setState(() {
      _messages.add(_ChatMessage(
        isFromBot: true, 
        text: text,
        chartData: chartData,
      ));
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
    final background = Theme.of(context).scaffoldBackgroundColor;
    final primaryText = isDark ? Colors.white : AppColors.textDark;
    final mutedText =
        isDark ? const Color(0xFFB0B0B0) : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isDark
                            ? const Color(0xFF2C2C2C)
                            : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.smart_toy, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.aiChatbot,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryText,
                          ),
                        ),
                        Text(
                          'Smart AI Ready',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: mutedText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: AppLayout.pagePadding,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final text =
                      message.text ??
                      _resolveText(localizations, message.textKey);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MessageBubble(
                      isFromBot: message.isFromBot,
                      text: text,
                      chartData: message.chartData,
                    ),
                  );
                },
              ),
            ),
            if (_isSending)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SkeletonBubble(isFromBot: true),
              ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppLayout.pagePaddingH,
                AppLayout.pagePaddingV,
                AppLayout.pagePaddingH,
                12,
              ),
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  top: BorderSide(
                    color:
                        isDark
                            ? const Color(0xFF2C2C2C)
                            : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: localizations.writeMessageHint,
                        hintStyle: TextStyle(color: mutedText, fontSize: 12),
                        filled: true,
                        fillColor:
                            isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFE0E0E0),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: TextStyle(color: primaryText, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
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

  _ChatMessage({
    required this.isFromBot,
    this.text,
    this.textKey,
    this.chartData,
  });
}

enum _ChatTextKey { welcome, normalConsumption, billHelp, help, defaultReply }

class _MessageBubble extends StatelessWidget {
  final bool isFromBot;
  final String text;
  final Map<String, dynamic>? chartData;

  const _MessageBubble({
    required this.isFromBot,
    required this.text,
    this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isFromBot
            ? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8))
            : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDDEBFF));
    final textColor = isDark ? Colors.white : AppColors.textDark;

    // Remove chart tag from display text
    final displayText = text.replaceAll(RegExp(r'\[CHART:.*?\]'), '').trim();

    return Align(
      alignment: isFromBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Column(
        crossAxisAlignment:
            isFromBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (displayText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                displayText,
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ),
          if (chartData != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: ChatChart(
                type: chartData!['type'] ?? 'line',
                values: List<double>.from(chartData!['values'] ?? []),
                labels: List<String>.from(chartData!['labels'] ?? []),
                title: chartData!['title'],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonBubble extends StatelessWidget {
  final bool isFromBot;

  const _SkeletonBubble({required this.isFromBot});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);

    return Align(
      alignment: isFromBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 6,
                width: 80,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

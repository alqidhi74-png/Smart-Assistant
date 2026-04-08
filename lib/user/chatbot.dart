import 'package:flutter/material.dart';
import '../constants/app_layout.dart';
import '../constants/colors.dart';
import '../constants/language.dart';
import '../core/utils.dart';

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

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(isFromBot: true, textKey: _ChatTextKey.welcome));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(_ChatMessage(isFromBot: false, text: text));
    });
    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final replyKey = _getReplyKey(text);
      setState(() {
        _messages.add(_ChatMessage(isFromBot: true, textKey: replyKey));
        _isSending = false;
      });
      _scrollToBottom();
    });
  }

  _ChatTextKey _getReplyKey(String text) {
    switch (ChatIntent.classify(text)) {
      case ChatIntentKind.consumption:
        return _ChatTextKey.normalConsumption;
      case ChatIntentKind.billRelated:
        return _ChatTextKey.billHelp;
      case ChatIntentKind.helpSupport:
        return _ChatTextKey.help;
      case ChatIntentKind.unknown:
        return _ChatTextKey.defaultReply;
    }
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.aiChatbot,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryText,
                        ),
                      ),
                      Text(
                        localizations.onlineNow,
                        style: TextStyle(color: mutedText, fontSize: 12),
                      ),
                    ],
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 18,
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

  _ChatMessage({required this.isFromBot, this.text, this.textKey});
}

enum _ChatTextKey { welcome, normalConsumption, billHelp, help, defaultReply }

class _MessageBubble extends StatelessWidget {
  final bool isFromBot;
  final String text;

  const _MessageBubble({required this.isFromBot, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor =
        isFromBot
            ? (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8))
            : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFDDEBFF));
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Align(
      alignment: isFromBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: textColor, fontSize: 12)),
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

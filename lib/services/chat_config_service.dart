import 'package:firebase_database/firebase_database.dart';

class ChatConfig {
  final String? systemPromptTemplate;
  final String? outOfScopeReplyEn;
  final String? outOfScopeReplyAr;

  const ChatConfig({
    this.systemPromptTemplate,
    this.outOfScopeReplyEn,
    this.outOfScopeReplyAr,
  });
}

class ChatConfigService {
  static const String _path = 'app_config/chatbot';

  Future<ChatConfig> fetchConfig() async {
    final snap = await FirebaseDatabase.instance.ref(_path).get();
    final value = snap.value;
    if (value is! Map) return const ChatConfig();

    String? readString(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    return ChatConfig(
      systemPromptTemplate: readString(value['systemPromptTemplate']),
      outOfScopeReplyEn: readString(value['outOfScopeReplyEn']),
      outOfScopeReplyAr: readString(value['outOfScopeReplyAr']),
    );
  }
}

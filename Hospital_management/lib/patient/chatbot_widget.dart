import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../theme.dart';

class ChatWidget extends StatefulWidget {
  final String? openAiApiKey;
  final VoidCallback? onRequestOpenAppointments;

  const ChatWidget({
    Key? key,
    this.openAiApiKey,
    this.onRequestOpenAppointments,
  }) : super(key: key);

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.insert(0, {'text': trimmed, 'isUser': true});
      _loading = true;
    });
    _controller.clear();

    String reply;
    try {
      reply = await _getBotReply(trimmed);
    } catch (e) {
      reply = 'Sorry, I could not process that. Please try again.';
    }

    setState(() {
      _messages.insert(0, {'text': reply, 'isUser': false});
      _loading = false;
    });
  }

  Future<String> _getBotReply(String input) async {
    // Always try Gemini via local proxy first (server holds the API key)
    print('========================================');
    print('DEBUG: User asked: $input');
    print('DEBUG: Attempting Gemini via local proxy...');
    print('========================================');

    try {
      final resp = await _callGemini(input, apiKey: geminiApiKey ?? '');
      print(
        'DEBUG: Gemini response received: ${resp?.substring(0, 50) ?? "NULL RESPONSE"}...',
      );
      if (resp != null && resp.isNotEmpty) {
        print('DEBUG: Returning Gemini response');
        return resp;
      }
      print('DEBUG: Gemini returned null or empty, trying fallback');
    } catch (e) {
      // If Gemini fails, continue to fallback
      print('DEBUG: Gemini proxy error: $e');
      // Check if it's an overload error
      if (e.toString().contains('overloaded') || e.toString().contains('503')) {
        return 'The AI service is currently experiencing high demand. Please try again in a moment. In the meantime, you can describe your symptoms and I\'ll try to help with basic health information.';
      }
    }

    // Try OpenAI as fallback
    final apiKey = widget.openAiApiKey ?? openAiApiKey;
    final proxy = openAiProxyUrl;

    if ((apiKey != null && apiKey.isNotEmpty) ||
        (proxy != null && proxy.isNotEmpty)) {
      try {
        final resp = await _callOpenAi(input, apiKey: apiKey, proxy: proxy);
        if (resp != null && resp.isNotEmpty) return resp;
      } catch (e) {
        // If OpenAI fails, return error message
        return 'Sorry, I encountered an error connecting to the AI service. The server might be busy. Please try again in a few moments.';
      }
    }

    // If everything fails, inform user succinctly
    print('DEBUG: No AI backends responded');
    return 'Sorry, the AI service is temporarily unavailable. This might be due to high demand. Please try again in a few moments, or contact support if the issue persists.';
  }

  Future<String?> _callGemini(String input, {required String apiKey}) async {
    // Use proxy server to avoid CORS issues
    final proxyUrl = 'http://localhost:3000/gemini';

    try {
      final resp = await http
          .post(
            Uri.parse(proxyUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'prompt': input}),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(resp.body);
        return data['response'] as String?;
      } else if (resp.statusCode == 503 || resp.statusCode == 429) {
        // Service unavailable or rate limited
        print(
          'DEBUG: Gemini service temporarily unavailable (${resp.statusCode})',
        );
        throw Exception('overloaded');
      } else {
        print(
          'DEBUG: Gemini proxy returned status ${resp.statusCode}: ${resp.body}',
        );
        return null;
      }
    } catch (e) {
      print('DEBUG: Gemini proxy error: $e');
      rethrow;
    }
  }

  Future<String?> _callOpenAi(
    String input, {
    String? apiKey,
    String? proxy,
  }) async {
    final systemPrompt =
        'You are a warm, polite, and empathetic medical assistant. Always use a kind and respectful tone. For simple greetings respond briefly and politely (e.g., user says "hello" -> respond "Hello! How can I help you today?"). Give conservative self-care advice and when appropriate suggest common OTC medicines (e.g., paracetamol, ibuprofen). Always include a clear disclaimer to consult a clinician for diagnosis, for children, pregnancy, or for severe symptoms.';

    final body = {
      'model': 'gpt-3.5-turbo',
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': input},
      ],
      'max_tokens': 400,
    };

    final uri = (proxy != null && proxy.isNotEmpty)
        ? Uri.parse('${proxy.replaceAll(RegExp(r'/+\$'), '')}/openai')
        : Uri.parse('https://api.openai.com/v1/chat/completions');

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (proxy == null || proxy.isEmpty) {
      if (apiKey == null || apiKey.isEmpty) throw Exception('No API key');
      headers['Authorization'] = 'Bearer $apiKey';
    }

    final resp = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(resp.body);
      try {
        final content = data['choices']?[0]?['message']?['content'] as String?;
        return content?.trim();
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isUser = msg['isUser'] as bool? ?? false;
    final text = msg['text'] as String? ?? '';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(color: isUser ? AppTheme.onPrimary : Colors.black87),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if Gemini or OpenAI is configured
    final hasGemini = (geminiApiKey?.isNotEmpty ?? false);
    // We use a local proxy for Gemini regardless of Flutter .env

    String aiStatus;
    aiStatus = hasGemini ? 'AI: Gemini Active ✓' : 'AI: Gemini via Proxy ✓';

    return Column(
      children: [
        Container(
          color: AppTheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Medical Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                aiStatus,
                style: TextStyle(
                  color: Colors.green.shade100,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            reverse: true,
            itemCount: _messages.length + (_loading ? 1 : 0),
            itemBuilder: (context, index) {
              if (_loading && index == 0) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Typing...'),
                  ),
                );
              }
              final msg = _messages[index - (_loading ? 1 : 0)];
              return _buildBubble(msg);
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.send,
                  decoration: const InputDecoration(
                    hintText: 'Type a message',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (v) => _sendMessage(v),
                ),
              ),
              IconButton(
                icon: Icon(Icons.send, color: AppTheme.primary),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

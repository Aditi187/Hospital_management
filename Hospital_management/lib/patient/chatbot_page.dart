import 'package:flutter/material.dart';
import '../theme.dart';
import '../config.dart';
import 'chatbot_widget.dart';

/// Simple page wrapper for the reusable ChatWidget.
/// Keeps the page minimal so the chat logic remains in `chatbot_widget.dart`.
class ChatbotPage extends StatelessWidget {
  const ChatbotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        backgroundColor: AppTheme.primary,
        foregroundColor: AppTheme.onPrimary,
      ),
      body: ChatWidget(openAiApiKey: openAiApiKey),
    );
  }
}

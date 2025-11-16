// Local configuration accessor.
// This file reads values from an optional .env file using flutter_dotenv.
// Create a local `.env` file at the project root with lines like:
// GEMINI_API_KEY=AIza...
// OPENAI_API_KEY=sk-...
// and do NOT commit that file. If the variables aren't present, the app
// will fall back to the local rule-based assistant.

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Gemini API key for real AI responses (recommended)
String? get geminiApiKey {
  try {
    return dotenv.env['GEMINI_API_KEY'];
  } catch (_) {
    return null;
  }
}

String? get openAiApiKey {
  try {
    return dotenv.env['OPENAI_API_KEY'];
  } catch (_) {
    // dotenv may not be initialized in some contexts (analyzer, tests).
    return null;
  }
}

/// Optional proxy URL to forward OpenAI requests through a server that keeps
/// the real API key secret. Example in `.env`:
/// OPENAI_PROXY_URL=http://localhost:3000
String? get openAiProxyUrl {
  try {
    return dotenv.env['OPENAI_PROXY_URL'];
  } catch (_) {
    return null;
  }
}

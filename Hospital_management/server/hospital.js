const express = require('express');
const axios = require('axios');
const cors = require('cors');
const path = require('path');
// Ensure .env is loaded from this server directory regardless of CWD
require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
app.use(cors());
app.use(express.json());

const OPENAI_KEY = process.env.OPENAI_API_KEY;
const GEMINI_KEY = process.env.GEMINI_API_KEY;

if (!OPENAI_KEY && !GEMINI_KEY) {
  console.warn('WARNING: Neither OPENAI_API_KEY nor GEMINI_API_KEY is set in server environment.');
} else {
  if (GEMINI_KEY) console.log('✓ GEMINI_API_KEY is configured');
  if (OPENAI_KEY) console.log('✓ OPENAI_API_KEY is configured');
}

// Simple health check to quickly verify server and env status
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', hasGeminiKey: Boolean(GEMINI_KEY), hasOpenAIKey: Boolean(OPENAI_KEY) });
});

// Simple browser test page for /gemini (GET) to avoid "Cannot GET /gemini"
app.get('/gemini', (_req, res) => {
  res.setHeader('Content-Type', 'text/html');
  res.send(`<!doctype html>
  <html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Gemini Proxy Tester</title>
    <style>
      body { font-family: -apple-system, Segoe UI, Roboto, sans-serif; margin: 20px; }
      textarea { width: 100%; height: 120px; }
      pre { white-space: pre-wrap; background: #111; color: #e6e6e6; padding: 12px; border-radius: 6px; }
      .row { display: flex; gap: 12px; align-items: center; }
      button { padding: 8px 14px; }
    </style>
  </head>
  <body>
    <h1>Gemini Proxy Tester</h1>
    <p>This page helps you test the POST /gemini endpoint from your browser.</p>
    <div class="row">
      <button onclick="window.location='/health'">Check /health</button>
      <button onclick="window.location='/models'">List /models</button>
    </div>
    <p><strong>Prompt</strong></p>
    <textarea id="prompt">Say hello briefly.</textarea>
    <div class="row" style="margin-top: 8px;">
      <button id="send">Send to /gemini</button>
      <span id="status"></span>
    </div>
    <h3>Response</h3>
    <pre id="out"></pre>
    <script>
      const btn = document.getElementById('send');
      const out = document.getElementById('out');
      const status = document.getElementById('status');
      btn.onclick = async () => {
        out.textContent = '';
        status.textContent = 'Sending...';
        try {
          const prompt = document.getElementById('prompt').value;
          const resp = await fetch('/gemini', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ prompt }) });
          const text = await resp.text();
          status.textContent = resp.status + ' ' + resp.statusText;
          out.textContent = text;
        } catch (e) {
          status.textContent = 'Error';
          out.textContent = String(e);
        }
      };
    </script>
  </body>
  </html>`);
});

// List available Gemini models (debug helper)
app.get('/models', async (_req, res) => {
  try {
    if (!GEMINI_KEY) {
      return res.status(500).json({ error: 'GEMINI_API_KEY not configured on server' });
    }
    // Try v1beta first
    const v1beta = await axios.get(
      `https://generativelanguage.googleapis.com/v1beta/models?key=${GEMINI_KEY}`,
      { timeout: 20000 }
    ).then(r => r.data).catch(() => null);

    // Also try v1 in case account is on GA endpoint only
    const v1 = await axios.get(
      `https://generativelanguage.googleapis.com/v1/models?key=${GEMINI_KEY}`,
      { timeout: 20000 }
    ).then(r => r.data).catch(() => null);

    res.json({ v1beta, v1 });
  } catch (err) {
    console.error('ListModels error:', err?.response?.data || err.message || err);
    const status = err?.response?.status || 500;
    const data = err?.response?.data || { error: err.message };
    res.status(status).json(data);
  }
});

// Gemini API proxy endpoint
app.post('/gemini', async (req, res) => {
  try {
    if (!GEMINI_KEY) {
      return res.status(500).json({ error: 'GEMINI_API_KEY not configured on server' });
    }

    const { prompt } = req.body;
    
    const systemContext = `You are a warm, polite, and empathetic medical assistant chatbot for a hospital management system. 

Key Guidelines:
- Always use a kind, respectful, and professional tone
- For greetings, respond briefly and warmly
- Provide helpful health information and general medical advice
- When discussing symptoms, ask clarifying questions if needed
- Suggest appropriate self-care measures and common over-the-counter medicines when relevant (e.g., paracetamol, ibuprofen)
- ALWAYS include a clear disclaimer to consult a licensed healthcare provider for proper diagnosis and treatment
- For serious symptoms (chest pain, severe bleeding, breathing difficulty, etc.), urgently advise seeking immediate medical attention
- For children, pregnancy, or severe symptoms, emphasize the importance of consulting a clinician
- Be informative but conservative in your advice
- Keep responses concise and actionable (aim for 2-4 sentences unless more detail is specifically requested)

Remember: You are an assistant to help patients navigate their health concerns, but you cannot replace professional medical advice.`;

    // Use a stable, supported model id (avoid "-latest" alias which may not exist on some endpoints)
    const response = await axios.post(
      `https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=${GEMINI_KEY}`,
      {
        contents: [
          {
            role: 'user',
            parts: [{ text: `${systemContext}\n\nUser question: ${prompt}` }],
          },
        ],
        generationConfig: {
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        },
        safetySettings: [
          { category: 'HARM_CATEGORY_HARASSMENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
          { category: 'HARM_CATEGORY_HATE_SPEECH', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
          { category: 'HARM_CATEGORY_SEXUALLY_EXPLICIT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
          { category: 'HARM_CATEGORY_DANGEROUS_CONTENT', threshold: 'BLOCK_MEDIUM_AND_ABOVE' },
        ],
      },
      {
        headers: { 'Content-Type': 'application/json' },
        timeout: 30000,
      }
    );

    const candidate = response.data?.candidates?.[0]?.content;
    let text = '';
    if (candidate?.parts && Array.isArray(candidate.parts)) {
      text = candidate.parts.map(p => p?.text || '').join('').trim();
    }
    if (text && text.length > 0) {
      res.json({ response: text });
    } else {
      res.status(500).json({ error: 'No response from Gemini' });
    }
  } catch (err) {
    console.error('Gemini proxy error:', err?.response?.data || err.message || err);
    const status = err?.response?.status || 500;
    const data = err?.response?.data || { error: err.message };
    res.status(status).json(data);
  }
});

// OpenAI API proxy endpoint
app.post('/openai', async (req, res) => {
  try {
    const body = req.body;

    const response = await axios.post('https://api.openai.com/v1/chat/completions', body, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_KEY}`,
      },
      timeout: 30000,
    });

    res.status(response.status).json(response.data);
  } catch (err) {
    console.error('OpenAI proxy error:', err?.response?.data || err.message || err);
    const status = err?.response?.status || 500;
    const data = err?.response?.data || { error: err.message };
    res.status(status).json(data);
  }
});

const port = process.env.PORT || 3000;
app.listen(port, () => {
  console.log(`===========================================`);
  console.log(`🚀 AI Proxy Server running on http://localhost:${port}`);
  console.log(`===========================================`);
});

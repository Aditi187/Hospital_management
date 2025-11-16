# OpenAI Proxy (dev)

This is a minimal development proxy to forward requests from the Flutter app to OpenAI.
It keeps your OpenAI API key on the server so the client never sees it.

WARNING: This is a simple example for development only. Do not deploy this to
production without adding authentication, rate limiting, and other security controls.

Setup

1. Create a `.env` file inside `server/` with:

```
OPENAI_API_KEY=sk-REPLACE_WITH_YOUR_KEY
```

2. Install dependencies and run:

```bash
cd server
npm install
npm start
```

3. In the Flutter app root `.env`, set the proxy URL:

```
OPENAI_PROXY_URL=http://localhost:3000
```

4. Restart the Flutter app (`flutter run -d chrome`). The chat widget will use the proxy if `OPENAI_PROXY_URL` is set.

Endpoint

POST /openai
- Expects the same JSON body the client would send to OpenAI's `/v1/chat/completions`.
- Forwards the request to OpenAI with the server's `OPENAI_API_KEY` and returns OpenAI's response.


Notes

- Add auth to the proxy before using in a shared environment. This example allows anyone who can reach the server to use your OpenAI credits.

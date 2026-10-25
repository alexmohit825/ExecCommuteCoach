// ExecCommuteCoach Cloudflare Edge Worker & Safari OTA Installer
// Platform: Cloudflare Workers + KV + Gemini 3.8 Flash

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

const PERSONA_SYSTEM_PROMPTS = {
  investor: `You are an aggressive activist investor listening to an executive update during a commute. 
Analyze the speaker's transcript. Pinpoint the single biggest assumption, missing revenue number, or vague promise.
Deliver ONE razor-sharp, natural spoken interruption (max 25 words).
Do NOT be polite. Cut to the chase. Example: "You're claiming 30% margin, but customer acquisition doubled. How do the unit economics hold up?"`,

  cfo: `You are a skeptical, risk-averse Chief Financial Officer listening to an executive briefing.
Analyze the speaker's transcript. Identify the greatest downside risk, unexpected capital requirement, or unbudgeted headcount.
Deliver ONE direct, firm spoken challenge (max 25 words).
Example: "Bottom-line it for me: if this launch slips by 60 days, what is our monthly burn rate?"`,

  clinical: `You are a Hospital Chief of Staff and Surgical Governance Director.
Analyze the speaker's medical or executive update. Focus on clinical liability, peer-review defensibility, patient safety, and regulatory compliance.
Deliver ONE commanding, surgical pushback (max 25 words).
Example: "If the morbidity committee reviews this protocol, what verified clinical benchmark protects us from scrutiny?"`,

  ceo: `You are a visionary, high-standards CEO.
Analyze the speaker's proposal. Challenge them if they are getting bogged down in small tactical details or failing to show a 10x competitive moat.
Deliver ONE crisp executive challenge (max 25 words).
Example: "This sounds like an incremental feature. What makes this impossible for our competitors to clone in six months?"`
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const normPath = url.pathname.replace(/\/+$/, '').toLowerCase() || '/';

    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS_HEADERS });
    }

    // 1. Apple OTA Manifest (/manifest.plist)
    if (normPath === '/manifest.plist') {
      const origin = url.origin;
      const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>items</key>
    <array>
        <dict>
            <key>assets</key>
            <array>
                <dict>
                    <key>kind</key>
                    <string>software-package</string>
                    <key>url</key>
                    <string>${origin}/ExecCommuteCoach.ipa</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>display-image</string>
                    <key>needs-shine</key>
                    <true/>
                    <key>url</key>
                    <string>${origin}/icon-57.png</string>
                </dict>
                <dict>
                    <key>kind</key>
                    <string>full-size-image</string>
                    <key>needs-shine</key>
                    <true/>
                    <key>url</key>
                    <string>${origin}/icon-512.png</string>
                </dict>
            </array>
            <key>metadata</key>
            <dict>
                <key>bundle-identifier</key>
                <string>com.alexmohit825.ExecCommuteCoach</string>
                <key>bundle-version</key>
                <string>1.0.0</string>
                <key>kind</key>
                <string>software</string>
                <key>title</key>
                <string>ExecCommuteCoach</string>
            </dict>
        </dict>
    </array>
</dict>
</plist>`;
      return new Response(plist, {
        headers: {
          'Content-Type': 'application/xml; charset=utf-8',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          ...CORS_HEADERS
        }
      });
    }

    // 2. Binary IPA Download (/ExecCommuteCoach.ipa)
    if (normPath === '/execcommutecoach.ipa') {
      if (env.VOCALIS_KV) {
        const ipaBuffer = await env.VOCALIS_KV.get('execcommutecoach_ipa', { type: 'arrayBuffer' });
        if (ipaBuffer) {
          return new Response(ipaBuffer, {
            headers: {
              'Content-Type': 'application/octet-stream',
              'Content-Disposition': 'attachment; filename="ExecCommuteCoach.ipa"',
              'Cache-Control': 'no-store',
              ...CORS_HEADERS
            }
          });
        }
      }
      
      if (env.ASSETS) {
        const ipaReq = new Request(new URL('/ExecCommuteCoach.ipa', url.origin), request);
        const assetResp = await env.ASSETS.fetch(ipaReq);
        if (assetResp.status === 200) {
          const headers = new Headers(assetResp.headers);
          headers.set('Content-Type', 'application/octet-stream');
          headers.set('Content-Disposition', 'attachment; filename="ExecCommuteCoach.ipa"');
          headers.set('Cache-Control', 'no-store');
          return new Response(assetResp.body, { status: 200, headers });
        }
      }

      return new Response(JSON.stringify({ error: 'IPA binary is being compiled by CI pipeline. Please check back in 2 minutes.' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
      });
    }

    // 3. Upload IPA Endpoint (POST /api/upload-ipa)
    if (normPath === '/api/upload-ipa' && request.method === 'POST') {
      const authHeader = request.headers.get('Authorization') || '';
      const secret = env.UPLOAD_SECRET || 'exec-commute-coach-secure-deploy-2026';
      if (!authHeader.includes(secret)) {
        return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: CORS_HEADERS });
      }

      const ipaBytes = await request.arrayBuffer();
      if (!ipaBytes || ipaBytes.byteLength < 1000) {
        return new Response(JSON.stringify({ error: 'Invalid IPA payload' }), { status: 400, headers: CORS_HEADERS });
      }

      if (env.VOCALIS_KV) {
        await env.VOCALIS_KV.put('execcommutecoach_ipa', ipaBytes);
        await env.VOCALIS_KV.put('ipa_uploaded_at', new Date().toISOString());
        await env.VOCALIS_KV.put('ipa_size_bytes', ipaBytes.byteLength.toString());
      }

      return new Response(JSON.stringify({
        success: true,
        sizeBytes: ipaBytes.byteLength,
        uploadedAt: new Date().toISOString()
      }), {
        headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
      });
    }

    // 4. Dynamic AI Boardroom Adversary (POST /api/spar)
    if (normPath === '/api/spar' && request.method === 'POST') {
      try {
        const body = await request.json();
        const transcript = body.transcript || '';
        const personaKey = (body.persona || 'investor').toLowerCase();
        const systemPrompt = PERSONA_SYSTEM_PROMPTS[personaKey] || PERSONA_SYSTEM_PROMPTS.investor;

        if (!transcript.trim()) {
          return new Response(JSON.stringify({ challenge: "Keep talking—what's the bottom line?" }), {
            headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
          });
        }

        const apiKey = env.GEMINI_API_KEY;
        if (!apiKey) {
          // Fallback if key is missing
          return new Response(JSON.stringify({ challenge: "Bottom-line it for me: what is the single biggest risk?" }), {
            headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
          });
        }

        const prompt = `${systemPrompt}\n\nHere is what the executive has said so far:\n"${transcript}"\n\nDeliver your realistic, sharp boardroom interruption now:`;
        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`;

        const geminiResp = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.7,
              maxOutputTokens: 60
            }
          })
        });

        if (!geminiResp.ok) {
          return new Response(JSON.stringify({ challenge: "What's the downside risk if this assumption fails?" }), {
            headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
          });
        }

        const data = await geminiResp.json();
        const challengeText = data.candidates?.[0]?.content?.parts?.[0]?.text?.trim() || "Can you quantify the ROI in under fifteen seconds?";

        return new Response(JSON.stringify({ challenge: challengeText }), {
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
        });
      } catch (err) {
        return new Response(JSON.stringify({ challenge: "How do you protect cash runway under these conditions?" }), {
          headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
        });
      }
    }

    // 5. Executive Debrief AI Analysis (POST /api/debrief)
    if (normPath === '/api/debrief' && request.method === 'POST') {
      try {
        const body = await request.json();
        const transcript = body.transcript || '';
        const wpm = body.wpm || 140;
        const fillers = body.fillers || 0;
        const hedgings = body.hedgings || 0;
        const apiKey = env.GEMINI_API_KEY;

        if (!apiKey || !transcript.trim()) {
          return new Response(JSON.stringify({
            verdict: "Strong executive cadence with clear delivery.",
            anchor: "Opening conclusion stated upfront with conviction.",
            flaw: "Minor filler usage during transition into financial evidence."
          }), { headers: { 'Content-Type': 'application/json', ...CORS_HEADERS } });
        }

        const debriefPrompt = `You are an elite speech coach for senior Fortune 500 executives and neurosurgeons.
Analyze this spoken rehearsal transcript:
"${transcript}"
Metrics: ${wpm} WPM, ${fillers} filler words, ${hedgings} hedging phrases.

Provide exactly 3 concise, high-impact bullet responses in JSON format:
{
  "verdict": "One sentence executive score and evaluation (e.g. 92/100 - Board Ready & Commanding).",
  "anchor": "One sentence identifying their most persuasive, data-backed statement.",
  "flaw": "One sentence identifying the single weakest evasion, hedge, or pacing slip to eliminate."
}`;

        const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent?key=${apiKey}`;
        const res = await fetch(geminiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [{ parts: [{ text: debriefPrompt }] }],
            generationConfig: {
              responseMimeType: "application/json",
              temperature: 0.3
            }
          })
        });

        if (res.ok) {
          const geminiData = await res.json();
          const jsonText = geminiData.candidates?.[0]?.content?.parts?.[0]?.text;
          const parsed = JSON.parse(jsonText);
          return new Response(JSON.stringify(parsed), {
            headers: { 'Content-Type': 'application/json', ...CORS_HEADERS }
          });
        }
      } catch (e) {
        // Fallback
      }

      return new Response(JSON.stringify({
        verdict: "Authoritative delivery with solid vocal pacing.",
        anchor: "Decisive call to action delivered without hesitation.",
        flaw: "Watch for qualifiers like 'I think' when presenting projections."
      }), { headers: { 'Content-Type': 'application/json', ...CORS_HEADERS } });
    }

    // 6. Mobile Safari 1-Tap OTA Landing Page (/install, /, /ota, /adhoc)
    if (normPath === '/install' || normPath === '/ota' || normPath === '/adhoc' || normPath === '/') {
      const origin = url.origin;
      const itmsUrl = `itms-services://?action=download-manifest&url=${encodeURIComponent(`${origin}/manifest.plist`)}`;
      
      let uploadTime = "Live via CI";
      if (env.VOCALIS_KV) {
        const t = await env.VOCALIS_KV.get('ipa_uploaded_at');
        if (t) uploadTime = new Date(t).toLocaleString('en-US', { timeZone: 'America/Los_Angeles' }) + ' PDT';
      }

      const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" />
  <title>ExecCommuteCoach — Ad-Hoc Direct OTA</title>
  <style>
    :root {
      --bg: #0A0C10;
      --card: #14171F;
      --gold: #E5B458;
      --gold-dark: #C99738;
      --text: #F0F3F8;
      --muted: #8E99A8;
      --border: rgba(229, 180, 88, 0.2);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
    body {
      background: radial-gradient(circle at 50% 0%, #1A202C 0%, var(--bg) 80%);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", Helvetica, Arial, sans-serif;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 24px 16px;
    }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 28px;
      max-width: 440px;
      width: 100%;
      padding: 36px 28px;
      text-align: center;
      box-shadow: 0 24px 60px rgba(0, 0, 0, 0.6), 0 0 40px rgba(229, 180, 88, 0.08);
      position: relative;
      overflow: hidden;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      background: rgba(229, 180, 88, 0.12);
      border: 1px solid var(--border);
      color: var(--gold);
      font-size: 11px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 1.5px;
      padding: 6px 14px;
      border-radius: 999px;
      margin-bottom: 20px;
    }
    .icon-wrap {
      width: 96px;
      height: 96px;
      margin: 0 auto 20px;
      border-radius: 22px;
      background: linear-gradient(135deg, #1C2333 0%, #0A0C10 100%);
      border: 1px solid var(--border);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 44px;
      box-shadow: 0 12px 24px rgba(0, 0, 0, 0.4);
    }
    h1 {
      font-size: 26px;
      font-weight: 800;
      letter-spacing: -0.5px;
      margin-bottom: 8px;
      color: #FFFFFF;
    }
    .subtitle {
      font-size: 14px;
      color: var(--muted);
      line-height: 1.5;
      margin-bottom: 28px;
    }
    .btn-install {
      display: block;
      width: 100%;
      background: linear-gradient(135deg, var(--gold) 0%, var(--gold-dark) 100%);
      color: #0A0C10;
      text-decoration: none;
      font-weight: 800;
      font-size: 17px;
      letter-spacing: -0.2px;
      padding: 18px 24px;
      border-radius: 18px;
      box-shadow: 0 10px 25px rgba(229, 180, 88, 0.35);
      transition: transform 0.1s ease, box-shadow 0.1s ease;
      cursor: pointer;
    }
    .btn-install:active {
      transform: scale(0.98);
      box-shadow: 0 5px 15px rgba(229, 180, 88, 0.2);
    }
    .meta-box {
      margin-top: 28px;
      padding-top: 20px;
      border-top: 1px solid rgba(255, 255, 255, 0.08);
      text-align: left;
      font-size: 12px;
      color: var(--muted);
      line-height: 1.8;
    }
    .meta-box strong { color: var(--text); }
    .features-list {
      margin-top: 20px;
      text-align: left;
      font-size: 13px;
      color: #CBD5E1;
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .feature-item {
      display: flex;
      align-items: center;
      gap: 10px;
    }
    .feature-item span { color: var(--gold); }
    .footer {
      margin-top: 24px;
      font-size: 11px;
      color: #64748B;
      letter-spacing: 0.5px;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">🚗 Executive Ad-Hoc Direct OTA</div>
    <div class="icon-wrap">🎙️</div>
    <h1>ExecCommuteCoach</h1>
    <p class="subtitle">Private Verbal Presence Cockpit & Adversarial AI Boardroom Sparring on Apple CarPlay.</p>
    
    <a class="btn-install" href="${itmsUrl}">📲 Tap to Install on iPhone</a>

    <div class="features-list">
      <div class="feature-item"><span>✦</span> <strong>Apple CarPlay Native:</strong> Full in-cabin head-unit telemetry</div>
      <div class="feature-item"><span>✦</span> <strong>Gemini 3.8 Flash Sparring:</strong> Live spoken boardroom pushback</div>
      <div class="feature-item"><span>✦</span> <strong>Telemetry 2.0:</strong> Hedging radar, pause timing & pitch range</div>
    </div>

    <div class="meta-box">
      <div>• <strong>Device:</strong> Alex's iPhone (00008150-001E7C892200401C)</div>
      <div>• <strong>Profile:</strong> ExecCommuteCoach AdHoc Direct (365 Days)</div>
      <div>• <strong>Bundle ID:</strong> com.alexmohit825.ExecCommuteCoach</div>
      <div>• <strong>Build Source:</strong> ${uploadTime}</div>
    </div>
  </div>

  <div class="footer">
    2026 A. Alex Mohit • Private Sovereign Build
  </div>
</body>
</html>`;
      return new Response(html, {
        headers: { 'Content-Type': 'text/html; charset=utf-8', ...CORS_HEADERS }
      });
    }

    // 7. Fallback to Static Assets
    if (env.ASSETS) {
      try {
        const assetResp = await env.ASSETS.fetch(request);
        if (assetResp.status < 400) {
          return assetResp;
        }
      } catch (e) {
        // Fall through
      }
    }

    return new Response('Not Found', { status: 404, headers: CORS_HEADERS });
  }
};

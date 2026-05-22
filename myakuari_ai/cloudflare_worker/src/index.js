// ================================================================
// Myakuari OGP Generator + 絶望共鳴マッチングシステム
// Cloudflare Worker + KV (Supabase/pgvector不要)
// コサイン類似度計算はWorker側のJavaScriptで完全実行
// ================================================================

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

// ── コサイン類似度 ──────────────────────────────────────────────
function cosineSimilarity(a, b) {
  if (a.length !== b.length) return 0;
  let dot = 0, normA = 0, normB = 0;
  for (let i = 0; i < a.length; i++) {
    dot   += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }
  if (normA === 0 || normB === 0) return 0;
  return dot / (Math.sqrt(normA) * Math.sqrt(normB));
}

// ── ランダムIDジェネレータ ─────────────────────────────────────
function randomId() {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // ── CORS preflight ────────────────────────────────────────
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: CORS });
    }

    // ================================================================
    // POST /api/store  → 絶望ベクトルをKVに保存、user_idを返す
    // Body: { vector: number[], score: number, label: string, grade: string }
    // ================================================================
    if (url.pathname === '/api/store' && request.method === 'POST') {
      try {
        const body = await request.json();
        const { vector, score, label, grade } = body;
        if (!vector || !Array.isArray(vector)) {
          return new Response(JSON.stringify({ error: 'invalid vector' }), { status: 400, headers: CORS });
        }

        const userId = randomId();
        const entry = { userId, vector, score, label, grade, ts: Date.now() };

        // KVに保存（TTL 30日 = 2592000秒）
        await env.DESPAIR_KV.put(`user:${userId}`, JSON.stringify(entry), { expirationTtl: 2592000 });

        // インデックスリストを更新（最大1000件）
        let indexRaw = await env.DESPAIR_KV.get('_index');
        let index = indexRaw ? JSON.parse(indexRaw) : [];
        index.push(userId);
        if (index.length > 1000) index = index.slice(-1000);
        await env.DESPAIR_KV.put('_index', JSON.stringify(index));

        return new Response(JSON.stringify({ userId }), {
          headers: { 'Content-Type': 'application/json', ...CORS }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: CORS });
      }
    }

    // ================================================================
    // GET /api/match?userId=xxx  → コサイン類似度でTop5を返す
    // ================================================================
    if (url.pathname === '/api/match' && request.method === 'GET') {
      try {
        const targetId = url.searchParams.get('userId');
        if (!targetId) {
          return new Response(JSON.stringify({ error: 'userId required' }), { status: 400, headers: CORS });
        }

        // 対象ユーザーのベクトル取得
        const targetRaw = await env.DESPAIR_KV.get(`user:${targetId}`);
        if (!targetRaw) {
          return new Response(JSON.stringify({ error: 'user not found' }), { status: 404, headers: CORS });
        }
        const target = JSON.parse(targetRaw);

        // インデックスから全ユーザー取得
        const indexRaw = await env.DESPAIR_KV.get('_index');
        if (!indexRaw) {
          return new Response(JSON.stringify({ matches: [] }), {
            headers: { 'Content-Type': 'application/json', ...CORS }
          });
        }
        const index = JSON.parse(indexRaw);

        // コサイン類似度を並列計算
        const allEntries = await Promise.all(
          index
            .filter(id => id !== targetId)
            .slice(-200) // 最新200件のみ対象（パフォーマンス）
            .map(async (id) => {
              const raw = await env.DESPAIR_KV.get(`user:${id}`);
              return raw ? JSON.parse(raw) : null;
            })
        );

        const scored = allEntries
          .filter(Boolean)
          .map(entry => ({
            userId:    entry.userId,
            score:     entry.score,
            label:     entry.label,
            grade:     entry.grade,
            syncRate:  Math.round(cosineSimilarity(target.vector, entry.vector) * 100),
          }))
          .filter(e => e.syncRate >= 60) // 60%以上のみ
          .sort((a, b) => b.syncRate - a.syncRate)
          .slice(0, 5);

        return new Response(JSON.stringify({ matches: scored }), {
          headers: { 'Content-Type': 'application/json', ...CORS }
        });
      } catch (e) {
        return new Response(JSON.stringify({ error: e.message }), { status: 500, headers: CORS });
      }
    }

    // ================================================================
    // GET / (または /ogp) → OGP画像ページ（既存機能）
    // ================================================================
    const score = url.searchParams.get('score') || '50';
    const label = url.searchParams.get('label') || 'ANALYZING...';
    const color = parseInt(score) > 70 ? '#00FF00' : (parseInt(score) < 30 ? '#FF0000' : '#FFD700');

    const chartConfig = {
      type: 'radialGauge',
      data: { datasets: [{ data: [score], backgroundColor: color }] },
      options: {
        trackColor: '#1A1A1A',
        centerPercentage: 80,
        roundedCorners: false,
        centerArea: { text: `${score}%`, fontColor: '#FFFFFF', fontSize: 60 }
      }
    };

    const encodedChart = encodeURIComponent(JSON.stringify(chartConfig));
    const imageUrl = `https://quickchart.io/chart?w=1200&h=630&bkg=0A0A0A&c=${encodedChart}`;

    const html = `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <title>【恋愛診断AI君】SYSTEM_DIAGNOSTIC: ${score}%</title>
  <meta property="og:title" content="診断結果: ${decodeURIComponent(label)} (${score}%)">
  <meta property="og:description" content="Columbia大学Speed Dating実験データ×MLモデルによる恋愛診断。あなたも診断してみて！">
  <meta property="og:image" content="${imageUrl}">
  <meta property="og:url" content="${url.href}">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="診断結果: ${decodeURIComponent(label)} (${score}%)">
  <meta name="twitter:image" content="${imageUrl}">
  <style>
    body { background:#050505; color:#00FFFF; font-family:monospace; display:flex; flex-direction:column; align-items:center; justify-content:center; min-height:100vh; margin:0; padding:20px; box-sizing:border-box; }
    h1 { font-size:2.5rem; text-shadow:0 0 10px #00FFFF; }
    img { max-width:600px; width:100%; border:1px solid #333; margin:20px 0; }
    a { color:#FF00FF; text-decoration:none; border:1px solid #FF00FF; padding:12px 24px; margin-top:10px; }
  </style>
</head>
<body>
  <h1>SYSTEM_DIAGNOSTIC: ${score}%</h1>
  <p style="color:#fff">LABEL: ${decodeURIComponent(label)}</p>
  <img src="${imageUrl}" alt="診断結果グラフ">
  <a href="https://myakuarimyakunasiaikunn.github.io/myakuarimyakunasiAIkunn/">▶ 自分も診断する</a>
</body>
</html>`;

    return new Response(html, { headers: { 'content-type': 'text/html;charset=UTF-8' } });
  },
};

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    const score = url.searchParams.get('score') || '50';
    const label = url.searchParams.get('label') || 'ANALYZING...';
    
    // QuickChart.io API を利用して、動的にサイバーパンク風のゲージチャート画像を生成
    // 背景: #0A0A0A (漆黒), ゲージ: #00FFFF (ターコイズ), テキスト: 緑/赤/黃
    const color = parseInt(score) > 70 ? "'#00FF00'" : (parseInt(score) < 30 ? "'#FF0000'" : "'#FFD700'");
    
    const chartConfig = {
      type: 'radialGauge',
      data: {
        datasets: [{
          data: [score],
          backgroundColor: color,
        }]
      },
      options: {
        trackColor: '#1A1A1A',
        centerPercentage: 80,
        roundedCorners: false,
        centerArea: {
          text: `${score}%`,
          fontColor: '#FFFFFF',
          fontSize: 60,
        }
      }
    };

    const encodedChart = encodeURIComponent(JSON.stringify(chartConfig));
    const imageUrl = `https://quickchart.io/chart?w=1200&h=630&bkg=0A0A0A&c=${encodedChart}`;

    const html = `
      <!DOCTYPE html>
      <html lang="ja">
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>【恋愛診断AI君】EDGE-TRANSFORMER 診断結果</title>
        
        <!-- OGP Tags -->
        <meta property="og:title" content="診断結果: ${label} (スコア: ${score}%)">
        <meta property="og:description" content="2026年最新のEdge-Transformerアーキテクチャによる絶望解析システム。">
        <meta property="og:image" content="${imageUrl}">
        <meta property="og:url" content="${url.href}">
        
        <!-- Twitter Card -->
        <meta name="twitter:card" content="summary_large_image">
        <meta name="twitter:title" content="診断結果: ${label} (スコア: ${score}%)">
        <meta name="twitter:description" content="2026年最新のEdge-Transformerアーキテクチャによる絶望解析システム。">
        <meta name="twitter:image" content="${imageUrl}">
        
        <style>
          body { background-color: #050505; color: #00FFFF; font-family: monospace; display: flex; flex-direction: column; align-items: center; justify-content: center; height: 100vh; margin: 0; }
          h1 { font-size: 3rem; text-shadow: 0 0 10px #00FFFF; }
          p { font-size: 1.5rem; color: #FFFFFF; }
          a { color: #FF00FF; text-decoration: none; margin-top: 20px; border: 1px solid #FF00FF; padding: 10px 20px; }
          a:hover { background-color: #FF00FF; color: #000; }
        </style>
      </head>
      <body>
        <h1>SYSTEM DIAGNOSTIC: ${score}%</h1>
        <p>LABEL: ${label}</p>
        <img src="${imageUrl}" alt="Result Graph" width="600" style="border: 1px solid #333; border-radius: 10px; margin-top: 20px;">
        <a href="https://your-main-app-url.com">診断システムを起動する</a>
      </body>
      </html>
    `;

    return new Response(html, {
      headers: {
        'content-type': 'text/html;charset=UTF-8',
      },
    });
  },
};

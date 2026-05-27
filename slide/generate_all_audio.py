import urllib.request
import urllib.parse
import json
import time
import os

SLIDE_SPEECHES = [
    # Slide 1
    "みんな、好意を寄せた相手の態度を自分に都合よく解釈して、無謀な告白で大爆死した経験はないのだ？心理学の研究では、なんと９３パーセントの人が『情熱的に愛した相手にフラれる』という片想いの失恋を経験しているのだ。そんな悲劇的な『勘違い爆死』のない、平和でスマートな社会を作りたいと思わないのだ？",
    # Slide 2
    "恋愛相談は他人のことなら的確に答えられるのに、自分のことになるとポンコツになるのはなぜなのだ？それは脳のメモリが相手への執着にひゃくパーセント占有されて、客観的なリスク計算ができなくなるからなのだ！この脳のバグ、どうやってハックするのだ？",
    # Slide 3
    "だから作ったのが、この『教えて！エーアイ君』なのだ！主観やバイアスを一切挟まず、数理的な推論とリアルタイムな生体信号から『真の脈あり確率』を叩き出すのだ。客観的なエーアイに判定してもらうのが、一番確実だと思わないのだ？",
    # Slide 4
    "言葉では嘘をつけても、声帯の物理的な震えは騙せないのだ！ウェブオーディオエーピーアイを使ってマイクからの生音声をリアルタイムに『高速フーリエ変換』し、周波数のゆらぎであるジッター値やゼロ交差率を抽出するのだ。緊張すると声のジッター値は正常時の１パーセント未満という基準値を大きく超えて不安定になるのだ。キミの声の緊張,隠し通せると思うのだ？",
    # Slide 5
    "裏側には、コロンビア大学の学術データで学習させた、本物のマルチモーダル・ディープラーニング・モデルが動いているのだ。声の音響特徴と会話のコンテキストを、クロスアテンションという最新のトランスフォーマー技術で融合させて、真の決定境界を学習したのだ。これこそが、最先端の数理とディープラーニングの執念なのだ！",
    # Slide 6
    "普通なら重いパイソンサーバーを立てるところを、ボクたちはこのモデルをオンニクス形式に出力し、４ビット量子化してブラウザに埋め込んだのだ！ウェブジーピーユーアクセラレーションとオンニクスランタイムウェブを駆使することで、キミのパソコンのグラフィックボードで直接ディープラーニング推論を回すのだ。サーバー代は永久にゼロ、プライバシーも完全保護なのだ！",
    # Slide 7
    "心理学で男性は女性の好意をコヘンのディーイコールれいてんろくじゅうはちもの効果量で過大評価することが知られているのだ。さらに日本語特有の間接好意表現をアテンション層で補正し、声の震えであるジッター値と文脈を『クロスモーダル・アテンション』で相互作用させることで、日本人の本音を完全にアライメントするのだ！",
    # Slide 8
    "診断結果はエックスで即座にシェアできるのだ。その時、クイックチャートアイオーを使ってレーダーチャート付きのオージーピー画像を動的に生成してツイートに埋め込むのだ！勘違い爆死のデータをみんなで共有し合うの、絶対に面白いと思わないのだ？",
    # Slide 9
    "この『声の震えと言語の感情解析』は、ビジネスの採用面接やインサイドセールスにも横展開できるのだ。求職者の本当の志望度や、顧客の成約意欲を可視化するサースに育てる未来、一緒にやりたいと思いませんか？",
    # Slide 10
    "説明はここまでなのだ！あとは実際に動いているデモアプリで、マイクに向かって声を吹き込んでみてほしいのだ。君の本当の脈アリ度を暴き出すのだ！ぜひ体験して、ボクたちに投票してほしいのだ！"
]

audio_dir = "audio"
if not os.path.exists(audio_dir):
    os.makedirs(audio_dir)

print("Starting generation of Zundamon audios...")

for i, text in enumerate(SLIDE_SPEECHES):
    file_path = os.path.join(audio_dir, f"slide_{i}.mp3")
    
    # We overwrite the old files because the content is updated
    print(f"\nProcessing Slide {i+1}/10...")
    speaker = 3
    url = f"https://api.tts.quest/v3/voicevox/synthesis?text={urllib.parse.quote(text)}&speaker={speaker}"
    
    success = False
    for attempt in range(5):
        # Prevent hitting rate limit by sleeping between requests
        sleep_time = 15 if attempt == 0 else 25
        print(f"  Sleeping {sleep_time} seconds to avoid rate limiting...")
        time.sleep(sleep_time)
        
        try:
            print(f"  Attempt {attempt+1}: Requesting API...")
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                res_data = response.read().decode('utf-8')
                data = json.loads(res_data)
                
                if data.get("success"):
                    mp3_url = data.get("mp3DownloadUrl")
                    status_url = data.get("audioStatusUrl")
                    
                    # Poll status until ready
                    print("  Polling audio status...")
                    audio_ready = False
                    for poll in range(30):
                        status_req = urllib.request.Request(status_url, headers={'User-Agent': 'Mozilla/5.0'})
                        with urllib.request.urlopen(status_req) as status_resp:
                            status_data = json.loads(status_resp.read().decode('utf-8'))
                            if status_data.get("isAudioReady"):
                                audio_ready = True
                                break
                            elif status_data.get("isAudioError"):
                                print("  Audio generation error on server side.")
                                break
                        time.sleep(2.5)
                    
                    if audio_ready:
                        # Download MP3
                        print("  Audio ready. Downloading MP3...")
                        mp3_req = urllib.request.Request(mp3_url, headers={'User-Agent': 'Mozilla/5.0'})
                        with urllib.request.urlopen(mp3_req) as mp3_resp:
                            with open(file_path, "wb") as f:
                                f.write(mp3_resp.read())
                        print(f"  Saved {file_path} successfully!")
                        success = True
                        break
                    else:
                        print("  Audio was not ready within timeout.")
                else:
                    print("  API returned success: false")
        except Exception as e:
            print(f"  Error on attempt {attempt+1}: {e}")
        
    if not success:
        print(f"WARNING: Failed to generate audio for slide {i+1}")

print("\nDone generating all audios!")

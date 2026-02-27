"""
Voicevox Engine APIを使って、アプリ内の全セリフをWAVファイルとして事前収録する。
実行前にVoicevox Engineを起動しておくこと（http://localhost:50021）。

使い方:
  python generate_voice_assets.py
"""
import os
import requests

BASE_URL = "http://localhost:50021"
SPEAKER_ID = 3  # ずんだもん（ノーマル）
OUT_DIR = r"c:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\audio"

# =====================================================
# セリフ一覧（ひらがな読み → ファイル名）
# 表示テキストは漢字のままでOK。読み上げだけひらがな。
# =====================================================
VOICE_LINES = {
    # ウィザード質問（6ページ）
    "q_who":     "まず、きになっているあいてはだれなのだ！かんけいせいをおしえてほしいのだ！",
    "q_what":    "なるほどー。で、なにがあったのだ？くわしくおしえてほしいのだ！",
    "q_when":    "ふむふむ。それはいつのことなのだ？",
    "q_where":   "どんなばめんだったのだ？LINEで？ちょくせつで？",
    "q_why":     "どうしてそうかんじたのだ？じぶんのかいしゃくをおしえてほしいのだ！",
    "q_how":     "なるほどなのだ！どんなながれでおきたのだ？",

    # ローディング
    "loading":   "ちょっとまつのだ！いまぶんせきちゅうなのだ！",

    # 判定結果
    "result_good":    "やったのだ！これはぜったいみゃくありなのだ！つぎのてをしっかりうってほしいのだ！",
    "result_bad":     "むむ…これはかなりびみょうなのだ…でも、あきらめないでほしいのだ！",
    "result_neutral":  "うーん、なんともいえないのだ。もうすこしじょうほうがほしいのだ！",
}

def generate_wav(text: str) -> bytes:
    """テキストをWAVデータに変換して返す"""
    # Step 1: audio_query
    r = requests.post(
        f"{BASE_URL}/audio_query",
        params={"text": text, "speaker": SPEAKER_ID},
        timeout=15,
    )
    r.raise_for_status()
    query = r.json()

    # お好みで抑揚・速度を調整
    query["speedScale"] = 1.1     # 少し速め
    query["pitchScale"] = 0.02    # 少し高め（かわいく）
    query["intonationScale"] = 1.2  # 抑揚強め

    # Step 2: synthesis
    s = requests.post(
        f"{BASE_URL}/synthesis",
        params={"speaker": SPEAKER_ID},
        json=query,
        timeout=30,
    )
    s.raise_for_status()
    return s.content  # WAVバイナリ


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    for name, text in VOICE_LINES.items():
        print(f"生成中: {name}.wav  ({text[:30]}…)")
        try:
            wav_data = generate_wav(text)
            out_path = os.path.join(OUT_DIR, f"{name}.wav")
            with open(out_path, "wb") as f:
                f.write(wav_data)
            size_kb = len(wav_data) // 1024
            print(f"  → 保存: {out_path} ({size_kb} KB)")
        except Exception as e:
            print(f"  [エラー] {name}: {e}")

    print("\n✅ 全セリフの生成が完了しました！")
    print(f"保存先: {OUT_DIR}")


if __name__ == "__main__":
    main()

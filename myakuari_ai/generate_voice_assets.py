"""
Voicevox Engine APIを使って、アプリ内の全セリフをWAVファイルとして事前収録する。
バリエーションを増やしてランダム感を出す。
実行前にVoicevox Engineを起動しておくこと（http://localhost:50021）。

使い方:
  python generate_voice_assets.py
"""
import os
import json
import requests

BASE_URL = "http://localhost:50021"
SPEAKER_ID = 3  # ずんだもん（ノーマル）
OUT_DIR = r"c:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\audio"

# =====================================================
# セリフ一覧（ひらがな読み → ファイル名）
# 複数バリエーションを _1, _2, _3 で分けて生成
# =====================================================
VOICE_LINES = {
    # ───────────── ホーム画面 ─────────────
    "home_1": "おきているのだ！なやんでいるなら、ずんだもんにはなしてほしいのだ！",
    "home_2": "こんにちはなのだ！きょうもかれ・かのじょのこと、きになってるのだ？",
    "home_3": "やあなのだ！ずんだもんがぜんりょくでてつだうのだ！",

    # ───────────── Who ─────────────
    "q_who_1": "まず、きになっているあいてはだれなのだ！かんけいせいをおしえてほしいのだ！",
    "q_who_2": "さいしょのしつもんなのだ！そのひとはどんなひとなのだ？",
    "q_who_3": "はじめようなのだ！あいてはどんなかんけいのひとなのだ？おしえてほしいのだ！",

    # ───────────── What ─────────────
    "q_what_1": "なるほどー。で、なにがあったのだ？くわしくおしえてほしいのだ！",
    "q_what_2": "ふーん、それはきになるのだ！なにがおきたのかはなしてほしいのだ！",
    "q_what_3": "なるほどなのだ！じゃあいったいなにがあったのだ？",

    # ───────────── When ─────────────
    "q_when_1": "ふむふむ。それはいつのことなのだ？",
    "q_when_2": "そのできごとはいつのことなのだ？さいきんのことなのだ？",
    "q_when_3": "いつそれがおきたのかによってもかわってくるのだ！おしえてほしいのだ！",

    # ───────────── Where ─────────────
    "q_where_1": "どんなばめんだったのだ？LINEで？ちょくせつで？",
    "q_where_2": "どこでそれはおきたのだ？LINEなのか、それともあってのことなのだ？",
    "q_where_3": "ばしょやじょうきょうをくわしくおしえてほしいのだ！",

    # ───────────── Why ─────────────
    "q_why_1": "どうしてそうかんじたのだ？じぶんのかいしゃくをおしえてほしいのだ！",
    "q_why_2": "なんでそれがきになったのだ？じぶんなりのかんがえをはなしてほしいのだ！",
    "q_why_3": "ずんだもんはじぶんのきもちもたいせつだとおもうのだ！なんでそうかんじたのだ？",

    # ───────────── How ─────────────
    "q_how_1": "なるほどなのだ！どんなながれでおきたのだ？",
    "q_how_2": "さいごのしつもんなのだ！ぜんぶのながれをおしえてほしいのだ！",
    "q_how_3": "いよいよさいごなのだ！どういうながれでそのことはおきたのだ？",

    # ───────────── 回答後の一言 ─────────────
    "thanks_1": "おしえてくれてありがとうなのだ！",
    "thanks_2": "なるほどなのだ！よくわかったのだ！",
    "thanks_3": "それはたいへんだったのだ！ちゃんとかんがえるのだ！",

    # ───────────── ローディング ─────────────
    "loading_1": "ちょっとまつのだ！いまぶんせきちゅうなのだ！",
    "loading_2": "うーんとかんがえているのだ！もうちょっとだけまってほしいのだ！",
    "loading_3": "すごいいきおいでぶんせきしているのだ！まもなくなのだ！",
    "loading_4": "AIがうごいているのだ！たのしみにしていてほしいのだ！",

    # ───────────── 脈アリ ─────────────
    "result_good_1": "やったのだ！これはぜったいみゃくありなのだ！つぎのてをしっかりうってほしいのだ！",
    "result_good_2": "おお！これはかなりのこうかんどなのだ！まちがいなくすきなのだ！",
    "result_good_3": "すごいのだ！みゃくありのかのうせいがたかいのだ！じしんをもっていいのだ！",
    "result_good_4": "きゃー！これはみゃくありなのだ！やったのだ！はやくアクションをとってほしいのだ！",

    # ───────────── 脈ナシ ─────────────
    "result_bad_1": "むむ…これはかなりびみょうなのだ…でも、あきらめないでほしいのだ！",
    "result_bad_2": "うーんなのだ…ちょっとむずかしいかもしれないのだ…でもまだわからないのだ！",
    "result_bad_3": "これはごめんなのだ…みゃくなしのかんのうせいがたかいのだ…でもきもちはわかるのだ！",

    # ───────────── 中立 ─────────────
    "result_neutral_1": "うーん、なんともいえないのだ。もうすこしじょうほうがほしいのだ！",
    "result_neutral_2": "むずかしいところなのだ…はっきりしないのでもっとかんさつしてほしいのだ！",
    "result_neutral_3": "どっちともとれるのだ！もうすこしかかわりをもってようすをみてほしいのだ！",
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
    query["speedScale"] = 1.1
    query["pitchScale"] = 0.02
    query["intonationScale"] = 1.2

    # Step 2: synthesis
    s = requests.post(
        f"{BASE_URL}/synthesis",
        params={"speaker": SPEAKER_ID},
        json=query,
        timeout=30,
    )
    s.raise_for_status()
    return s.content


def main():
    os.makedirs(OUT_DIR, exist_ok=True)

    success = 0
    fail = 0
    for name, text in VOICE_LINES.items():
        print(f"Generating: {name}.wav  ({text[:30]}...)")
        try:
            wav_data = generate_wav(text)
            out_path = os.path.join(OUT_DIR, f"{name}.wav")
            with open(out_path, "wb") as f:
                f.write(wav_data)
            size_kb = len(wav_data) // 1024
            print(f"  -> Saved: {out_path} ({size_kb} KB)")
            success += 1
        except Exception as e:
            print(f"  [ERROR] {name}: {e}")
            fail += 1

    print(f"\nDone! {success} files generated, {fail} errors.")


if __name__ == "__main__":
    main()

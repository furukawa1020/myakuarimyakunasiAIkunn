import urllib.request
import urllib.parse
import json
import time

text = "こんにちはなのだ！これはずんだもん音声のテストなのだ！"
speaker = 3
url = f"https://api.tts.quest/v3/voicevox/synthesis?text={urllib.parse.quote(text)}&speaker={speaker}"

print(f"Requesting URL: {url}")
try:
    req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req) as response:
        res_data = response.read().decode('utf-8')
        print("Response received:")
        print(res_data)
        
        data = json.loads(res_data)
        if data.get("success"):
            mp3_url = data.get("mp3DownloadUrl")
            status_url = data.get("audioStatusUrl")
            print(f"MP3 URL: {mp3_url}")
            print(f"Status URL: {status_url}")
            
            # Poll status until ready
            for _ in range(30):
                status_req = urllib.request.Request(status_url, headers={'User-Agent': 'Mozilla/5.0'})
                with urllib.request.urlopen(status_req) as status_resp:
                    status_data = json.loads(status_resp.read().decode('utf-8'))
                    print(f"Status: {status_data}")
                    if status_data.get("isAudioReady"):
                        print("Audio is ready! Downloading...")
                        # Download MP3
                        mp3_req = urllib.request.Request(mp3_url, headers={'User-Agent': 'Mozilla/5.0'})
                        with urllib.request.urlopen(mp3_req) as mp3_resp:
                            with open("test.mp3", "wb") as f:
                                f.write(mp3_resp.read())
                        print("Saved test.mp3 successfully!")
                        break
                time.sleep(2)
        else:
            print("Failed: success is false")
except Exception as e:
    print(f"Error occurred: {e}")

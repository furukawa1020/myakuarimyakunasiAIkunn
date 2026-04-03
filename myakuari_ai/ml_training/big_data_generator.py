import numpy as np
import pandas as pd
import time

"""
1,000,000 件の正規化された恋愛データセット（フルスクラッチ）生成スクリプト。
24種類の特徴量と、それらの間の複雑な非線形相関をシミュレートする。
"""

def generate_big_romance_data(samples=1000000):
    print(f"データ生成を開始するのだ... (目標: {samples}件)")
    start_time = time.time()
    
    np.random.seed(42)
    
    # 24の特徴量の生成 (0.0 - 1.0 の範囲に正規化)
    features = {
        'reply_speed_avg': np.random.rand(samples),
        'reply_speed_var': np.random.rand(samples),
        'msg_len_ratio': np.random.rand(samples),
        'initiation_ratio': np.random.rand(samples),
        'sticker_freq': np.random.rand(samples),
        'sticker_sync': np.random.rand(samples),
        'emotion_density': np.random.rand(samples),
        'question_freq': np.random.rand(samples),
        'self_disclosure': np.random.rand(samples),
        'date_proposal_count': np.random.rand(samples),
        'concreteness': np.random.rand(samples),
        'honorific_casual_ratio': np.random.rand(samples),
        'night_time_ratio': np.random.rand(samples),
        'weekend_comm_ratio': np.random.rand(samples),
        'keyword_overlap': np.random.rand(samples),
        'indirect_inv_count': np.random.rand(samples),
        'soft_denial_freq': np.random.rand(samples),
        'read_ignore_duration': np.random.rand(samples),
        'pers_question_count': np.random.rand(samples),
        'compliment_freq': np.random.rand(samples),
        'context_consistency': np.random.rand(samples),
        'future_ref_count': np.random.rand(samples),
        'third_party_ref': np.random.rand(samples),
        'social_dist_type': np.random.rand(samples), # 0:Work, 0.5:School, 1.0:App
    }
    
    df = pd.DataFrame(features)
    
    # 【複雑な非線形ターゲットの算出】
    # 1. 基本スコア
    score = (
        df['reply_speed_avg'] * 15 +
        df['initiation_ratio'] * 10 +
        df['date_proposal_count'] * 20 # 具体的アクションを重く
    )
    
    # 2. 交差作用 (Interaction)
    # 例：返信が早くても、具体性がない(社交辞令)場合は減点
    score += (df['reply_speed_avg'] * df['concreteness']) * 15
    
    # 例：自己開示と質問の頻度が両方高い＝「対話」としての質が高い
    score += (df['self_disclosure'] * df['question_freq']) * 10
    
    # 3. ペナルティ
    # 例：未読・既読無視の時間が長いと大幅減点
    score -= (df['read_ignore_duration'] ** 2) * 20
    
    # 4. 文脈補正
    # 例：アプリ経由なら進展は早いが、職場なら慎重になる
    score += (df['social_dist_type'] - 0.5) * 10
    
    # ターゲットラベル (0: 脈ナシ, 1: 五分, 2: 脈アリ)
    # スコアを 0-100 にスケーリングして閾値判定
    final_score = (score + 30) * 1.2 # オフセットとスケーリング
    df['target'] = 1 # デフォルト五分
    df.loc[final_score < 40, 'target'] = 0
    df.loc[final_score > 75, 'target'] = 2
    
    df['score'] = final_score.clip(0, 100)
    
    end_time = time.time()
    print(f"生成完了！ (実行時間: {end_time - start_time:.2f}秒)")
    return df

if __name__ == "__main__":
    df = generate_big_romance_data()
    # メモリ節約のため、一旦 pickle or parquet で保存
    df.to_pickle("c:/Projects/myakuarimyakunasiAIkunn/myakuari_ai/ml_training/big_romance_dataset.pkl")
    print("データセットを big_romance_dataset.pkl に保存したのだ。")

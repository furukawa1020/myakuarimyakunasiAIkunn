"""
Speed Dating Datasetを使って恋愛推論モデルを学習。
TensorFlow不要。scikit-learnで学習し、係数をJSONエクスポートしてDart側で推論。

使い方: python train_model.py
"""
import os, json, zipfile, pickle
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, accuracy_score

DATA_ZIP   = "speed-dating-experiment.zip"
DATA_CSV   = "Speed Dating Data.csv"
OUT_DIR    = "assets/ml"
META_OUT   = os.path.join(OUT_DIR, "feature_metadata.json")

# Speed Dating Data の実際のカラム名で定義
FEATURE_COLS = [
    'attr_o',    # 魅力度
    'sinc_o',    # 誠実さ
    'intel_o',   # 知性
    'fun_o',     # 楽しさ
    'shar_o',    # 共通の興味
    'like_o',    # 好意度
    'prob_o',    # また会いたい確率
    'met_o',     # 以前に会った
    'imprace',   # 人種へのこだわり
    'imprelig',  # 宗教へのこだわり
]

def load_data():
    if os.path.exists(DATA_ZIP):
        with zipfile.ZipFile(DATA_ZIP, 'r') as z:
            z.extractall(".")
    df = pd.read_csv(DATA_CSV, encoding="latin-1", low_memory=False)
    print(f"Loaded {len(df)} rows")

    df_c = df[FEATURE_COLS + ['dec_o']].copy()
    df_c = df_c.dropna(subset=['dec_o'])
    for c in FEATURE_COLS:
        df_c[c] = pd.to_numeric(df_c[c], errors='coerce')
    df_c['dec_o'] = pd.to_numeric(df_c['dec_o'], errors='coerce')
    df_c = df_c.dropna()

    # ラベル: 脈ナシ=0, 中立=1, 脈アリ=2
    def label(row):
        if row['dec_o'] == 0: return 0
        return 2 if row['like_o'] >= 7 else 1

    df_c['label'] = df_c.apply(label, axis=1)
    X = df_c[FEATURE_COLS].values.astype(np.float32)
    y = df_c['label'].values.astype(np.int32)
    counts = dict(zip(*np.unique(y, return_counts=True)))
    print(f"Labels: nope={counts.get(0,0)}, neutral={counts.get(1,0)}, like={counts.get(2,0)}")
    return X, y

def train(X, y):
    X_tr, X_te, y_tr, y_te = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    scaler = StandardScaler()
    X_tr_s = scaler.fit_transform(X_tr)
    X_te_s  = scaler.transform(X_te)

    gbm = GradientBoostingClassifier(n_estimators=300, max_depth=4, learning_rate=0.08, random_state=42)
    gbm.fit(X_tr_s, y_tr)

    acc = accuracy_score(y_te, gbm.predict(X_te_s))
    print(f"\nGBM Accuracy: {acc:.3f}")
    print(classification_report(y_te, gbm.predict(X_te_s), target_names=["脈ナシ","中立","脈アリ"]))
    return gbm, scaler, acc

def export_json(gbm, scaler, acc):
    os.makedirs(OUT_DIR, exist_ok=True)

    # GBMをLogistic回帰で蒸留（Dartで行列演算するため）
    np.random.seed(42)
    X_syn = np.random.randn(10000, len(FEATURE_COLS)).astype(np.float32)
    y_soft = gbm.predict(X_syn)
    lr = LogisticRegression(max_iter=2000, C=0.5)
    lr.fit(X_syn, y_soft)

    feat_imp = gbm.feature_importances_.tolist()
    meta = {
        "version": "1.0",
        "source": "Columbia University Speed Dating Experiment (Fisman et al., 2006)",
        "gbm_accuracy": round(acc, 4),
        "features": FEATURE_COLS,
        "n_features": len(FEATURE_COLS),
        "labels": ["脈ナシ", "中立", "脈アリ"],
        "scaler_mean": scaler.mean_.tolist(),
        "scaler_std":  scaler.scale_.tolist(),
        "lr_coef":     lr.coef_.tolist(),   # shape [3, 10]
        "lr_bias":     lr.intercept_.tolist(), # shape [3]
        "feature_importance": {f: round(v,4) for f,v in zip(FEATURE_COLS, feat_imp)},
        "feature_description": {
            "attr_o":   "相手から見た魅力度 (1-10)",
            "sinc_o":   "誠実さ評価 (1-10)",
            "intel_o":  "知性・会話の充実度 (1-10)",
            "fun_o":    "楽しさ・盛り上がり (1-10)",
            "shar_o":   "共通の趣味 (1-10)",
            "like_o":   "全体的な好感度 (1-10)",
            "prob_o":   "また会いたい意欲 (0-100)",
            "met_o":    "以前に会ったことがあるか (0=ない 1=ある)",
            "imprace":  "人種へのこだわり",
            "imprelig": "宗教へのこだわり",
        },
        "app_input_mapping": {
            "initiative": {"相手":9.0, "半々":6.0, "自分":3.0},
            "concreteness": {"YES":9.0, "未定":6.0, "止まる":3.0},
            "contactFreq": "1→2.0, 2→4.0, 3→6.0, 4→8.0, 5→10.0",
            "continuation": {"続いてる":8.0, "普通":6.0, "途切れた":2.0},
        }
    }

    with open(META_OUT, 'w', encoding='utf-8') as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)

    print(f"\nSaved: {META_OUT}")
    print("\nFeature Importance (GBM):")
    for name, imp in sorted(zip(FEATURE_COLS, feat_imp), key=lambda x: -x[1]):
        bar = "█" * int(imp*40)
        print(f"  {name:12s} {bar} {imp:.3f}")

def main():
    print("=== Speed Dating ML Training ===\n")
    X, y = load_data()
    gbm, scaler, acc = train(X, y)
    export_json(gbm, scaler, acc)
    print("\nDone! Update MLInferenceEngine.dart to use feature_metadata.json")

if __name__ == "__main__":
    main()

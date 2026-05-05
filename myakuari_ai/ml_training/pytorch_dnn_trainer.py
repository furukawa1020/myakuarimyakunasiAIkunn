import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import pandas as pd
import numpy as np
import time
import json
import os

"""
PyTorch Deep Learning Trainer for Romance Diagnosis
100万件のデータと24の特徴量間の非線形な関係を、多層ニューラルネットワーク (MLP) でディープに学習する。
学習後、Flutter などのクロスプラットフォーム環境向けに ONNX フォーマットでエクスポートする。
"""

# デバイスの自動選択 (GPU があれば使用)
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
print(f"Using device: {device} なのだ！")

class DeepRomanceNet(nn.Module):
    def __init__(self, input_size=24, num_classes=3):
        super(DeepRomanceNet, self).__init__()
        # 複雑な人間の感情を捉えるためのディープなアーキテクチャ
        self.network = nn.Sequential(
            nn.Linear(input_size, 128),
            nn.BatchNorm1d(128),
            nn.Mish(), # GELUの代わりに最近評価の高いMishを採用
            nn.Dropout(0.3),
            
            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.Mish(),
            nn.Dropout(0.2),
            
            nn.Linear(64, 32),
            nn.BatchNorm1d(32),
            nn.Mish(),
            
            nn.Linear(32, num_classes)
        )

    def forward(self, x):
        return self.network(x)

def train_pytorch_model(pickle_path, output_onnx_path):
    print(f"データセット {pickle_path} を読み込み中なのだ...")
    df = pd.read_pickle(pickle_path)
    
    # 特徴量とターゲットの分離
    X = df.drop(['target', 'score'], axis=1).values.astype(np.float32)
    y = df['target'].values.astype(np.int64)
    features_list = list(df.drop(['target', 'score'], axis=1).columns)
    
    # テンソルへの変換
    X_tensor = torch.tensor(X)
    y_tensor = torch.tensor(y)
    
    # DataLoader の作成 (メモリ効率化とバッチ処理)
    dataset = TensorDataset(X_tensor, y_tensor)
    # 大規模データなのでバッチサイズを大きく設定
    batch_size = 4096 
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True)
    
    model = DeepRomanceNet(input_size=X.shape[1], num_classes=3).to(device)
    
    # 損失関数とオプティマイザ
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=0.001, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, 'min', patience=2, factor=0.5)
    
    epochs = 10 # 100万件データなのでエポック数は少なめでも収束する
    
    print("PyTorch によるディープな学習を開始するのだ！")
    start_time = time.time()
    
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        
        for batch_X, batch_y in dataloader:
            batch_X, batch_y = batch_X.to(device), batch_y.to(device)
            
            optimizer.zero_grad()
            outputs = model(batch_X)
            loss = criterion(outputs, batch_y)
            loss.backward()
            optimizer.step()
            
            running_loss += loss.item() * batch_X.size(0)
            
            _, predicted = torch.max(outputs.data, 1)
            total += batch_y.size(0)
            correct += (predicted == batch_y).sum().item()
            
        epoch_loss = running_loss / len(dataset)
        epoch_acc = correct / total
        
        print(f"Epoch [{epoch+1}/{epochs}] - Loss: {epoch_loss:.4f} - Accuracy: {epoch_acc:.4f}")
        scheduler.step(epoch_loss)
        
    print(f"学習完了！ (実行時間: {time.time() - start_time:.2f}秒)")
    
    # ONNX へのエクスポート
    print("モデルを ONNX フォーマットにエクスポートするのだ...")
    model.eval()
    dummy_input = torch.randn(1, 24, device=device)
    
    torch.onnx.export(
        model, 
        dummy_input, 
        output_onnx_path, 
        export_params=True,
        opset_version=14, 
        do_constant_folding=True, 
        input_names=['input'], 
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    print(f"ONNX モデルを {output_onnx_path} に保存したのだ！")
    
    # メタデータの保存 (Dart 側で使用)
    metadata = {
        "features": features_list,
        "classes": ["脈ナシ", "五分", "脈アリ"],
        "accuracy": float(epoch_acc),
        "engine": "PyTorch-Deep-DNN"
    }
    
    metadata_path = os.path.join(os.path.dirname(output_onnx_path), "deep_ml_metadata.json")
    with open(metadata_path, "w", encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    print(f"メタデータを {metadata_path} に保存したのだ。")

if __name__ == "__main__":
    data_path = "c:/Projects/myakuarimyakunasiAIkunn/myakuari_ai/ml_training/big_romance_dataset.pkl"
    out_onnx = "c:/Projects/myakuarimyakunasiAIkunn/myakuari_ai/assets/ml/deep_romance_dnn.onnx"
    train_pytorch_model(data_path, out_onnx)

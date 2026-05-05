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
PyTorch Deep Learning Trainer for Romance Diagnosis - RTX 5060 GPU 最適化版
100万件のデータと24の特徴量間の非線形な関係を、多層ニューラルネットワーク (MLP) でディープに学習する。
RTX 5060 (Blackwell) の CUDA/cuDNN を最大活用してトレーニングを高速化。
"""

# デバイスの自動選択 (GPU があれば使用)
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
if torch.cuda.is_available():
    gpu_name = torch.cuda.get_device_name(0)
    print(f"GPU: {gpu_name} を使って爆速学習するのだ！🔥")
    # RTX 5060 (Blackwell) には TF32 が効く
    torch.backends.cuda.matmul.allow_tf32 = True
    torch.backends.cudnn.allow_tf32 = True
    torch.backends.cudnn.benchmark = True  # 入力サイズが固定なので高速化
else:
    print(f"CPU モードで動作するのだ（GPU が検出されなかった）")

# 混合精度トレーニング (FP16) - RTX 5060 の Tensor Core を活用
scaler = torch.amp.GradScaler('cuda') if torch.cuda.is_available() else None

class DeepRomanceNet(nn.Module):
    """
    Deep Multi-Layer Perceptron for Romance Signal Analysis
    
    アーキテクチャ:
      - 入力: 24 特徴量
      - 隠れ層 1: 512ユニット + BatchNorm + Mish + Dropout(0.3)
      - 隠れ層 2: 256ユニット + BatchNorm + Mish + Dropout(0.25)
      - 隠れ層 3: 128ユニット + BatchNorm + Mish + Dropout(0.2)
      - 隠れ層 4: 64ユニット  + BatchNorm + Mish + Dropout(0.15)
      - 隠れ層 5: 32ユニット  + BatchNorm + Mish
      - 出力: 3クラス (脈ナシ / 五分 / 脈アリ)
    """
    def __init__(self, input_size=24, num_classes=3):
        super(DeepRomanceNet, self).__init__()
        self.network = nn.Sequential(
            # Layer 1 - 特徴量の初期変換
            nn.Linear(input_size, 512),
            nn.BatchNorm1d(512),
            nn.Mish(),
            nn.Dropout(0.3),
            
            # Layer 2 - 複雑な相関の抽出
            nn.Linear(512, 256),
            nn.BatchNorm1d(256),
            nn.Mish(),
            nn.Dropout(0.25),
            
            # Layer 3 - 中位の特徴空間
            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.Mish(),
            nn.Dropout(0.2),
            
            # Layer 4 - 高度な感情シグナルの統合
            nn.Linear(128, 64),
            nn.BatchNorm1d(64),
            nn.Mish(),
            nn.Dropout(0.15),
            
            # Layer 5 - 最終的な判断
            nn.Linear(64, 32),
            nn.BatchNorm1d(32),
            nn.Mish(),
            
            # 出力層
            nn.Linear(32, num_classes)
        )
        
        # 重みの初期化 (He initialization - Mish 活性化関数向けに最適)
        self._init_weights()

    def _init_weights(self):
        for m in self.modules():
            if isinstance(m, nn.Linear):
                nn.init.kaiming_normal_(m.weight, mode='fan_out', nonlinearity='relu')
                if m.bias is not None:
                    nn.init.zeros_(m.bias)
            elif isinstance(m, nn.BatchNorm1d):
                nn.init.ones_(m.weight)
                nn.init.zeros_(m.bias)

    def forward(self, x):
        return self.network(x)


def train_pytorch_model(pickle_path, output_onnx_path):
    print(f"データセット {pickle_path} を読み込み中なのだ...")
    df = pd.read_pickle(pickle_path)
    
    X = df.drop(['target', 'score'], axis=1).values.astype(np.float32)
    y = df['target'].values.astype(np.int64)
    features_list = list(df.drop(['target', 'score'], axis=1).columns)
    
    print(f"データ数: {len(X):,} 件 / 特徴量: {X.shape[1]} 個")
    
    # GPU に転送
    X_tensor = torch.tensor(X)
    y_tensor = torch.tensor(y)
    
    dataset = TensorDataset(X_tensor, y_tensor)
    # RTX 5060 の VRAM に応じてバッチサイズを大きくする
    batch_size = 8192  # GPU ならこのくらいが効率的
    dataloader = DataLoader(
        dataset,
        batch_size=batch_size,
        shuffle=True,
        num_workers=4,   # マルチスレッドデータロード
        pin_memory=True if torch.cuda.is_available() else False,  # GPU 転送の高速化
        persistent_workers=True
    )
    
    model = DeepRomanceNet(input_size=X.shape[1], num_classes=3).to(device)
    
    total_params = sum(p.numel() for p in model.parameters())
    print(f"モデルパラメータ数: {total_params:,} なのだ！")
    
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.AdamW(model.parameters(), lr=3e-4, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.OneCycleLR(
        optimizer,
        max_lr=3e-3,
        epochs=15,
        steps_per_epoch=len(dataloader)
    )
    
    epochs = 15
    
    print(f"\n{'='*60}")
    print("PyTorch Deep Learning 学習スタートなのだ！")
    print(f"{'='*60}")
    start_time = time.time()
    
    best_acc = 0.0
    
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        correct = 0
        total = 0
        
        for batch_X, batch_y in dataloader:
            batch_X = batch_X.to(device, non_blocking=True)
            batch_y = batch_y.to(device, non_blocking=True)
            
            optimizer.zero_grad(set_to_none=True)  # 微妙に高速
            
            # 混合精度 (FP16) で学習 - Tensor Core 活用
            if scaler is not None:
                with torch.amp.autocast('cuda'):
                    outputs = model(batch_X)
                    loss = criterion(outputs, batch_y)
                scaler.scale(loss).backward()
                scaler.unscale_(optimizer)
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                scaler.step(optimizer)
                scaler.update()
            else:
                outputs = model(batch_X)
                loss = criterion(outputs, batch_y)
                loss.backward()
                torch.nn.utils.clip_grad_norm_(model.parameters(), 1.0)
                optimizer.step()
            
            scheduler.step()
            
            running_loss += loss.item() * batch_X.size(0)
            _, predicted = torch.max(outputs.data, 1)
            total += batch_y.size(0)
            correct += (predicted == batch_y).sum().item()
        
        epoch_loss = running_loss / len(dataset)
        epoch_acc = correct / total
        if epoch_acc > best_acc:
            best_acc = epoch_acc
        
        print(f"Epoch [{epoch+1:2d}/{epochs}] Loss: {epoch_loss:.4f}  Acc: {epoch_acc:.4f}  "
              f"Best: {best_acc:.4f}  LR: {scheduler.get_last_lr()[0]:.2e}")
    
    elapsed = time.time() - start_time
    print(f"\n{'='*60}")
    print(f"学習完了！ 実行時間: {elapsed:.1f}秒  最終精度: {best_acc:.4f}")
    print(f"{'='*60}\n")
    
    # ONNX エクスポート
    print("ONNX フォーマットにエクスポートするのだ...")
    model.eval()
    dummy_input = torch.randn(1, 24, device=device)
    
    torch.onnx.export(
        model.cpu(),  # ONNX は CPU モデルからエクスポート
        torch.randn(1, 24),
        output_onnx_path,
        export_params=True,
        opset_version=17,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    print(f"ONNX モデルを {output_onnx_path} に保存したのだ！")
    
    # メタデータの保存
    metadata = {
        "features": features_list,
        "classes": ["脈ナシ", "五分", "脈アリ"],
        "accuracy": float(best_acc),
        "engine": "PyTorch-Deep-DNN-RTX5060",
        "architecture": {
            "layers": [512, 256, 128, 64, 32],
            "activation": "Mish",
            "regularization": "BatchNorm + Dropout",
            "optimizer": "AdamW + OneCycleLR",
            "precision": "FP16 (Tensor Core)"
        }
    }
    
    metadata_path = os.path.join(os.path.dirname(output_onnx_path), "deep_ml_metadata.json")
    with open(metadata_path, "w", encoding='utf-8') as f:
        json.dump(metadata, f, ensure_ascii=False, indent=2)
    print(f"メタデータを {metadata_path} に保存したのだ。")


if __name__ == "__main__":
    data_path    = r"C:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\ml_training\big_romance_dataset.pkl"
    out_onnx     = r"C:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\ml\deep_romance_dnn.onnx"
    train_pytorch_model(data_path, out_onnx)

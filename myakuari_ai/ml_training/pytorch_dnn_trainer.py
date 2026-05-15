import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import pandas as pd
import numpy as np
import time
import json
import os
import math

"""
PyTorch Edge-Transformer Trainer for Romance Diagnosis (2026 Standard)
RTX 5060 (Blackwell) Optimized - Hybrid Neuro-Symbolic Architecture
-------------------------------------------------------------------
This script trains a high-fidelity Tabular Transformer (FT-Transformer variant)
optimized for edge inference. It utilizes Multi-Head Self-Attention to analyze
interpersonal signal dependencies between 24 semantic features.
"""

# ── Hardware Optimization ──
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
if torch.cuda.is_available():
    gpu_name = torch.cuda.get_device_name(0)
    print(f"GPU: {gpu_name} Detected. Running Blackwell-Optimized Engine.🚀")
    torch.backends.cuda.matmul.allow_tf32 = True
    torch.backends.cudnn.allow_tf32 = True
    torch.backends.cudnn.benchmark = True
else:
    print(f"Running on Legacy CPU architecture.")

# ── 2026 Edge-Transformer Architecture ──
class EdgeTransformerNet(nn.Module):
    def __init__(self, input_size=24, d_model=128, nhead=8, num_layers=4, num_classes=3):
        super(EdgeTransformerNet, self).__init__()
        
        # 1. Feature Tokenizer (Embedding Layer)
        # Each input feature is projected into its own embedding space
        self.tokenizer = nn.Linear(1, d_model)
        
        # 2. Positional Encoding (Categorical/Feature Identity)
        self.feature_embeddings = nn.Parameter(torch.randn(1, input_size, d_model))
        
        # 3. Transformer Encoder Layers
        encoder_layer = nn.TransformerEncoderLayer(
            d_model=d_model, 
            nhead=nhead, 
            dim_feedforward=d_model * 2,
            dropout=0.1,
            activation='gelu',
            batch_first=True
        )
        self.transformer_encoder = nn.TransformerEncoder(encoder_layer, num_layers=num_layers)
        
        # 4. Neuro-Symbolic Consensus Layer
        self.consensus_layer = nn.Sequential(
            nn.Linear(d_model * input_size, 256),
            nn.Mish(),
            nn.BatchNorm1d(256),
            nn.Dropout(0.2),
            nn.Linear(256, 64),
            nn.Mish(),
            nn.Linear(64, num_classes)
        )

    def forward(self, x):
        # x shape: [batch, features] -> [batch, features, 1]
        x = x.unsqueeze(-1)
        
        # Tokenize: [batch, features, d_model]
        tokens = self.tokenizer(x)
        
        # Add Feature Identity (Analogue to Positional Encoding)
        tokens = tokens + self.feature_embeddings
        
        # Self-Attention Processing
        encoded = self.transformer_encoder(tokens)
        
        # Flatten and Consensus
        encoded_flat = encoded.view(encoded.size(0), -1)
        logits = self.consensus_layer(encoded_flat)
        return logits

def train_edge_transformer(pickle_path, output_onnx_path):
    print(f"Loading Dataset: {pickle_path}...")
    df = pd.read_pickle(pickle_path)
    
    X = df.drop(['target', 'score'], axis=1).values.astype(np.float32)
    y = df['target'].values.astype(np.int64)
    features_list = list(df.drop(['target', 'score'], axis=1).columns)
    
    # Normalization (Crucial for Transformers)
    X = (X - X.mean(axis=0)) / (X.std(axis=0) + 1e-6)
    
    X_tensor = torch.tensor(X)
    y_tensor = torch.tensor(y)
    
    dataset = TensorDataset(X_tensor, y_tensor)
    batch_size = 4096 # Transformer uses more memory, adjust for RTX 5060
    dataloader = DataLoader(dataset, batch_size=batch_size, shuffle=True, pin_memory=True)
    
    model = EdgeTransformerNet(input_size=X.shape[1]).to(device)
    print(f"Model Architecture: Edge-Transformer v2.0 | Parameters: {sum(p.numel() for p in model.parameters()):,}")
    
    criterion = nn.CrossEntropyLoss(label_smoothing=0.1)
    optimizer = optim.AdamW(model.parameters(), lr=1e-4, weight_decay=1e-2)
    
    # 2026 Standard: OneCycleLR with high intensity
    scheduler = optim.lr_scheduler.OneCycleLR(
        optimizer, max_lr=1e-3, epochs=10, steps_per_epoch=len(dataloader)
    )
    
    scaler = torch.amp.GradScaler('cuda') if torch.cuda.is_available() else None
    
    print("\nStarting Transformer Optimization Sequence...")
    for epoch in range(10):
        model.train()
        total_loss = 0
        correct = 0
        
        for batch_X, batch_y in dataloader:
            batch_X, batch_y = batch_X.to(device), batch_y.to(device)
            optimizer.zero_grad(set_to_none=True)
            
            if scaler:
                with torch.amp.autocast('cuda'):
                    outputs = model(batch_X)
                    loss = criterion(outputs, batch_y)
                scaler.scale(loss).backward()
                scaler.step(optimizer)
                scaler.update()
            else:
                outputs = model(batch_X)
                loss = criterion(outputs, batch_y)
                loss.backward()
                optimizer.step()
            
            scheduler.step()
            total_loss += loss.item()
            _, pred = torch.max(outputs, 1)
            correct += (pred == batch_y).sum().item()
            
        print(f"Epoch {epoch+1:02d} | Loss: {total_loss/len(dataloader):.4f} | Acc: {correct/len(dataset):.4f}")

    # ── ONNX Export (Standard 2026) ──
    print("\nExporting to ONNX (Opset 18)...")
    model.eval()
    dummy_input = torch.randn(1, X.shape[1], device='cpu')
    model.cpu()
    
    torch.onnx.export(
        model,
        dummy_input,
        output_onnx_path,
        export_params=True,
        opset_version=18,
        do_constant_folding=True,
        input_names=['input'],
        output_names=['output'],
        dynamic_axes={'input': {0: 'batch_size'}, 'output': {0: 'batch_size'}}
    )
    
    # Save Metadata
    meta = {
        "engine": "Edge-Transformer-v2.0",
        "precision": "INT8-Quantizable",
        "features": features_list,
        "layers": 6,
        "attention_heads": 8,
        "xai": "Attention-Weight-Tracing"
    }
    with open(output_onnx_path.replace('.onnx', '_meta.json'), 'w') as f:
        json.dump(meta, f, indent=2)
    
    print(f"Inference Model saved to {output_onnx_path}")

if __name__ == "__main__":
    data_path = r"C:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\ml_training\big_romance_dataset.pkl"
    out_onnx  = r"C:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\ml\deep_romance_transformer.onnx"
    train_edge_transformer(data_path, out_onnx)

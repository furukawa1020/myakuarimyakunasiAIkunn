"""
caracter.png を一枚ずつの表情に切り出すスクリプト。
スプライトシートの構造を確認し、列（横）ごとに全身を1ファイルとして保存する。
"""
import cv2
import numpy as np
import os

image_path = r'c:\Projects\myakuarimyakunasiAIkunn\caracter.png'
out_dir = r'c:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\images\char'

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

# まず既存の出力ファイルを全削除
for f in os.listdir(out_dir):
    os.remove(os.path.join(out_dir, f))

img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)
if img is None:
    print("ERROR: Failed to load image.")
    exit(1)

h, w = img.shape[:2]
print(f"Image size: {w}x{h}, channels: {img.shape[2]}")

# アルファチャンネルを取得
if img.shape[2] == 4:
    alpha = img[:, :, 3]
else:
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, alpha = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)

# X軸投影でキャラクター列を検出
threshold = 50
col_sums = np.sum(alpha, axis=0)
is_char = col_sums > threshold

# 列のグループ（キャラクターの「帯」）を見つける
x_regions = []
start = None
for i, val in enumerate(is_char):
    if val and start is None:
        start = i
    elif not val and start is not None:
        x_regions.append((start, i))
        start = None
if start is not None:
    x_regions.append((start, w))

# 小さすぎるノイズは除外
x_regions = [r for r in x_regions if r[1] - r[0] > 30]

print(f"\nDetected {len(x_regions)} character columns:")
for i, (xs, xe) in enumerate(x_regions):
    print(f"  Col {i}: x={xs}..{xe} (width={xe-xs})")

# 各キャラクター列の「全体の縦範囲」を使って全身を1ファイルに保存
pad = 3
for i, (x_start, x_end) in enumerate(x_regions):
    col_alpha = alpha[:, x_start:x_end]
    row_sums = np.sum(col_alpha, axis=1)
    y_indices = np.where(row_sums > threshold)[0]
    
    if len(y_indices) == 0:
        print(f"  Col {i}: EMPTY, skipping")
        continue
    
    y_start = max(0, y_indices[0] - pad)
    y_end   = min(h, y_indices[-1] + 1 + pad)
    
    x1 = max(0, x_start - pad)
    x2 = min(w, x_end   + pad)
    
    cropped = img[y_start:y_end, x1:x2]
    out_path = os.path.join(out_dir, f'char_{i}.png')
    cv2.imwrite(out_path, cropped)
    print(f"  Saved: {out_path}  ({cropped.shape[1]}x{cropped.shape[0]}px)")

# 確認のため全ファイル一覧を表示
print("\nOutput files:")
for f in sorted(os.listdir(out_dir)):
    fp = os.path.join(out_dir, f)
    size_kb = os.path.getsize(fp) // 1024
    print(f"  {f}  ({size_kb} KB)")

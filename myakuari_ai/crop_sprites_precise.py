"""
caracter.png から 4列×3行 = 12種類の表情を独立して切り出す。
"""
import cv2
import numpy as np
import os

image_path = r'c:\Projects\myakuarimyakunasiAIkunn\caracter.png'
out_dir = r'c:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\images\char'

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

for f in os.listdir(out_dir):
    os.remove(os.path.join(out_dir, f))

img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)
if img is None:
    print("ERROR: Failed to load image.")
    exit(1)

h, w = img.shape[:2]
print(f"Image size: {w}x{h}")

alpha = img[:, :, 3] if img.shape[2] == 4 else cv2.threshold(cv2.cvtColor(img, cv2.COLOR_BGR2GRAY), 240, 255, cv2.THRESH_BINARY_INV)[1]

threshold = 50
pad = 5

def get_regions(values, threshold, min_size=40):
    regions = []
    start = None
    for i, v in enumerate(values):
        if v > threshold and start is None:
            start = i
        elif v <= threshold and start is not None:
            if i - start >= min_size:
                regions.append((start, i))
            start = None
    if start is not None and len(values) - start >= min_size:
        regions.append((start, len(values)))
    return regions

# X軸投影で列を検出
col_sums = np.sum(alpha, axis=0)
x_regions = get_regions(col_sums, threshold * alpha.shape[0] * 0.005, min_size=30)
print(f"Detected {len(x_regions)} columns")

char_count = 0
for col_idx, (x_start, x_end) in enumerate(x_regions):
    col_alpha = alpha[:, x_start:x_end]
    row_sums = np.sum(col_alpha, axis=1)
    y_regions = get_regions(row_sums, threshold * col_alpha.shape[1] * 0.005, min_size=40)
    print(f"  Col {col_idx}: {len(y_regions)} rows detected")

    for row_idx, (y_start, y_end) in enumerate(y_regions):
        x1 = max(0, x_start - pad)
        y1 = max(0, y_start - pad)
        x2 = min(w, x_end + pad)
        y2 = min(h, y_end + pad)

        cropped = img[y1:y2, x1:x2]
        if np.sum(cropped[:, :, 3]) < 5000:
            print(f"    Row {row_idx}: mostly empty, skipping")
            continue

        out_path = os.path.join(out_dir, f'char_{char_count}.png')
        cv2.imwrite(out_path, cropped)
        print(f"    char_{char_count}.png  ({cropped.shape[1]}x{cropped.shape[0]}px)")
        char_count += 1

print(f"\nTotal: {char_count} expressions saved.")

import cv2
import os

image_path = r'c:\Projects\myakuarimyakunasiAIkunn\caracter.png'
out_dir = r'c:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\images\char'

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)

if img is None:
    print("Failed to load image.")
    exit(1)

# Divide into 4 columns (1536 / 4 = 384)
h, w = img.shape[:2]
col_w = w // 4

for i in range(4):
    x1 = i * col_w
    x2 = (i + 1) * col_w
    cropped = img[:, x1:x2]
    out_path = os.path.join(out_dir, f'char_{i}.png')
    cv2.imwrite(out_path, cropped)
    print(f"Saved: {out_path} (Size: {cropped.shape[1]}x{cropped.shape[0]})")

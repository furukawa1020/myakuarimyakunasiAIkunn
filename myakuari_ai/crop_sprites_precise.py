import cv2
import numpy as np
import os

image_path = r'c:\Projects\myakuarimyakunasiAIkunn\caracter.png'
out_dir = r'c:\Projects\myakuarimyakunasiAIkunn\myakuari_ai\assets\images\char'

if not os.path.exists(out_dir):
    os.makedirs(out_dir)

# Clear old chars
for f in os.listdir(out_dir):
    os.remove(os.path.join(out_dir, f))

img = cv2.imread(image_path, cv2.IMREAD_UNCHANGED)
if img is None:
    print("Failed to load image.")
    exit(1)

if img.shape[2] == 3:
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    _, alpha = cv2.threshold(gray, 240, 255, cv2.THRESH_BINARY_INV)
    img = cv2.cvtColor(img, cv2.COLOR_BGR2BGRA)
    img[:, :, 3] = alpha
else:
    alpha = img[:, :, 3]

# 1. Project alpha onto X-axis to find character columns
threshold = 100
col_sums = np.sum(alpha, axis=0)
is_char_x = col_sums > threshold

x_regions = []
start = None
for i, val in enumerate(is_char_x):
    if val and start is None:
        start = i
    elif not val and start is not None:
        x_regions.append((start, i))
        start = None
if start is not None:
    x_regions.append((start, len(is_char_x)))

x_regions = [r for r in x_regions if r[1] - r[0] > 50]

char_count = 0
for x_start, x_end in x_regions:
    col_alpha = alpha[:, x_start:x_end]
    row_sums = np.sum(col_alpha, axis=1)
    
    is_char_y = row_sums > threshold
    
    y_regions = []
    y_start_idx = None
    for i, val in enumerate(is_char_y):
        if val and y_start_idx is None:
            y_start_idx = i
        elif not val and y_start_idx is not None:
            y_regions.append((y_start_idx, i))
            y_start_idx = None
    if y_start_idx is not None:
        y_regions.append((y_start_idx, len(is_char_y)))
        
    y_regions = [r for r in y_regions if r[1] - r[0] > 50]
    
    for y_start, y_end in y_regions:
        pad = 5
        x1 = max(0, x_start - pad)
        y1 = max(0, y_start - pad)
        x2 = min(img.shape[1], x_end + pad)
        y2 = min(img.shape[0], y_end + pad)
        
        cropped = img[y1:y2, x1:x2]
        
        # Double check if the cropped image is mostly empty
        if np.sum(cropped[:, :, 3]) < 1000:
            continue
            
        out_path = os.path.join(out_dir, f'char_{char_count}.png')
        cv2.imwrite(out_path, cropped)
        print(f"Saved {out_path} (size: {cropped.shape[1]}x{cropped.shape[0]})")
        char_count += 1

print(f"Detected {char_count} individual expressions in total.")

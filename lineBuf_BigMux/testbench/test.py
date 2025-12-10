#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
HW-Exact single-layer CNN for testbench (matches Conv3x3_RGB888.v & RGB888ToRGB565.v)

- Input : Xilinx COE (480x272, RGB888, 130,560 words)
- Kernel: txt with **exactly 9 numbers** (signed int8). Same 3x3 kernel is applied to R,G,B.
- Ops   : 3x3 cross-correlation, stride=1, **zero padding=1**, integer MAC
          -> **Clipped ReLU** identical to RTL
- Output:
  * --out888 : RGB888 after ReLU, line-per-pixel hex "0xRRGGBB"
  * --out565 : RGB565 (truncate) hex "0xFFFF"
"""

import argparse, re, numpy as np

# ---------------- COE loader ----------------
def parse_coe(path):
    txt = open(path, 'r', encoding='utf-8', errors='ignore').read()
    m = re.search(r'memory_initialization_radix\s*=\s*(\d+)', txt, re.I)
    radix = int(m.group(1)) if m else 16
    m2 = re.search(r'memory_initialization_vector\s*=\s*(.*?);', txt, re.I | re.S)
    data_str = m2.group(1) if m2 else txt
    toks = re.split(r'[,;\s]+', data_str.strip())
    toks = [t for t in toks if t]
    vals = []
    for t in toks:
        t0 = t.lower()
        if radix == 16:
            if t0.startswith('0x'): vals.append(int(t0, 16))
            else:
                t0 = re.sub(r'[^0-9a-f]', '', t0)
                if t0: vals.append(int(t0, 16))
        elif radix == 2:
            t0 = re.sub(r'[^01]', '', t0)
            if t0: vals.append(int(t0, 2))
        elif radix == 10:
            t0 = re.sub(r'[^0-9\-+eE\.]', '', t0)
            if t0: vals.append(int(float(t0)))
        else:
            raise ValueError("Unsupported radix")
    return np.array(vals, dtype=np.uint32)

def unpack_rgb24(words, width=480, height=272, order='RRGGBB'):
    if words.size != width*height:
        raise ValueError(f"COE length {words.size} != {width*height}")
    r = ((words >> 16) & 0xFF).astype(np.uint8)
    g = ((words >> 8)  & 0xFF).astype(np.uint8)
    b = (words & 0xFF).astype(np.uint8)
    if order.upper() in ('BGR','BBGGRR'):
        r, b = b, r
    return np.stack([r,g,b], axis=-1).reshape((height, width, 3))

# ---------------- Kernel loader (exactly 9) ----------------
def load_kernel_3x3(path):
    raw = open(path, 'r', encoding='utf-8').read()
    raw = re.sub(r'//.*', '', raw)
    raw = re.sub(r'#.*',  '', raw)
    nums = [float(x) for x in re.findall(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?', raw)]
    if len(nums) != 9:
        raise ValueError(f"Filter must contain exactly 9 numbers; got {len(nums)}")
    # Convert to signed int8 with saturation (Verilog param is signed [7:0])
    k = np.clip(np.rint(nums), -128, 127).astype(np.int8).reshape(3,3)
    return k

# ---------------- Core ops (HW-identical) ----------------
def zero_pad2d_u8(x2d, pad=1):
    return np.pad(x2d, pad_width=pad, mode='constant', constant_values=0)

def conv3x3_single_channel_u8(x2d_u8, k3x3_i8):
    """
    x2d_u8: HxW uint8
    k3x3_i8: 3x3 int8
    Returns: HxW int32 (raw MAC sum) with zero padding=1, cross-correlation
    """
    H, W = x2d_u8.shape
    x = zero_pad2d_u8(x2d_u8, 1).astype(np.int32)  # promote
    k = k3x3_i8.astype(np.int32)

    # Sliding window 3x3 (stride=1)
    # manual sum is fastest & most explicit for exact matching
    s  = (x[0:H,   0:W  ] * k[0,0] + x[0:H,   1:W+1] * k[0,1] + x[0:H,   2:W+2] * k[0,2] +
          x[1:H+1, 0:W  ] * k[1,0] + x[1:H+1, 1:W+1] * k[1,1] + x[1:H+1, 2:W+2] * k[1,2] +
          x[2:H+2, 0:W  ] * k[2,0] + x[2:H+2, 1:W+1] * k[2,1] + x[2:H+2, 2:W+2] * k[2,2])
    return s.astype(np.int32)

def clipped_relu_0_255(sum_int):
    """
    Replicates RTL:
    (x < 0) ? 0 : (x > 255) ? 255 : x[7:0]
    """
    y = sum_int
    y = np.where(y < 0, 0, y)
    y = np.where(y > 255, 255, y)
    # x in [0,255] -> taking lower 8 bits is identical to value itself
    return y.astype(np.uint8)

def rgb888_to_rgb565_trunc(img888):
    r5 = (img888[...,0].astype(np.uint16) >> 3)
    g6 = (img888[...,1].astype(np.uint16) >> 2)
    b5 = (img888[...,2].astype(np.uint16) >> 3)
    return ((r5 << 11) | (g6 << 5) | b5).astype(np.uint16)

# ---------------- Save helpers ----------------
def save_rgb888_hex(path, img888):
    flat = img888.reshape(-1,3)
    vals = (flat[:,0].astype(np.uint32) << 16) | (flat[:,1].astype(np.uint32) << 8) | flat[:,2].astype(np.uint32)
    with open(path, 'w', encoding='utf-8') as f:
        for v in vals:
            f.write(f"0x{v:06X}\n")

def save_rgb565_hex(path, img565):
    flat = img565.reshape(-1)
    with open(path, 'w', encoding='utf-8') as f:
        for v in flat:
            f.write(f"0x{v:04X}\n")

# ---------------- Main ----------------
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--coe", required=True, help="input COE (480x272, RGB888)")
    ap.add_argument("--filter", required=True, help="kernel txt (exactly 9 numbers, signed int8)")
    ap.add_argument("--out888", default="out_rgb888.txt")
    ap.add_argument("--out565", default="out_rgb565.txt")
    ap.add_argument("--rgb_order", default="RRGGBB", help="RRGGBB or BGR")
    args = ap.parse_args()

    words = parse_coe(args.coe)
    img   = unpack_rgb24(words, width=480, height=272, order=args.rgb_order)  # HxWx3 uint8
    k3x3  = load_kernel_3x3(args.filter)  # int8, shape (3,3)

    # per-channel (same kernel for R,G,B), exactly like RTL
    r_sum = conv3x3_single_channel_u8(img[...,0], k3x3)
    g_sum = conv3x3_single_channel_u8(img[...,1], k3x3)
    b_sum = conv3x3_single_channel_u8(img[...,2], k3x3)

    r_relu = clipped_relu_0_255(r_sum)
    g_relu = clipped_relu_0_255(g_sum)
    b_relu = clipped_relu_0_255(b_sum)

    y888 = np.stack([r_relu, g_relu, b_relu], axis=-1)  # uint8
    save_rgb888_hex(args.out888, y888)

    y565 = rgb888_to_rgb565_trunc(y888)
    save_rgb565_hex(args.out565, y565)

    print("[DONE] RGB888:", args.out888, "RGB565:", args.out565)

if __name__ == "__main__":
    main()

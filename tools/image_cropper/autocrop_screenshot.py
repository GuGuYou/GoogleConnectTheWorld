"""
智能裁剪脚本：自动去除截图边缘的纯黑/暗棕色背景条以及顶部标题文字区域。

输入：任意 PNG 截图（手机/模拟器截屏）。
输出：裁剪后的 PNG 图像，保留原始比例与清晰度。

策略
----
1. 取四角 + 边缘中点像素的中位颜色作为"背景色"；
2. 构造 L1 色距 < tol 的"背景二值图"；
3. 投影到行/列，得到"每行/每列背景率" row_bg / col_bg；
4. 同时识别"长纯色带"（合并相邻 ≤ gap_max 的纯色段）和
   "长彩色内容带"（连续 ≥ min_run 行 row_bg <= low_rate），
   分别作为非内容（黑边/标题/状态栏/底部黑条）和有效内容
   （地图/按钮/图标）的边界；
5. 底部最后一个纯色带如果紧贴底部（与底端相距 ≤ nav_reserve），
   则跳过它（视为 BottomNav，不裁掉）。
6. 最终：
     top    = max(首段内容上沿,   首段长纯色带下沿)
     bottom = min(末段内容下沿,   末段长纯色带上沿)

如果 top > bottom（理论上不会发生），fallback 为 H/2 居中裁切。
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import numpy as np
from PIL import Image


# ---------------------------------------------------------------------------
# 背景色估计
# ---------------------------------------------------------------------------

def estimate_background(arr: np.ndarray) -> np.ndarray:
    """从图像四角 + 边缘中点采样背景色，取中位数（抗离群点）。"""
    h, w, _ = arr.shape
    samples = np.array(
        [
            arr[0, 0], arr[0, w - 1], arr[h - 1, 0], arr[h - 1, w - 1],
            arr[0, w // 2], arr[h - 1, w // 2],
            arr[h // 2, 0], arr[h // 2, w - 1],
        ],
        dtype=np.int32,
    )
    return np.median(samples, axis=0)


def background_mask(arr: np.ndarray, bg: np.ndarray, tol: int) -> np.ndarray:
    """True 表示该像素与背景色 L1 色距 < tol。"""
    diff = np.abs(arr.astype(np.int32) - bg.astype(np.int32))
    return diff.sum(axis=2) < tol


# ---------------------------------------------------------------------------
# 行/列背景率 + 边界定位
# ---------------------------------------------------------------------------

def row_rates(mask: np.ndarray) -> np.ndarray:
    return mask.mean(axis=1)


def col_rates(mask: np.ndarray) -> np.ndarray:
    return mask.mean(axis=0)


def _find_blocks(rates: np.ndarray, predicate) -> list[tuple[int, int]]:
    """返回所有满足 predicate(rate)=True 的连续段 [(start,end_exclusive), ...]"""
    n = rates.shape[0]
    blocks: list[tuple[int, int]] = []
    i = 0
    while i < n:
        if not predicate(rates[i]):
            i += 1
            continue
        j = i
        while j < n and predicate(rates[j]):
            j += 1
        blocks.append((i, j))
        i = j
    return blocks


def _merge_blocks(
    blocks: list[tuple[int, int]], gap_max: int
) -> list[tuple[int, int]]:
    """合并相邻 gap ≤ gap_max 的连续段。"""
    if not blocks:
        return []
    merged = [blocks[0]]
    for s, e in blocks[1:]:
        ps, pe = merged[-1]
        if s - pe <= gap_max:
            merged[-1] = (ps, e)
        else:
            merged.append((s, e))
    return merged


def _first_content(
    rates: np.ndarray, low_rate: float, min_run: int
) -> int:
    """从 0 端出发，找首个"连续 ≥ min_run 行/列 rate <= low_rate"内容块上沿。"""
    for s, e in _find_blocks(rates, lambda r: r <= low_rate):
        if e - s >= min_run:
            return s
    return 0


def _last_content(
    rates: np.ndarray, low_rate: float, min_run: int
) -> int:
    """从末端出发，找最后一个"连续 ≥ min_run 行/列 rate <= low_rate"
    内容块下沿（不含）。"""
    for s, e in reversed(_find_blocks(rates, lambda r: r <= low_rate)):
        if e - s >= min_run:
            return e
    return rates.shape[0]


def _first_solid_band(
    rates: np.ndarray,
    high_rate: float,
    min_run: int,
    gap_max: int = 5,
) -> int:
    """从 0 端起，第一个"合并后总长 ≥ min_run 且每段 rate > high_rate"
    纯色带的下沿。"""
    bands = _merge_blocks(
        _find_blocks(rates, lambda r: r > high_rate), gap_max
    )
    for s, e in bands:
        if e - s >= min_run:
            return e
    return 0


def _last_solid_band(
    rates: np.ndarray,
    high_rate: float,
    min_run: int,
    gap_max: int = 5,
    nav_reserve: int = 0,
) -> int:
    """从末端起，最后一个"合并后总长 ≥ min_run 且每段 rate > high_rate"
    纯色带的上沿。如果该段紧贴底部（与底端相距 ≤ nav_reserve），
    则跳过它（视为 BottomNav，不裁掉）。"""
    n = rates.shape[0]
    bands = _merge_blocks(
        _find_blocks(rates, lambda r: r > high_rate), gap_max
    )
    for s, e in reversed(bands):
        if e - s < min_run:
            continue
        if nav_reserve > 0 and s >= n - nav_reserve:
            continue
        return s
    return n


# ---------------------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------------------

def autocrop(
    img: Image.Image,
    tol: int = 30,
    low_rate: float = 0.10,
    high_rate: float = 0.85,
    min_run: int = 30,
    min_solid_run: int = 16,
    solid_gap_max: int = 5,
    bottom_nav_reserve: int = 80,
) -> Image.Image:
    """自动裁剪掉四周的非内容（黑边、状态栏、顶部文字、底部黑条等）。"""
    arr = np.array(img.convert("RGB"))
    h, w, _ = arr.shape

    bg = estimate_background(arr)
    mask = background_mask(arr, bg, tol)
    row_bg = row_rates(mask)
    col_bg = col_rates(mask)

    # 顶部
    top_content = _first_content(row_bg, low_rate, min_run)
    top_solid = _first_solid_band(
        row_bg, high_rate, min_solid_run, solid_gap_max
    )
    top = max(top_content, top_solid)

    # 底部
    bot_content = _last_content(row_bg, low_rate, min_run)
    bot_solid = _last_solid_band(
        row_bg, high_rate, min_solid_run, solid_gap_max, bottom_nav_reserve
    )
    bottom = min(bot_content, bot_solid)

    # 左右（列向）
    left = _first_content(col_bg, low_rate, min_run)
    right = _last_content(col_bg, low_rate, min_run)

    # 安全兜底
    top = max(0, min(top, h - 64))
    bottom = max(top + 64, min(bottom, h))
    left = max(0, min(left, w - 64))
    right = max(left + 64, min(right, w))

    return img.crop((left, top, right, bottom))


def main() -> int:
    p = argparse.ArgumentParser(description="自动裁剪截图黑边与顶部文字。")
    p.add_argument("input", type=Path, help="输入 PNG 路径")
    p.add_argument("output", type=Path, help="输出 PNG 路径")
    p.add_argument("--tol", type=int, default=30, help="背景色判定容差 L1")
    p.add_argument("--low-rate", type=float, default=0.10,
                   help="行/列背景率上限。低于此值视为内容。")
    p.add_argument("--high-rate", type=float, default=0.85,
                   help="行/列背景率下限。高于此值视为纯色背景。")
    p.add_argument("--min-run", type=int, default=30,
                   help="最少连续内容行/列数（建议 >= 20）")
    p.add_argument("--min-solid-run", type=int, default=16,
                   help="最少连续纯色背景行/列数")
    p.add_argument("--solid-gap-max", type=int, default=5,
                   help="相邻纯色段之间的最大可合并间隙")
    p.add_argument("--bottom-nav-reserve", type=int, default=80,
                   help="底部不裁掉的保留区高度（避免裁掉 BottomNav）")
    args = p.parse_args()

    img = Image.open(args.input)
    out = autocrop(
        img,
        tol=args.tol,
        low_rate=args.low_rate,
        high_rate=args.high_rate,
        min_run=args.min_run,
        min_solid_run=args.min_solid_run,
        solid_gap_max=args.solid_gap_max,
        bottom_nav_reserve=args.bottom_nav_reserve,
    )
    out.save(args.output, "PNG", optimize=True)
    print(
        f"OK: {args.input.name} {img.size} -> {out.size}  saved {args.output}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())

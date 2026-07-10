# Assets / images

`fig_` 前缀的文件提取自 `Ref/Untitled.fig`（202607 视觉重设计），由
`tools/figma_extract/copy_assets.py` 生成（>200KB 的已降采样压缩）；
映射明细见 `tools/figma_extract/out/asset_manifest.json`。

| 文件 | 用途 |
| --- | --- |
| `avatars/fig_avatar_hero.png` | 3D 卡通头像主图（捏脸页预览 / Profile 头像） |
| `avatars/parts/fig_<类别>_NN.png` | 捏脸选择器缩略图；每类 `01`=行首图标，`02-06`=部件缩略图，`07`=自定义/更多图标。类别：face / hair / eyes / mouth / acc / bg |
| `decorations/fig_buzz_orbit.png` | "Buzz around" 轨道 + 定位 pin 插画（地图引导态） |
| `decorations/fig_orbit_rings.png` | 金色轨道环装饰（活动卡片右侧） |
| `decorations/fig_constellation.png` | 金色星座网络装饰（Profile 顶部） |

其余目录为占位；高保真原型主要使用代码绘制的渐变与图标。

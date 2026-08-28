# CardFX Golden Card Shader

Shader：`CardFX/GoldenCard`

这个实现按参考视频的结构组织：一张原画、一张 RGBA 分区遮罩、一张动态扰动图，以及四层可独立变换和混合的效果纹理。

## 使用步骤

1. 创建材质并选择 `CardFX/GoldenCard`。
2. 将材质赋给卡牌原画的 `Image` 或普通 Quad/SpriteRenderer。
3. `Mask` 的 R/G/B/A 通道分别存放不同区域；每个 Effect 的 `Channel` 决定读取哪个区域。
4. 给 Effect 指定黑底粒子、烟雾、流光或渐变纹理，并将纹理 Wrap Mode 设为 `Repeat`。
5. 使用 `PanX/PanY`、`Angle`、`RotV`、`Polar`、`Spiral` 和 `FlashV` 制作运动。
6. HDR 颜色配合 URP Bloom 可得到视频中的高亮发光效果。

## UGUI 与 Sprite Atlas

普通独立 Sprite 可以直接使用 UV0。若卡图被打入 Sprite Atlas：

1. 给同一个 `Image` 添加 `CardFxMeshEffect`。
2. 在材质的 Advanced 分组启用 `Use Local UV1`。

这样原画继续采样图集 UV，而 Mask、扰动图和效果纹理使用卡牌本地 0..1 UV。

## 参数含义

- `DisturbAmpX/Y`：原画 UV 的水平、垂直扰动幅度。
- `Polar`：把笛卡尔 UV 转换成极坐标，用于环形或旋涡效果。
- `RotV`：每秒旋转圈数。
- `Spiral`：角度随半径产生偏移，形成螺旋。
- `FlashV`：亮度脉冲频率；0 表示不闪烁。
- `BlendMode`：Additive、Screen、Multiply、Alpha 四种图层混合方式。
- `Time Offset`：错开不同卡牌动画相位。

效果的最终外观仍取决于原画、RGBA 遮罩、扰动贴图和粒子纹理。参考视频没有提供这些源素材，因此 Shader 的结构与控制方式可以复刻，具体画面需要用对应贴图调制。

from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageEnhance, ImageFilter, ImageOps
import random
import sys

W, H = 1080, 1920
CLEAN_MODE = "--clean" in sys.argv
OUT = Path(__file__).parent / ("BattleUI_CleanMockup_1080x1920.png" if CLEAN_MODE else "BattleUI_ArtMockup_1080x1920.png")
FONT_CN = r"C:\Windows\Fonts\simhei.ttf"
FONT_NUM = r"C:\Users\LQ\.codex\skills\canvas-design\canvas-fonts\BigShoulders-Bold.ttf"

SOURCES = [
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-7da1a32a-e6d7-4581-ad1a-825f5eaae3d7.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-f58b2634-2789-4a0a-92ed-1c26498c81d9.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-5c6fb03f-52d5-4856-8b7f-ad161f9cb770.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-acff4f92-9e23-43b9-a4fe-4eb1f0d62533.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-17663af4-77b3-4fe6-95b6-9519b9cb8fc2.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-27e61ab5-319a-4486-9132-1af11902d6b4.png"),
]


def font(size, number=False):
    return ImageFont.truetype(FONT_NUM if number else FONT_CN, size)


def centered(draw, box, text, fnt, fill, stroke=0, stroke_fill=None):
    x0, y0, x1, y1 = box
    b = draw.textbbox((0, 0), text, font=fnt, stroke_width=stroke)
    tw, th = b[2] - b[0], b[3] - b[1]
    draw.text(((x0 + x1 - tw) / 2, (y0 + y1 - th) / 2 - b[1]), text,
              font=fnt, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)


def add_grain(base, strength=20, opacity=0.18):
    noise = Image.effect_noise(base.size, strength).convert("L")
    noise = ImageOps.colorize(noise, (18, 15, 12), (110, 95, 72)).convert("RGBA")
    noise.putalpha(int(255 * opacity))
    base.alpha_composite(noise)


def panel(canvas, box, fill, border=(83, 73, 58, 255), radius=5, width=2):
    d = ImageDraw.Draw(canvas)
    d.rounded_rectangle(box, radius=radius, fill=fill, outline=border, width=width)
    x0, y0, x1, y1 = box
    d.line((x0 + 10, y0 + 5, x1 - 10, y0 + 5), fill=(150, 120, 70, 90), width=1)


def art_crop(path, size):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    crop = im.crop((max(0, int(w * .05)), int(h * .16), min(w, int(w * .95)), int(h * .79)))
    crop = ImageOps.fit(crop, size, method=Image.Resampling.LANCZOS, centering=(.5, .48))
    crop = ImageEnhance.Color(crop).enhance(.78)
    crop = ImageEnhance.Contrast(crop).enhance(1.08)
    return crop.convert("RGBA")


def segmented_bar(d, box, active, total, color):
    x0, y0, x1, y1 = box
    gap = 3
    cell = (x1 - x0 - gap * (total - 1)) / total
    for i in range(total):
        a = x0 + i * (cell + gap)
        d.rectangle((a, y0, a + cell, y1), fill=color if i < active else (16, 17, 15, 220),
                    outline=(125, 112, 87, 170), width=1)


def render_card(source, power, tag, status, team="enemy", scan=.55, accent=None):
    cw, ch = 288, 184
    card = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    art = art_crop(source, (272, 168))
    card.alpha_composite(art, (8, 8))
    shade = Image.new("RGBA", (272, 168), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for yy in range(168):
        alpha = int(130 * abs(yy - 84) / 84)
        sd.line((0, yy, 272, yy), fill=(0, 0, 0, alpha))
    card.alpha_composite(shade, (8, 8))

    d = ImageDraw.Draw(card)
    if not CLEAN_MODE:
        # CD is an independent runtime shader layer and is intentionally absent from the clean slicing mockup.
        scan_y = 8 + int((1.0 - scan) * 136)
        mask = Image.new("RGBA", (272, max(1, scan_y - 8)), (0, 0, 0, 128))
        card.alpha_composite(mask, (8, 8))
        glow_color = accent or ((212, 79, 62, 255) if team == "enemy" else (64, 220, 222, 255))
        glow = Image.new("RGBA", (272, 32), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        gd.rectangle((0, 14, 272, 18), fill=glow_color)
        glow = glow.filter(ImageFilter.GaussianBlur(6))
        card.alpha_composite(glow, (8, max(0, scan_y - 14)))
        d = ImageDraw.Draw(card)
        d.line((8, scan_y, 280, scan_y), fill=glow_color, width=3)

    # Common frame: every card uses exactly the same 288x184 geometry.
    frame = (104, 63, 47, 255) if team == "enemy" else (47, 91, 96, 255)
    if team == "hero":
        frame = (168, 119, 42, 255)
    d.rounded_rectangle((1, 1, 286, 182), radius=6, outline=(24, 20, 15, 255), width=7)
    d.rounded_rectangle((4, 4, 283, 179), radius=5, outline=frame, width=3)
    d.line((12, 8, 276, 8), fill=(182, 154, 104, 150), width=2)
    for cx, cy, sx, sy in [(6, 6, 1, 1), (282, 6, -1, 1), (6, 178, 1, -1), (282, 178, -1, -1)]:
        d.polygon([(cx, cy), (cx + 18 * sx, cy), (cx + 7 * sx, cy + 7 * sy), (cx, cy + 18 * sy)],
                  fill=(72, 63, 48, 255), outline=(152, 123, 76, 255))

    # Top information zones.
    d.rounded_rectangle((12, 10, 96, 49), radius=5, fill=(5, 7, 7, 205))
    d.ellipse((18, 18, 38, 38), outline=(218, 202, 166, 255), width=2)
    d.line((21, 35, 35, 21), fill=(218, 202, 166, 255), width=2)
    d.text((44, 7), str(power), font=font(38, True), fill=(241, 232, 207, 255),
           stroke_width=1, stroke_fill=(14, 11, 8, 255))
    badge_color = (92, 49, 98, 230) if "召唤" in tag else ((137, 91, 25, 230) if tag in ("防御", "主角") else (31, 82, 79, 230))
    d.polygon([(184, 12), (271, 12), (276, 31), (269, 50), (184, 50), (177, 31)],
              fill=(5, 7, 7, 210), outline=(125, 105, 74, 255))
    d.polygon([(184, 16), (207, 16), (212, 31), (207, 46), (184, 46), (179, 31)],
              fill=badge_color, outline=(190, 162, 110, 255))
    d.text((216, 18), tag, font=font(18), fill=(226, 216, 192, 255))

    # Shared status strip. HP and non-HP cards occupy the same exact box.
    d.rounded_rectangle((10, 145, 278, 176), radius=4, fill=(5, 6, 6, 225), outline=(97, 81, 60, 255), width=2)
    kind = status[0]
    if kind == "hp":
        cur, maximum, color = status[1], status[2], status[3]
        d.ellipse((16, 151, 34, 169), fill=(65, 16, 17, 255), outline=(171, 79, 68, 255))
        d.rectangle((42, 152, 194, 169), fill=(18, 14, 12, 255), outline=(116, 93, 65, 255), width=1)
        fill_w = int(150 * max(0, min(1, cur / maximum)))
        d.rectangle((43, 153, 43 + fill_w, 168), fill=color)
        d.text((205, 146), f"{cur}/{maximum}", font=font(24, True), fill=(244, 235, 210, 255))
    elif kind == "pips":
        active, total, color = status[1], status[2], status[3]
        segmented_bar(d, (18, 152, 215, 169), active, total, color)
        d.text((229, 146), f"{active}/{total}", font=font(24, True), fill=(244, 235, 210, 255))
    elif kind == "charge":
        value, color = status[1], status[2]
        segmented_bar(d, (18, 152, 215, 169), int(round(value / 10)), 10, color)
        d.text((228, 146), f"{value}%", font=font(24, True), fill=(244, 235, 210, 255))
    else:
        d.text((18, 149), "常驻", font=font(20), fill=(220, 205, 170, 255))
        d.line((88, 160, 260, 160), fill=(110, 91, 62, 180), width=2)
    return card


def draw_top(canvas):
    panel(canvas, (0, 0, 1079, 156), (8, 11, 11, 250), (45, 47, 42, 255), 0, 2)
    d = ImageDraw.Draw(canvas)
    avatar = art_crop(SOURCES[5], (112, 112))
    mask = Image.new("L", (112, 112), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 111, 111), radius=8, fill=255)
    canvas.paste(avatar, (28, 22), mask)
    d.rounded_rectangle((25, 19, 143, 137), radius=10, outline=(144, 109, 56, 255), width=4)
    d.text((162, 25), "森境远征", font=font(31), fill=(242, 236, 218, 255))
    d.text((164, 76), "Lv.42", font=font(21, True), fill=(196, 181, 147, 255))
    d.rectangle((244, 83, 467, 98), fill=(23, 22, 18, 255), outline=(84, 73, 53, 255), width=1)
    d.rectangle((245, 84, 392, 97), fill=(180, 142, 62, 255))
    d.text((164, 108), "17620 / 26500", font=font(17, True), fill=(144, 139, 124, 255))
    resources = [("◆", "128", (61, 209, 225, 255)), ("●", "1412", (237, 179, 55, 255)), ("◆", "3690", (212, 72, 120, 255))]
    x = 544
    for sym, value, color in resources:
        d.rounded_rectangle((x, 42, x + 148, 106), radius=8, fill=(14, 17, 16, 255), outline=(61, 58, 49, 255), width=2)
        d.text((x + 14, 52), sym, font=font(22), fill=color)
        d.text((x + 47, 45), value, font=font(34, True), fill=(231, 225, 207, 255))
        x += 160


def draw_middle(canvas):
    d = ImageDraw.Draw(canvas)
    panel(canvas, (40, 858, 690, 1126), (13, 22, 21, 245), (71, 76, 65, 255), 5, 2)
    panel(canvas, (710, 858, 1040, 1126), (16, 22, 20, 248), (88, 72, 53, 255), 5, 2)
    centered(d, (60, 875, 670, 930), "第 1 章 · 关卡 20 / 20", font(36), (239, 232, 213, 255))
    d.line((72, 937, 658, 937), fill=(112, 88, 51, 170), width=2)
    d.text((72, 957), "挂机经验  +18 / 分钟", font=font(24), fill=(65, 213, 208, 255))
    d.text((72, 995), "天气：浓雾", font=font(22), fill=(151, 154, 142, 255))
    d.text((434, 957), "下一次行动", font=font(20), fill=(151, 154, 142, 255))
    d.text((591, 950), "27.1s", font=font(27, True), fill=(231, 178, 69, 255))
    buttons = [(62, "伤害统计"), (260, "×2 倍速"), (458, "世界聊天")]
    for bx, label in buttons:
        d.rounded_rectangle((bx, 1048, bx + 170, 1108), radius=5, fill=(25, 33, 31, 255), outline=(60, 66, 59, 255), width=2)
        centered(d, (bx, 1048, bx + 170, 1108), label, font(22), (226, 221, 205, 255))
    d.text((742, 880), "主线任务", font=font(29), fill=(237, 226, 201, 255))
    d.text((742, 928), "通关 1-25", font=font(25), fill=(221, 215, 197, 255))
    d.text((742, 973), "20 / 25", font=font(22, True), fill=(155, 158, 145, 255))
    d.text((842, 974), "金币 ×320", font=font(20), fill=(181, 164, 124, 255))
    d.rounded_rectangle((750, 1035, 1002, 1096), radius=5, fill=(129, 58, 35, 255), outline=(190, 133, 64, 255), width=2)
    centered(d, (750, 1035, 1002, 1096), "任务详情", font(23), (247, 230, 194, 255))


def draw_nav(canvas):
    d = ImageDraw.Draw(canvas)
    d.rectangle((0, 1744, 1080, 1920), fill=(7, 12, 12, 255), outline=(42, 43, 38, 255), width=2)
    labels = ["抽奖", "卡组", "主城", "探索", "装备", "活动"]
    for i, label in enumerate(labels):
        x0, x1 = i * 180, (i + 1) * 180
        if i == 3:
            d.rectangle((x0 + 6, 1748, x1 - 6, 1918), fill=(74, 56, 23, 255))
            d.line((x0 + 18, 1748, x1 - 18, 1748), fill=(226, 176, 58, 255), width=4)
        col = (236, 184, 54, 255) if i == 3 else (121, 156, 158, 255)
        cx, cy = (x0 + x1) // 2, 1802
        if i == 0:  # diamond/gacha
            d.polygon([(cx, cy - 22), (cx + 22, cy), (cx, cy + 22), (cx - 22, cy)], outline=col)
            d.polygon([(cx, cy - 13), (cx + 13, cy), (cx, cy + 13), (cx - 13, cy)], outline=col)
        elif i == 1:  # stacked cards
            d.rounded_rectangle((cx - 23, cy - 19, cx + 17, cy + 23), radius=3, outline=col, width=2)
            d.rounded_rectangle((cx - 15, cy - 25, cx + 25, cy + 17), radius=3, outline=col, width=2)
            d.line((cx - 5, cy - 11, cx + 15, cy - 11), fill=col, width=2)
        elif i == 2:  # city
            d.polygon([(cx - 27, cy - 5), (cx, cy - 27), (cx + 27, cy - 5)], outline=col)
            d.rectangle((cx - 24, cy - 5, cx + 24, cy + 23), outline=col, width=2)
            d.rectangle((cx - 6, cy + 6, cx + 6, cy + 23), outline=col, width=2)
        elif i == 3:  # exploration star
            d.polygon([(cx, cy - 27), (cx + 8, cy - 8), (cx + 27, cy), (cx + 8, cy + 8),
                       (cx, cy + 27), (cx - 8, cy + 8), (cx - 27, cy), (cx - 8, cy - 8)], outline=col)
            d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=col)
        elif i == 4:  # equipment shield
            d.polygon([(cx, cy - 27), (cx + 24, cy - 16), (cx + 18, cy + 13),
                       (cx, cy + 28), (cx - 18, cy + 13), (cx - 24, cy - 16)], outline=col)
            d.line((cx, cy - 19, cx, cy + 17), fill=col, width=2)
        else:  # activity grid/calendar
            d.rounded_rectangle((cx - 25, cy - 22, cx + 25, cy + 24), radius=4, outline=col, width=2)
            d.line((cx - 25, cy - 8, cx + 25, cy - 8), fill=col, width=2)
            for gx in (cx - 10, cx + 8):
                for gy in (cy + 1, cy + 13):
                    d.rectangle((gx, gy, gx + 5, gy + 5), fill=col)
        centered(d, (x0, 1844, x1, 1898), label, font(24), col)
        if i:
            d.line((x0, 1760, x0, 1904), fill=(26, 33, 32, 255), width=1)


def main():
    canvas = Image.new("RGBA", (W, H), (7, 9, 8, 255))
    # Layered ashen background with restrained texture and vignette.
    grad = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gd = ImageDraw.Draw(grad)
    for y in range(H):
        t = y / H
        gd.line((0, y, W, y), fill=(13 + int(8 * t), 15 + int(7 * t), 13 + int(5 * t), 255))
    canvas.alpha_composite(grad)
    if not CLEAN_MODE:
        add_grain(canvas, 22, .13)
    bgd = ImageDraw.Draw(canvas)
    if CLEAN_MODE:
        bgd.rectangle((72, 230, 1008, 844), fill=(7, 10, 9, 255), outline=(38, 42, 37, 255), width=2)
        bgd.rectangle((72, 1120, 1008, 1732), fill=(7, 10, 9, 255), outline=(38, 42, 37, 255), width=2)
    else:
        random.seed(11)
        for _ in range(36):
            x = random.randint(-100, W + 100)
            y = random.randint(130, 1770)
            r = random.randint(45, 190)
            bgd.ellipse((x-r, y-r, x+r, y+r), outline=(48, 43, 34, random.randint(18, 42)), width=2)

    draw_top(canvas)

    enemy_defs = [
        (0, 68, "召唤", ("hp", 550, 800, (122, 65, 155, 255)), .22),
        (1, 36, "防御", ("hp", 120, 180, (176, 137, 62, 255)), .38),
        (2, 48, "剑系", ("hp", 360, 540, (156, 54, 50, 255)), .52),
        (3, 95, "雷电", ("hp", 490, 720, (51, 154, 170, 255)), .67),
        (4, 72, "枪械", ("hp", 310, 610, (155, 70, 42, 255)), .76),
        (5, 84, "剑士", ("hp", 820, 950, (160, 55, 48, 255)), .34),
        (1, 44, "防御", ("hp", 430, 680, (176, 137, 62, 255)), .58),
        (0, 61, "召唤", ("hp", 470, 760, (122, 65, 155, 255)), .83),
        (2, 57, "剑系", ("hp", 390, 590, (156, 54, 50, 255)), .47),
    ]
    player_defs = [
        (3, 95, "雷电", ("charge", 72, (59, 154, 171, 255)), "player", .81),
        (1, 36, "召唤", ("hp", 880, 1100, (57, 166, 145, 255)), "player", .61),
        (0, 68, "符文", ("pips", 5, 8, (111, 78, 157, 255)), "player", .42),
        (3, 82, "时序", ("charge", 48, (58, 143, 164, 255)), "player", .49),
        (2, 48, "剑系", ("pips", 7, 10, (116, 72, 160, 255)), "player", .72),
        (4, 72, "枪械", ("pips", 4, 6, (178, 115, 49, 255)), "player", .36),
        (0, 64, "召唤", ("hp", 610, 780, (57, 166, 145, 255)), "player", .56),
        (5, 88, "主角", ("hp", 820, 950, (153, 53, 47, 255)), "hero", .77),
        (0, 59, "召唤", ("hp", 520, 690, (57, 166, 145, 255)), "player", .28),
    ]

    xs = [92, 396, 700]
    enemy_ys = [250, 450, 650]
    player_ys = [1140, 1340, 1540]
    for idx, data in enumerate(enemy_defs):
        src, pwr, tag, status, scan = data
        card = render_card(SOURCES[src], pwr, tag, status, "enemy", scan)
        canvas.alpha_composite(card, (xs[idx % 3], enemy_ys[idx // 3]))
    draw_middle(canvas)
    for idx, data in enumerate(player_defs):
        src, pwr, tag, status, team, scan = data
        card = render_card(SOURCES[src], pwr, tag, status, team, scan)
        canvas.alpha_composite(card, (xs[idx % 3], player_ys[idx // 3]))
    draw_nav(canvas)

    if not CLEAN_MODE:
        # Final vignette belongs to the atmospheric preview, not to cuttable UI sources.
        vignette = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        vd = ImageDraw.Draw(vignette)
        for i in range(44):
            a = int(2.2 * i)
            vd.rectangle((i, i, W-1-i, H-1-i), outline=(0, 0, 0, a), width=1)
        canvas.alpha_composite(vignette)
    canvas.convert("RGB").save(OUT, quality=96)
    print(OUT)


if __name__ == "__main__":
    main()

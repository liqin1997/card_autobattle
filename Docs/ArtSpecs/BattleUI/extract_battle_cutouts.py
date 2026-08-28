from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageFont
import sys

ROOT = Path(__file__).parents[3]
OUT = ROOT / "Assets" / "Art" / "BattleUI" / "Cutouts"
PREVIEW = ROOT / "Assets" / "Art" / "BattleUI" / "Preview" / "BattleUI_Cutouts_ContactSheet.png"
FONT = r"C:\Windows\Fonts\simhei.ttf"
SOURCES = [
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-7da1a32a-e6d7-4581-ad1a-825f5eaae3d7.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-f58b2634-2789-4a0a-92ed-1c26498c81d9.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-5c6fb03f-52d5-4856-8b7f-ad161f9cb770.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-acff4f92-9e23-43b9-a4fe-4eb1f0d62533.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-17663af4-77b3-4fe6-95b6-9519b9cb8fc2.png"),
    Path(r"C:\Users\LQ\AppData\Local\Temp\codex-clipboard-27e61ab5-319a-4486-9132-1af11902d6b4.png"),
]
NAMES = ["summon_skull", "defense_shield", "sword_relic", "thunder_cannon", "gun_rifle", "hero_swordsman"]


def art_crop(path, size=(544, 336)):
    im = Image.open(path).convert("RGB")
    w, h = im.size
    # Remove the supplied card's old frame and status strip, retaining only the illustration.
    crop = im.crop((max(0, int(w * .05)), int(h * .24), min(w, int(w * .95)), int(h * .80)))
    return ImageOps.fit(crop, size, method=Image.Resampling.LANCZOS, centering=(.5, .48)).convert("RGBA")


def frame_layer():
    im = Image.new("RGBA", (576, 368), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((2, 2, 573, 365), radius=12, outline=(24, 20, 15, 255), width=14)
    d.rounded_rectangle((8, 8, 567, 359), radius=10, outline=(104, 73, 47, 255), width=7)
    d.rounded_rectangle((15, 15, 560, 352), radius=8, outline=(178, 147, 96, 210), width=3)
    d.line((25, 17, 551, 17), fill=(222, 195, 141, 170), width=3)
    for cx, cy, sx, sy in [(9, 9, 1, 1), (567, 9, -1, 1), (9, 359, 1, -1), (567, 359, -1, -1)]:
        d.polygon([(cx, cy), (cx + 36 * sx, cy), (cx + 14 * sx, cy + 14 * sy), (cx, cy + 36 * sy)],
                  fill=(72, 63, 48, 255), outline=(178, 147, 96, 230))
    # Keep the content window transparent for independent art placement.
    return im


def rounded_layer(size, fill, outline, radius=10, width=4):
    im = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((width // 2, width // 2, size[0] - width // 2 - 1, size[1] - width // 2 - 1),
                        radius=radius, fill=fill, outline=outline, width=width)
    return im


def tag_layer():
    im = Image.new("RGBA", (196, 76), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.polygon([(14, 4), (184, 4), (194, 38), (184, 72), (14, 72), (3, 38)],
              fill=(7, 9, 8, 238), outline=(178, 147, 96, 255))
    d.polygon([(14, 10), (58, 10), (68, 38), (58, 66), (14, 66), (6, 38)],
              fill=(72, 48, 93, 255), outline=(219, 192, 139, 255))
    return im


def status_base():
    im = Image.new("RGBA", (520, 62), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((2, 2, 517, 59), radius=8, fill=(5, 6, 6, 230), outline=(116, 93, 65, 255), width=3)
    return im


def status_fill(color):
    im = Image.new("RGBA", (300, 34), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rectangle((1, 1, 298, 32), fill=color, outline=(236, 216, 165, 180), width=2)
    return im


def make_contact_sheet(art_layers):
    sheet = Image.new("RGBA", (1200, 950), (13, 15, 13, 255))
    d = ImageDraw.Draw(sheet)
    title_font = ImageFont.truetype(FONT, 30)
    d.text((32, 22), "BATTLE CARD CUTOUTS · MASTER 2X", font=title_font, fill=(237, 225, 198, 255))
    for i, (name, art) in enumerate(art_layers):
        x = 32 + (i % 3) * 390
        y = 86 + (i // 3) * 245
        preview = art.resize((272, 168), Image.Resampling.LANCZOS)
        sheet.alpha_composite(preview, (x, y))
        sheet.alpha_composite(frame_layer().resize((288, 184), Image.Resampling.LANCZOS), (x - 8, y - 8))
        d.text((x, y + 180), name, font=title_font, fill=(185, 175, 153, 255))
    sheet.alpha_composite(tag_layer().resize((196, 76), Image.Resampling.LANCZOS), (850, 595))
    sheet.alpha_composite(status_base().resize((520, 62), Image.Resampling.LANCZOS), (620, 760))
    sheet.convert("RGB").save(PREVIEW, quality=95)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    arts = []
    for src, name in zip(SOURCES, NAMES):
        art = art_crop(src)
        path = OUT / f"battle_card_art_{name}_544x336.png"
        art.save(path)
        arts.append((name, art))
    frame_layer().save(OUT / "battle_card_frame_common_576x368.png")
    tag_layer().save(OUT / "battle_card_tag_badge_196x76.png")
    status_base().save(OUT / "battle_card_status_base_520x62.png")
    status_fill((58, 166, 145, 255)).save(OUT / "battle_card_status_hp_fill_300x34.png")
    status_fill((122, 65, 155, 255)).save(OUT / "battle_card_status_charge_fill_300x34.png")
    make_contact_sheet(arts)
    print(f"Wrote {len(arts) + 5} cutout assets and contact sheet")


if __name__ == "__main__":
    main()

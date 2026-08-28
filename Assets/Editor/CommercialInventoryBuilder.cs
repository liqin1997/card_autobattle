using System;
using System.IO;
using System.Linq;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.U2D;

namespace CardAutobattle.EditorTools
{
    public static class CommercialInventoryBuilder
    {
        private const string ArtFolder = "Assets/Resources/Commercial/Inventory/Art";
        private const string Prefabs = "Assets/Resources/Commercial/Prefabs";
        private const string Source = "C:/Users/LQ/Documents/Codex/2026-07-29/c-unityproject-lyzwlkjvip/outputs/feilong/Assets/Sprites/MetaUI/";
        private static Font font;
        private static readonly Color Ink = new(.035f, .065f, .105f), Panel = new(.065f, .12f, .19f), Muted = new(.61f, .75f, .86f), Gold = new(1, .79f, .35f);
        [MenuItem("Tools/Card Autobattle/Install Backpack System")]
        public static void InstallIntoScene()
        {
            if (Application.isPlaying) throw new InvalidOperationException("Exit Play Mode first.");
            var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
            if (scene.path != "Assets/Scenes/CommercialVerticalSlice.unity") throw new InvalidOperationException("Open CommercialVerticalSlice first.");
            var root = GameObject.Find("CommercialGameRoot"); if (!root) throw new InvalidOperationException("Commercial root missing.");
            ImportArt(); Install(root); SavePrefabs(root);
            EditorSceneManager.MarkSceneDirty(scene); EditorSceneManager.SaveScene(scene); AssetDatabase.SaveAssets();
        }
        public static void ImportArt()
        {
            var files = new[] { "Backpack/Pack/set_button_backpack.png", "Shop/Pack/icon_box.png", "task/Pack/Icon_chest01.png", "task/Pack/Icon_chest02.png",
                "Icon/Weapon_material/material_01.png", "Icon/Weapon_material/material_02.png", "Icon/Weapon_material/material_03.png", "Icon/Weapon_material/material_04.png",
                "Icon/Weapon_material/material_05.png", "Icon/Weapon_material/weapon_refine.png", "Icon/Weapon_material/weapon_coin.png", "Icon/Weapon_material/icon_decomposition.png",
                "Icon/RegionShop/icon_book.png", "Icon/RegionShop/icon_bamboo.png", "Icon/RegionShop/icon_rock.png", "Icon/RegionShop/icon_ice.png", "Icon/Plotprop/Scales.png" };
            var jobs = files.Select(f => (Source: Path.GetFullPath(Source + f), Target: ArtFolder + "/" + Path.GetFileName(f))).ToArray();
            var expected = Path.GetFullPath(ArtFolder) + Path.DirectorySeparatorChar;
            foreach (var j in jobs)
                if (!File.Exists(j.Source) || !Path.GetFullPath(j.Target).StartsWith(expected, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Invalid asset import: " + j.Source);
            Folder(ArtFolder);
            foreach (var j in jobs)
            {
                if (!File.Exists(j.Target)) File.Copy(j.Source, j.Target, false);
                AssetDatabase.ImportAsset(j.Target, ImportAssetOptions.ForceSynchronousImport);
                var t = (TextureImporter)AssetImporter.GetAtPath(j.Target);
                t.textureType = TextureImporterType.Sprite; t.spriteImportMode = SpriteImportMode.Single; t.spritePixelsPerUnit = 100;
                t.mipmapEnabled = false; t.isReadable = false; t.alphaIsTransparency = true; t.wrapMode = TextureWrapMode.Clamp;
                t.filterMode = FilterMode.Bilinear; t.npotScale = TextureImporterNPOTScale.None; t.maxTextureSize = 256; t.textureCompression = TextureImporterCompression.CompressedHQ;
                t.SaveAndReimport();
            }
            var path = "Assets/Resources/Commercial/Inventory/InventoryUI.spriteatlas";
            var atlas = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(path);
            if (!atlas)
            {
                atlas = new SpriteAtlas(); AssetDatabase.CreateAsset(atlas, path);
                atlas.SetPackingSettings(new SpriteAtlasPackingSettings { enableRotation = false, enableTightPacking = false, padding = 4, blockOffset = 1 });
                atlas.SetTextureSettings(new SpriteAtlasTextureSettings { readable = false, generateMipMaps = false, filterMode = FilterMode.Bilinear, sRGB = true });
                atlas.SetIncludeInBuild(true);
            }
            atlas.Remove(atlas.GetPackables());
            atlas.Add(jobs.Select(j => AssetDatabase.LoadAssetAtPath<Texture2D>(j.Target)).ToArray()); EditorUtility.SetDirty(atlas);
        }
        public static void Install(GameObject root)
        {
            if (root.GetComponent<CommercialInventoryView>()) return;
            if (!Art("icon_box")) ImportArt();
            var page = root.GetComponentsInChildren<RectTransform>(true).First(x => x.name == "Page_Gacha" || x.name == "Page_Backpack");
            page.name = "Page_Backpack";
            var popup = root.GetComponentsInChildren<RectTransform>(true).First(x => x.name == "PopupCanvas");
            font = root.GetComponentsInChildren<Text>(true).First().font;
            var children = page.Cast<Transform>().ToArray();
            var legacy = Rect(page, "LegacyGachaLayout", 0, 0, 1080, 1586);
            foreach (var child in children) Undo.SetTransformParent(child, legacy, "Preserve old page layout"); legacy.gameObject.SetActive(false);
            var view = Undo.AddComponent<CommercialInventoryView>(root); view.PageBounds = page;
            var ui = Rect(page, "BackpackPageContent", 0, 0, 1080, 1586); Center(ui); view.RootUI = ui;
            ui.gameObject.AddComponent<Canvas>(); ui.gameObject.AddComponent<GraphicRaycaster>(); Surface(ui, Ink);
            var bg = Picture(ui, "BAG_Background", EquipmentArt("bg_interface"), 0, 0, 1080, 1586); bg.color = new Color(.32f, .41f, .51f); bg.preserveAspect = false;
            Label(ui, "BAG_Title", "背 包", 42, Color.white, 28, 14, 260, 62);
            Label(ui, "BAG_Count", "自动分类入库", 28, Gold, 350, 18, 698, 54, TextAnchor.MiddleRight);
            var tabs = Rect(ui, "BAG_TabsViewport", 24, 98, 1032, 74); Surface(tabs, Ink); tabs.gameObject.AddComponent<RectMask2D>();
            var content = Rect(tabs, "BAG_TabsContent", 0, 0, 1032, 74); view.TabContent = content;
            var scroll = tabs.gameObject.AddComponent<ScrollRect>(); scroll.content = content; scroll.viewport = tabs; scroll.horizontal = true; scroll.vertical = false; scroll.movementType = ScrollRect.MovementType.Clamped; scroll.scrollSensitivity = 35;
            var template = Button(content, "BAG_TabTemplate", "仓库", 0, 0, 248, 74, 31); template.gameObject.SetActive(false); view.TabTemplate = template;
            Label(ui, "BAG_Description", "物品自动分类入库", 27, Muted, 32, 186, 1016, 48);
            var searchRect = Rect(ui, "BAG_Search", 24, 252, 506, 60); Surface(searchRect, Ink).raycastTarget = true;
            view.Search = searchRect.gameObject.AddComponent<InputField>(); view.Search.characterLimit = 40;
            var inputText = Label(searchRect, "BAG_SearchText", "", 29, Color.white, 18, 0, 470, 60); inputText.supportRichText = false;
            var placeholder = Label(searchRect, "BAG_SearchPlaceholder", "搜索名称", 28, Muted, 18, 0, 470, 60); placeholder.fontStyle = FontStyle.Italic;
            view.Search.textComponent = inputText; view.Search.placeholder = placeholder; view.Search.targetGraphic = searchRect.GetComponent<Image>();
            Button(ui, "BAG_Filter", "全部类型 ↻", 550, 252, 238, 60, 27);
            Button(ui, "BAG_Sort", "最近获得 ↻", 808, 252, 248, 60, 27);
            var bag = Rect(ui, "BAG_GridPanel", 24, 332, 1032, 1076); Surface(bag, new Color(.04f, .075f, .12f));
            bag.gameObject.AddComponent<Canvas>(); bag.gameObject.AddComponent<GraphicRaycaster>();
            view.Cells = new CommercialEquipmentCell[20];
            for (var i = 0; i < 20; i++) view.Cells[i] = Cell(bag, "BAG_Item_" + i.ToString("00"), 18 + i % 5 * 202, 18 + i / 5 * 246);
            Label(bag, "BAG_Empty", "仓库暂时为空\n探索掉落或任务奖励会自动存入这里", 32, Muted, 76, 390, 880, 170, TextAnchor.MiddleCenter);
            Button(bag, "BAG_Previous", "上一页", 18, 1008, 172, 54, 27);
            Label(bag, "BAG_Page", "1 / 1", 28, Color.white, 202, 1008, 192, 54, TextAnchor.MiddleCenter);
            Button(bag, "BAG_Next", "下一页", 408, 1008, 172, 54, 27);
            Button(bag, "BAG_OpenEquipment", "装备养成", 640, 1008, 172, 54, 27);
            Button(bag, "BAG_OpenMap", "前往探索", 836, 1008, 178, 54, 27);
            var recent = Rect(ui, "BAG_RecentPanel", 24, 1426, 1032, 142); Surface(recent, Panel);
            Label(recent, "BAG_RecentLabel", "最近入库", 26, Gold, 18, 8, 160, 36);
            Label(recent, "BAG_Recent", "探索战利品与任务奖励将在这里显示。", 25, Muted, 18, 48, 996, 88, TextAnchor.UpperLeft);

            var modalRoot = Rect(popup, "InventoryModalLayer", 0, 0, 1080, 1920); Stretch(modalRoot); view.ModalRoot = modalRoot;
            var overlay = Rect(modalRoot, "BAG_ItemModal", 0, 0, 1080, 1920); Stretch(overlay); Surface(overlay, new Color(0, 0, 0, .78f)).raycastTarget = true;
            overlay.gameObject.AddComponent<CanvasGroup>();
            var p = Rect(overlay, "Panel", 0, 0, 960, 1280); Center(p); Surface(p, Ink).raycastTarget = true;
            Label(p, "BAG_DetailHeading", "物品详情", 32, Muted, 36, 24, 650, 54); Button(p, "BAG_Close", "×", 846, 22, 78, 60, 36);
            Picture(p, "BAG_DetailIcon", Art("icon_box"), 38, 112, 158, 164);
            Label(p, "BAG_DetailName", "物品名称", 38, Gold, 224, 120, 686, 62);
            Label(p, "BAG_DetailMeta", "持有数量", 29, Muted, 224, 200, 686, 62);
            Label(p, "BAG_DetailBody", "物品说明", 30, Color.white, 42, 322, 876, 274, TextAnchor.UpperLeft);
            var rewards = Rect(p, "BAG_Rewards", 36, 612, 888, 310); Surface(rewards, Panel);
            Label(rewards, "BAG_RewardTitle", "本次使用可获得", 29, Gold, 24, 14, 840, 48);
            Label(rewards, "BAG_RewardPreview", "奖励预览", 28, Color.white, 24, 80, 840, 214, TextAnchor.UpperLeft);
            var qty = Rect(p, "BAG_Quantity", 36, 960, 888, 82);
            Label(qty, "BAG_QuantityLabel", "使用数量", 29, Muted, 10, 0, 232, 76);
            Button(qty, "BAG_Minus", "−", 270, 0, 88, 76, 36);
            Label(qty, "BAG_QuantityValue", "1", 34, Color.white, 380, 0, 148, 76, TextAnchor.MiddleCenter);
            Button(qty, "BAG_Plus", "+", 550, 0, 88, 76, 36); Button(qty, "BAG_Max", "最大", 688, 0, 190, 76, 30);
            Button(p, "BAG_Source", "查看地图来源", 36, 1106, 420, 84, 30);
            var use = Button(p, "BAG_Use", "开启 1 个", 504, 1106, 420, 84, 32); use.image.color = new Color(.18f, .49f, .71f);
            Label(p, "BAG_DetailFootnote", "奖励自动分类入库 · 换装与升级属性下一场战斗生效", 24, Muted, 36, 1212, 888, 40, TextAnchor.MiddleCenter);
            overlay.gameObject.SetActive(false);
            var toast = Rect(modalRoot, "BAG_Toast", 0, 0, 980, 126); toast.anchorMin = toast.anchorMax = toast.pivot = new Vector2(.5f, 1); toast.anchoredPosition = new Vector2(0, -174);
            Surface(toast, new Color(.03f, .10f, .16f, .98f)); var group = toast.gameObject.AddComponent<CanvasGroup>(); group.alpha = 0; group.blocksRaycasts = false;
            Label(toast, "BAG_ToastText", "", 27, Color.white, 20, 12, 940, 102, TextAnchor.MiddleCenter);
            var nav = CommercialPrototypeController.FindDeep(root.transform, "Nav_0");
            foreach (var text in nav.GetComponentsInChildren<Text>(true)) if (text.text == "抽奖") text.text = "背包";
            var oldIcon = nav.Find("Icon") as RectTransform;
            if (oldIcon) { var icon = Picture(nav, "BackpackIcon", Art("set_button_backpack"), 0, 0, 56, 56); icon.rectTransform.anchorMin = icon.rectTransform.anchorMax = new Vector2(.5f, 1); icon.rectTransform.pivot = new Vector2(.5f, .5f); icon.rectTransform.anchoredPosition = new Vector2(0, -60); oldIcon.gameObject.SetActive(false); }
            EditorUtility.SetDirty(view);
        }
        private static CommercialEquipmentCell Cell(Transform parent, string name, float x, float y)
        {
            var r = Rect(parent, name, x, y, 188, 226); var rim = Surface(r, Color.white); rim.sprite = EquipmentArt("tab_equip_01"); rim.type = Image.Type.Sliced; rim.raycastTarget = true;
            var button = r.gameObject.AddComponent<Button>(); button.targetGraphic = rim;
            var backing = Surface(Rect(r, name + "_Backing", 3, 3, 182, 220), Color.white); backing.sprite = EquipmentArt("bg_equip_level"); backing.type = Image.Type.Sliced;
            var cell = r.gameObject.AddComponent<CommercialEquipmentCell>(); cell.Rim = rim; cell.Button = button;
            cell.Icon = Picture(r, name + "_Icon", Art("icon_box"), 23, 12, 142, 134);
            cell.Caption = Label(r, name + "_Caption", "物品", 24, Color.white, 6, 156, 176, 34, TextAnchor.MiddleCenter);
            cell.Meta = Label(r, name + "_Meta", "材料", 22, Muted, 6, 193, 176, 30, TextAnchor.MiddleCenter);
            cell.Badge = Label(r, name + "_Badge", "", 25, Gold, 7, 121, 174, 33, TextAnchor.MiddleRight);
            cell.RarityOutline = r.gameObject.AddComponent<Outline>(); cell.RarityOutline.effectDistance = new Vector2(2, -2);
            return cell;
        }
        private static RectTransform Rect(Transform parent, string name, float x, float y, float w, float h)
        { var r = new GameObject(name, typeof(RectTransform)).GetComponent<RectTransform>(); r.SetParent(parent, false); r.anchorMin = r.anchorMax = r.pivot = new Vector2(0, 1); r.sizeDelta = new Vector2(w, h); r.anchoredPosition = new Vector2(x, -y); return r; }
        private static void Center(RectTransform r) { r.anchorMin = r.anchorMax = r.pivot = new Vector2(.5f, .5f); r.anchoredPosition = Vector2.zero; }
        private static void Stretch(RectTransform r) { r.anchorMin = Vector2.zero; r.anchorMax = Vector2.one; r.offsetMin = r.offsetMax = Vector2.zero; }
        private static Image Surface(RectTransform r, Color c) { var image = r.gameObject.AddComponent<Image>(); image.color = c; image.raycastTarget = false; return image; }
        private static Image Picture(Transform p, string n, Sprite sprite, float x, float y, float w, float h)
        { var image = Surface(Rect(p, n, x, y, w, h), Color.white); image.sprite = sprite; image.preserveAspect = true; return image; }
        private static Text Label(Transform p, string n, string value, int size, Color color, float x, float y, float w, float h, TextAnchor align = TextAnchor.MiddleLeft)
        { var t = Rect(p, n, x, y, w, h).gameObject.AddComponent<Text>(); t.font = font; t.fontSize = size; t.text = value; t.color = color; t.alignment = align; t.raycastTarget = false; t.horizontalOverflow = HorizontalWrapMode.Wrap; t.verticalOverflow = VerticalWrapMode.Truncate; return t; }
        private static Button Button(Transform p, string n, string value, float x, float y, float w, float h, int size)
        { var r = Rect(p, n, x, y, w, h); var image = Surface(r, new Color(.11f, .23f, .35f)); image.sprite = EquipmentArt("tab_equip_01"); image.type = Image.Type.Sliced; image.raycastTarget = true; var b = r.gameObject.AddComponent<Button>(); b.targetGraphic = image; Label(r, n + "_Label", value, size, Color.white, 8, 0, w - 16, h, TextAnchor.MiddleCenter); return b; }
        private static Sprite EquipmentArt(string name) => AssetDatabase.LoadAssetAtPath<Sprite>(CommercialEquipmentBuilder.ArtFolder + "/" + name + ".png");
        private static Sprite Art(string name) => AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/" + name + ".png");
        private static void Folder(string path) { if (AssetDatabase.IsValidFolder(path)) return; var parent = Path.GetDirectoryName(path).Replace('\\', '/'); Folder(parent); AssetDatabase.CreateFolder(parent, Path.GetFileName(path)); }
        public static void SavePrefabs(GameObject root)
        {
            var view = root.GetComponent<CommercialInventoryView>(); if (!view) return;
            PrefabUtility.SaveAsPrefabAsset(view.PageBounds.gameObject, Prefabs + "/PF_Screen_Backpack.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.Cells[0].gameObject, Prefabs + "/PF_UI_InventoryItem.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.ModalRoot.Find("BAG_ItemModal").gameObject, Prefabs + "/PF_Popup_InventoryItem.prefab");
            var nav = CommercialPrototypeController.FindDeep(root.transform, "Nav_0");
            PrefabUtility.SaveAsPrefabAsset(nav.parent.gameObject, Prefabs + "/PF_UI_BottomNavigation.prefab");
            PrefabUtility.SaveAsPrefabAsset(root, Prefabs + "/PF_CommercialGameRoot.prefab");
        }
    }
}

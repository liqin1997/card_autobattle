using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.U2D;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.U2D;

namespace CardAutobattle.EditorTools
{
    public static class CommercialEquipmentBuilder
    {
        public const string ArtFolder = "Assets/Resources/Commercial/Equipment/Art";
        public const string FeilongArtFolder = "Assets/Resources/Commercial/FeilongUI/Equipment";
        private const string Prefabs = "Assets/Resources/Commercial/Prefabs";
        private const string ReferenceProject = "C:/Users/LQ/Documents/Codex/2026-07-29/c-unityproject-lyzwlkjvip/outputs/feilong";
        private static Font font;
        private static readonly Color Ink = new(.036f, .066f, .11f, 1);
        private static readonly Color PanelColor = new(.065f, .12f, .19f, 1);
        private static readonly Color ButtonColor = new(.11f, .23f, .35f, 1);
        private static readonly Color Blue = new(.18f, .49f, .71f, 1);
        private static readonly Color Muted = new(.60f, .74f, .85f, 1);
        private static readonly Color Gold = new(1f, .79f, .35f, 1);

        [MenuItem("Tools/Card Autobattle/Install Equipment System")]
        public static void InstallIntoScene()
        {
            if (Application.isPlaying) throw new InvalidOperationException("Exit Play Mode first.");
            var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
            if (scene.path != "Assets/Scenes/CommercialVerticalSlice.unity") throw new InvalidOperationException("Open CommercialVerticalSlice first.");
            ImportReferenceArt();
            var root = GameObject.Find("CommercialGameRoot"); if (!root) throw new InvalidOperationException("Commercial root missing.");
            Install(root); SavePrefabs(root);
            EditorSceneManager.MarkSceneDirty(scene); EditorSceneManager.SaveScene(scene); AssetDatabase.SaveAssets();
        }

        public static string ImportReferenceArt()
        {
            var source = Path.GetFullPath(ReferenceProject);
            if (!Directory.Exists(source)) throw new DirectoryNotFoundException(source);
            EnsureFolder(ArtFolder);
            var jobs = new List<(string Source, string Destination)>();
            foreach (var tier in new[] { 1, 2, 4, 6 })
            {
                foreach (var part in new[] { 1, 2, 3, 4, 6 }) Add($"Icon/weapon/equip_{tier}000{part}.png");
                foreach (var weapon in new[] { "sword", "crossbow", "rod" }) Add($"Icon/weapon/icon_{weapon}_{tier:00}.png");
            }
            foreach (var name in new[] { "bg_equip_level", "bg_quality_icon", "bg_icon_helmet", "bg_icon_gloves", "bg_icon_clothes", "bg_icon_trousers", "bg_icon_shoes", "bg_icon_weapons", "tab_equip_01", "tab_equip_02", "btn_locked", "btn_unlock", "btn_enchant", "btn_resolve", "btn_scheme", "icon_forge", "icon_level", "icon_ore03", "icon_randomization" })
                Add("Equip/Pack/" + name + ".png");
            Add("Equip/NotPack/bg_interface.png");
            // Check every source and exact destination before copying. Never copy source meta GUIDs.
            var targetRoot = Path.GetFullPath(ArtFolder) + Path.DirectorySeparatorChar;
            foreach (var job in jobs)
            {
                if (!File.Exists(job.Source)) throw new FileNotFoundException(job.Source);
                if (!Path.GetFullPath(job.Destination).StartsWith(targetRoot, StringComparison.OrdinalIgnoreCase)) throw new InvalidOperationException("Import path outside equipment Art folder.");
            }
            AssetDatabase.StartAssetEditing();
            try
            {
                foreach (var job in jobs)
                {
                    if (!File.Exists(job.Destination)) File.Copy(job.Source, job.Destination, false);
                    AssetDatabase.ImportAsset(job.Destination, ImportAssetOptions.ForceSynchronousImport);
                }
            }
            finally { AssetDatabase.StopAssetEditing(); }
            foreach (var job in jobs)
            {
                var importer = AssetImporter.GetAtPath(job.Destination) as TextureImporter;
                if (!importer) continue;
                importer.textureType = TextureImporterType.Sprite; importer.spriteImportMode = SpriteImportMode.Single;
                importer.spritePixelsPerUnit = 100; importer.mipmapEnabled = false; importer.isReadable = false;
                importer.alphaIsTransparency = true; importer.wrapMode = TextureWrapMode.Clamp;
                importer.filterMode = FilterMode.Bilinear; importer.npotScale = TextureImporterNPOTScale.None;
                importer.maxTextureSize = job.Destination.EndsWith("bg_interface.png") ? 1024 : 512;
                importer.textureCompression = TextureImporterCompression.CompressedHQ;
                var meta = job.Source + ".meta";
                if (File.Exists(meta))
                {
                    var match = Regex.Match(File.ReadAllText(meta), @"spriteBorder: \{x: ([\d.]+), y: ([\d.]+), z: ([\d.]+), w: ([\d.]+)\}");
                    if (match.Success) importer.spriteBorder = new Vector4(Parse(1), Parse(2), Parse(3), Parse(4));
                    float Parse(int n) => float.Parse(match.Groups[n].Value, System.Globalization.CultureInfo.InvariantCulture);
                }
                importer.SaveAndReimport();
            }
            var atlasPath = "Assets/Resources/Commercial/Equipment/EquipmentUI.spriteatlas";
            var atlas = AssetDatabase.LoadAssetAtPath<SpriteAtlas>(atlasPath);
            if (!atlas)
            {
                atlas = new SpriteAtlas(); AssetDatabase.CreateAsset(atlas, atlasPath);
                atlas.SetPackingSettings(new SpriteAtlasPackingSettings { blockOffset = 1, enableRotation = false, enableTightPacking = false, padding = 4 });
                atlas.SetTextureSettings(new SpriteAtlasTextureSettings { readable = false, generateMipMaps = false, filterMode = FilterMode.Bilinear, sRGB = true });
                atlas.Add(jobs.Where(j => !j.Destination.EndsWith("bg_interface.png")).Select(j => AssetDatabase.LoadAssetAtPath<Texture2D>(j.Destination)).ToArray());
                atlas.SetIncludeInBuild(true);
            }
            AssetDatabase.SaveAssets();
            return $"Imported {jobs.Count} referenced PNGs with new GUIDs. Source project unchanged.";
            void Add(string relative)
            {
                var file = Path.Combine(source, "Assets/Sprites/MetaUI", relative).Replace('\\', '/');
                jobs.Add((file, ArtFolder + "/" + Path.GetFileName(relative)));
            }
        }

        public static void Install(GameObject root)
        {
            if (root.GetComponent<CommercialEquipmentView>()) return;
            if (!AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/bg_equip_level.png")) ImportReferenceArt();
            var page = root.GetComponentsInChildren<RectTransform>(true).First(x => x.name == "Page_Equipment");
            var popup = root.GetComponentsInChildren<RectTransform>(true).First(x => x.name == "PopupCanvas");
            font = root.GetComponentsInChildren<Text>(true).FirstOrDefault()?.font ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            var oldChildren = page.Cast<Transform>().ToArray();
            var legacy = new GameObject("LegacyEquipmentLayout", typeof(RectTransform)); legacy.transform.SetParent(page, false);
            foreach (var child in oldChildren) Undo.SetTransformParent(child, legacy.transform, "Preserve previous equipment layout");
            legacy.SetActive(false);
            var view = Undo.AddComponent<CommercialEquipmentView>(root);
            view.PageBounds = page;
            var ui = Rect(page, "EquipmentPageContent", 0, 0, 1080, 1586); ui.anchorMin = ui.anchorMax = ui.pivot = new Vector2(.5f, .5f); ui.anchoredPosition = Vector2.zero;
            ui.gameObject.AddComponent<Canvas>(); ui.gameObject.AddComponent<GraphicRaycaster>();
            Panel(ui, Ink); view.RootUI = ui;
            var background = Rect(ui, "EQ_Background", 0, 0, 1080, 1586); var bg = Panel(background, new Color(.38f, .47f, .57f)); bg.sprite = Art("bg_interface");
            Label(ui, "EQ_Title", "角色装备", 40, Color.white, 28, 14, 280, 62);
            Label(ui, "EQ_Wallet", "金币 0    锻造尘 0", 28, Gold, 360, 12, 684, 40, TextAnchor.MiddleRight);
            Label(ui, "EQ_Tip", "换装与养成在下一场战斗生效", 24, Muted, 358, 51, 686, 34, TextAnchor.MiddleRight);
            Button(ui, "EQ_TabGear", "装 备", 28, 96, 242, 60);
            Button(ui, "EQ_TabForge", "定向锻造", 288, 96, 242, 60);
            Button(ui, "EQ_TabLoadouts", "配装方案", 548, 96, 242, 60);
            Button(ui, "EQ_TabSets", "套装图鉴", 808, 96, 242, 60);

            var showcase = Rect(ui, "EQ_Showcase", 24, 174, 1032, 536); Panel(showcase, PanelColor);
            var portrait = Image(showcase, "EQ_HeroPortrait", 318, 20, 396, 244,
                AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Resources/Commercial/BattleUI/battle_card_art_hero_swordsman_544x336.png"));
            portrait.preserveAspect = true;
            Label(showcase, "EQ_HeroName", "战士  Lv.1", 36, Color.white, 232, 274, 568, 50, TextAnchor.MiddleCenter);
            Label(showcase, "EQ_Power", "综合评分 0", 32, Gold, 232, 326, 568, 44, TextAnchor.MiddleCenter);
            Label(showcase, "EQ_FourAttributes", "力量 10    敏捷 10\n智力 10    体质 10", 29, Color.white, 232, 377, 568, 78, TextAnchor.MiddleCenter);
            Label(showcase, "EQ_CombatStats", "生命 140  护甲 3\n强度 16  暴击 7%", 25, Muted, 232, 455, 568, 68, TextAnchor.MiddleCenter);
            view.Slots = new CommercialEquipmentCell[6];
            for (var i = 0; i < 6; i++)
            {
                var column = i < 3 ? 0 : 1; var row = i % 3;
                view.Slots[i] = Cell(showcase, "EQ_Slot_" + i, column == 0 ? 24 : 832, 22 + row * 169, 176, 152);
            }
            var setBar = Rect(ui, "EQ_SetBar", 24, 724, 1032, 60); Panel(setBar, PanelColor);
            Label(setBar, "EQ_ActiveSets", "套装效果  ·  集齐 2 / 4 / 6 件激活", 27, Muted, 18, 0, 846, 60);
            Button(setBar, "EQ_SetInfo", "查看 ›", 864, 8, 152, 44, 26);

            var bag = Rect(ui, "EQ_InventoryPanel", 24, 800, 1032, 770); Panel(bag, new Color(.04f, .075f, .12f));
            bag.gameObject.AddComponent<Canvas>(); bag.gameObject.AddComponent<GraphicRaycaster>();
            Button(bag, "EQ_FilterSlot", "全部部位 ▾", 18, 10, 237, 56, 27);
            Button(bag, "EQ_FilterRarity", "全部品质 ▾", 271, 10, 237, 56, 27);
            Button(bag, "EQ_FilterSet", "全部套装 ▾", 524, 10, 237, 56, 27);
            Button(bag, "EQ_Sort", "最新获得 ↕", 777, 10, 237, 56, 27);
            Label(bag, "EQ_BagCount", "装备背包", 24, Muted, 18, 71, 996, 32);
            view.Cells = new CommercialEquipmentCell[20];
            for (var i = 0; i < 20; i++) view.Cells[i] = Cell(bag, "EQ_Item_" + i.ToString("00"), 18 + i % 5 * 202, 110 + i / 5 * 146, 188, 136);
            Label(bag, "EQ_EmptyBag", "暂无符合筛选的装备\n探索战斗掉落装备，分解可获得锻造尘", 30, Muted, 68, 260, 896, 160, TextAnchor.MiddleCenter);
            Button(bag, "EQ_Previous", "‹", 18, 706, 88, 50, 36);
            Label(bag, "EQ_PageNumber", "1 / 1", 26, Color.white, 116, 706, 170, 50, TextAnchor.MiddleCenter);
            Button(bag, "EQ_Next", "›", 298, 706, 88, 50, 36);
            Button(bag, "EQ_ResumeRoll", "待确认重铸", 410, 706, 254, 50, 25);
            Button(bag, "EQ_BulkSalvage", "分解普通装备", 710, 706, 304, 50, 25);

            var workshop = Rect(ui, "EQ_WorkshopPanel", 24, 174, 1032, 1396); Panel(workshop, PanelColor);
            Label(workshop, "EQ_ForgeHeading", "定向锻造", 38, Gold, 40, 28, 930, 64);
            Label(workshop, "EQ_ForgeHint", "指定套装与部位，补齐构筑缺少的一件。", 28, Muted, 40, 100, 930, 54);
            Image(workshop, "EQ_CraftIcon", 366, 175, 300, 260, Art("icon_sword_02"));
            Label(workshop, "EQ_CraftPreview", "装备预览", 32, Color.white, 44, 453, 944, 140, TextAnchor.MiddleCenter);
            Button(workshop, "EQ_CraftSet", "套装 ▾", 44, 634, 300, 72);
            Button(workshop, "EQ_CraftSlot", "部位 ▾", 366, 634, 300, 72);
            Button(workshop, "EQ_CraftRarity", "品质 ▾", 688, 634, 300, 72);
            Label(workshop, "EQ_ForgeSetInfo", "套装效果", 29, Muted, 52, 748, 928, 238);
            Label(workshop, "EQ_CraftCost", "消耗与持有", 30, Gold, 52, 1042, 928, 102, TextAnchor.MiddleCenter);
            Button(workshop, "EQ_Craft", "锻 造 装 备", 250, 1170, 532, 84, 34, Blue);
            Label(workshop, "EQ_ForgeFootnote", "锻造尘来自装备分解；品质越高，随机词条越多。\n随机范围、掉落率和全部消耗均由装备配置表控制。", 25, Muted, 52, 1290, 928, 78, TextAnchor.MiddleCenter);
            workshop.gameObject.SetActive(false);

            var modalRoot = new GameObject("EquipmentModalLayer", typeof(RectTransform)).GetComponent<RectTransform>();
            modalRoot.SetParent(popup, false); Stretch(modalRoot); view.ModalRoot = modalRoot;
            BuildDetail(modalRoot); BuildSets(modalRoot); BuildLoadouts(modalRoot); BuildConfirm(modalRoot);
            var toast = Rect(modalRoot, "EQ_Toast", 0, 0, 970, 90); toast.anchorMin = toast.anchorMax = toast.pivot = new Vector2(.5f, 1); toast.anchoredPosition = new Vector2(0, -180);
            Panel(toast, new Color(.03f, .10f, .16f, .98f)); var toastGroup = toast.gameObject.AddComponent<CanvasGroup>(); toastGroup.alpha = 0; toastGroup.blocksRaycasts = false;
            Label(toast, "EQ_ToastText", "", 29, Color.white, 24, 10, 922, 70, TextAnchor.MiddleCenter);
            EditorUtility.SetDirty(view);
        }

        private static void BuildDetail(RectTransform root)
        {
            var p = Modal(root, "EQ_DetailModal", 960, 1576);
            Label(p, "EQ_DetailHeading", "装备详情", 32, Muted, 36, 24, 580, 52);
            Button(p, "EQ_CloseDetail", "×", 846, 22, 78, 58, 36);
            Image(p, "EQ_DetailIcon", 36, 96, 140, 134, Art("equip_10001"));
            Label(p, "EQ_DetailTitle", "铁誓·头盔", 36, Color.white, 198, 100, 726, 58);
            Label(p, "EQ_DetailMeta", "属性", 26, Muted, 198, 167, 726, 73);
            var comparison = Rect(p, "EQ_ComparePanel", 36, 272, 888, 188); Panel(comparison, new Color(.055f, .105f, .16f));
            Label(comparison, "EQ_Comparison", "替换对比", 27, Color.white, 18, 10, 850, 170, TextAnchor.UpperLeft);
            Button(comparison, "EQ_CompareMore", "全部属性变化 ›", 614, 144, 254, 36, 23);
            Label(p, "EQ_BaseStats", "基础属性", 29, Color.white, 44, 482, 870, 188, TextAnchor.UpperLeft);
            Label(p, "EQ_AffixHeader", "随机词条", 27, Muted, 44, 680, 870, 44);
            for (var i = 0; i < 3; i++) Button(p, "EQ_Affix_" + i, "词条", 36, 736 + i * 70, 888, 62, 28);
            Label(p, "EQ_UpgradeInfo", "强化", 26, Muted, 44, 960, 870, 118, TextAnchor.UpperLeft);
            Label(p, "EQ_DetailSet", "套装", 26, Muted, 44, 1100, 870, 158, TextAnchor.UpperLeft);
            var actions = Rect(p, "EQ_DetailActions", 36, 1290, 888, 238);
            Button(actions, "EQ_Equip", "穿戴装备", 0, 0, 278, 78, 30, Blue);
            Button(actions, "EQ_Lock", "锁定装备", 306, 0, 278, 78, 29);
            Button(actions, "EQ_Salvage", "分解装备", 610, 0, 278, 78, 29);
            Button(actions, "EQ_Upgrade", "强化槽位", 0, 98, 430, 78, 29);
            Button(actions, "EQ_Reforge", "重铸所选词条", 458, 98, 430, 78, 29);
            Label(actions, "EQ_DetailFooter", "普通装备无随机词条；锁定不限制穿戴与养成。", 23, Muted, 0, 194, 888, 38, TextAnchor.MiddleCenter);
            var pending = Rect(p, "EQ_PendingRollPanel", 36, 1266, 888, 280); Panel(pending, new Color(.075f, .19f, .22f));
            Label(pending, "EQ_PendingRollText", "待确认词条", 27, Color.white, 18, 10, 852, 180, TextAnchor.UpperLeft);
            Button(pending, "EQ_DiscardRoll", "保留原词条", 20, 204, 402, 60, 28);
            Button(pending, "EQ_AcceptRoll", "使用新词条", 466, 204, 402, 60, 28, Blue);
            pending.gameObject.SetActive(false);
        }
        private static void BuildSets(RectTransform root)
        {
            var p = Modal(root, "EQ_SetsModal", 960, 1550);
            Label(p, "EQ_SetsTitle", "套装图鉴", 38, Gold, 36, 24, 760, 64); Button(p, "EQ_CloseSets", "×", 846, 24, 78, 60, 36);
            Label(p, "EQ_SetsHint", "同套装不同部位累计件数，混合品质也可激活。\n2 / 4 / 6 件效果累加；每个部位最多计入 1 件。", 27, Muted, 36, 110, 888, 88);
            Label(p, "EQ_SetsBody", "套装信息", 29, Color.white, 40, 230, 880, 1230, TextAnchor.UpperLeft);
        }
        private static void BuildLoadouts(RectTransform root)
        {
            var p = Modal(root, "EQ_LoadoutsModal", 960, 1010);
            Label(p, "EQ_LoadoutsTitle", "配装方案", 38, Gold, 36, 24, 760, 64); Button(p, "EQ_CloseLoadouts", "×", 846, 24, 78, 60, 36);
            Label(p, "EQ_LoadoutsHint", "保存 3 套装备组合，一键切换，下场战斗生效。\n方案中装备受到分解保护，清空方案后解除。", 27, Muted, 36, 110, 888, 88);
            for (var i = 0; i < 3; i++)
            {
                var row = Rect(p, "EQ_LoadoutRow_" + i, 36, 230 + i * 238, 888, 214); Panel(row, PanelColor);
                Label(row, "EQ_LoadoutText_" + i, "方案 " + (i + 1), 30, Color.white, 24, 14, 840, 100);
                Button(row, "EQ_SaveLoadout_" + i, "保存当前", 24, 130, 260, 64, 28);
                Button(row, "EQ_ApplyLoadout_" + i, "应用方案", 314, 130, 260, 64, 28, Blue);
                Button(row, "EQ_ClearLoadout_" + i, "清空", 604, 130, 260, 64, 28);
            }
        }
        private static void BuildConfirm(RectTransform root)
        {
            var p = Modal(root, "EQ_ConfirmModal", 900, 640);
            Label(p, "EQ_ConfirmTitle", "确认操作", 38, Gold, 38, 32, 824, 72);
            Label(p, "EQ_ConfirmBody", "", 30, Color.white, 38, 130, 824, 330, TextAnchor.UpperLeft);
            Button(p, "EQ_ConfirmNo", "取 消", 38, 520, 388, 78, 32);
            Button(p, "EQ_ConfirmYes", "确 认", 474, 520, 388, 78, 32, Blue);
        }

        private static RectTransform Modal(RectTransform parent, string name, float width, float height)
        {
            var overlay = new GameObject(name, typeof(RectTransform), typeof(CanvasGroup)).GetComponent<RectTransform>(); overlay.SetParent(parent, false); Stretch(overlay);
            Panel(overlay, new Color(0, 0, 0, .78f)).raycastTarget = true;
            var panel = Rect(overlay, "Panel", 0, 0, width, height); panel.anchorMin = panel.anchorMax = panel.pivot = new Vector2(.5f, .5f); panel.anchoredPosition = Vector2.zero;
            Panel(panel, Ink).raycastTarget = true; overlay.gameObject.SetActive(false); return panel;
        }
        private static CommercialEquipmentCell Cell(Transform parent, string name, float x, float y, float width, float height)
        {
            var rect = Rect(parent, name, x, y, width, height); var rim = Panel(rect, new Color(.19f, .32f, .44f)); rim.sprite = Art("tab_equip_01"); rim.type = UnityEngine.UI.Image.Type.Sliced;
            rim.raycastTarget = true;
            var button = rect.gameObject.AddComponent<Button>(); button.targetGraphic = rim;
            var inside = Rect(rect, name + "_Backing", 3, 3, width - 6, height - 6); var backing = Panel(inside, Color.white); backing.sprite = Art("bg_equip_level"); backing.type = UnityEngine.UI.Image.Type.Sliced;
            var icon = Image(rect, name + "_Icon", (width - 94) / 2, 3, 94, height - 62, Art("equip_10001"));
            var caption = Label(rect, name + "_Caption", "未装备", 22, Color.white, 4, height - 58, width - 8, 30, TextAnchor.MiddleCenter);
            var meta = Label(rect, name + "_Meta", "", 21, Muted, 4, height - 29, width - 8, 28, TextAnchor.MiddleCenter);
            var badge = Label(rect, name + "_Badge", "", 22, Gold, 6, 3, width - 12, 27, TextAnchor.UpperRight);
            var cell = rect.gameObject.AddComponent<CommercialEquipmentCell>(); cell.Icon = icon; cell.Rim = rim; cell.Caption = caption; cell.Meta = meta; cell.Badge = badge; cell.Button = button;
            cell.RarityOutline = rect.gameObject.AddComponent<Outline>(); cell.RarityOutline.effectDistance = new Vector2(2, -2);
            return cell;
        }
        public static void PolishExistingCells(GameObject root)
        {
            var view = root.GetComponent<CommercialEquipmentView>();
            font = root.GetComponentsInChildren<Text>(true).First().font;
            var comparison = view.ModalRoot.Find("EQ_DetailModal/Panel/EQ_ComparePanel");
            if (comparison && !comparison.Find("EQ_CompareMore")) Button(comparison, "EQ_CompareMore", "全部属性变化 ›", 614, 144, 254, 36, 23);
            foreach (var cell in view.Slots.Concat(view.Cells))
            {
                var rect = (RectTransform)cell.transform; var width = rect.rect.width; var height = rect.rect.height;
                cell.Rim.raycastTarget = true;
                cell.Icon.rectTransform.sizeDelta = new Vector2(94, height - 62);
                cell.Caption.fontSize = 22; cell.Caption.rectTransform.anchoredPosition = new Vector2(4, -(height - 58)); cell.Caption.rectTransform.sizeDelta = new Vector2(width - 8, 30);
                cell.Meta.rectTransform.anchoredPosition = new Vector2(4, -(height - 29)); cell.Meta.rectTransform.sizeDelta = new Vector2(width - 8, 28);
                cell.RarityOutline = cell.GetComponent<Outline>() ?? cell.gameObject.AddComponent<Outline>();
                cell.RarityOutline.effectDistance = new Vector2(2, -2); EditorUtility.SetDirty(cell);
            }
        }
        private static RectTransform Rect(Transform parent, string name, float x, float y, float w, float h)
        {
            var rect = new GameObject(name, typeof(RectTransform)).GetComponent<RectTransform>(); rect.SetParent(parent, false);
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(0, 1); rect.anchoredPosition = new Vector2(x, -y); rect.sizeDelta = new Vector2(w, h); return rect;
        }
        private static void Stretch(RectTransform rect) { rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero; }
        private static Image Panel(RectTransform rect, Color color) { var image = rect.gameObject.AddComponent<Image>(); image.color = color; image.raycastTarget = false; return image; }
        private static Image Image(Transform parent, string name, float x, float y, float w, float h, Sprite sprite)
        { var image = Panel(Rect(parent, name, x, y, w, h), Color.white); image.sprite = sprite; image.preserveAspect = true; return image; }
        private static Text Label(Transform parent, string name, string text, int size, Color color, float x, float y, float w, float h, TextAnchor alignment = TextAnchor.MiddleLeft)
        {
            var label = Rect(parent, name, x, y, w, h).gameObject.AddComponent<Text>(); label.font = font; label.fontSize = size; label.text = text; label.color = color;
            label.alignment = alignment; label.supportRichText = true; label.raycastTarget = false; label.horizontalOverflow = HorizontalWrapMode.Wrap; label.verticalOverflow = VerticalWrapMode.Truncate; return label;
        }
        private static Button Button(Transform parent, string name, string label, float x, float y, float w, float h, int size = 30, Color? color = null)
        {
            var rect = Rect(parent, name, x, y, w, h); var image = Panel(rect, color ?? ButtonColor); image.raycastTarget = true;
            image.sprite = Art("tab_equip_01"); image.type = UnityEngine.UI.Image.Type.Sliced;
            var button = rect.gameObject.AddComponent<Button>(); button.targetGraphic = image;
            var colors = button.colors; colors.highlightedColor = new Color(.90f, .97f, 1); colors.pressedColor = new Color(.64f, .77f, .92f); colors.disabledColor = new Color(.36f, .43f, .50f); button.colors = colors;
            Label(rect, name + "_Label", label, size, Color.white, 8, 0, w - 16, h, TextAnchor.MiddleCenter); return button;
        }
        private static Sprite Art(string name) =>
            AssetDatabase.LoadAssetAtPath<Sprite>(FeilongArtFolder + "/" + name + ".png") ??
            AssetDatabase.LoadAssetAtPath<Sprite>(ArtFolder + "/" + name + ".png");
        private static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path)) return; var parent = Path.GetDirectoryName(path).Replace('\\', '/'); EnsureFolder(parent); AssetDatabase.CreateFolder(parent, Path.GetFileName(path));
        }
        public static void SavePrefabs(GameObject root)
        {
            EnsureFolder(Prefabs); var view = root.GetComponent<CommercialEquipmentView>(); if (!view) return;
            PrefabUtility.SaveAsPrefabAsset(view.RootUI.gameObject, Prefabs + "/PF_Screen_EquipmentContent.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.PageBounds.gameObject, Prefabs + "/PF_Screen_Equipment.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.Slots[0].gameObject, Prefabs + "/PF_UI_EquipmentSlot.prefab");
            PrefabUtility.SaveAsPrefabAsset(view.Cells[0].gameObject, Prefabs + "/PF_UI_EquipmentItem.prefab");
            foreach (var name in new[] { "EQ_DetailModal", "EQ_SetsModal", "EQ_LoadoutsModal", "EQ_ConfirmModal" })
                PrefabUtility.SaveAsPrefabAsset(view.ModalRoot.Find(name).gameObject, Prefabs + "/PF_Popup_" + name.Substring(3) + ".prefab");
            PrefabUtility.SaveAsPrefabAsset(root, Prefabs + "/PF_CommercialGameRoot.prefab");
        }
    }
}

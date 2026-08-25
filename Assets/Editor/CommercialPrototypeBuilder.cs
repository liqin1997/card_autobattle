using System.IO;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class CommercialPrototypeBuilder
    {
        private const string RootFolder = "Assets/Resources/Commercial";
        private const string PrefabFolder = RootFolder + "/Prefabs";
        private const string ScenePath = "Assets/Scenes/CommercialVerticalSlice.unity";
        private const float UiScale = 2f;
        private static readonly Vector2 ReferenceResolution = new(1080f, 1920f);
        private static readonly Font Font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        private static readonly Color Background = new(.018f, .035f, .045f, 1f);
        private static readonly Color Panel = new(.035f, .071f, .088f, .96f);
        private static readonly Color Panel2 = new(.052f, .095f, .114f, .98f);
        private static readonly Color Cyan = new(.31f, .87f, .91f, 1f);
        private static readonly Color Gold = new(1f, .76f, .28f, 1f);
        private static readonly Color Red = new(.95f, .31f, .35f, 1f);
        private static readonly Color Muted = new(.52f, .65f, .70f, 1f);

        [MenuItem("Tools/Card Autobattle/Build Commercial Vertical Slice")]
        public static void Build()
        {
            EnsureFolder("Assets/Resources", "Commercial");
            EnsureFolder(RootFolder, "Prefabs");
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            scene.name = "CommercialVerticalSlice";

            var root = new GameObject("CommercialGameRoot", typeof(CommercialPrototypeController));
            CreateCamera(root.transform);
            CreateEventSystem(root.transform);

            var staticCanvas = CreateCanvas(root.transform, "StaticPageCanvas", 0);
            CreateTopBar(staticCanvas.transform);

            var cardPrefab = CreateBattleCardPrefab();
            var battlePresentation = CreateBattlePresentation(root.transform, cardPrefab);
            PrefabUtility.SaveAsPrefabAsset(battlePresentation, $"{PrefabFolder}/PF_UI_BattlePresentation.prefab");
            var pages = new GameObject[6];
            pages[0] = CreatePlaceholderPage(staticCanvas.transform, "Page_Gacha", "抽奖商城", "卡包、每日商店与付费入口", "今日免费抽取  1 / 1");
            pages[1] = CreateFormationPage(staticCanvas.transform);
            pages[2] = CreatePlaceholderPage(staticCanvas.transform, "Page_City", "主城", "任务、活动与装备打造的外围玩法中心", "铁匠铺  ·  委托所  ·  营地");
            pages[3] = CreateExplorePage(staticCanvas.transform);
            pages[4] = CreateEquipmentPage(staticCanvas.transform);
            pages[5] = CreatePlaceholderPage(staticCanvas.transform, "Page_Activities", "活动", "常驻活动与限时玩法入口", "七日远征  ·  首领挑战  ·  赛季目标");

            for (var i = 0; i < pages.Length; i++)
            {
                pages[i].SetActive(i == 3);
                PrefabUtility.SaveAsPrefabAsset(pages[i], $"{PrefabFolder}/PF_Screen_{PageAssetName(i)}.prefab");
            }

            var navCanvas = CreateCanvas(root.transform, "NavigationCanvas", 70);
            var nav = CreateNavigation(navCanvas.transform);
            PrefabUtility.SaveAsPrefabAsset(nav, $"{PrefabFolder}/PF_UI_BottomNavigation.prefab");

            var popupCanvas = CreateCanvas(root.transform, "PopupCanvas", 100);
            var popup = CreateCardDetailPopup(popupCanvas.transform);
            PrefabUtility.SaveAsPrefabAsset(popup, $"{PrefabFolder}/PF_Popup_CardDetail.prefab");
            popup.SetActive(false);

            PrefabUtility.SaveAsPrefabAsset(root, $"{PrefabFolder}/PF_CommercialGameRoot.prefab");
            EditorSceneManager.SaveScene(scene, ScenePath);
            AddSceneToBuildSettings(ScenePath);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Selection.activeGameObject = root;
            Debug.Log($"[CommercialPrototypeBuilder] Built scene and prefabs: {ScenePath}");
        }

        private static GameObject CreateBattleCardPrefab()
        {
            var root = CreateRect(null, "PF_Card_Battle", new Vector2(144f, 92f));
            var surface = root.AddComponent<Image>();
            surface.color = new Color(.08f, .25f, .32f, 1f);
            surface.raycastTarget = true;
            var button = root.AddComponent<Button>();
            button.targetGraphic = surface;
            root.AddComponent<CommercialBattleCardView>();

            var cooldown = AddFullImage(root.transform, "CooldownFill", new Color(.22f, .92f, 1f, .18f), false);
            cooldown.type = Image.Type.Filled;
            cooldown.sprite = FilledSprite();
            cooldown.fillMethod = Image.FillMethod.Vertical;
            cooldown.fillOrigin = 0;
            cooldown.fillAmount = .52f;
            var sweep = AddFullImage(root.transform, "CooldownSweep", new Color(.55f, 1f, 1f, .58f), false);

            var accent = AddPanel(root.transform, "Accent", Cyan, new Vector2(.02f, .78f), new Vector2(.98f, .82f));
            accent.GetComponent<Image>().raycastTarget = false;
            AddText(root.transform, "Name", "卡牌", 17, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.08f, .42f), new Vector2(.95f, .84f), FontStyle.Bold);
            AddText(root.transform, "Meta", "3.0s · 主动", 12, Muted, TextAnchor.MiddleLeft,
                new Vector2(.08f, .12f), new Vector2(.95f, .43f));

            var health = AddPanel(root.transform, "HealthGroup", new Color(.018f, .027f, .032f, .96f),
                new Vector2(.05f, .035f), new Vector2(.95f, .235f));
            var healthBg = health.GetComponent<Image>();
            healthBg.raycastTarget = false;
            var lag = AddFullImage(health.transform, "HealthLagFill", new Color(.95f, .20f, .13f, .78f), false);
            lag.type = Image.Type.Simple;
            lag.rectTransform.anchorMax = new Vector2(.75f, 1f);
            var fill = AddFullImage(health.transform, "HealthFill", new Color(.28f, .91f, .57f, 1f), false);
            fill.type = Image.Type.Simple;
            fill.rectTransform.anchorMax = new Vector2(.75f, 1f);
            var shield = AddFullImage(health.transform, "ShieldFill", new Color(.20f, .78f, 1f, .95f), false);
            shield.type = Image.Type.Simple;
            var shieldRect = shield.rectTransform;
            shieldRect.anchorMin = new Vector2(1f, .76f);
            shieldRect.anchorMax = Vector2.one;
            shieldRect.offsetMin = shieldRect.offsetMax = Vector2.zero;
            AddText(health.transform, "HealthText", "HP 100/100", 11, Color.white, TextAnchor.MiddleCenter,
                Vector2.zero, Vector2.one, FontStyle.Bold);

            PrefabUtility.SaveAsPrefabAsset(root, $"{PrefabFolder}/PF_Card_Battle.prefab");
            Object.DestroyImmediate(root);
            return AssetDatabase.LoadAssetAtPath<GameObject>($"{PrefabFolder}/PF_Card_Battle.prefab");
        }

        private static GameObject CreateExplorePage(Transform parent)
        {
            var page = CreatePage(parent, "Page_Explore");
            return page;
        }

        private static void CreateBattleInfoLayer(Transform parent)
        {
            var timeline = AddTopRect(parent, "BattleTimeline", 20f, 190f, 357f, 130f);
            AddImage(timeline, new Color(.035f, .07f, .085f, 1f), false);
            AddText(timeline.transform, "LocationTitle", "第 1 章 · 关卡 01 / 20", 19, Color.white, TextAnchor.MiddleCenter,
                new Vector2(.04f, .63f), new Vector2(.96f, .92f), FontStyle.Bold);
            AddText(timeline.transform, "IdleExperience", "挂机经验  +18 / 分钟", 13, Cyan, TextAnchor.MiddleLeft,
                new Vector2(.04f, .42f), new Vector2(.58f, .65f), FontStyle.Bold);
            AddText(timeline.transform, "WeatherText", "天气：浓雾", 12, Muted, TextAnchor.MiddleLeft,
                new Vector2(.04f, .25f), new Vector2(.42f, .44f));
            AddText(timeline.transform, "NextAction", "下一次行动", 11, Muted, TextAnchor.MiddleRight,
                new Vector2(.58f, .42f), new Vector2(.78f, .65f));
            AddText(timeline.transform, "TimelineClock", "◷", 24, Gold, TextAnchor.MiddleCenter,
                new Vector2(.78f, .40f), new Vector2(.86f, .66f), FontStyle.Bold);
            AddText(timeline.transform, "BattleTimer", "00.0s", 12, Gold, TextAnchor.MiddleRight,
                new Vector2(.86f, .43f), new Vector2(.97f, .65f), FontStyle.Bold);
            AddButton(timeline.transform, "DamageStatsButton", "伤害统计", Panel2,
                new Vector2(.04f, .05f), new Vector2(.31f, .26f));
            AddButton(timeline.transform, "SpeedButton", "×2 倍速", Panel2,
                new Vector2(.365f, .05f), new Vector2(.635f, .26f));
            AddButton(timeline.transform, "WorldChatButton", "世界聊天", Panel2,
                new Vector2(.69f, .05f), new Vector2(.96f, .26f));

            var quest = AddTopRect(parent, "MainQuestPanel", 360f, 20f, 357f, 130f);
            AddImage(quest, new Color(.045f, .08f, .095f, 1f), true);
            AddText(quest.transform, "MainQuestTitle", "主线任务 · 通关 1-05", 15, Color.white,
                TextAnchor.MiddleLeft, new Vector2(.07f, .58f), new Vector2(.93f, .92f), FontStyle.Bold);
            AddText(quest.transform, "MainQuestProgress", "1 / 5   奖励：金币 ×160", 12, Muted,
                TextAnchor.MiddleLeft, new Vector2(.07f, .32f), new Vector2(.93f, .60f));
            AddText(quest.transform, "BattleResultHint", "战斗在切换页面后仍会继续", 11, Cyan,
                TextAnchor.MiddleLeft, new Vector2(.07f, .08f), new Vector2(.53f, .33f));
            var retry = AddButton(quest.transform, "RetryBattleButton", "重新挑战", Gold,
                new Vector2(.42f, .08f), new Vector2(.93f, .31f));
            retry.gameObject.SetActive(false);
            PrefabUtility.SaveAsPrefabAsset(quest, $"{PrefabFolder}/PF_UI_MainQuest.prefab");
        }

        private static GameObject CreateBattlePresentation(Transform parent, GameObject cardPrefab)
        {
            var presentation = new GameObject("BattlePresentationRoot");
            presentation.transform.SetParent(parent, false);

            var battleCamera = CreateBattleCamera(presentation.transform);
            var battleCanvas = CreateBattleCanvas(presentation.transform, battleCamera);
            var page = CreatePage(battleCanvas.transform, "BattlePageRoot");

            CreateEffectLayer(page.transform, "BattleStaticLayer", 10, false);
            var cardLayer = CreateEffectLayer(page.transform, "BattleCardLayer", 20, true);
            var enemyGrid = AddTopRect(cardLayer, "EnemyGrid", 46f, 46f, 61f, 292f);
            AddImage(enemyGrid, new Color(.10f, .025f, .04f, .48f), false);
            CreateManualGrid(enemyGrid.transform, cardPrefab, "EnemyCard", 9);
            var playerGrid = AddTopRect(cardLayer, "PlayerGrid", 46f, 46f, 491f, 292f);
            AddImage(playerGrid, new Color(.015f, .12f, .15f, .52f), false);
            CreateManualGrid(playerGrid.transform, cardPrefab, "PlayerCard", 9);

            var infoLayer = CreateEffectLayer(page.transform, "BattleInfoLayer", 25, true);
            CreateBattleInfoLayer(infoLayer);
            CreateEffectLayer(page.transform, "HealthLayer", 30, false);
            var projectileLayer = CreateEffectLayer(page.transform, "ProjectileLayer", 40, false);
            projectileLayer.gameObject.AddComponent<CommercialProjectilePool>();
            CreateParticleLayer(page.transform, "VFXLayer", 50);
            var damageLayer = CreateEffectLayer(page.transform, "DamageTextLayer", 60, false);
            damageLayer.gameObject.AddComponent<CommercialFloatingTextPool>();
            CreateEffectLayer(page.transform, "BattleDragLayer", 80, false);

            SetLayerRecursively(presentation.transform, LayerMask.NameToLayer("UI"));
            return presentation;
        }

        private static GameObject CreateFormationPage(Transform parent)
        {
            var page = CreatePage(parent, "Page_Formation");
            AddText(page.transform, "FormationTitle", "卡组与阵容", 24, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.06f, .91f), new Vector2(.58f, .98f), FontStyle.Bold);
            AddText(page.transform, "FormationHint", "点击卡牌查看详情；从详情选择部署，再点击3×3格子", 12, Muted,
                TextAnchor.MiddleRight, new Vector2(.38f, .91f), new Vector2(.94f, .98f));

            var board = AddTopRect(page.transform, "FormationBoard", 34f, 34f, 62f, 270f);
            AddImage(board, new Color(.025f, .12f, .145f, .65f), false);
            for (var i = 0; i < 9; i++)
            {
                var row = i / 3;
                var col = i % 3;
                var slot = AddButton(board.transform, $"FormationSlot_{i}", "空部署位", new Color(.06f, .15f, .17f, 1f),
                    GridMin(col, row, 3, 3, .018f), GridMax(col, row, 3, 3, .018f));
                slot.GetComponentInChildren<Text>().fontSize = ScaleFont(13);
            }
            var hero = AddButton(page.transform, "HeroLibraryButton", "主角 · 战败核心 · 3.0s", new Color(.42f, .31f, .10f, 1f),
                new Vector2(.06f, .52f), new Vector2(.58f, .58f));
            hero.GetComponentInChildren<Text>().fontSize = ScaleFont(13);
            AddButton(page.transform, "ClearFormationSelection", "取消选择", Panel2,
                new Vector2(.76f, .52f), new Vector2(.94f, .58f));
            AddText(page.transform, "CardLibraryTitle", "已拥有卡牌 · 20 / 20", 17, Cyan, TextAnchor.MiddleLeft,
                new Vector2(.06f, .46f), new Vector2(.55f, .51f), FontStyle.Bold);

            var library = AddPanel(page.transform, "CardLibrary", new Color(.025f, .055f, .07f, .95f),
                new Vector2(.05f, .035f), new Vector2(.95f, .46f));
            for (var i = 0; i < 20; i++)
            {
                var row = i / 4;
                var col = i % 4;
                var button = AddButton(library.transform, $"LibraryCard_{i:00}", $"卡牌 {i + 1:00}",
                    i >= 17 ? new Color(.08f, .28f, .31f, 1f) : i is 12 or 13 ? new Color(.30f, .23f, .09f, 1f) : Panel2,
                    GridMin(col, row, 4, 5, .012f), GridMax(col, row, 4, 5, .012f));
                button.GetComponentInChildren<Text>().fontSize = ScaleFont(10);
            }
            CreateEffectLayer(page.transform, "FormationDragLayer", 80, false);
            return page;
        }

        private static GameObject CreateEquipmentPage(Transform parent)
        {
            var page = CreatePage(parent, "Page_Equipment");
            AddText(page.transform, "EquipmentTitle", "角色装备", 24, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.06f, .91f), new Vector2(.52f, .98f), FontStyle.Bold);
            AddText(page.transform, "PlayerPower", "主角 Lv.1 · 战力 132", 15, Gold, TextAnchor.MiddleRight,
                new Vector2(.48f, .91f), new Vector2(.94f, .98f), FontStyle.Bold);
            AddText(page.transform, "EquipmentTip", "点击已穿戴部位卸下；点击背包装备穿戴。修改在下一场生效。", 12, Muted,
                TextAnchor.MiddleLeft, new Vector2(.06f, .85f), new Vector2(.94f, .91f));

            var slots = AddPanel(page.transform, "EquippedSlots", new Color(.025f, .065f, .08f, 1f),
                new Vector2(.05f, .50f), new Vector2(.95f, .84f));
            var slotNames = new[] { "头部", "手部", "护甲", "裤子", "鞋子", "主武器" };
            for (var i = 0; i < 6; i++)
            {
                var row = i / 3;
                var col = i % 3;
                var button = AddButton(slots.transform, $"EquipmentSlot_{i}", $"{slotNames[i]}\n未装备", Panel2,
                    GridMin(col, row, 3, 2, .02f), GridMax(col, row, 3, 2, .02f));
                button.GetComponentInChildren<Text>().fontSize = ScaleFont(13);
            }

            AddText(page.transform, "InventoryTitle", "装备背包 · 关卡掉落", 17, Cyan, TextAnchor.MiddleLeft,
                new Vector2(.06f, .445f), new Vector2(.55f, .50f), FontStyle.Bold);
            var inventory = AddPanel(page.transform, "EquipmentInventory", new Color(.025f, .055f, .07f, .95f),
                new Vector2(.05f, .035f), new Vector2(.95f, .445f));
            for (var i = 0; i < 12; i++)
            {
                var row = i / 3;
                var col = i % 3;
                var button = AddButton(inventory.transform, $"Inventory_{i:00}", "装备", Panel2,
                    GridMin(col, row, 3, 4, .018f), GridMax(col, row, 3, 4, .018f));
                button.GetComponentInChildren<Text>().fontSize = ScaleFont(11);
            }
            return page;
        }

        private static GameObject CreatePlaceholderPage(Transform parent, string name, string title, string subtitle, string chips)
        {
            var page = CreatePage(parent, name);
            AddText(page.transform, "Title", title, 28, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.07f, .86f), new Vector2(.93f, .96f), FontStyle.Bold);
            AddText(page.transform, "Subtitle", subtitle, 14, Muted, TextAnchor.MiddleLeft,
                new Vector2(.07f, .80f), new Vector2(.93f, .87f));
            var hero = AddPanel(page.transform, "FeaturePanel", Panel, new Vector2(.07f, .39f), new Vector2(.93f, .77f));
            AddText(hero.transform, "FeatureIcon", "◇", 84, Gold, TextAnchor.MiddleCenter,
                new Vector2(.05f, .24f), new Vector2(.42f, .88f), FontStyle.Bold);
            AddText(hero.transform, "FeatureName", title + "功能纵切入口", 22, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.40f, .58f), new Vector2(.94f, .84f), FontStyle.Bold);
            AddText(hero.transform, "FeatureState", "界面结构已预留，后续接入配置表和业务系统", 13, Muted,
                TextAnchor.UpperLeft, new Vector2(.40f, .30f), new Vector2(.92f, .60f));
            AddText(page.transform, "Chips", chips, 16, Cyan, TextAnchor.MiddleCenter,
                new Vector2(.08f, .27f), new Vector2(.92f, .36f), FontStyle.Bold);
            AddButton(page.transform, "ResetPrototypeButton", "重置纵切版存档", new Color(.25f, .10f, .11f, 1f),
                new Vector2(.29f, .12f), new Vector2(.71f, .19f));
            return page;
        }

        private static GameObject CreateNavigation(Transform parent)
        {
            var root = AddPanel(parent, "BottomNavigation", new Color(.025f, .045f, .055f, 1f),
                Vector2.zero, new Vector2(1f, .092f));
            var labels = new[] { "抽奖", "卡组", "主城", "探索", "装备", "活动" };
            var icons = new[] { "◇", "▤", "⌂", "✧", "⬡", "▦" };
            for (var i = 0; i < 6; i++)
            {
                var min = new Vector2(i / 6f + .005f, .05f);
                var max = new Vector2((i + 1) / 6f - .005f, .95f);
                var button = AddButton(root.transform, $"Nav_{i}", string.Empty,
                    i == 3 ? new Color(.25f, .20f, .09f, 1f) : new Color(.035f, .055f, .07f, 1f), min, max);
                AddText(button.transform, "Icon", icons[i], 23, i == 3 ? Gold : Muted, TextAnchor.MiddleCenter,
                    new Vector2(0f, .34f), new Vector2(1f, .96f), FontStyle.Bold);
                AddText(button.transform, "Label", labels[i], 13, i == 3 ? Gold : Muted, TextAnchor.MiddleCenter,
                    new Vector2(0f, .02f), new Vector2(1f, .40f), FontStyle.Bold);
            }
            return root;
        }

        private static GameObject CreateCardDetailPopup(Transform parent)
        {
            var root = AddPanel(parent, "CardDetailPopup", new Color(0f, 0f, 0f, .70f), Vector2.zero, Vector2.one);
            root.GetComponent<Image>().raycastTarget = true;
            var panel = AddPanel(root.transform, "DetailPanel", new Color(.035f, .075f, .09f, 1f),
                new Vector2(.09f, .25f), new Vector2(.91f, .75f));
            AddText(panel.transform, "DetailTitle", "卡牌详情", 26, Gold, TextAnchor.MiddleLeft,
                new Vector2(.07f, .79f), new Vector2(.82f, .94f), FontStyle.Bold);
            AddButton(panel.transform, "CloseDetail", "×", new Color(.18f, .08f, .09f, 1f),
                new Vector2(.84f, .82f), new Vector2(.94f, .93f)).GetComponentInChildren<Text>().fontSize = ScaleFont(24);
            AddText(panel.transform, "DetailBody", "卡牌效果说明", 16, Color.white, TextAnchor.UpperLeft,
                new Vector2(.07f, .24f), new Vector2(.93f, .77f));
            AddButton(panel.transform, "DetailAction", "选择部署", new Color(.42f, .31f, .10f, 1f),
                new Vector2(.28f, .07f), new Vector2(.72f, .19f));
            return root;
        }

        private static void CreateTopBar(Transform parent)
        {
            var bar = AddPanel(parent, "TopBar", new Color(.02f, .04f, .05f, 1f),
                new Vector2(0f, .918f), Vector2.one);
            AddText(bar.transform, "Brand", "▲  森境远征", 18, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.035f, .18f), new Vector2(.30f, .91f), FontStyle.Bold);
            AddText(bar.transform, "PlayerLevel", "Lv.1  EXP 0/65", 11, Muted, TextAnchor.LowerLeft,
                new Vector2(.07f, .04f), new Vector2(.35f, .35f));
            AddResource(bar.transform, "ResourceEnergy", "◆", "128", .40f, Cyan);
            AddResource(bar.transform, "ResourceGold", "●", "500", .61f, Gold);
            AddResource(bar.transform, "ResourcePremium", "♦", "3690", .79f, new Color(1f, .35f, .52f));
        }

        private static void AddResource(Transform parent, string name, string icon, string value, float x, Color color)
        {
            AddText(parent, name + "Icon", icon, 17, color, TextAnchor.MiddleCenter,
                new Vector2(x, .24f), new Vector2(x + .055f, .82f), FontStyle.Bold);
            AddText(parent, name, value, 13, Color.white, TextAnchor.MiddleLeft,
                new Vector2(x + .05f, .22f), new Vector2(x + .16f, .84f), FontStyle.Bold);
        }

        private static void CreateManualGrid(Transform parent, GameObject prefab, string prefix, int count)
        {
            for (var i = 0; i < count; i++)
            {
                var instance = (GameObject)PrefabUtility.InstantiatePrefab(prefab);
                instance.name = $"{prefix}_{i}";
                instance.transform.SetParent(parent, false);
                var rect = (RectTransform)instance.transform;
                var row = i / 3;
                var col = i % 3;
                rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
                rect.pivot = new Vector2(0f, 1f);
                rect.sizeDelta = ScaleVector(new Vector2(144f, 92f));
                rect.anchoredPosition = ScaleVector(new Vector2(col * 152f, -row * 100f));
            }
        }

        private static RectTransform CreateEffectLayer(Transform parent, string name, int sorting, bool raycaster)
        {
            var rect = CreateRect(parent, name, Vector2.zero).GetComponent<RectTransform>();
            Stretch(rect, Vector2.zero, Vector2.one);
            var canvas = rect.gameObject.AddComponent<Canvas>();
            canvas.overrideSorting = true;
            canvas.sortingOrder = sorting;
            if (raycaster) rect.gameObject.AddComponent<GraphicRaycaster>();
            return rect;
        }

        private static RectTransform CreateParticleLayer(Transform parent, string name, int sorting)
        {
            var rect = CreateRect(parent, name, Vector2.zero).GetComponent<RectTransform>();
            Stretch(rect, Vector2.zero, Vector2.one);
            var bridge = rect.gameObject.AddComponent<CommercialBattleParticleLayer>();
            bridge.Configure(sorting);
            return rect;
        }

        private static GameObject CreatePage(Transform parent, string name)
        {
            var page = CreateRect(parent, name, Vector2.zero);
            var rect = page.GetComponent<RectTransform>();
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = new Vector2(0f, Scale(88f));
            rect.offsetMax = new Vector2(0f, -Scale(79f));
            return page;
        }

        private static Canvas CreateCanvas(Transform parent, string name, int sorting)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            go.transform.SetParent(parent, false);
            var canvas = go.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = sorting;
            var scaler = go.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = ReferenceResolution;
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = .5f;
            return canvas;
        }

        private static Canvas CreateBattleCanvas(Transform parent, Camera battleCamera)
        {
            var go = new GameObject("BattleCanvas", typeof(RectTransform), typeof(Canvas),
                typeof(CanvasScaler), typeof(GraphicRaycaster));
            go.transform.SetParent(parent, false);
            var canvas = go.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceCamera;
            canvas.worldCamera = battleCamera;
            canvas.planeDistance = 100f;
            canvas.sortingLayerID = 0;
            canvas.sortingOrder = 0;
            var scaler = go.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = ReferenceResolution;
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = .5f;
            return canvas;
        }

        private static Camera CreateCamera(Transform parent)
        {
            var go = new GameObject("Main Camera", typeof(Camera), typeof(AudioListener));
            go.transform.SetParent(parent, false);
            go.tag = "MainCamera";
            var camera = go.GetComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = Background;
            camera.depth = -10f;
            var uiLayer = LayerMask.NameToLayer("UI");
            if (uiLayer >= 0) camera.cullingMask &= ~(1 << uiLayer);
            return camera;
        }

        private static Camera CreateBattleCamera(Transform parent)
        {
            var go = new GameObject("BattleUICamera", typeof(Camera));
            go.transform.SetParent(parent, false);
            go.transform.localPosition = new Vector3(0f, 0f, -100f);
            var camera = go.GetComponent<Camera>();
            camera.clearFlags = CameraClearFlags.Depth;
            camera.backgroundColor = new Color(0f, 0f, 0f, 0f);
            camera.orthographic = true;
            camera.orthographicSize = 5f;
            camera.nearClipPlane = .3f;
            camera.farClipPlane = 500f;
            camera.depth = 0f;
            var uiLayer = LayerMask.NameToLayer("UI");
            camera.cullingMask = uiLayer >= 0 ? 1 << uiLayer : ~0;
            return camera;
        }

        private static void CreateEventSystem(Transform parent)
        {
            var go = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
            go.transform.SetParent(parent, false);
        }

        private static GameObject AddTopRect(Transform parent, string name, float left, float right, float top, float height)
        {
            var go = CreateRect(parent, name, Vector2.zero);
            var rect = go.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0f, 1f);
            rect.anchorMax = new Vector2(1f, 1f);
            rect.pivot = new Vector2(.5f, 1f);
            rect.offsetMin = new Vector2(Scale(left), -Scale(top + height));
            rect.offsetMax = new Vector2(-Scale(right), -Scale(top));
            return go;
        }

        private static GameObject AddPanel(Transform parent, string name, Color color, Vector2 min, Vector2 max)
        {
            var go = CreateRect(parent, name, Vector2.zero);
            Stretch(go.GetComponent<RectTransform>(), min, max);
            AddImage(go, color, false);
            return go;
        }

        private static Image AddFullImage(Transform parent, string name, Color color, bool raycast)
        {
            var go = CreateRect(parent, name, Vector2.zero);
            Stretch(go.GetComponent<RectTransform>(), Vector2.zero, Vector2.one);
            return AddImage(go, color, raycast);
        }

        private static Image AddImage(GameObject go, Color color, bool raycast)
        {
            var image = go.GetComponent<Image>() ?? go.AddComponent<Image>();
            image.color = color;
            image.raycastTarget = raycast;
            return image;
        }

        private static Text AddText(Transform parent, string name, string value, int size, Color color,
            TextAnchor alignment, Vector2 min, Vector2 max, FontStyle style = FontStyle.Normal)
        {
            var go = CreateRect(parent, name, Vector2.zero);
            Stretch(go.GetComponent<RectTransform>(), min, max);
            var text = go.AddComponent<Text>();
            text.font = Font;
            text.text = value;
            text.fontSize = ScaleFont(size);
            text.fontStyle = style;
            text.color = color;
            text.alignment = alignment;
            text.raycastTarget = false;
            text.horizontalOverflow = HorizontalWrapMode.Wrap;
            text.verticalOverflow = VerticalWrapMode.Truncate;
            return text;
        }

        private static Button AddButton(Transform parent, string name, string label, Color color, Vector2 min, Vector2 max)
        {
            var go = AddPanel(parent, name, color, min, max);
            var image = go.GetComponent<Image>();
            image.raycastTarget = true;
            var button = go.AddComponent<Button>();
            button.targetGraphic = image;
            AddText(go.transform, "Label", label, 14, Color.white, TextAnchor.MiddleCenter,
                new Vector2(.04f, .04f), new Vector2(.96f, .96f), FontStyle.Bold);
            return button;
        }

        private static GameObject CreateRect(Transform parent, string name, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform));
            if (parent) go.transform.SetParent(parent, false);
            go.GetComponent<RectTransform>().sizeDelta = ScaleVector(size);
            return go;
        }

        private static float Scale(float value) => value * UiScale;

        private static int ScaleFont(int value) => Mathf.RoundToInt(value * UiScale);

        private static Vector2 ScaleVector(Vector2 value) => value * UiScale;

        private static void Stretch(RectTransform rect, Vector2 min, Vector2 max)
        {
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
        }

        private static void SetLayerRecursively(Transform root, int layer)
        {
            if (!root || layer < 0) return;
            root.gameObject.layer = layer;
            for (var i = 0; i < root.childCount; i++) SetLayerRecursively(root.GetChild(i), layer);
        }

        private static Vector2 GridMin(int col, int row, int columns, int rows, float gap)
        {
            var width = 1f / columns;
            var height = 1f / rows;
            return new Vector2(col * width + gap, 1f - (row + 1) * height + gap);
        }

        private static Vector2 GridMax(int col, int row, int columns, int rows, float gap)
        {
            var width = 1f / columns;
            var height = 1f / rows;
            return new Vector2((col + 1) * width - gap, 1f - row * height - gap);
        }

        private static string PageAssetName(int index) => index switch
        {
            0 => "Gacha",
            1 => "Formation",
            2 => "City",
            3 => "Explore",
            4 => "Equipment",
            _ => "Activities"
        };

        private static void EnsureFolder(string parent, string child)
        {
            var full = parent + "/" + child;
            if (!AssetDatabase.IsValidFolder(full)) AssetDatabase.CreateFolder(parent, child);
        }

        private static void AddSceneToBuildSettings(string path)
        {
            foreach (var scene in EditorBuildSettings.scenes)
                if (scene.path == path) return;
            var previous = EditorBuildSettings.scenes;
            var updated = new EditorBuildSettingsScene[previous.Length + 1];
            previous.CopyTo(updated, 0);
            updated[^1] = new EditorBuildSettingsScene(path, true);
            EditorBuildSettings.scenes = updated;
        }

        private static Sprite FilledSprite() => Resources.GetBuiltinResource<Sprite>("UI/Skin/UISprite.psd");
    }
}

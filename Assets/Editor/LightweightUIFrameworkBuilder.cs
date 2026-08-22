using System;
using System.Collections.Generic;
using CardAutobattle.Preparation;
using CardAutobattle.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class LightweightUIFrameworkBuilder
    {
        private const string RootFolder = "Assets/Resources/UI";
        private const string ScreenFolder = RootFolder + "/Screens";
        private const string MainHubPath = ScreenFolder + "/MainHubScreen.prefab";
        private const string ScavengerDraftPath = ScreenFolder + "/ScavengerDraftScreen.prefab";
        private const string RootPath = RootFolder + "/GameUIRoot.prefab";
        private const string PreparationPath = "Assets/Prefab/UI/Preparation/PreparationCanvas.prefab";

        private static readonly Color Background = new(.018f, .035f, .045f, 1f);
        private static readonly Color Panel = new(.035f, .065f, .08f, .98f);
        private static readonly Color PanelRaised = new(.055f, .095f, .115f, 1f);
        private static readonly Color Accent = new(.10f, .72f, .60f, 1f);
        private static readonly Color Gold = new(1f, .76f, .22f, 1f);
        private static readonly Color PrimaryText = new(.92f, .96f, .98f, 1f);
        private static readonly Color SecondaryText = new(.56f, .68f, .74f, 1f);

        [MenuItem("Tools/Card Autobattle/Build Lightweight UI Framework")]
        public static void Build()
        {
            EnsureFolder("Assets/Resources");
            EnsureFolder(RootFolder);
            EnsureFolder(ScreenFolder);

            var mainHub = BuildMainHub();
            var scavengerDraft = BuildScavengerDraft();
            var preparation = ConfigurePreparationScreen();
            BuildRoot(mainHub, scavengerDraft, preparation);

            AssetDatabase.SaveAssets();
            AssetDatabase.ImportAsset(MainHubPath, ImportAssetOptions.ForceSynchronousImport);
            AssetDatabase.ImportAsset(ScavengerDraftPath, ImportAssetOptions.ForceSynchronousImport);
            AssetDatabase.ImportAsset(PreparationPath, ImportAssetOptions.ForceSynchronousImport);
            AssetDatabase.ImportAsset(RootPath, ImportAssetOptions.ForceSynchronousImport);
            Debug.Log("[UIFramework] Built GameUIRoot, MainHubScreen and Preparation screen adapter.");
        }

        private static GameObject BuildMainHub()
        {
            var root = NewRect("MainHubScreen", null);
            Stretch(root);
            root.gameObject.AddComponent<CanvasGroup>();
            var screen = root.gameObject.AddComponent<MainHubScreen>();

            var background = AddImage("Background", root, Background);
            Stretch(background.rectTransform);

            var safeArea = NewRect("SafeArea", root);
            Stretch(safeArea);
            safeArea.gameObject.AddComponent<SafeAreaFitter>();

            var header = AddImage("Header", safeArea, new Color(.025f, .055f, .07f, .98f));
            SetAnchors(header.rectTransform, new Vector2(0f, .90f), Vector2.one, Vector2.zero, Vector2.zero);
            AddText("PlayerName", header.transform, "PLAYER  Lv.1", 30, TextAnchor.MiddleLeft,
                PrimaryText, new Vector2(.05f, .15f), new Vector2(.48f, .85f));
            AddText("Currencies", header.transform, "GOLD  1,250     GEM  80", 28, TextAnchor.MiddleRight,
                Gold, new Vector2(.48f, .15f), new Vector2(.95f, .85f));

            var content = NewRect("ContentLayer", safeArea);
            SetAnchors(content, new Vector2(.035f, .145f), new Vector2(.965f, .89f), Vector2.zero, Vector2.zero);

            var pages = new GameObject[5];
            pages[0] = BuildPage(content, "GachaPage", "召唤", "抽取新的卡牌与英雄", new Color(.09f, .055f, .12f, 1f));
            BuildGachaContent(pages[0].transform);
            pages[1] = BuildPage(content, "HeroesPage", "英雄", "管理英雄、装备与编队", new Color(.045f, .075f, .12f, 1f));
            BuildHeroContent(pages[1].transform);
            pages[2] = BuildPage(content, "CityPage", "主城", "整备资源并规划下一次冒险", new Color(.035f, .09f, .085f, 1f));
            BuildCityContent(pages[2].transform);
            pages[3] = BuildPage(content, "ExplorePage", "探索", "选择地图后进入战前准备", new Color(.045f, .08f, .065f, 1f));
            var enterButton = BuildExploreContent(pages[3].transform);
            pages[4] = BuildPage(content, "CodexPage", "图鉴", "查看已发现卡牌与组合", new Color(.065f, .06f, .105f, 1f));
            BuildCodexContent(pages[4].transform);

            var bottom = AddImage("BottomNavigation", safeArea, new Color(.02f, .045f, .058f, 1f));
            SetAnchors(bottom.rectTransform, Vector2.zero, new Vector2(1f, .13f), Vector2.zero, Vector2.zero);
            var layout = bottom.gameObject.AddComponent<HorizontalLayoutGroup>();
            layout.padding = new RectOffset(18, 18, 14, 18);
            layout.spacing = 8f;
            layout.childAlignment = TextAnchor.MiddleCenter;
            layout.childControlWidth = true;
            layout.childControlHeight = true;
            layout.childForceExpandWidth = true;
            layout.childForceExpandHeight = true;

            var names = new[] { "抽卡", "英雄", "主城", "探索", "图鉴" };
            var buttons = new Button[5];
            var buttonImages = new Image[5];
            var labels = new Text[5];
            for (var i = 0; i < names.Length; i++)
            {
                buttons[i] = AddButton($"Tab_{i}_{names[i]}", bottom.transform, names[i],
                    new Color(.055f, .085f, .105f, .98f), out var image, out var label);
                buttonImages[i] = image;
                labels[i] = label;
            }

            screen.EditorConfigure(buttons, buttonImages, labels, pages, enterButton);
            for (var i = 0; i < pages.Length; i++)
                pages[i].SetActive(i == (int)MainHubScreen.MainTab.City);

            PrefabUtility.SaveAsPrefabAsset(root.gameObject, MainHubPath);
            UnityEngine.Object.DestroyImmediate(root.gameObject);
            return AssetDatabase.LoadAssetAtPath<GameObject>(MainHubPath);
        }

        private static GameObject ConfigurePreparationScreen()
        {
            var root = PrefabUtility.LoadPrefabContents(PreparationPath);
            try
            {
                var canvasGroup = root.GetComponent<CanvasGroup>();
                if (!canvasGroup)
                    canvasGroup = root.AddComponent<CanvasGroup>();
                canvasGroup.alpha = 1f;
                canvasGroup.interactable = true;
                canvasGroup.blocksRaycasts = true;

                var screen = root.GetComponent<PreparationUIScreen>();
                if (!screen)
                    screen = root.AddComponent<PreparationUIScreen>();
                var safeArea = FindDeep(root.transform, "SafeArea");
                var preparationRoot = FindDeep(root.transform, "PreparationRoot");
                if (!safeArea || !preparationRoot)
                    throw new InvalidOperationException("PreparationCanvas is missing SafeArea or PreparationRoot.");

                var existing = safeArea.Find("BackToHubButton");
                Button backButton;
                if (existing)
                {
                    backButton = existing.GetComponent<Button>();
                }
                else
                {
                    backButton = AddButton("BackToHubButton", safeArea, "返回主页",
                        new Color(.035f, .11f, .13f, .96f), out _, out _);
                    var rect = (RectTransform)backButton.transform;
                    rect.anchorMin = rect.anchorMax = new Vector2(0f, 0f);
                    rect.pivot = Vector2.zero;
                    rect.anchoredPosition = new Vector2(36f, 38f);
                    rect.sizeDelta = new Vector2(190f, 68f);
                    backButton.transform.SetAsLastSibling();
                }

                screen.EditorConfigure(preparationRoot.gameObject, backButton);
                PrefabUtility.SaveAsPrefabAsset(root, PreparationPath);
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }

            return AssetDatabase.LoadAssetAtPath<GameObject>(PreparationPath);
        }

        private static void BuildRoot(GameObject mainHub, GameObject scavengerDraft, GameObject preparation)
        {
            var root = NewRect("GameUIRoot", null);
            Stretch(root);
            var canvas = root.gameObject.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            canvas.sortingOrder = 0;
            var scaler = root.gameObject.AddComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 0f;
            root.gameObject.AddComponent<GraphicRaycaster>();

            var background = NewLayer("BackgroundLayer", root);
            var bg = background.gameObject.AddComponent<Image>();
            bg.color = Background;
            bg.raycastTarget = false;
            var screenLayer = NewLayer("ScreenLayer", root);
            var hud = NewLayer("HUDLayer", root);
            var drag = NewLayer("DragLayer", root);
            var effect = NewLayer("EffectLayer", root);
            var modal = NewLayer("ModalLayer", root);
            var system = NewLayer("SystemLayer", root);

            var modalBlocker = AddImage("ModalBlocker", modal, new Color(.005f, .012f, .018f, .78f));
            Stretch(modalBlocker.rectTransform);
            modalBlocker.raycastTarget = true;
            modalBlocker.gameObject.AddComponent<Button>().targetGraphic = modalBlocker;
            modalBlocker.gameObject.SetActive(false);

            var inputBlockerImage = AddImage("TransitionInputBlocker", system, new Color(0f, 0f, 0f, .001f));
            Stretch(inputBlockerImage.rectTransform);
            inputBlockerImage.raycastTarget = true;
            var inputBlocker = inputBlockerImage.gameObject.AddComponent<CanvasGroup>();
            inputBlocker.gameObject.SetActive(false);

            var router = root.gameObject.AddComponent<UIScreenRouter>();
            router.EditorConfigure(screenLayer, inputBlocker, UIScreenId.MainHub,
                new List<UIScreenRegistration>
                {
                    new() { Id = UIScreenId.MainHub, Prefab = mainHub, KeepAlive = true },
                    new() { Id = UIScreenId.ScavengerDraft, Prefab = scavengerDraft, KeepAlive = false },
                    new() { Id = UIScreenId.Preparation, Prefab = preparation, KeepAlive = true }
                });

            var popupService = root.gameObject.AddComponent<UIPopupService>();
            popupService.EditorConfigure(modalBlocker);
            var uiRoot = root.gameObject.AddComponent<GameUIRoot>();
            uiRoot.EditorConfigure(router, popupService, background, screenLayer, hud, drag, effect, modal, system);

            PrefabUtility.SaveAsPrefabAsset(root.gameObject, RootPath);
            UnityEngine.Object.DestroyImmediate(root.gameObject);
        }

        private static GameObject BuildScavengerDraft()
        {
            var root = NewRect("ScavengerDraftScreen", null);
            Stretch(root);
            root.gameObject.AddComponent<CanvasGroup>();
            var screen = root.gameObject.AddComponent<ScavengerDraftScreen>();
            var background = AddImage("Background", root, Background);
            Stretch(background.rectTransform);
            var safeArea = NewRect("SafeArea", root);
            Stretch(safeArea);
            safeArea.gameObject.AddComponent<SafeAreaFitter>();

            AddText("Title", safeArea, "选择拾荒者", 52, TextAnchor.MiddleLeft, PrimaryText,
                new Vector2(.055f, .915f), new Vector2(.72f, .98f));
            AddText("Subtitle", safeArea, "随机四维与成长 · 天赋槽2–6 · 6槽明确优于2槽", 25,
                TextAnchor.MiddleLeft, SecondaryText, new Vector2(.055f, .865f), new Vector2(.94f, .92f));

            var buttons = new Button[3];
            var frames = new Image[3];
            var names = new Text[3];
            var stats = new Text[3];
            var talents = new Text[3];
            for (var i = 0; i < 3; i++)
            {
                var yMax = .84f - i * .235f;
                var frame = AddImage($"Candidate_{i}", safeArea, PanelRaised);
                frame.raycastTarget = true;
                SetAnchors(frame.rectTransform, new Vector2(.055f, yMax - .205f),
                    new Vector2(.945f, yMax), Vector2.zero, Vector2.zero);
                var button = frame.gameObject.AddComponent<Button>();
                button.targetGraphic = frame;
                buttons[i] = button;
                frames[i] = frame;
                names[i] = AddText("Name", frame.transform, "拾荒者", 29, TextAnchor.MiddleLeft,
                    PrimaryText, new Vector2(.035f, .72f), new Vector2(.96f, .95f));
                stats[i] = AddText("Stats", frame.transform, "四维与成长", 21, TextAnchor.UpperLeft,
                    PrimaryText, new Vector2(.035f, .08f), new Vector2(.42f, .72f));
                talents[i] = AddText("Talents", frame.transform, "天赋", 20, TextAnchor.UpperLeft,
                    SecondaryText, new Vector2(.43f, .08f), new Vector2(.965f, .72f));
            }

            var summary = AddText("SelectionSummary", safeArea, "请选择一个拾荒者", 23,
                TextAnchor.MiddleCenter, Gold, new Vector2(.08f, .105f), new Vector2(.92f, .155f));
            var back = AddButton("BackButton", safeArea, "返回地图", PanelRaised, out _, out _);
            SetAnchors((RectTransform)back.transform, new Vector2(.055f, .025f), new Vector2(.34f, .095f),
                Vector2.zero, Vector2.zero);
            var confirm = AddButton("ConfirmButton", safeArea, "确认并进入探索", Accent, out _, out _);
            SetAnchors((RectTransform)confirm.transform, new Vector2(.40f, .025f), new Vector2(.945f, .095f),
                Vector2.zero, Vector2.zero);
            confirm.interactable = false;
            screen.EditorConfigure(buttons, frames, names, stats, talents, summary, confirm, back);

            PrefabUtility.SaveAsPrefabAsset(root.gameObject, ScavengerDraftPath);
            UnityEngine.Object.DestroyImmediate(root.gameObject);
            return AssetDatabase.LoadAssetAtPath<GameObject>(ScavengerDraftPath);
        }

        private static GameObject BuildPage(RectTransform parent, string name, string title,
            string subtitle, Color color)
        {
            var page = AddImage(name, parent, color);
            Stretch(page.rectTransform);
            AddText("Title", page.transform, title, 52, TextAnchor.MiddleLeft, PrimaryText,
                new Vector2(.055f, .86f), new Vector2(.7f, .97f));
            AddText("Subtitle", page.transform, subtitle, 25, TextAnchor.MiddleLeft, SecondaryText,
                new Vector2(.055f, .80f), new Vector2(.9f, .87f));
            return page.gameObject;
        }

        private static void BuildGachaContent(Transform page)
        {
            var banner = AddImage("FeaturedBanner", page, new Color(.22f, .10f, .28f, 1f));
            SetAnchors(banner.rectTransform, new Vector2(.055f, .35f), new Vector2(.945f, .77f), Vector2.zero, Vector2.zero);
            AddText("BannerTitle", banner.transform, "限定召唤", 48, TextAnchor.MiddleCenter, Gold,
                new Vector2(.05f, .45f), new Vector2(.95f, .80f));
            AddText("BannerInfo", banner.transform, "卡池占位 · 后续接入概率与保底系统", 24,
                TextAnchor.MiddleCenter, SecondaryText, new Vector2(.05f, .20f), new Vector2(.95f, .48f));
            var once = AddButton("DrawOnce", page, "召唤 1 次", PanelRaised, out _, out _);
            SetAnchors((RectTransform)once.transform, new Vector2(.08f, .15f), new Vector2(.47f, .27f), Vector2.zero, Vector2.zero);
            var ten = AddButton("DrawTen", page, "召唤 10 次", Accent, out _, out _);
            SetAnchors((RectTransform)ten.transform, new Vector2(.53f, .15f), new Vector2(.92f, .27f), Vector2.zero, Vector2.zero);
        }

        private static void BuildHeroContent(Transform page)
        {
            var grid = NewRect("HeroGrid", page);
            SetAnchors(grid, new Vector2(.055f, .15f), new Vector2(.945f, .76f), Vector2.zero, Vector2.zero);
            var layout = grid.gameObject.AddComponent<GridLayoutGroup>();
            layout.cellSize = new Vector2(280f, 260f);
            layout.spacing = new Vector2(22f, 22f);
            layout.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            layout.constraintCount = 3;
            var cards = new GameObject[6];
            var names = new Text[6];
            var details = new Text[6];
            for (var i = 0; i < 6; i++)
            {
                var card = AddImage($"Hero_{i:00}", grid, i == 0 ? Accent : PanelRaised);
                cards[i] = card.gameObject;
                names[i] = AddText("Name", card.transform, i == 0 ? "暂无历练拾荒者" : "空位", 24,
                    TextAnchor.MiddleCenter, PrimaryText, new Vector2(.05f, .54f), new Vector2(.95f, .94f));
                details[i] = AddText("Details", card.transform,
                    i == 0 ? "完成一次地图探索后显示" : string.Empty, 18,
                    TextAnchor.UpperCenter, SecondaryText, new Vector2(.06f, .08f), new Vector2(.94f, .55f));
            }
            var roster = grid.gameObject.AddComponent<ScavengerRosterView>();
            roster.EditorConfigure(cards, names, details);
        }

        private static void BuildCityContent(Transform page)
        {
            var core = AddImage("CityCore", page, new Color(.06f, .18f, .16f, 1f));
            SetAnchors(core.rectTransform, new Vector2(.22f, .40f), new Vector2(.78f, .76f), Vector2.zero, Vector2.zero);
            AddText("CoreTitle", core.transform, "主城核心", 48, TextAnchor.MiddleCenter, PrimaryText,
                new Vector2(.05f, .42f), new Vector2(.95f, .72f));
            AddText("CoreInfo", core.transform, "挂机收益  02:31:18", 25, TextAnchor.MiddleCenter, Gold,
                new Vector2(.05f, .23f), new Vector2(.95f, .45f));
            var labels = new[] { "任务", "商店", "养成" };
            for (var i = 0; i < labels.Length; i++)
            {
                var x0 = .055f + i * .305f;
                var tile = AddImage($"CityAction_{i}", page, PanelRaised);
                SetAnchors(tile.rectTransform, new Vector2(x0, .14f), new Vector2(x0 + .275f, .32f), Vector2.zero, Vector2.zero);
                AddText("Label", tile.transform, labels[i], 28, TextAnchor.MiddleCenter, PrimaryText,
                    new Vector2(.05f, .1f), new Vector2(.95f, .9f));
            }
        }

        private static Button BuildExploreContent(Transform page)
        {
            var map = AddImage("MapPreview", page, new Color(.07f, .18f, .13f, 1f));
            SetAnchors(map.rectTransform, new Vector2(.055f, .30f), new Vector2(.945f, .76f), Vector2.zero, Vector2.zero);
            AddText("MapName", map.transform, "灰烬边境 · 难度1", 50, TextAnchor.MiddleCenter, PrimaryText,
                new Vector2(.05f, .52f), new Vector2(.95f, .78f));
            AddText("MapInfo", map.transform, "7场战斗 · 3场精英 · 1名首领", 25,
                TextAnchor.MiddleCenter, SecondaryText, new Vector2(.05f, .30f), new Vector2(.95f, .52f));
            AddText("FlowHint", page, "选择地图 → 战前购买与布阵 → 自动战斗", 25,
                TextAnchor.MiddleCenter, SecondaryText, new Vector2(.08f, .20f), new Vector2(.92f, .28f));
            var enter = AddButton("EnterPreparationButton", page, "进入地图", Accent, out _, out _);
            SetAnchors((RectTransform)enter.transform, new Vector2(.27f, .075f), new Vector2(.73f, .18f), Vector2.zero, Vector2.zero);
            return enter;
        }

        private static void BuildCodexContent(Transform page)
        {
            AddText("Progress", page, "已发现  20 / 120", 34, TextAnchor.MiddleCenter, Gold,
                new Vector2(.15f, .68f), new Vector2(.85f, .78f));
            var labels = new[] { "卡牌", "英雄", "敌人", "组合" };
            for (var i = 0; i < labels.Length; i++)
            {
                var row = i / 2;
                var col = i % 2;
                var x0 = .07f + col * .46f;
                var y1 = .62f - row * .25f;
                var tile = AddImage($"Codex_{labels[i]}", page, PanelRaised);
                SetAnchors(tile.rectTransform, new Vector2(x0, y1 - .19f), new Vector2(x0 + .40f, y1), Vector2.zero, Vector2.zero);
                AddText("Label", tile.transform, labels[i], 30, TextAnchor.MiddleCenter, PrimaryText,
                    new Vector2(.05f, .1f), new Vector2(.95f, .9f));
            }
        }

        private static RectTransform NewLayer(string name, Transform parent)
        {
            var rect = NewRect(name, parent);
            Stretch(rect);
            return rect;
        }

        private static RectTransform NewRect(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rect = (RectTransform)go.transform;
            if (parent)
                rect.SetParent(parent, false);
            return rect;
        }

        private static Image AddImage(string name, Transform parent, Color color)
        {
            var rect = NewRect(name, parent);
            var image = rect.gameObject.AddComponent<Image>();
            image.color = color;
            image.raycastTarget = false;
            return image;
        }

        private static Text AddText(string name, Transform parent, string value, int size,
            TextAnchor alignment, Color color, Vector2 anchorMin, Vector2 anchorMax)
        {
            var rect = NewRect(name, parent);
            SetAnchors(rect, anchorMin, anchorMax, Vector2.zero, Vector2.zero);
            var text = rect.gameObject.AddComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.text = value;
            text.fontSize = size;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = 16;
            text.resizeTextMaxSize = size;
            text.alignment = alignment;
            text.color = color;
            text.raycastTarget = false;
            return text;
        }

        private static Button AddButton(string name, Transform parent, string value, Color color,
            out Image image, out Text label)
        {
            image = AddImage(name, parent, color);
            image.raycastTarget = true;
            var button = image.gameObject.AddComponent<Button>();
            button.targetGraphic = image;
            var colors = button.colors;
            colors.highlightedColor = Color.Lerp(color, Color.white, .12f);
            colors.pressedColor = Color.Lerp(color, Color.black, .16f);
            colors.selectedColor = colors.highlightedColor;
            button.colors = colors;
            label = AddText("Label", image.transform, value, 27, TextAnchor.MiddleCenter,
                PrimaryText, new Vector2(.05f, .08f), new Vector2(.95f, .92f));
            return button;
        }

        private static void Stretch(RectTransform rect)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
        }

        private static void SetAnchors(RectTransform rect, Vector2 min, Vector2 max,
            Vector2 offsetMin, Vector2 offsetMax)
        {
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = offsetMin;
            rect.offsetMax = offsetMax;
            rect.localScale = Vector3.one;
        }

        private static Transform FindDeep(Transform root, string objectName)
        {
            foreach (var child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == objectName)
                    return child;
            return null;
        }

        private static void EnsureFolder(string path)
        {
            if (AssetDatabase.IsValidFolder(path))
                return;
            var slash = path.LastIndexOf('/');
            var parent = path.Substring(0, slash);
            var name = path.Substring(slash + 1);
            EnsureFolder(parent);
            AssetDatabase.CreateFolder(parent, name);
        }
    }
}

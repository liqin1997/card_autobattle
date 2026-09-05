#if UNITY_EDITOR
using System.Linq;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;
using UnityEngine.UI;

namespace CardAutobattle.Editor
{
    public static class CommercialBattleV2Builder
    {
        private const string ScenePath = "Assets/Scenes/CommercialVerticalSlice.unity";
        private const string PrefabFolder = "Assets/Resources/Commercial/Prefabs";
        private static readonly Color Ink = new(.012f, .016f, .019f, 1f);
        private static readonly Color Panel = new(.035f, .045f, .047f, .96f);
        private static readonly Color PanelSoft = new(.06f, .065f, .06f, .82f);
        private static readonly Color Gold = new(.78f, .58f, .25f, 1f);
        private static readonly Color Cyan = new(.20f, .76f, .78f, 1f);
        private static readonly Color Red = new(.72f, .16f, .15f, 1f);
        private static readonly Color Muted = new(.60f, .62f, .58f, 1f);

        [MenuItem("Tools/Commercial/Rebuild Battle V2")]
        public static void Rebuild()
        {
            var scene = SceneManager.GetActiveScene().path == ScenePath
                ? SceneManager.GetActiveScene() : EditorSceneManager.OpenScene(ScenePath, OpenSceneMode.Single);
            var root = GameObject.Find("CommercialGameRoot");
            if (!root) throw new System.InvalidOperationException("CommercialGameRoot not found.");

            DestroyChild(root.transform, "BattlePresentationRoot");
            DestroyChild(root.transform, "NavigationCanvas");
            var presentation = BuildPresentation(root.transform);
            BuildNavigation(root.transform);
            WireWorldMapPreview(root, presentation);
            NormalizeCardPrefab();

            PrefabUtility.SaveAsPrefabAsset(presentation, $"{PrefabFolder}/PF_UI_BattlePresentation.prefab");
            PrefabUtility.SaveAsPrefabAsset(root, $"{PrefabFolder}/PF_CommercialGameRoot.prefab");
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh();
            Debug.Log("[BattleV2] Rebuilt arena combat UI, 270x160 cards, 282x172 slots, five-tab navigation.");
        }

        private static GameObject BuildPresentation(Transform parent)
        {
            var root = new GameObject("BattlePresentationRoot");
            root.transform.SetParent(parent, false);
            var cameraGo = new GameObject("BattleUICamera", typeof(Camera));
            cameraGo.transform.SetParent(root.transform, false);
            var camera = cameraGo.GetComponent<Camera>();
            cameraGo.transform.localPosition = new Vector3(0f, 0f, -10f);
            camera.clearFlags = CameraClearFlags.Depth;
            camera.orthographic = true;
            camera.orthographicSize = 5f;
            camera.depth = 40f;
            camera.cullingMask = (1 << LayerMask.NameToLayer("UI")) | 1;

            var worldStage = new GameObject("WorldBattleStage");
            worldStage.transform.SetParent(root.transform, false);
            var worldView = worldStage.AddComponent<CommercialWorldBattleView>();
            var worldSerialized = new SerializedObject(worldView);
            worldSerialized.FindProperty("battleCamera").objectReferenceValue = camera;
            worldSerialized.FindProperty("heroSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/superhero_melee_1.png");
            worldSerialized.FindProperty("minionSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/melee_9.png");
            worldSerialized.FindProperty("eliteSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/range_9.png");
            worldSerialized.FindProperty("bossSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/superhero_melee_3.png");
            worldSerialized.FindProperty("backgroundSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/road2.png");
            worldSerialized.FindProperty("sceneryLeftSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/building_4.png");
            worldSerialized.FindProperty("sceneryRightSprite").objectReferenceValue = AssetDatabase.LoadAssetAtPath<Sprite>("Assets/Art/TowerDefenseBattle/building_2.png");
            worldSerialized.ApplyModifiedPropertiesWithoutUndo();

            var canvasGo = new GameObject("BattleCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(root.transform, false);
            var canvas = canvasGo.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceCamera;
            canvas.worldCamera = camera;
            canvas.planeDistance = 5f;
            canvas.sortingOrder = 40;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080f, 1920f);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = .5f;

            var page = NewUI("BattlePageRoot", canvasGo.transform);
            var pageRect = (RectTransform)page.transform;
            pageRect.anchorMin = new Vector2(0f, .092f);
            pageRect.anchorMax = new Vector2(1f, .918f);
            pageRect.offsetMin = pageRect.offsetMax = Vector2.zero;
            AddImage(page, new Color(Ink.r, Ink.g, Ink.b, .14f), false);

            var staticLayer = CreateLayer(page.transform, "BattleStaticLayer", 41, true);
            AddImage(staticLayer.gameObject, new Color(.018f, .023f, .024f, .12f), false);
            BuildHeader(staticLayer.transform);
            BuildMapAndTask(staticLayer.transform);

            var arena = CreateLayer(page.transform, "BattleArenaLayer", 42, true);
            arena.gameObject.AddComponent<CommercialBattleArenaView>();
            BuildArena(arena.transform);

            var cardLayer = CreateLayer(page.transform, "BattleCardLayer", 43, true);
            BuildPlayerBoard(cardLayer.transform);

            CreateLayer(page.transform, "HealthLayer", 44, false);
            var projectile = CreateLayer(page.transform, "ProjectileLayer", 50, false);
            projectile.gameObject.AddComponent<CommercialProjectilePool>();
            var vfx = CreateLayer(page.transform, "VFXLayer", 60, false);
            vfx.gameObject.AddComponent<CommercialMeleeFxPool>();
            var worldVfxRoot = new GameObject("BattleWorldVFXRoot");
            worldVfxRoot.transform.SetParent(root.transform, false);
            var prefabVfx = worldVfxRoot.AddComponent<CommercialCombatPrefabVfxPool>();
            var prefabVfxSerialized = new SerializedObject(prefabVfx);
            prefabVfxSerialized.FindProperty("enemyProjectilePrefab").objectReferenceValue = AssetDatabase.LoadAssetAtPath<GameObject>(
                "Assets/VFX/feilongfx/FX/enemy_skill/CorruptedPaladin/Prefabs/Eff_CorruptedPaladin_SpearHead_Decay.prefab");
            prefabVfxSerialized.FindProperty("allyProjectilePrefab").objectReferenceValue = AssetDatabase.LoadAssetAtPath<GameObject>(
                "Assets/VFX/feilongfx/FX/enemy_skill/CorruptedPaladin/Prefabs/Eff_CorruptedPaladin_Spear_Glory.prefab");
            prefabVfxSerialized.FindProperty("allyMeleePrefab").objectReferenceValue = AssetDatabase.LoadAssetAtPath<GameObject>(
                "Assets/VFX/feilongfx/FX/enemy_skill/Aquaman_water_blade/prefab/aquaman_blade.prefab");
            prefabVfxSerialized.FindProperty("worldCamera").objectReferenceValue = camera;
            prefabVfxSerialized.ApplyModifiedPropertiesWithoutUndo();
            var damage = CreateLayer(page.transform, "DamageTextLayer", 70, false);
            damage.gameObject.AddComponent<CommercialFloatingTextPool>();
            CreateLayer(page.transform, "BattleDragLayer", 80, false);

            SetLayer(root.transform, LayerMask.NameToLayer("UI"));
            return root;
        }

        private static void BuildHeader(Transform parent)
        {
            var stage = AddTopRect(parent, "StageHeader", 292, 18, 496, 112);
            AddImage(stage.gameObject, new Color(.025f, .028f, .026f, .96f), true);
            AddText(stage, "LocationTitle", "灰烬森林 · 荒原营地", 36, Gold, TextAnchor.MiddleCenter,
                new Vector2(.04f, .44f), new Vector2(.96f, .96f), FontStyle.Bold);
            AddText(stage, "BattleStatus", "战斗中", 22, Cyan, TextAnchor.MiddleCenter,
                new Vector2(.22f, .06f), new Vector2(.78f, .45f), FontStyle.Bold);

            var boss = AddTopRect(parent, "EnemyBossBar", 300, 126, 480, 72);
            AddImage(boss.gameObject, new Color(.10f, .025f, .025f, .92f), false);
            AddText(boss, "EnemyTitle", "荒原冥主 · 夜枭", 24, new Color(1f, .66f, .35f), TextAnchor.MiddleCenter,
                new Vector2(0f, .52f), Vector2.one, FontStyle.Bold);
            var track = PanelRect(boss, "EnemyHpTrack", new Color(.16f, .035f, .035f, 1f), new Vector2(.04f, .08f), new Vector2(.96f, .39f));
            var fill = FullImage(track.transform, "EnemyHpFill", Red);
            fill.type = Image.Type.Filled; fill.fillMethod = Image.FillMethod.Horizontal; fill.fillAmount = .67f;
            AddText(track.transform, "LivingEnemyCount", "6 / 6", 18, Color.white, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, FontStyle.Bold);

            AddButton(parent, "SpeedButton", "×2 倍速", new Vector2(922, -250), new Vector2(136, 62));
            AddButton(parent, "AutoButton", "自动 ON", new Vector2(922, -320), new Vector2(136, 62));
            AddButton(parent, "PauseButton", "暂停", new Vector2(922, -390), new Vector2(136, 62));
        }

        private static void BuildMapAndTask(Transform parent)
        {
            var map = AddTopRect(parent, "WorldMapPreviewPanel", 24, 22, 250, 194);
            AddImage(map.gameObject, new Color(.09f, .075f, .055f, .96f), true);
            var preview = PanelRect(map, "WorldMapPreview", new Color(.18f, .14f, .08f, .95f), new Vector2(.035f, .08f), new Vector2(.965f, .98f));
            Object.DestroyImmediate(preview.GetComponent<Image>());
            var raw = preview.AddComponent<RawImage>(); raw.raycastTarget = false;
            AddText(preview.transform, "PreviewLocation", "幽冥荒原", 27, Color.white, TextAnchor.MiddleCenter,
                new Vector2(0f, .22f), Vector2.one, FontStyle.Bold);
            AddText(preview.transform, "PreviewHint", "点击前往大世界", 18, Gold, TextAnchor.MiddleCenter,
                Vector2.zero, new Vector2(1f, .30f), FontStyle.Bold);
            var open = map.gameObject.AddComponent<Button>(); open.targetGraphic = map.GetComponent<Image>();
            open.name = "OpenWorldMapButton";

            var task = AddTopRect(parent, "MainQuestPanel", 24, 226, 250, 174);
            AddImage(task.gameObject, new Color(.035f, .042f, .04f, .76f), true);
            task.gameObject.AddComponent<Button>().targetGraphic = task.GetComponent<Image>();
            AddText(task, "TaskCaption", "追踪任务", 20, Gold, TextAnchor.MiddleLeft,
                new Vector2(.07f, .70f), new Vector2(.93f, .96f), FontStyle.Bold);
            AddText(task, "MainQuestTitle", "调查荒原异变", 18, Color.white, TextAnchor.MiddleLeft,
                new Vector2(.07f, .38f), new Vector2(.93f, .70f), FontStyle.Bold);
            AddText(task, "MainQuestProgress", "击败夜枭  2 / 5", 16, Cyan, TextAnchor.MiddleLeft,
                new Vector2(.07f, .10f), new Vector2(.93f, .40f));
            AddText(task, "BattleResultHint", string.Empty, 13, Muted, TextAnchor.MiddleLeft,
                new Vector2(.07f, -.16f), new Vector2(.93f, .08f));
        }

        private static void BuildArena(Transform parent)
        {
            // All combatants live inside this viewport. It prevents entrance tweens or large
            // enemy groups from remaining under the map/task/control UI areas.
            var bounds = AddTopRect(parent, "CombatantBounds", 280, 205, 620, 745);
            bounds.gameObject.AddComponent<RectMask2D>();
            var enemyPositions = new[]
            {
                // Local positions inside the 620x745 combat viewport.
                new Vector2(310,-250), new Vector2(145,-300), new Vector2(475,-300), new Vector2(72,-430),
                new Vector2(220,-400), new Vector2(400,-400), new Vector2(548,-430), new Vector2(310,-305)
            };
            for (var i = 0; i < enemyPositions.Length; i++)
                CreateDisc(bounds, $"EnemyDisc_{i}", enemyPositions[i], i == 0 ? 230f : 144f, true);
            CreateDisc(bounds, "HeroDisc", new Vector2(310, -555), 220f, false);
            CreateDisc(bounds, "SummonDisc_0", new Vector2(145, -570), 108f, false);
            CreateDisc(bounds, "SummonDisc_1", new Vector2(475, -570), 108f, false);
            CreateDisc(bounds, "SummonDisc_2", new Vector2(310, -680), 108f, false);
        }

        private static void BuildPlayerBoard(Transform parent)
        {
            var board = AddTopRect(parent, "PlayerGrid", 85, 982, 910, 584);
            AddImage(board.gameObject, new Color(.012f, .026f, .027f, .94f), false);
            AddText(board, "PlayerRule", "战斗中拖拽换位 · 上下左右相邻生效", 18, Cyan, TextAnchor.MiddleCenter,
                new Vector2(.08f, .94f), new Vector2(.92f, .995f), FontStyle.Bold);
            var prefab = AssetDatabase.LoadAssetAtPath<GameObject>($"{PrefabFolder}/PF_Card_Battle.prefab");
            for (var i = 0; i < 9; i++)
            {
                var col = i % 3; var row = i / 3;
                var slot = NewUI($"CardSlot_{i}", board);
                var slotRect = (RectTransform)slot.transform;
                slotRect.anchorMin = slotRect.anchorMax = new Vector2(0f, 1f);
                slotRect.pivot = new Vector2(0f, 1f);
                slotRect.anchoredPosition = new Vector2(8 + col * 306, -34 - row * 184);
                slotRect.sizeDelta = new Vector2(282, 172);
                AddImage(slot, new Color(.12f, .105f, .075f, 1f), false);
                var card = (GameObject)PrefabUtility.InstantiatePrefab(prefab, slot.transform);
                card.name = $"PlayerCard_{i}";
                var rect = (RectTransform)card.transform;
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.pivot = new Vector2(.5f, .5f);
                rect.anchoredPosition = Vector2.zero;
                rect.sizeDelta = new Vector2(270, 160);
            }
        }

        private static void CreateDisc(Transform parent, string name, Vector2 topPosition, float size, bool enemy)
        {
            var root = NewUI(name, parent);
            var rect = (RectTransform)root.transform;
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f);
            rect.pivot = new Vector2(.5f, .5f);
            rect.anchoredPosition = topPosition;
            rect.sizeDelta = new Vector2(size, size);
            var baseImage = root.AddComponent<Image>();
            baseImage.sprite = BuiltinCircle(); baseImage.color = Color.clear;
            var button = root.AddComponent<Button>(); button.targetGraphic = baseImage;

            var hp = FullImage(root.transform, "HealthFill", enemy ? Red : Cyan);
            hp.type = Image.Type.Filled; hp.fillMethod = Image.FillMethod.Horizontal;
            hp.rectTransform.anchorMin = new Vector2(.08f, -.01f); hp.rectTransform.anchorMax = new Vector2(.92f, .055f);
            var shield = FullImage(root.transform, "ShieldFill", new Color(.18f, .66f, 1f, .82f));
            shield.type = Image.Type.Filled; shield.fillMethod = Image.FillMethod.Horizontal; shield.fillAmount = 0f;
            shield.rectTransform.anchorMin = new Vector2(.08f, .06f); shield.rectTransform.anchorMax = new Vector2(.92f, .095f);
            // RectMask2D only clips its children and never renders a mask graphic itself.
            // The previous Image + Mask setup occasionally drew the white mask over a disc.
            var portraitMask = PanelRect(root.transform, "PortraitMask", Color.clear,
                new Vector2(.10f, .10f), new Vector2(.90f, .90f));
            portraitMask.GetComponent<Image>().raycastTarget = false;
            var portraitObject = NewUI("Portrait", portraitMask.transform);
            Stretch((RectTransform)portraitObject.transform);
            var portrait = portraitObject.AddComponent<RawImage>();
            portrait.color = Color.white;
            portrait.raycastTarget = false;
            portrait.enabled = false;
            var hit = FullImage(portraitMask.transform, "HitFlash", new Color(1f, 1f, 1f, 0f));
            hit.sprite = BuiltinCircle(); hit.gameObject.SetActive(false);
            var select = FullImage(root.transform, "Selection", new Color(1f, .74f, .18f, .16f));
            select.sprite = BuiltinCircle(); select.rectTransform.anchorMin = new Vector2(-.05f, -.05f); select.rectTransform.anchorMax = new Vector2(1.05f, 1.05f); select.gameObject.SetActive(false);
            select.transform.SetAsFirstSibling();
            AddText(root.transform, "Title", enemy ? "敌人" : "主角", Mathf.RoundToInt(size * .105f), Color.white,
                TextAnchor.MiddleCenter, new Vector2(-.18f, .72f), new Vector2(1.18f, .99f), FontStyle.Bold);
            AddText(root.transform, "HiddenCards", enemy ? "卡组 1" : string.Empty, Mathf.RoundToInt(size * .08f), Gold,
                TextAnchor.MiddleCenter, new Vector2(.10f, .04f), new Vector2(.90f, .24f), FontStyle.Bold);
            AddText(root.transform, "HealthText", "100/100", Mathf.RoundToInt(size * .075f), Color.white,
                TextAnchor.MiddleCenter, new Vector2(-.08f, -.10f), new Vector2(1.08f, .10f), FontStyle.Bold);
            root.AddComponent<CommercialCombatantDiscView>();
        }

        private static void BuildNavigation(Transform parent)
        {
            var canvasGo = new GameObject("NavigationCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(parent, false);
            var canvas = canvasGo.GetComponent<Canvas>(); canvas.renderMode = RenderMode.ScreenSpaceOverlay; canvas.sortingOrder = 70;
            var scaler = canvasGo.GetComponent<CanvasScaler>(); scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920); scaler.matchWidthOrHeight = .5f;
            var bar = PanelRect(canvasGo.transform, "BottomNavigation", new Color(.018f, .024f, .025f, 1f), Vector2.zero, new Vector2(1f, .092f));
            var labels = new[] { "角色", "卡组", "探险", "背包", "商城" };
            var icons = new[] { "♜", "▤", "✦", "▣", "♛" };
            for (var i = 0; i < 5; i++)
            {
                var selected = i == 2;
                var button = AddButton(bar.transform, $"Nav_{i}", string.Empty,
                    new Vector2(i * 216 + 4, -8), new Vector2(208, 160));
                button.GetComponent<Image>().color = selected ? new Color(.27f, .20f, .08f, 1f) : new Color(.025f, .035f, .037f, 1f);
                AddText(button.transform, "Icon", icons[i], 42, selected ? Gold : Muted, TextAnchor.MiddleCenter,
                    new Vector2(0f, .34f), Vector2.one, FontStyle.Bold);
                AddText(button.transform, "Label", labels[i], 25, selected ? Gold : Muted, TextAnchor.MiddleCenter,
                    Vector2.zero, new Vector2(1f, .38f), FontStyle.Bold);
            }
            SetLayer(canvasGo.transform, LayerMask.NameToLayer("UI"));
        }

        private static void WireWorldMapPreview(GameObject root, GameObject presentation)
        {
            var map = root.GetComponent<CommercialWorldMapView>();
            if (!map) return;
            var preview = presentation.GetComponentsInChildren<RawImage>(true).FirstOrDefault(item => item.name == "WorldMapPreview");
            var open = presentation.GetComponentsInChildren<Button>(true).FirstOrDefault(item => item.name == "OpenWorldMapButton");
            var serialized = new SerializedObject(map);
            serialized.FindProperty("PreviewImage").objectReferenceValue = preview;
            serialized.FindProperty("OpenPreviewButton").objectReferenceValue = open;
            serialized.FindProperty("PreviewLocation").objectReferenceValue = FindText(presentation, "PreviewLocation");
            serialized.FindProperty("PreviewHint").objectReferenceValue = FindText(presentation, "PreviewHint");
            serialized.ApplyModifiedPropertiesWithoutUndo();
        }

        private static void NormalizeCardPrefab()
        {
            var path = $"{PrefabFolder}/PF_Card_Battle.prefab";
            var root = PrefabUtility.LoadPrefabContents(path);
            ((RectTransform)root.transform).sizeDelta = new Vector2(270, 160);
            PrefabUtility.SaveAsPrefabAsset(root, path);
            PrefabUtility.UnloadPrefabContents(root);
        }

        private static Canvas CreateLayer(Transform parent, string name, int order, bool raycaster)
        {
            var go = NewUI(name, parent);
            Stretch(go.transform as RectTransform);
            var canvas = go.AddComponent<Canvas>(); canvas.overrideSorting = true; canvas.sortingOrder = order;
            if (raycaster) go.AddComponent<GraphicRaycaster>();
            return canvas;
        }

        private static GameObject NewUI(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform)); go.transform.SetParent(parent, false); return go;
        }

        private static RectTransform AddTopRect(Transform parent, string name, float x, float y, float width, float height)
        {
            var go = NewUI(name, parent); var rect = (RectTransform)go.transform;
            rect.anchorMin = rect.anchorMax = new Vector2(0f, 1f); rect.pivot = new Vector2(0f, 1f);
            rect.anchoredPosition = new Vector2(x, -y); rect.sizeDelta = new Vector2(width, height); return rect;
        }

        private static GameObject PanelRect(Transform parent, string name, Color color, Vector2 min, Vector2 max)
        {
            var go = NewUI(name, parent); var rect = (RectTransform)go.transform;
            rect.anchorMin = min; rect.anchorMax = max; rect.offsetMin = rect.offsetMax = Vector2.zero;
            AddImage(go, color, false); return go;
        }

        private static Image FullImage(Transform parent, string name, Color color)
        {
            var go = NewUI(name, parent); Stretch((RectTransform)go.transform); return AddImage(go, color, false);
        }

        private static Image AddImage(GameObject go, Color color, bool raycast)
        {
            var image = go.GetComponent<Image>() ?? go.AddComponent<Image>(); image.color = color; image.raycastTarget = raycast; return image;
        }

        private static Text AddText(Transform parent, string name, string value, int size, Color color,
            TextAnchor align, Vector2 min, Vector2 max, FontStyle style = FontStyle.Normal)
        {
            var go = NewUI(name, parent); var rect = (RectTransform)go.transform; rect.anchorMin = min; rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero; var text = go.AddComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf"); text.text = value; text.fontSize = size;
            text.color = color; text.alignment = align; text.fontStyle = style; text.raycastTarget = false;
            text.resizeTextForBestFit = true; text.resizeTextMinSize = Mathf.Max(10, size / 2); text.resizeTextMaxSize = size;
            return text;
        }

        private static Button AddButton(Transform parent, string name, string label, Vector2 topLeft, Vector2 size)
        {
            var rect = AddTopRect(parent, name, topLeft.x, -topLeft.y, size.x, size.y);
            AddImage(rect.gameObject, new Color(.07f, .065f, .055f, .96f), true);
            var button = rect.gameObject.AddComponent<Button>(); button.targetGraphic = rect.GetComponent<Image>();
            if (!string.IsNullOrEmpty(label)) AddText(rect, "Label", label, 22, Color.white, TextAnchor.MiddleCenter, Vector2.zero, Vector2.one, FontStyle.Bold);
            return button;
        }

        private static Text FindText(GameObject root, string name) => root.GetComponentsInChildren<Text>(true).FirstOrDefault(item => item.name == name);
        private static Sprite BuiltinCircle() => AssetDatabase.GetBuiltinExtraResource<Sprite>("UI/Skin/Knob.psd");
        private static void Stretch(RectTransform rect) { rect.anchorMin = Vector2.zero; rect.anchorMax = Vector2.one; rect.offsetMin = rect.offsetMax = Vector2.zero; }
        private static void DestroyChild(Transform parent, string name) { var child = parent.Find(name); if (child) Object.DestroyImmediate(child.gameObject); }
        private static void SetLayer(Transform root, int layer) { foreach (var t in root.GetComponentsInChildren<Transform>(true)) t.gameObject.layer = layer; }
    }
}
#endif

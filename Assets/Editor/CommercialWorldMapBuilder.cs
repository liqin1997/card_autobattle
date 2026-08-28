using System;
using System.IO;
using System.Linq;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.Rendering.Universal;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class CommercialWorldMapBuilder
    {
        private const string Art = "Assets/FantasyMapCreator_2/";
        private const string Prefabs = "Assets/Resources/Commercial/Prefabs/";
        private static readonly Color Ink = new(.055f, .065f, .065f, .98f);
        private static readonly Color Gold = new(.86f, .69f, .36f, 1);
        private static Font font;
        private static Material spriteMaterial;
        private static int layer;

        [MenuItem("Tools/Card Autobattle/Install World Map Into Commercial Scene")]
        public static void InstallIntoScene()
        {
            if (Application.isPlaying) throw new InvalidOperationException("Exit Play Mode before installing the map.");
            var scene = UnityEngine.SceneManagement.SceneManager.GetActiveScene();
            if (scene.path != "Assets/Scenes/CommercialVerticalSlice.unity")
                throw new InvalidOperationException("Open CommercialVerticalSlice first. This operation does not replace another scene.");
            var root = GameObject.Find("CommercialGameRoot");
            if (!root) throw new InvalidOperationException("Commercial root missing.");
            Install(root);
            SavePrefabs(root);
            EditorSceneManager.MarkSceneDirty(scene);
            EditorSceneManager.SaveScene(scene);
            Debug.Log("[WorldMap] Installed map, fog, task/event UI and exploration preview. Existing card boards preserved.");
        }

        public static void Install(GameObject root)
        {
            if (root.GetComponent<CommercialWorldMapView>()) return; // Idempotent; never overwrite hand-edited map content.
            font = root.GetComponentsInChildren<Text>(true).FirstOrDefault()?.font ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            layer = LayerMask.NameToLayer("CommercialWorldMap");
            if (layer < 0)
            {
                var tags = new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/TagManager.asset")[0]);
                var layers = tags.FindProperty("layers");
                for (var i = 8; i < 32; i++) if (string.IsNullOrEmpty(layers.GetArrayElementAtIndex(i).stringValue))
                { layer = i; layers.GetArrayElementAtIndex(i).stringValue = "CommercialWorldMap"; break; }
                if (layer < 0) throw new InvalidOperationException("No free layer for world map camera isolation.");
                tags.ApplyModifiedProperties();
            }
            foreach (var cam in root.GetComponentsInChildren<Camera>(true)) cam.cullingMask &= ~(1 << layer);
            const string matPath = "Assets/Resources/Commercial/WorldMapSprite.mat";
            spriteMaterial = AssetDatabase.LoadAssetAtPath<Material>(matPath);
            if (!spriteMaterial)
            {
                spriteMaterial = new Material(Shader.Find("Universal Render Pipeline/2D/Sprite-Unlit-Default"));
                AssetDatabase.CreateAsset(spriteMaterial, matPath);
            }
            var view = Undo.AddComponent<CommercialWorldMapView>(root);
            var world = new GameObject("WorldMapSceneRoot");
            Undo.RegisterCreatedObjectUndo(world, "Install world map");
            world.transform.SetParent(root.transform, false);
            world.transform.localPosition = new Vector3(2000, 2000, 0);
            view.MapRoot = world.transform;
            var terrain = Group(world.transform, "01_TerrainLayer");
            var scenery = Group(world.transform, "02_SceneryLayer");
            var buildings = Group(world.transform, "03_BuildingsLayer");
            var objects = Group(world.transform, "04_ObjectsLayer");
            Sprite(terrain, "Ocean", "1_Backgrounds/Background_Water.png", Vector2.zero, new Vector2(54, 64), 0);
            Sprite(terrain, "Continent", "1_Backgrounds/Continent_Gigantic_Custom.png", Vector2.zero, new Vector2(54, 64), 1);
            var trees = new[] { "Dark_forest_little", "Leaf_forest_middle", "Palm_Jungle_little", "SnowSpruce_forest_little", "Dark_trees" };
            var castles = new[] { "Village_1", "Town_2", "Desert_temple", "Town_1_Snow", "Evil_Castle" };
            var mountains = new[] { "Mountain_Big_0", "Mountain_Big_1", "Mountain_2", "SnowMountain_Big_0", "DarkMountain_Big_1" };
            for (var c = 0; c < 5; c++)
            {
                var p = CommercialWorldCatalog.RegionCenters[c];
                var biome = new[] { "Earth_green", "Earth_green", "Earth_sand", "Earth_Snow", "Earth_dark" }[c];
                Sprite(terrain, "Biome_" + c, "2_Trees_Mountains/" + biome + ".png", p, new Vector2(17, 16), 2 + c);
                Sprite(buildings, "Region_" + (c + 1), "3_Buildings/" + castles[c] + ".png", p, new Vector2(4, 3.5f), 30);
                for (var i = 0; i < 7; i++)
                {
                    var angle = i * 360f / 7 * Mathf.Deg2Rad;
                    var offset = new Vector2(Mathf.Cos(angle) * 5.4f, Mathf.Sin(angle) * 4.5f);
                    Sprite(scenery, "Forest_" + c + "_" + i, "2_Trees_Mountains/" + trees[c] + ".png", p + offset, new Vector2(3.3f, 3), 10 + i);
                }
                Sprite(scenery, "Ridge_" + c, "2_Trees_Mountains/" + mountains[c] + ".png", p + new Vector2(-6, 5), new Vector2(5, 4), 20);
                Sprite(objects, "QuestCamp_" + c, "4_Objects/Camp.png", p + new Vector2(-3, -3), new Vector2(2, 1.5f), 40);
                Sprite(objects, "Elite_" + c, "4_Objects/Monsters_Ogres.png", p + new Vector2(3, -2), new Vector2(2, 2), 41);
                Sprite(objects, "Boss_" + c, "4_Objects/" + (c == 3 ? "Monsters_Yeti" : "Monsters_Dragon") + ".png", p + new Vector2(2, 4), new Vector2(3, 2.5f), 42);
                Sprite(objects, "Treasure_" + c, "4_Objects/Treasures.png", p + new Vector2(-3.5f, 3), new Vector2(1.5f, 1.5f), 43);
            }
            var fog = new GameObject("05_FogLayer", typeof(SpriteRenderer));
            fog.transform.SetParent(world.transform, false); fog.layer = layer;
            view.FogRenderer = fog.GetComponent<SpriteRenderer>();
            view.FogRenderer.sharedMaterial = spriteMaterial; view.FogRenderer.sortingOrder = 100;
            var cameraGo = new GameObject("WorldMapCamera", typeof(Camera), typeof(UniversalAdditionalCameraData));
            cameraGo.transform.SetParent(root.transform, false);
            var camera = cameraGo.GetComponent<Camera>();
            camera.orthographic = true; camera.orthographicSize = 14; camera.cullingMask = 1 << layer;
            camera.nearClipPlane = .1f; camera.farClipPlane = 50;
            camera.clearFlags = CameraClearFlags.SolidColor; camera.backgroundColor = new Color(.08f, .1f, .13f);
            camera.allowHDR = false; camera.allowMSAA = false; camera.enabled = false; camera.depth = -10;
            var urp = cameraGo.GetComponent<UniversalAdditionalCameraData>();
            urp.renderPostProcessing = false; urp.renderShadows = false;
            urp.requiresColorOption = CameraOverrideOption.Off; urp.requiresDepthOption = CameraOverrideOption.Off;
            view.MapCamera = camera;

            var canvasGo = new GameObject("WorldMapCanvas", typeof(RectTransform), typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvasGo.transform.SetParent(root.transform, false);
            canvasGo.GetComponent<Canvas>().renderMode = RenderMode.ScreenSpaceOverlay;
            canvasGo.GetComponent<Canvas>().sortingOrder = 90;
            var scaler = canvasGo.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize; scaler.referenceResolution = new Vector2(1080, 1920); scaler.matchWidthOrHeight = .5f;
            var page = Rect(canvasGo.transform, "Page_WorldMap", Vector2.zero, Vector2.one);
            Panel(page, Ink); view.FullPage = page.gameObject;
            var safe = Rect(page, "WorldMapSafeArea", Vector2.zero, Vector2.one);
            safe.gameObject.AddComponent<CommercialWorldMapSafeArea>();
            var viewport = Rect(safe, "MapViewport", new Vector2(0, .12f), new Vector2(1, .91f));
            view.FullImage = viewport.gameObject.AddComponent<RawImage>();
            view.FullImage.color = Color.white;
            view.MarkerLayer = Rect(viewport, "06_EventButtonLayer", Vector2.zero, Vector2.one);
            view.MarkerLayer.gameObject.AddComponent<RectMask2D>();
            var marker = Button(view.MarkerLayer, "EventTemplate", "事件", Vector2.zero, Vector2.zero);
            var mr = (RectTransform)marker.transform; mr.anchorMin = mr.anchorMax = mr.pivot = new Vector2(.5f, .5f); mr.sizeDelta = new Vector2(90, 90);
            var ml = marker.GetComponentInChildren<Text>(); ml.rectTransform.anchorMin = new Vector2(-.6f, -.46f); ml.rectTransform.anchorMax = new Vector2(1.6f, .06f);
            ml.fontSize = 25; ml.color = new Color(1, .9f, .6f); ml.gameObject.AddComponent<Outline>().effectDistance = new Vector2(2, -2);
            marker.image.preserveAspect = true; view.MarkerTemplate = marker;
            view.EventIcons = new[] { "Icon_Camp", "Icon_Quest", "Icon_fight", "Icon_Skull", "Icon_Chest" }.Select(n => Load("5_Icons_Ornaments/" + n + ".png")).ToArray();
            view.Header = Label(safe, "WorldMapTitle", "世界探索", 34, new Vector2(.04f, .945f), new Vector2(.76f, .99f));
            view.Status = Label(safe, "WorldMapStatus", "拖动地图 · 缩放 · 探索", 23, new Vector2(.04f, .91f), new Vector2(.96f, .945f));
            view.BackButton = Button(safe, "ReturnFromWorld", "返回", new Vector2(.79f, .948f), new Vector2(.96f, .989f));
            var controls = Rect(safe, "MapControls", new Vector2(.03f, .019f), new Vector2(.97f, .117f));
            view.LocateButton = Button(controls, "LocatePlayer", "定位", new Vector2(0, .56f), new Vector2(.20f, 1));
            view.RevealButton = Button(controls, "RevealRegion", "探索区域", new Vector2(.22f, .56f), new Vector2(.50f, 1));
            view.QuestButton = Button(controls, "OpenQuestList", "任务日志", new Vector2(.52f, .56f), new Vector2(.80f, 1));
            Label(controls, "ZoomLabel", "远近", 26, new Vector2(0, .01f), new Vector2(.15f, .45f));
            var sliderRoot = Rect(controls, "MapZoomSlider", new Vector2(.18f, .08f), new Vector2(.97f, .43f));
            var slider = sliderRoot.gameObject.AddComponent<Slider>(); view.ZoomSlider = slider;
            var track = Rect(sliderRoot, "Track", new Vector2(0, .40f), new Vector2(1, .60f)); Panel(track, new Color(.25f, .25f, .22f));
            var handleArea = Rect(sliderRoot, "HandleArea", Vector2.zero, Vector2.one);
            var handle = Rect(handleArea, "Handle", new Vector2(.5f, 0), new Vector2(.5f, 1)); handle.sizeDelta = new Vector2(42, 0); Panel(handle, Gold);
            slider.handleRect = handle; slider.targetGraphic = handle.GetComponent<Image>(); slider.direction = Slider.Direction.LeftToRight;
            var taskOverlay = Rect(safe, "TaskLog", new Vector2(.025f, .125f), new Vector2(.975f, .39f));
            view.MainQuestRow = Button(taskOverlay, "MainTask", "主线 · 世界探索", Vector2.zero, new Vector2(1, .16f));
            view.QuestRows = new Button[5];
            for (var i = 0; i < 5; i++)
                view.QuestRows[i] = Button(taskOverlay, "SideTask_" + i, "支线", new Vector2(0, .18f + i * .16f), new Vector2(1, .32f + i * .16f));
            var detail = Rect(safe, "WorldEventDetail", new Vector2(.025f, .127f), new Vector2(.975f, .39f));
            Panel(detail, Ink); view.DetailPanel = detail.gameObject;
            view.DetailTitle = Label(detail, "EventTitle", "事件", 30, new Vector2(.04f, .79f), new Vector2(.80f, .98f));
            var close = Button(detail, "CloseWorldDetail", "×", new Vector2(.86f, .82f), new Vector2(.98f, .98f));
            UnityEditor.Events.UnityEventTools.AddBoolPersistentListener(close.onClick, detail.gameObject.SetActive, false);
            view.DetailBody = Label(detail, "EventDescription", "说明", 26, new Vector2(.04f, .28f), new Vector2(.96f, .79f));
            view.DetailBody.alignment = TextAnchor.UpperLeft;
            view.ActionButton = Button(detail, "WorldEventAction", "立即前往", new Vector2(.04f, .035f), new Vector2(.69f, .23f));
            view.ActionButton.image.color = new Color(.38f, .29f, .12f); view.ActionLabel = view.ActionButton.GetComponentInChildren<Text>();
            view.TrackButton = Button(detail, "WorldTrackTask", "追踪", new Vector2(.72f, .035f), new Vector2(.96f, .23f));

            var timeline = CommercialPrototypeController.FindDeep(root.transform, "BattleTimeline");
            if (!timeline) throw new InvalidOperationException("BattleTimeline missing.");
            var preview = Rect(timeline, "WorldMapPreview", new Vector2(0, .29f), Vector2.one);
            preview.SetAsFirstSibling(); view.PreviewImage = preview.gameObject.AddComponent<RawImage>();
            view.OpenPreviewButton = preview.gameObject.AddComponent<Button>(); view.OpenPreviewButton.targetGraphic = view.PreviewImage;
            var shade = Rect(preview, "PreviewTitleShade", new Vector2(0, .70f), Vector2.one); Panel(shade, new Color(.015f, .02f, .025f, .80f), false);
            var footer = Rect(preview, "PreviewFooterShade", Vector2.zero, new Vector2(1, .22f)); Panel(footer, new Color(.015f, .02f, .025f, .70f), false);
            view.PreviewHint = Label(preview, "GoWorldMapLabel", "前往大地图  ›", 24, new Vector2(.59f, 0), new Vector2(.98f, .23f));
            view.PreviewHint.alignment = TextAnchor.MiddleRight; view.PreviewHint.color = Gold;
            var markerCurrent = Label(preview, "CurrentPositionMarker", "◆", 32, new Vector2(.44f, .22f), new Vector2(.56f, .70f));
            markerCurrent.alignment = TextAnchor.MiddleCenter; markerCurrent.color = Gold;
            view.PreviewLocation = CommercialPrototypeController.FindDeep(timeline, "LocationTitle").GetComponent<Text>();
            Fit(view.PreviewLocation.rectTransform, new Vector2(.035f, .79f), new Vector2(.96f, .99f)); view.PreviewLocation.fontSize = 28;
            view.PreviewLocation.alignment = TextAnchor.MiddleLeft;
            var idleText = CommercialPrototypeController.FindDeep(timeline, "IdleExperience").GetComponent<Text>();
            Fit(idleText.rectTransform, new Vector2(.03f, .30f), new Vector2(.57f, .45f)); idleText.fontSize = 22; idleText.text = "挂机 · 战斗胜利获取经验";
            var weather = CommercialPrototypeController.FindDeep(timeline, "WeatherText"); weather.gameObject.SetActive(false);
            var timer = CommercialPrototypeController.FindDeep(timeline, "BattleTimer"); if (timer) timer.gameObject.SetActive(false);
            var next = CommercialPrototypeController.FindDeep(timeline, "NextAction"); if (next) next.gameObject.SetActive(false);
            var clock = CommercialPrototypeController.FindDeep(timeline, "TimelineClock"); if (clock) clock.gameObject.SetActive(false);
            var city = CommercialPrototypeController.FindDeep(root.transform, "Page_City");
            view.OpenCityButton = Button(city, "CityWorldMapButton", "世界地图\n探索区域 · 接取任务 · 挑战首领", new Vector2(.06f, .52f), new Vector2(.94f, .69f));
            view.OpenCityButton.image.color = new Color(.20f, .21f, .14f);
            var cityIcon = Rect(view.OpenCityButton.transform, "MapIcon", new Vector2(.035f, .20f), new Vector2(.19f, .80f));
            var icon = cityIcon.gameObject.AddComponent<Image>(); icon.sprite = Load("5_Icons_Ornaments/Compass.png"); icon.preserveAspect = true; icon.raycastTarget = false;
            view.FullPage.SetActive(false);
            EditorUtility.SetDirty(view);
        }

        public static void SavePrefabs(GameObject root)
        {
            foreach (var pair in new[] { ("WorldMapSceneRoot", "PF_WorldMap_SpriteWorld"), ("Page_WorldMap", "PF_Screen_WorldMap"),
                         ("WorldMapPreview", "PF_WorldMap_ExplorePreview"), ("Page_City", "PF_Screen_City"),
                         ("BattlePresentationRoot", "PF_UI_BattlePresentation") })
            {
                var t = CommercialPrototypeController.FindDeep(root.transform, pair.Item1);
                if (t) PrefabUtility.SaveAsPrefabAsset(t.gameObject, Prefabs + pair.Item2 + ".prefab");
            }
            PrefabUtility.SaveAsPrefabAsset(root, Prefabs + "PF_CommercialGameRoot.prefab");
        }
        private static Transform Group(Transform parent, string name)
        { var go = new GameObject(name); go.transform.SetParent(parent, false); go.layer = layer; return go.transform; }
        private static Sprite Load(string path) => AssetDatabase.LoadAssetAtPath<Sprite>(Art + path) ?? throw new InvalidOperationException("Map sprite missing: " + path);
        private static void Sprite(Transform parent, string name, string path, Vector2 position, Vector2 size, int order)
        {
            var go = new GameObject(name, typeof(SpriteRenderer)); go.transform.SetParent(parent, false); go.layer = layer;
            go.transform.localPosition = position;
            var r = go.GetComponent<SpriteRenderer>(); r.sprite = Load(path); r.sharedMaterial = spriteMaterial; r.sortingOrder = order;
            go.transform.localScale = new Vector3(size.x / r.sprite.bounds.size.x, size.y / r.sprite.bounds.size.y, 1);
        }
        private static RectTransform Rect(Transform parent, string name, Vector2 min, Vector2 max)
        {
            var go = new GameObject(name, typeof(RectTransform)); go.layer = LayerMask.NameToLayer("UI");
            var r = (RectTransform)go.transform; r.SetParent(parent, false); Fit(r, min, max); return r;
        }
        private static void Fit(RectTransform rect, Vector2 min, Vector2 max)
        { rect.anchorMin = min; rect.anchorMax = max; rect.offsetMin = rect.offsetMax = Vector2.zero; }
        private static void Panel(RectTransform rect, Color color, bool raycast = true)
        { var i = rect.gameObject.AddComponent<Image>(); i.color = color; i.raycastTarget = raycast; }
        private static Text Label(Transform parent, string name, string value, int size, Vector2 min, Vector2 max)
        {
            var r = Rect(parent, name, min, max); var t = r.gameObject.AddComponent<Text>(); t.font = font; t.fontSize = size;
            t.text = value; t.color = new Color(.9f, .87f, .77f); t.alignment = TextAnchor.MiddleLeft; t.raycastTarget = false;
            return t;
        }
        private static Button Button(Transform parent, string name, string value, Vector2 min, Vector2 max)
        {
            var r = Rect(parent, name, min, max); Panel(r, Ink); var b = r.gameObject.AddComponent<Button>(); b.targetGraphic = r.GetComponent<Image>();
            var t = Label(r, "Label", value, 28, new Vector2(.03f, .03f), new Vector2(.97f, .97f)); t.alignment = TextAnchor.MiddleCenter;
            return b;
        }
    }
}

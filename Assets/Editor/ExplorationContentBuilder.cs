using CardAutobattle.Exploration;
using CardAutobattle.UI;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class ExplorationContentBuilder
    {
        private const string EventFolder = "Assets/Resources/UI/Events";
        private const string PreparationPath = "Assets/Prefab/UI/Preparation/PreparationCanvas.prefab";

        private static readonly Color Background = new(.012f, .024f, .032f, .94f);
        private static readonly Color Panel = new(.035f, .060f, .075f, 1f);
        private static readonly Color Choice = new(.060f, .100f, .120f, 1f);
        private static readonly Color Primary = new(.93f, .97f, .98f, 1f);
        private static readonly Color Secondary = new(.62f, .73f, .78f, 1f);

        [MenuItem("Tools/Card Autobattle/Build Exploration Content")]
        public static void Build()
        {
            EnsureFolder("Assets/Resources");
            EnsureFolder("Assets/Resources/UI");
            EnsureFolder(EventFolder);

            BuildChoicePrefab("CardWorkshopEvent", new Color(.95f, .48f, .16f));
            BuildChoicePrefab("WastelandCampEvent", new Color(.20f, .82f, .58f));
            BuildChoicePrefab("TacticalProtocolEvent", new Color(.18f, .72f, 1f));
            BuildChoicePrefab("RuinsExplorationEvent", new Color(.72f, .50f, .94f));
            BuildChoicePrefab("EquipmentCacheEvent", new Color(1f, .76f, .22f));
            BuildCompletePrefab();
            ConfigurePreparationPrefab();

            AssetDatabase.SaveAssets();
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            Debug.Log("[Exploration] Built five event prefabs, completion prefab and preparation runtime binding.");
        }

        private static void BuildChoicePrefab(string name, Color accentColor)
        {
            var root = NewRect(name, null);
            Stretch(root);
            var blocker = root.gameObject.AddComponent<Image>();
            blocker.color = Background;
            blocker.raycastTarget = true;
            root.gameObject.AddComponent<CanvasGroup>();
            var view = root.gameObject.AddComponent<ExplorationChoiceEventView>();

            var panel = AddImage("EventPanel", root, Panel);
            SetAnchors(panel.rectTransform, new Vector2(.055f, .14f), new Vector2(.945f, .86f));

            var accent = AddImage("AccentBar", panel.transform, accentColor);
            SetAnchors(accent.rectTransform, new Vector2(0f, .965f), Vector2.one);

            var title = AddText("Title", panel.transform, "探索事件", 48, TextAnchor.MiddleCenter, Primary);
            SetAnchors(title.rectTransform, new Vector2(.055f, .86f), new Vector2(.945f, .955f));
            var description = AddText("Description", panel.transform, "从三个选项中选择一个。", 26,
                TextAnchor.MiddleCenter, Secondary);
            SetAnchors(description.rectTransform, new Vector2(.07f, .785f), new Vector2(.93f, .865f));

            var buttons = new Button[3];
            var choiceTitles = new Text[3];
            var choiceDescriptions = new Text[3];
            for (var i = 0; i < 3; i++)
            {
                var yMax = .75f - i * .225f;
                var image = AddImage($"Choice_{i}", panel.transform, Choice);
                image.raycastTarget = true;
                SetAnchors(image.rectTransform, new Vector2(.065f, yMax - .19f), new Vector2(.935f, yMax));
                var button = image.gameObject.AddComponent<Button>();
                button.targetGraphic = image;
                var colors = button.colors;
                colors.highlightedColor = Color.Lerp(Choice, accentColor, .22f);
                colors.pressedColor = Color.Lerp(Choice, Color.black, .18f);
                colors.selectedColor = colors.highlightedColor;
                button.colors = colors;
                buttons[i] = button;

                choiceTitles[i] = AddText("ChoiceTitle", image.transform, $"选项 {i + 1}", 32,
                    TextAnchor.MiddleLeft, Primary);
                SetAnchors(choiceTitles[i].rectTransform, new Vector2(.055f, .55f), new Vector2(.945f, .9f));
                choiceDescriptions[i] = AddText("ChoiceDescription", image.transform, "效果说明", 24,
                    TextAnchor.UpperLeft, Secondary);
                SetAnchors(choiceDescriptions[i].rectTransform, new Vector2(.055f, .12f), new Vector2(.945f, .57f));
            }

            var footer = AddText("Footer", panel.transform, "选择后立即生效", 21,
                TextAnchor.MiddleCenter, Secondary);
            SetAnchors(footer.rectTransform, new Vector2(.08f, .025f), new Vector2(.92f, .085f));
            view.EditorConfigure(accent, title, description, buttons, choiceTitles, choiceDescriptions, footer);

            PrefabUtility.SaveAsPrefabAsset(root.gameObject, $"{EventFolder}/{name}.prefab");
            Object.DestroyImmediate(root.gameObject);
        }

        private static void BuildCompletePrefab()
        {
            var root = NewRect("ExplorationComplete", null);
            Stretch(root);
            var blocker = root.gameObject.AddComponent<Image>();
            blocker.color = Background;
            blocker.raycastTarget = true;
            root.gameObject.AddComponent<CanvasGroup>();
            var view = root.gameObject.AddComponent<ExplorationCompleteView>();

            var panel = AddImage("CompletePanel", root, Panel);
            SetAnchors(panel.rectTransform, new Vector2(.10f, .27f), new Vector2(.90f, .73f));
            var accent = AddImage("AccentBar", panel.transform, new Color(.22f, 1f, .68f));
            SetAnchors(accent.rectTransform, new Vector2(0f, .965f), Vector2.one);
            var title = AddText("Title", panel.transform, "探索完成", 54, TextAnchor.MiddleCenter, Primary);
            SetAnchors(title.rectTransform, new Vector2(.06f, .76f), new Vector2(.94f, .93f));
            var summary = AddText("Summary", panel.transform, "结算信息", 29, TextAnchor.MiddleCenter, Secondary);
            SetAnchors(summary.rectTransform, new Vector2(.08f, .30f), new Vector2(.92f, .76f));
            var buttonImage = AddImage("ReturnButton", panel.transform, new Color(.10f, .72f, .60f));
            buttonImage.raycastTarget = true;
            SetAnchors(buttonImage.rectTransform, new Vector2(.24f, .09f), new Vector2(.76f, .25f));
            var button = buttonImage.gameObject.AddComponent<Button>();
            button.targetGraphic = buttonImage;
            var buttonText = AddText("Label", buttonImage.transform, "返回主城", 31, TextAnchor.MiddleCenter, Primary);
            Stretch(buttonText.rectTransform);
            view.EditorConfigure(title, summary, button);

            PrefabUtility.SaveAsPrefabAsset(root.gameObject, $"{EventFolder}/ExplorationComplete.prefab");
            Object.DestroyImmediate(root.gameObject);
        }

        private static void ConfigurePreparationPrefab()
        {
            var root = PrefabUtility.LoadPrefabContents(PreparationPath);
            try
            {
                var safeArea = FindDeep(root.transform, "SafeArea");
                if (!safeArea)
                {
                    Debug.LogError("[Exploration] PreparationCanvas has no SafeArea.");
                    return;
                }
                if (!safeArea.GetComponent<ExplorationSessionController>())
                    safeArea.gameObject.AddComponent<ExplorationSessionController>();
                PrefabUtility.SaveAsPrefabAsset(root, PreparationPath);
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static RectTransform NewRect(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rect = (RectTransform)go.transform;
            if (parent) rect.SetParent(parent, false);
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
            TextAnchor alignment, Color color)
        {
            var rect = NewRect(name, parent);
            var text = rect.gameObject.AddComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.text = value;
            text.fontSize = size;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = 15;
            text.resizeTextMaxSize = size;
            text.alignment = alignment;
            text.color = color;
            text.raycastTarget = false;
            return text;
        }

        private static void SetAnchors(RectTransform rect, Vector2 min, Vector2 max)
        {
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            rect.localScale = Vector3.one;
        }

        private static void Stretch(RectTransform rect)
        {
            SetAnchors(rect, Vector2.zero, Vector2.one);
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

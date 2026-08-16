using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using CardAutobattle.Prototype;
using UnityEditor;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class CardVisualRepairTool
    {
        private const string ThemePath = "Assets/Resources/CardVisualTheme.asset";
        private const string PrefabPath = "Assets/Prefab/UI/VisualCard.prefab";
        private const string SweepMaterialPath = "Assets/Resources/CardCooldownSweep.mat";
        private const string QualityMaterialPath = "Assets/Resources/CardQualityFrame.mat";
        private const string PackedNoisePath = "Assets/Art/VFX/CardCooldownPackedNoise.asset";

        [MenuItem("Tools/Card Autobattle/Repair Card Visual")]
        public static void Repair()
        {
            var backup = RebuildTheme();
            RepairPrefab();
            AssetDatabase.SaveAssets();
            AssetDatabase.ImportAsset(ThemePath, ImportAssetOptions.ForceSynchronousImport);
            AssetDatabase.ImportAsset(PrefabPath, ImportAssetOptions.ForceSynchronousImport);

            var theme = AssetDatabase.LoadAssetAtPath<CardVisualTheme>(ThemePath);
            if (!theme)
                throw new InvalidOperationException("CardVisualTheme could not be loaded after repair.");

            var distinct = PrototypeCardCatalog.All
                .Select(definition => theme.GetArtwork(definition.Id))
                .Where(sprite => sprite)
                .Distinct()
                .Count();
            Debug.Log($"[CardVisualRepair] Complete. Cards={PrototypeCardCatalog.All.Count}, " +
                      $"distinct artwork={distinct}, backup={backup ?? "not needed"}.");
        }

        private static string RebuildTheme()
        {
            if (!AssetDatabase.IsValidFolder("Assets/EditorBackup"))
                AssetDatabase.CreateFolder("Assets", "EditorBackup");

            var theme = AssetDatabase.LoadAssetAtPath<CardVisualTheme>(ThemePath);
            string backup = null;
            if (!theme && !string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(ThemePath)))
            {
                backup = AssetDatabase.GenerateUniqueAssetPath(
                    "Assets/EditorBackup/CardVisualTheme.rollback-backup.asset");
                var moveError = AssetDatabase.MoveAsset(ThemePath, backup);
                if (!string.IsNullOrEmpty(moveError))
                    MoveBrokenAssetAsFiles(ThemePath, backup);
            }

            var ids = new[]
            {
                "blade", "dagger", "hammer", "bow", "shield", "armor", "potion", "herbs",
                "fire", "poison", "frost", "drum", "hourglass", "banner", "battery", "thorns",
                "vampire", "spark", "coin", "core"
            };
            var buffs = new[] { 72, 73, 90, 78, 80, 49, 43, 56, 53, 46, 48, 54, 52, 50, 71, 57, 45, 62, 42, 61 };
            var scales = new[]
            {
                1.08f, .94f, 1.02f, .94f, 1.02f, 1.12f, .94f, 1.02f, 1.02f, .96f,
                1.12f, .94f, .96f, 1.04f, .94f, .94f, 1.04f, .92f, 1.02f, .92f
            };

            var artwork = new List<CardArtEntry>(ids.Length);
            for (var index = 0; index < ids.Length; index++)
            {
                artwork.Add(new CardArtEntry
                {
                    CardId = ids[index],
                    Artwork = LoadSprite($"Assets/Sprite/card/card_icon/ArtifactName_Buff{buffs[index]}.png"),
                    Scale = scales[index],
                    Offset = Vector2.zero
                });
            }

            if (!theme)
            {
                theme = ScriptableObject.CreateInstance<CardVisualTheme>();
                theme.name = "CardVisualTheme";
                AssetDatabase.CreateAsset(theme, ThemePath);
            }

            theme.EditorConfigure(
                LoadSprite("Assets/Sprite/card/card_bg/blue_card.png"),
                LoadSprite("Assets/Sprite/card/card_bg/purple_card.png"),
                LoadSprite("Assets/Sprite/card/card_bg/orange_max_card.png"),
                artwork);
            EditorUtility.SetDirty(theme);
            return backup;
        }

        private static void MoveBrokenAssetAsFiles(string sourceAssetPath, string destinationAssetPath)
        {
            var projectRoot = Path.GetFullPath(Path.Combine(Application.dataPath, ".."));
            var source = Path.GetFullPath(Path.Combine(projectRoot, sourceAssetPath));
            var destination = Path.GetFullPath(Path.Combine(projectRoot, destinationAssetPath));
            var expectedPrefix = projectRoot.TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
            if (!source.StartsWith(expectedPrefix, StringComparison.OrdinalIgnoreCase) ||
                !destination.StartsWith(expectedPrefix, StringComparison.OrdinalIgnoreCase) ||
                !(string.Equals(sourceAssetPath, ThemePath, StringComparison.Ordinal) ||
                  string.Equals(sourceAssetPath, SweepMaterialPath, StringComparison.Ordinal) ||
                  string.Equals(sourceAssetPath, PackedNoisePath, StringComparison.Ordinal)))
                throw new InvalidOperationException("Refusing to move an unexpected asset path.");
            if (!File.Exists(source))
                throw new FileNotFoundException("Broken source asset is missing.", source);

            Directory.CreateDirectory(Path.GetDirectoryName(destination) ?? projectRoot);
            File.Move(source, destination);
            var sourceMeta = source + ".meta";
            if (File.Exists(sourceMeta))
                File.Move(sourceMeta, destination + ".meta");
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
        }

        private static void RepairPrefab()
        {
            var frontMaterial = AssetDatabase.LoadAssetAtPath<Material>(
                "Assets/Resources/CardCooldownFrontAdditive.mat");
            if (!frontMaterial)
                throw new InvalidOperationException("CardCooldownFrontAdditive material is missing.");
            frontMaterial.SetFloat("_CorePixels", .72f);
            frontMaterial.SetFloat("_InnerPixels", 2.8f);
            frontMaterial.SetFloat("_GlowAbovePixels", 6.5f);
            frontMaterial.SetFloat("_GlowBelowPixels", 15f);
            frontMaterial.SetFloat("_LineIntensity", 1.35f);
            frontMaterial.SetFloat("_Distortion", .0015f);
            frontMaterial.SetFloat("_GlowStrength", 1f);
            EditorUtility.SetDirty(frontMaterial);

            var surfaceMaterial = EnsureSweepMaterial();
            surfaceMaterial.SetFloat("_GlowStrength", 0f);
            surfaceMaterial.SetFloat("_NoiseStrength", .002f);
            surfaceMaterial.SetFloat("_UnreadyBrightness", .52f);
            surfaceMaterial.SetFloat("_UnreadySaturation", .28f);
            surfaceMaterial.SetFloat("_ChargedBrightness", 1.02f);
            EditorUtility.SetDirty(surfaceMaterial);

            var qualityMaterial = EnsureQualityFrameMaterial();

            var root = PrefabUtility.LoadPrefabContents(PrefabPath);
            try
            {
                var motionRoot = root.transform.Find("MotionRoot") ?? root.transform.Find("shadow");
                if (!motionRoot)
                    throw new InvalidOperationException("VisualCard motion root is missing.");
                motionRoot.name = "MotionRoot";

                var shadow = motionRoot.Find("Shadow") ?? motionRoot.Find("shadow");
                if (shadow)
                    shadow.name = "Shadow";

                var cardRoot = motionRoot.Find("CardVisualRoot") ?? motionRoot.Find("card");
                if (!cardRoot)
                    throw new InvalidOperationException("VisualCard visual root is missing.");
                cardRoot.name = "CardVisualRoot";

                var surface = cardRoot.Find("CardSurfaceBg") ?? cardRoot.Find("cardBG");
                if (!surface)
                    throw new InvalidOperationException("VisualCard surface background is missing.");
                surface.name = "CardSurfaceBg";
                var surfaceImage = surface.GetComponent<Image>();
                surfaceImage.material = null;

                var iconTransform = cardRoot.Find("CardArt") ?? surface.Find("cardicon");
                if (!iconTransform)
                    throw new InvalidOperationException("VisualCard artwork is missing.");
                iconTransform.name = "CardArt";
                iconTransform.SetParent(cardRoot, false);
                var icon = iconTransform.GetComponent<Image>();
                if (!icon)
                    throw new InvalidOperationException("VisualCard/CardArt Image is missing.");

                icon.rectTransform.anchorMin = icon.rectTransform.anchorMax = new Vector2(.5f, .5f);
                icon.rectTransform.pivot = new Vector2(.5f, .5f);
                icon.rectTransform.sizeDelta = new Vector2(232f, 150f);
                icon.rectTransform.anchoredPosition = Vector2.zero;
                icon.rectTransform.localScale = Vector3.one;
                icon.rectTransform.localRotation = Quaternion.identity;
                icon.type = Image.Type.Simple;
                icon.preserveAspect = true;
                icon.raycastTarget = false;
                icon.material = null;

                var statLayer = cardRoot.Find("StatLayer") as RectTransform;
                if (!statLayer)
                {
                    var statObject = new GameObject("StatLayer", typeof(RectTransform));
                    statLayer = (RectTransform)statObject.transform;
                    statLayer.SetParent(cardRoot, false);
                    StretchCard(statLayer);
                }
                MoveChild(surface, statLayer, "atk");
                MoveChild(surface, statLayer, "sheild");

                var overlay = cardRoot.Find("MetadataLayer") ?? root.transform.Find("RuntimeOverlay");
                if (!overlay)
                    throw new InvalidOperationException("VisualCard metadata layer is missing.");
                overlay.name = "MetadataLayer";
                overlay.SetParent(cardRoot, false);
                Stretch((RectTransform)overlay, 0f);
                DestroyChild(overlay, "TitleBar");
                DestroyChild(overlay, "Title");
                DestroyChild(overlay, "CooldownFill");
                RenameChild(overlay, "FooterBar", "PricePlate");
                RenameChild(overlay, "Footer", "PriceText");
                SetChildActive(overlay, "PricePlate", false);
                SetChildActive(overlay, "PriceText", false);

                var frontTransform = cardRoot.Find("CooldownFrontFx") ?? overlay.Find("CooldownFrontFx");
                Image frontImage;
                if (!frontTransform)
                {
                    var frontObject = new GameObject(
                        "CooldownFrontFx",
                        typeof(RectTransform),
                        typeof(CanvasRenderer),
                        typeof(Image));
                    frontTransform = frontObject.transform;
                    frontTransform.SetParent(cardRoot, false);
                    frontImage = frontObject.GetComponent<Image>();
                }
                else
                {
                    frontImage = frontTransform.GetComponent<Image>() ??
                                 frontTransform.gameObject.AddComponent<Image>();
                }

                frontTransform.SetParent(cardRoot, false);
                StretchCard((RectTransform)frontTransform);
                frontImage.type = Image.Type.Simple;
                frontImage.color = Color.white;
                frontImage.material = frontMaterial;
                frontImage.raycastTarget = false;
                frontTransform.gameObject.SetActive(false);

                var qualityTransform = cardRoot.Find("QualityFrame");
                Image qualityImage;
                if (!qualityTransform)
                {
                    var qualityObject = new GameObject(
                        "QualityFrame",
                        typeof(RectTransform),
                        typeof(CanvasRenderer),
                        typeof(Image));
                    qualityTransform = qualityObject.transform;
                    qualityTransform.SetParent(cardRoot, false);
                    qualityImage = qualityObject.GetComponent<Image>();
                }
                else
                {
                    qualityImage = qualityTransform.GetComponent<Image>() ??
                                   qualityTransform.gameObject.AddComponent<Image>();
                }
                StretchCard((RectTransform)qualityTransform);
                qualityImage.sprite = surfaceImage.sprite;
                qualityImage.type = Image.Type.Sliced;
                qualityImage.color = Color.white;
                qualityImage.material = qualityMaterial;
                qualityImage.raycastTarget = false;
                if (!qualityTransform.GetComponent<CardQualityFrameMeshEffect>())
                    qualityTransform.gameObject.AddComponent<CardQualityFrameMeshEffect>();

                surface.SetSiblingIndex(0);
                iconTransform.SetSiblingIndex(1);
                frontTransform.SetSiblingIndex(2);
                qualityTransform.SetSiblingIndex(3);
                statLayer.SetSiblingIndex(4);
                overlay.SetSiblingIndex(5);

                foreach (var graphic in root.GetComponentsInChildren<Graphic>(true))
                    graphic.raycastTarget = false;

                PrefabUtility.SaveAsPrefabAsset(root, PrefabPath);
            }
            finally
            {
                PrefabUtility.UnloadPrefabContents(root);
            }
        }

        private static Sprite LoadSprite(string path)
        {
            var sprite = AssetDatabase.LoadAssetAtPath<Sprite>(path);
            if (!sprite)
                throw new InvalidOperationException("Sprite is missing: " + path);
            return sprite;
        }

        private static Material EnsureSweepMaterial()
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(SweepMaterialPath);
            if (!material)
            {
                if (!AssetDatabase.IsValidFolder("Assets/EditorBackup"))
                    AssetDatabase.CreateFolder("Assets", "EditorBackup");

                if (!string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(SweepMaterialPath)))
                {
                    var backup = AssetDatabase.GenerateUniqueAssetPath(
                        "Assets/EditorBackup/CardCooldownSweep.rollback-backup.mat");
                    var moveError = AssetDatabase.MoveAsset(SweepMaterialPath, backup);
                    if (!string.IsNullOrEmpty(moveError))
                        MoveBrokenAssetAsFiles(SweepMaterialPath, backup);
                }

                var shader = Shader.Find("UI/CardCooldownSweep");
                if (!shader)
                    throw new InvalidOperationException("UI/CardCooldownSweep shader is missing.");

                material = new Material(shader) { name = "CardCooldownSweep" };
                AssetDatabase.CreateAsset(material, SweepMaterialPath);
            }

            var noise = EnsurePackedNoise();
            if (noise)
                material.SetTexture("_NoiseTex", noise);
            return material;
        }

        private static Material EnsureQualityFrameMaterial()
        {
            var material = AssetDatabase.LoadAssetAtPath<Material>(QualityMaterialPath);
            if (!material)
            {
                var shader = Shader.Find("UI/CardQualityFrame");
                if (!shader)
                    throw new InvalidOperationException("UI/CardQualityFrame shader is missing.");
                material = new Material(shader) { name = "CardQualityFrame" };
                AssetDatabase.CreateAsset(material, QualityMaterialPath);
            }

            material.SetVector("_RectSize", new Vector4(260f, 170f, 0f, 0f));
            material.SetVector("_FrameInset", new Vector4(15f, 12f, 0f, 0f));
            material.SetFloat("_EdgeFeather", 1f);
            EditorUtility.SetDirty(material);
            return material;
        }

        private static Texture2D EnsurePackedNoise()
        {
            var texture = AssetDatabase.LoadAssetAtPath<Texture2D>(PackedNoisePath);
            if (texture)
                return texture;

            if (!string.IsNullOrEmpty(AssetDatabase.AssetPathToGUID(PackedNoisePath)))
            {
                var backup = AssetDatabase.GenerateUniqueAssetPath(
                    "Assets/EditorBackup/CardCooldownPackedNoise.rollback-backup.asset");
                var moveError = AssetDatabase.MoveAsset(PackedNoisePath, backup);
                if (!string.IsNullOrEmpty(moveError))
                    MoveBrokenAssetAsFiles(PackedNoisePath, backup);
            }

            const int size = 256;
            texture = new Texture2D(size, size, TextureFormat.RGBA32, false, true)
            {
                name = "CardCooldownPackedNoise",
                wrapMode = TextureWrapMode.Repeat,
                filterMode = FilterMode.Bilinear,
                anisoLevel = 1
            };
            var pixels = new Color[size * size];
            for (var y = 0; y < size; y++)
            for (var x = 0; x < size; x++)
            {
                var u = x / (float)size;
                var v = y / (float)size;
                var low = Mathf.PerlinNoise(u * 2.7f + 13.1f, v * 2.7f + 71.7f) * .68f +
                          Mathf.PerlinNoise(u * 6.1f + 37.2f, v * 6.1f + 11.3f) * .32f;
                var vertical = Mathf.PerlinNoise(u * 7.5f + 93.4f, v * 1.35f + 28.6f) * .62f +
                               Mathf.PerlinNoise(u * 15.0f + 7.8f, v * 2.4f + 56.2f) * .38f;
                var high = Mathf.PerlinNoise(u * 23.0f + 45.9f, v * 19.0f + 81.1f);
                var spark = Mathf.Pow(Mathf.Clamp01((high - .58f) / .42f), 3.5f);
                var breakup = Mathf.PerlinNoise(u * 11.0f + 3.7f, v * 13.0f + 19.4f);
                pixels[y * size + x] = new Color(low, vertical, spark, breakup);
            }
            texture.SetPixels(pixels);
            texture.Apply(false, false);
            AssetDatabase.CreateAsset(texture, PackedNoisePath);
            return texture;
        }

        private static void Stretch(RectTransform rect, float inset)
        {
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = Vector2.one;
            rect.pivot = new Vector2(.5f, .5f);
            rect.offsetMin = new Vector2(inset, inset);
            rect.offsetMax = new Vector2(-inset, -inset);
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }

        private static void StretchCard(RectTransform rect)
        {
            rect.anchorMin = rect.anchorMax = rect.pivot = new Vector2(.5f, .5f);
            rect.sizeDelta = new Vector2(260f, 170f);
            rect.anchoredPosition = Vector2.zero;
            rect.localScale = Vector3.one;
            rect.localRotation = Quaternion.identity;
        }

        private static void MoveChild(Transform source, Transform destination, string childName)
        {
            var child = source.Find(childName);
            if (child)
                child.SetParent(destination, false);
        }

        private static void DestroyChild(Transform root, string childName)
        {
            var child = root.Find(childName);
            if (child)
                UnityEngine.Object.DestroyImmediate(child.gameObject);
        }

        private static void RenameChild(Transform root, string oldName, string newName)
        {
            var child = root.Find(newName) ?? root.Find(oldName);
            if (child)
                child.name = newName;
        }

        private static void SetChildActive(Transform root, string childName, bool active)
        {
            var child = root.Find(childName);
            if (child)
                child.gameObject.SetActive(active);
        }
    }
}

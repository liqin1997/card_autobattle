using UnityEngine;
using UnityEngine.UI;
using TMPro;

namespace CardAutobattle.Prototype
{
    public static class CardPresentationUtility
    {
        public readonly struct CardVisualParts
        {
            public CardVisualParts(
                Image surfaceBackground,
                Image artwork,
                Image qualityFrame,
                Image cooldownFrontFx,
                Transform metadataLayer)
            {
                SurfaceBackground = surfaceBackground;
                Artwork = artwork;
                QualityFrame = qualityFrame;
                CooldownFrontFx = cooldownFrontFx;
                MetadataLayer = metadataLayer;
            }

            public Image SurfaceBackground { get; }
            public Image Artwork { get; }
            public Image QualityFrame { get; }
            public Image CooldownFrontFx { get; }
            public Transform MetadataLayer { get; }
        }

        private static Font cachedFont;

        public static Font Font
        {
            get
            {
                if (!cachedFont)
                    cachedFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
                return cachedFont;
            }
        }

        public static CardVisualParts GetVisualParts(Transform cardRoot)
        {
            if (!cardRoot)
                return default;

            var surfaceBackground = FindImage(cardRoot, "CardSurfaceBg") ?? FindImage(cardRoot, "cardBG");
            var artwork = FindImage(cardRoot, "CardArt") ?? FindImage(cardRoot, "cardicon");
            var qualityFrame = FindImage(cardRoot, "QualityFrame");
            var frontFx = FindImage(cardRoot, "CooldownFrontFx");
            var metadata = FindDeep(cardRoot, "MetadataLayer") ?? cardRoot.Find("RuntimeOverlay");
            return new CardVisualParts(surfaceBackground, artwork, qualityFrame, frontFx, metadata);
        }

        public static void ApplyCardArt(Transform cardRoot, CardDefinition definition, int level)
        {
            if (!cardRoot || definition == null)
                return;

            var theme = CardVisualTheme.Instance;
            if (!theme)
                return;

            var frame = theme.GetFrame(level);
            var artEntry = theme.GetArtEntry(definition.Id);
            var artwork = artEntry?.Artwork;
            var parts = GetVisualParts(cardRoot);
            var background = parts.SurfaceBackground;
            var qualityFrame = parts.QualityFrame;
            var shadow = FindImage(cardRoot, "Shadow") ?? FindImage(cardRoot, "shadow", background ? background.transform : null);
            var icon = parts.Artwork;

            if (background && frame)
            {
                background.sprite = frame;
                background.type = Image.Type.Sliced;
                background.color = Color.white;
            }

            if (qualityFrame && frame)
            {
                qualityFrame.sprite = frame;
                qualityFrame.type = Image.Type.Sliced;
                qualityFrame.color = Color.white;
                qualityFrame.gameObject.SetActive(true);
            }

            if (shadow && frame)
            {
                shadow.sprite = frame;
                shadow.type = Image.Type.Sliced;
            }

            if (icon && artwork)
            {
                icon.sprite = artwork;
                icon.preserveAspect = true;
                icon.type = Image.Type.Simple;
                icon.rectTransform.sizeDelta = new Vector2(232f, 150f);
                icon.rectTransform.anchoredPosition = artEntry?.Offset ?? Vector2.zero;
                icon.rectTransform.localScale = Vector3.one * (artEntry?.Scale ?? 1f);
            }

            UpdateStatBadge(cardRoot, "atk", HasDamage(definition.Effect), GetDamageValue(definition, level));
            UpdateStatBadge(cardRoot, "sheild", HasShield(definition.Effect), GetShieldValue(definition, level));
        }

        public static void SetMetadataVisibility(Transform cardRoot, bool showPrice, int price)
        {
            var overlay = GetVisualParts(cardRoot).MetadataLayer;
            if (!overlay)
                return;

            SetChildActive(overlay, "PricePlate", showPrice);
            SetChildActive(overlay, "PriceText", showPrice);
            SetChildActive(overlay, "FooterBar", showPrice);
            SetChildActive(overlay, "Footer", showPrice);
            var footer = overlay.Find("PriceText")?.GetComponent<Text>() ??
                         overlay.Find("Footer")?.GetComponent<Text>();
            if (footer)
                footer.text = showPrice ? $"{price} GOLD" : string.Empty;
        }

        private static void UpdateStatBadge(Transform root, string objectName, bool visible, float value)
        {
            var target = FindDeep(root, objectName);
            if (!target)
                return;
            target.gameObject.SetActive(visible);
            if (!visible)
                return;
            var label = target.GetComponentInChildren<TMP_Text>(true);
            if (label)
                label.text = Mathf.CeilToInt(value).ToString();
            else
            {
                var legacyLabel = target.GetComponentInChildren<Text>(true);
                if (legacyLabel)
                    legacyLabel.text = Mathf.CeilToInt(value).ToString();
            }
        }

        private static bool HasDamage(CardEffectKind effect)
        {
            return effect is CardEffectKind.Damage or CardEffectKind.DamageAndBurn or
                CardEffectKind.DamageAndPoison or CardEffectKind.DamageAndSlow or
                CardEffectKind.DamageAndHaste or CardEffectKind.ShieldAndDamage or
                CardEffectKind.Drain or CardEffectKind.ChainDamage;
        }

        private static bool HasShield(CardEffectKind effect)
        {
            return effect is CardEffectKind.Shield or CardEffectKind.ShieldAndDamage or
                CardEffectKind.ShieldAndVictoryGold or CardEffectKind.ShieldAndHeal;
        }

        private static float GetDamageValue(CardDefinition definition, int level)
        {
            var baseValue = definition.Effect == CardEffectKind.ShieldAndDamage
                ? definition.SecondaryPower
                : definition.Power;
            return baseValue * PrototypeCardCatalog.QualityMultiplier(level);
        }

        private static float GetShieldValue(CardDefinition definition, int level)
        {
            return definition.Power * PrototypeCardCatalog.QualityMultiplier(level);
        }

        private static Image FindImage(Transform root, string objectName, Transform excludedRoot = null)
        {
            foreach (var image in root.GetComponentsInChildren<Image>(true))
                if (image.name == objectName && (!excludedRoot || !image.transform.IsChildOf(excludedRoot)))
                    return image;
            return null;
        }

        private static Transform FindDeep(Transform root, string objectName)
        {
            foreach (var child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == objectName)
                    return child;
            return null;
        }

        private static void SetChildActive(Transform root, string childName, bool active)
        {
            var child = root.Find(childName);
            if (child)
                child.gameObject.SetActive(active);
        }

        public static RectTransform CreateRect(string name, Transform parent, Vector2 anchorMin, Vector2 anchorMax)
        {
            var go = new GameObject(name, typeof(RectTransform));
            var rect = (RectTransform)go.transform;
            rect.SetParent(parent, false);
            rect.anchorMin = anchorMin;
            rect.anchorMax = anchorMax;
            rect.offsetMin = Vector2.zero;
            rect.offsetMax = Vector2.zero;
            return rect;
        }

        public static Image CreateImage(string name, Transform parent, Color color)
        {
            var rect = CreateRect(name, parent, Vector2.zero, Vector2.one);
            var image = rect.gameObject.AddComponent<Image>();
            image.color = color;
            image.raycastTarget = false;
            return image;
        }

        public static Text CreateText(string name, Transform parent, int size, TextAnchor alignment, Color color)
        {
            var rect = CreateRect(name, parent, Vector2.zero, Vector2.one);
            var text = rect.gameObject.AddComponent<Text>();
            text.font = Font;
            text.fontSize = size;
            text.alignment = alignment;
            text.color = color;
            text.raycastTarget = false;
            text.resizeTextForBestFit = true;
            text.resizeTextMinSize = 12;
            text.resizeTextMaxSize = size;
            return text;
        }
    }
}

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    /// <summary>Applies the imported Feilong production cuts to the live equipment UGUI.</summary>
    public static class CommercialFeilongEquipmentSkin
    {
        private const string Root = "Commercial/FeilongUI/Equipment/";
        private static readonly Dictionary<string, Sprite> Cache = new();

        private static Sprite Art(string name)
        {
            if (!Cache.TryGetValue(name, out var sprite)) Cache[name] = sprite = Resources.Load<Sprite>(Root + name);
            return sprite;
        }

        public static void Apply(CommercialEquipmentView view)
        {
            if (!view || !view.RootUI || !view.ModalRoot) return;

            var normalFrame = Art("tab_equip_01");
            var equippedFrame = Art("tab_equip_02");
            var backing = Art("bg_equip_level");

            foreach (var button in view.RootUI.GetComponentsInChildren<Button>(true))
                ApplyFrame(button.image, normalFrame);
            foreach (var button in view.ModalRoot.GetComponentsInChildren<Button>(true))
                ApplyFrame(button.image, normalFrame);

            if (view.Slots != null)
                foreach (var cell in view.Slots)
                    ApplyCell(cell, equippedFrame, backing);
            if (view.Cells != null)
                foreach (var cell in view.Cells)
                    ApplyCell(cell, normalFrame, backing);

            Decorate(view.RootUI, "EQ_TabGear", "btn_img_clothes", 46);
            Decorate(view.RootUI, "EQ_TabForge", "icon_forge", 44);
            Decorate(view.RootUI, "EQ_TabLoadouts", "btn_scheme", 44);
            Decorate(view.RootUI, "EQ_TabSets", "bg_quality_icon", 42);
            Decorate(view.RootUI, "EQ_SetInfo", "bg_quality_icon", 34);
            Decorate(view.RootUI, "EQ_FilterSlot", "icon_screen_01", 38);
            Decorate(view.RootUI, "EQ_FilterRarity", "icon_screen_02", 38);
            Decorate(view.RootUI, "EQ_FilterSet", "icon_screen_03", 38);
            Decorate(view.RootUI, "EQ_Sort", "icon_triangle", 32);
            Decorate(view.RootUI, "EQ_BulkSalvage", "btn_resolve", 38);
            Decorate(view.RootUI, "EQ_Craft", "icon_forge", 48);

            Decorate(view.ModalRoot, "EQ_Equip", "img_replace", 46);
            Decorate(view.ModalRoot, "EQ_Lock", "btn_locked", 46);
            Decorate(view.ModalRoot, "EQ_Salvage", "btn_resolve", 48);
            Decorate(view.ModalRoot, "EQ_Upgrade", "icon_level", 46);
            Decorate(view.ModalRoot, "EQ_Reforge", "icon_randomization", 46);
        }

        private static void ApplyCell(CommercialEquipmentCell cell, Sprite frame, Sprite backing)
        {
            if (!cell) return;
            ApplyFrame(cell.Rim, frame);
            var background = cell.transform.Find(cell.name + "_Backing")?.GetComponent<Image>();
            ApplyFrame(background, backing);
        }

        private static void ApplyFrame(Image image, Sprite sprite)
        {
            if (!image || !sprite) return;
            image.sprite = sprite;
            image.type = sprite.border.sqrMagnitude > 0 ? Image.Type.Sliced : Image.Type.Simple;
        }

        private static void Decorate(Transform root, string buttonName, string spriteName, float size)
        {
            var button = Find(root, buttonName)?.GetComponent<Button>();
            if (!button) return;
            SetButtonIcon(button.transform, Art(spriteName), size);
        }

        public static void SetButtonIcon(Transform button, Sprite sprite, float size = 46)
        {
            if (!button || !sprite) return;
            var icon = button.Find("FeilongIcon")?.GetComponent<Image>();
            if (!icon)
            {
                var go = new GameObject("FeilongIcon", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
                var rect = (RectTransform)go.transform;
                rect.SetParent(button, false);
                rect.anchorMin = rect.anchorMax = new Vector2(0, .5f);
                rect.pivot = new Vector2(.5f, .5f);
                rect.anchoredPosition = new Vector2(31, 0);
                rect.sizeDelta = new Vector2(size, size);
                icon = go.GetComponent<Image>();
                icon.raycastTarget = false;
                icon.preserveAspect = true;
                var label = button.GetComponentInChildren<Text>();
                if (label)
                {
                    var labelRect = label.rectTransform;
                    labelRect.offsetMin = new Vector2(Mathf.Max(labelRect.offsetMin.x, 55), labelRect.offsetMin.y);
                }
            }
            icon.sprite = sprite;
            icon.enabled = true;
        }

        private static Transform Find(Transform root, string name)
        {
            if (!root) return null;
            foreach (var child in root.GetComponentsInChildren<Transform>(true))
                if (child.name == name) return child;
            return null;
        }
    }
}

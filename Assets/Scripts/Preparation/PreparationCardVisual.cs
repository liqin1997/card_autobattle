using UnityEngine;
using UnityEngine.UI;
using CardAutobattle.Prototype;

namespace CardAutobattle.Preparation
{
    [DisallowMultipleComponent]
    public sealed class PreparationCardVisual : MonoBehaviour
    {
        [Header("Follow")]
        [SerializeField] private float followSharpness = 18f;
        [SerializeField] private float rotationSharpness = 15f;
        [SerializeField] private float rotationPerPixel = 0.18f;
        [SerializeField] private float maxDragRotation = 18f;

        [Header("Tilt")]
        [SerializeField] private float tiltSharpness = 14f;
        [SerializeField] private float maxTilt = 7f;
        [SerializeField] private float idleTilt = 1.2f;

        [Header("Scale")]
        [SerializeField] private float hoverScale = 1.055f;
        [SerializeField] private float dragScale = 1.10f;
        [SerializeField] private float pressedScale = 0.975f;
        [SerializeField] private float scaleSharpness = 18f;

        private PreparationCardInput target;
        private RectTransform rectTransform;
        private RectTransform shakeRoot;
        private RectTransform tiltRoot;
        private RectTransform shadow;
        private Canvas sortingCanvas;
        private Vector2 shadowRestPosition;
        private float currentZ;
        private float hoverPunch;
        public void Initialize(PreparationCardInput input)
        {
            target = input;
            rectTransform = (RectTransform)transform;
            shakeRoot = FindRect(transform, "MotionRoot") ?? FindRect(transform, "shadow");
            tiltRoot = FindRect(transform, "CardVisualRoot") ?? FindRect(transform, "card");
            shadow = FindImageRect(transform, "Shadow") ?? FindImageRect(transform, "shadow");

            if (!shakeRoot)
                shakeRoot = rectTransform;
            if (!tiltRoot)
                tiltRoot = shakeRoot;
            if (shadow)
                shadowRestPosition = shadow.anchoredPosition;

            sortingCanvas = GetComponent<Canvas>();
            if (!sortingCanvas)
                sortingCanvas = gameObject.AddComponent<Canvas>();
            sortingCanvas.overrideSorting = false;

            foreach (var graphic in GetComponentsInChildren<Graphic>(true))
                graphic.raycastTarget = false;

            rectTransform.position = target.transform.position;
        }

        public void BindCardData()
        {
            if (!target)
                return;

            var definition = target.Definition;
            CardPresentationUtility.ApplyCardArt(transform, definition, target.Level);
            CardPresentationUtility.SetMetadataVisibility(transform, target.IsShopOffer, target.PurchasePrice);
            var parts = CardPresentationUtility.GetVisualParts(transform);
            if (parts.SurfaceBackground)
                parts.SurfaceBackground.material = null;
            if (parts.Artwork)
                parts.Artwork.material = null;
            if (parts.CooldownFrontFx)
            {
                parts.CooldownFrontFx.material = null;
                parts.CooldownFrontFx.gameObject.SetActive(false);
            }
        }

        public void SetEffectValues(ResolvedCardValues values)
        {
            CardPresentationUtility.ApplyEffectValues(transform, values);
        }

        private void LateUpdate()
        {
            if (!target)
                return;

            var followT = ExpLerp(followSharpness);
            rectTransform.position = Vector3.Lerp(rectTransform.position, target.transform.position, followT);

            var canvas = GetComponentInParent<Canvas>();
            var scaleFactor = canvas ? Mathf.Max(0.01f, canvas.scaleFactor) : 1f;
            var lagPixels = (target.transform.position.x - rectTransform.position.x) / scaleFactor;
            var targetZ = target.IsDragging
                ? Mathf.Clamp(-lagPixels * rotationPerPixel, -maxDragRotation, maxDragRotation)
                : 0f;
            currentZ = Mathf.LerpAngle(currentZ, targetZ, ExpLerp(rotationSharpness));
            rectTransform.localRotation = Quaternion.Euler(0f, 0f, currentZ);

            UpdateScale();
            UpdateTilt();
            UpdateShadow();
        }

        private void UpdateScale()
        {
            var targetScale = target.IsDragging
                ? dragScale
                : target.IsPressed
                    ? pressedScale
                    : target.IsHovered ? hoverScale : 1f;

            rectTransform.localScale = Vector3.Lerp(
                rectTransform.localScale,
                Vector3.one * targetScale,
                ExpLerp(scaleSharpness));
        }

        private void UpdateTilt()
        {
            if (!tiltRoot)
                return;

            var x = 0f;
            var y = 0f;
            var interactive = target.IsHovered || target.IsDragging;

            if (interactive && RectTransformUtility.ScreenPointToLocalPointInRectangle(
                    rectTransform,
                    target.PointerScreenPosition,
                    null,
                    out var localPoint))
            {
                var half = rectTransform.rect.size * 0.5f;
                x = -Mathf.Clamp(localPoint.y / Mathf.Max(1f, half.y), -1f, 1f) * maxTilt;
                y = Mathf.Clamp(localPoint.x / Mathf.Max(1f, half.x), -1f, 1f) * maxTilt;
            }
            else
            {
                x = Mathf.Sin(Time.unscaledTime * 1.1f + transform.GetInstanceID() * 0.01f) * idleTilt;
                y = Mathf.Cos(Time.unscaledTime * 0.9f + transform.GetInstanceID() * 0.01f) * idleTilt;
            }

            tiltRoot.localRotation = Quaternion.Slerp(
                tiltRoot.localRotation,
                Quaternion.Euler(x, y, 0f),
                ExpLerp(tiltSharpness));
        }

        private void UpdateShadow()
        {
            if (!shadow)
                return;

            var targetPosition = target.IsPressed || target.IsDragging
                ? shadowRestPosition + new Vector2(0f, 7f)
                : shadowRestPosition;
            shadow.anchoredPosition = Vector2.Lerp(shadow.anchoredPosition, targetPosition, ExpLerp(20f));
        }

        public void BringToFront()
        {
            transform.SetAsLastSibling();
            sortingCanvas.overrideSorting = true;
            sortingCanvas.sortingOrder = 100;
        }

        public void ReleaseSorting()
        {
            sortingCanvas.overrideSorting = false;
        }

        private float ExpLerp(float sharpness)
        {
            return 1f - Mathf.Exp(-sharpness * Time.unscaledDeltaTime);
        }

        private static RectTransform FindRect(Transform root, string objectName)
        {
            foreach (var rect in root.GetComponentsInChildren<RectTransform>(true))
                if (rect != root && rect.name == objectName)
                    return rect;
            return null;
        }

        private static RectTransform FindImageRect(Transform root, string objectName)
        {
            foreach (var image in root.GetComponentsInChildren<Image>(true))
                if (image.name == objectName)
                    return image.rectTransform;
            return null;
        }
    }
}

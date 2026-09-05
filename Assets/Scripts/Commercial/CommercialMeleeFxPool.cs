using System.Collections.Generic;
using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialMeleeFxPool : MonoBehaviour
    {
        [SerializeField, Range(4, 20)] private int capacity = 10;
        [SerializeField, Range(.04f, .25f)] private float repeatBlockSeconds = .10f;
        private readonly List<Image> pool = new();
        private readonly Dictionary<long, float> lastPlayAt = new();
        private void Awake()
        {
            for (var i = 0; i < capacity; i++) pool.Add(Create(i));
        }

        public void Play(RectTransform source, RectTransform target, Color color)
        {
            if (!target || !gameObject.activeInHierarchy) return;
            // A single resolved hit must create one weapon swing.  Multiple visual events can
            // reach this layer in the same frame (action/profession followups); collapse only
            // those duplicates while still allowing deliberately separated combo hits.
            var sourceId = source ? source.GetInstanceID() : 0;
            var key = ((long)sourceId << 32) ^ (uint)target.GetInstanceID();
            var now = Time.unscaledTime;
            if (lastPlayAt.TryGetValue(key, out var previous) && now - previous < repeatBlockSeconds) return;
            lastPlayAt[key] = now;
            var image = pool.Find(item => !item.gameObject.activeSelf) ?? pool[0];
            image.DOKill();
            image.rectTransform.DOKill();
            // Use a compact procedural blade. Imported Feilong effect textures rely on their
            // particle shaders and render as opaque rectangles under a normal UGUI Image.
            image.sprite = null;
            image.color = new Color(color.r, color.g, color.b, 0f);
            image.preserveAspect = false;
            image.gameObject.SetActive(true);
            image.transform.SetAsLastSibling();
            var bounds = RectTransformUtility.CalculateRelativeRectTransformBounds(transform, target);
            var start = (Vector2)bounds.center + new Vector2(72f, 90f);
            image.rectTransform.anchoredPosition = start;
            image.rectTransform.localRotation = Quaternion.Euler(0f, 0f, -62f);
            image.rectTransform.localScale = Vector3.one * .78f;
            var sequence = DOTween.Sequence().SetUpdate(true).SetTarget(image);
            sequence.Append(image.DOFade(.95f, .05f));
            sequence.Join(image.rectTransform.DOAnchorPos((Vector2)bounds.center + new Vector2(-16f, 16f), .20f).SetEase(Ease.InCubic));
            sequence.Join(image.rectTransform.DORotate(new Vector3(0f, 0f, 48f), .20f).SetEase(Ease.InCubic));
            sequence.Join(image.rectTransform.DOScale(1.12f, .20f));
            sequence.Append(image.DOFade(0f, .16f));
            sequence.OnComplete(() => image.gameObject.SetActive(false));
        }

        private Image Create(int index)
        {
            var go = new GameObject($"MeleeFx_{index:00}", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            go.layer = gameObject.layer;
            var rect = (RectTransform)go.transform;
            rect.SetParent(transform, false);
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.sizeDelta = new Vector2(22f, 176f);
            var image = go.GetComponent<Image>();
            image.raycastTarget = false;
            go.SetActive(false);
            return image;
        }

        private void OnDisable()
        {
            foreach (var image in pool)
            {
                if (!image) continue;
                image.DOKill();
                image.rectTransform.DOKill();
                image.gameObject.SetActive(false);
            }
            lastPlayAt.Clear();
        }
    }
}

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialFloatingTextPool : MonoBehaviour
    {
        private sealed class ActiveText
        {
            public Text Text;
            public float Life;
            public Vector2 Start;
            public int TargetKey;
        }

        [SerializeField, Range(8, 48)] private int capacity = 24;
        private readonly Queue<Text> available = new();
        private readonly List<ActiveText> active = new();

        public void Show(RectTransform target, string value, Color color)
        {
            if (!target) return;
            var text = available.Count > 0 ? available.Dequeue() : CreateText();
            if (!text) return;
            text.gameObject.SetActive(true);
            text.text = value;
            text.color = color;
            var rect = text.rectTransform;
            var targetKey = target.GetInstanceID();
            var lane = 0;
            foreach (var item in active) if (item.TargetKey == targetKey && item.Life > .42f) lane++;
            rect.position = target.TransformPoint(new Vector3(0f, target.rect.height * .5f + 10f, 0f));
            rect.anchoredPosition += new Vector2((lane % 2 == 0 ? -1f : 1f) * lane * 9f, lane * 24f);
            rect.localScale = Vector3.one * .82f;
            active.Add(new ActiveText
            {
                Text = text,
                Life = 1f,
                Start = rect.anchoredPosition,
                TargetKey = targetKey
            });
        }

        private void Update()
        {
            for (var i = active.Count - 1; i >= 0; i--)
            {
                var item = active[i];
                item.Life -= Time.unscaledDeltaTime * 1.25f;
                var progress = 1f - Mathf.Clamp01(item.Life);
                var eased = 1f - (1f - progress) * (1f - progress);
                item.Text.rectTransform.anchoredPosition = item.Start + Vector2.up * eased * 78f;
                item.Text.rectTransform.localScale = Vector3.one * Mathf.Lerp(.82f, 1.08f,
                    Mathf.Sin(Mathf.Min(1f, progress * 2f) * Mathf.PI * .5f));
                var color = item.Text.color;
                color.a = Mathf.Clamp01(item.Life * 1.7f);
                item.Text.color = color;
                if (item.Life > 0f) continue;
                item.Text.gameObject.SetActive(false);
                active.RemoveAt(i);
                available.Enqueue(item.Text);
            }
        }

        private Text CreateText()
        {
            if (active.Count + available.Count >= capacity) return null;
            var go = new GameObject("DamageText", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            var rect = (RectTransform)go.transform;
            rect.SetParent(transform, false);
            rect.sizeDelta = new Vector2(180f, 70f);
            var text = go.GetComponent<Text>();
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            text.fontSize = 30;
            text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter;
            text.raycastTarget = false;
            var outline = go.AddComponent<Outline>();
            outline.effectColor = new Color(0f, 0f, 0f, .82f);
            outline.effectDistance = new Vector2(1.5f, -1.5f);
            return text;
        }
    }
}

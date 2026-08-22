using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialProjectilePool : MonoBehaviour
    {
        private sealed class Projectile
        {
            public RectTransform Rect;
            public Image Glow;
            public Image Core;
            public Image Tail;
            public Vector3 Start;
            public Vector3 End;
            public float Duration;
            public float Elapsed;
            public float Arc;
            public bool Active;
        }

        [SerializeField, Range(8, 48)] private int capacity = 24;
        [SerializeField, Range(.12f, .6f)] private float travelDuration = .28f;
        private readonly List<Projectile> projectiles = new();
        public float TravelDuration => travelDuration;
        public int ActiveCount
        {
            get
            {
                var count = 0;
                foreach (var projectile in projectiles) if (projectile.Active) count++;
                return count;
            }
        }

        private void Awake()
        {
            for (var i = 0; i < capacity; i++) projectiles.Add(CreateProjectile(i));
        }

        public void Play(RectTransform source, RectTransform target, Color color)
        {
            if (!source || !target || !gameObject.activeInHierarchy) return;
            var projectile = projectiles.Find(candidate => !candidate.Active) ?? projectiles[0];
            projectile.Active = true;
            projectile.Elapsed = 0f;
            projectile.Duration = travelDuration;
            projectile.Start = source.position;
            projectile.End = target.position;
            projectile.Arc = Mathf.Clamp(Vector3.Distance(projectile.Start, projectile.End) * .16f, 30f, 86f);
            projectile.Glow.color = new Color(color.r, color.g, color.b, .32f);
            projectile.Core.color = new Color(Mathf.Lerp(color.r, 1f, .72f),
                Mathf.Lerp(color.g, 1f, .72f), Mathf.Lerp(color.b, 1f, .72f), 1f);
            projectile.Tail.color = new Color(color.r, color.g, color.b, .48f);
            projectile.Rect.position = projectile.Start;
            projectile.Rect.localScale = Vector3.one;
            projectile.Rect.gameObject.SetActive(true);
            projectile.Rect.SetAsLastSibling();
        }

        private void Update()
        {
            foreach (var projectile in projectiles)
            {
                if (!projectile.Active) continue;
                projectile.Elapsed += Time.unscaledDeltaTime;
                var t = Mathf.Clamp01(projectile.Elapsed / projectile.Duration);
                var eased = t * t * (3f - 2f * t);
                var position = Vector3.Lerp(projectile.Start, projectile.End, eased);
                position += Vector3.up * (Mathf.Sin(t * Mathf.PI) * projectile.Arc);
                var previous = projectile.Rect.position;
                projectile.Rect.position = position;
                var direction = position - previous;
                if (direction.sqrMagnitude > .001f)
                    projectile.Rect.rotation = Quaternion.Euler(0f, 0f,
                        Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg);
                var pulse = 1f + Mathf.Sin(t * Mathf.PI) * .32f;
                projectile.Rect.localScale = Vector3.one * pulse;
                if (t < 1f) continue;
                projectile.Active = false;
                projectile.Rect.gameObject.SetActive(false);
            }
        }

        private Projectile CreateProjectile(int index)
        {
            var go = new GameObject($"Projectile_{index:00}", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            var rect = (RectTransform)go.transform;
            rect.SetParent(transform, false);
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.sizeDelta = new Vector2(48f, 9f);
            var glow = go.GetComponent<Image>();
            glow.color = new Color(.2f, 1f, 1f, .32f);
            glow.raycastTarget = false;

            var coreGo = new GameObject("Core", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            var coreRect = (RectTransform)coreGo.transform;
            coreRect.SetParent(rect, false);
            coreRect.anchorMin = new Vector2(.34f, .24f);
            coreRect.anchorMax = new Vector2(.98f, .76f);
            coreRect.offsetMin = coreRect.offsetMax = Vector2.zero;
            var core = coreGo.GetComponent<Image>();
            core.color = Color.white;
            core.raycastTarget = false;

            var tailGo = new GameObject("Tail", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            var tailRect = (RectTransform)tailGo.transform;
            tailRect.SetParent(rect, false);
            tailRect.anchorMin = new Vector2(.02f, .39f);
            tailRect.anchorMax = new Vector2(.58f, .61f);
            tailRect.offsetMin = tailRect.offsetMax = Vector2.zero;
            var tail = tailGo.GetComponent<Image>();
            tail.color = new Color(.2f, 1f, 1f, .48f);
            tail.raycastTarget = false;
            tailRect.SetAsFirstSibling();
            go.SetActive(false);
            return new Projectile { Rect = rect, Glow = glow, Core = core, Tail = tail };
        }
    }
}

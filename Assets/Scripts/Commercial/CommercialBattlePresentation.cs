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
            public Vector3 Control;
            public Vector3 End;
            public float Duration;
            public float Elapsed;
            public bool Active;
        }

        [SerializeField, Range(8, 48)] private int capacity = 24;
        [SerializeField, Range(.2f, .8f)] private float travelDuration = .45f;
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
            projectile.Start = CardCenterInLayer(source);
            projectile.End = CardCenterInLayer(target);
            var distance = Vector3.Distance(projectile.Start, projectile.End);
            var lift = Mathf.Clamp(distance * .70f, 220f, 460f);
            projectile.Control = (projectile.Start + projectile.End) * .5f + Vector3.up * lift;
            projectile.Glow.color = new Color(color.r, color.g, color.b, .32f);
            projectile.Core.color = new Color(Mathf.Lerp(color.r, 1f, .72f),
                Mathf.Lerp(color.g, 1f, .72f), Mathf.Lerp(color.b, 1f, .72f), 1f);
            projectile.Tail.color = new Color(color.r, color.g, color.b, .48f);
            projectile.Rect.localPosition = projectile.Start;
            projectile.Rect.localRotation = RotationForTangent(projectile.Control - projectile.Start);
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
                var eased = t * t * t * (t * (t * 6f - 15f) + 10f);
                var oneMinusT = 1f - eased;
                var position = oneMinusT * oneMinusT * projectile.Start +
                               2f * oneMinusT * eased * projectile.Control +
                               eased * eased * projectile.End;
                projectile.Rect.localPosition = position;
                var tangent = 2f * oneMinusT * (projectile.Control - projectile.Start) +
                              2f * eased * (projectile.End - projectile.Control);
                if (tangent.sqrMagnitude > .001f) projectile.Rect.localRotation = RotationForTangent(tangent);
                var pulse = 1f + Mathf.Sin(t * Mathf.PI) * .32f;
                projectile.Rect.localScale = Vector3.one * pulse;
                if (t < 1f) continue;
                projectile.Active = false;
                projectile.Rect.gameObject.SetActive(false);
            }
        }

        private Vector3 CardCenterInLayer(RectTransform card)
        {
            var worldCenter = card.TransformPoint(card.rect.center);
            var localCenter = transform.InverseTransformPoint(worldCenter);
            localCenter.z = 0f;
            return localCenter;
        }

        private static Quaternion RotationForTangent(Vector3 tangent)
        {
            return Quaternion.Euler(0f, 0f, Mathf.Atan2(tangent.y, tangent.x) * Mathf.Rad2Deg);
        }

        private void OnDisable()
        {
            foreach (var projectile in projectiles)
            {
                projectile.Active = false;
                if (projectile.Rect) projectile.Rect.gameObject.SetActive(false);
            }
        }

        private Projectile CreateProjectile(int index)
        {
            var go = new GameObject($"Projectile_{index:00}", typeof(RectTransform),
                typeof(CanvasRenderer), typeof(Image));
            go.layer = gameObject.layer;
            var rect = (RectTransform)go.transform;
            rect.SetParent(transform, false);
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.sizeDelta = new Vector2(96f, 18f);
            var glow = go.GetComponent<Image>();
            glow.color = new Color(.2f, 1f, 1f, .32f);
            glow.raycastTarget = false;

            var coreGo = new GameObject("Core", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            coreGo.layer = gameObject.layer;
            var coreRect = (RectTransform)coreGo.transform;
            coreRect.SetParent(rect, false);
            coreRect.anchorMin = new Vector2(.34f, .24f);
            coreRect.anchorMax = new Vector2(.98f, .76f);
            coreRect.offsetMin = coreRect.offsetMax = Vector2.zero;
            var core = coreGo.GetComponent<Image>();
            core.color = Color.white;
            core.raycastTarget = false;

            var tailGo = new GameObject("Tail", typeof(RectTransform), typeof(CanvasRenderer), typeof(Image));
            tailGo.layer = gameObject.layer;
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

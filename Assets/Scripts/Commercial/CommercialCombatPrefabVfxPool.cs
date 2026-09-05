using System.Collections.Generic;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialCombatPrefabVfxPool : MonoBehaviour
    {
        private enum FxKind { EnemyProjectile, AllyProjectile, AllyMelee }

        // Runtime state is deliberately separate from the visual prefab. The actor root
        // is the only transform advanced along the trajectory.
        private sealed class Instance
        {
            public FxKind Kind;
            public Transform Root;
            public GameObject Visual;
            public CommercialProjectileActor Actor;
            public bool Active;
            public bool Travelling;
            public float Elapsed;
            public float Duration;
            public float Hold;
            public Vector3 Start;
            public Vector3 Control;
            public Vector3 End;
        }

        [SerializeField] private GameObject enemyProjectilePrefab;
        [SerializeField] private GameObject allyProjectilePrefab;
        [SerializeField] private GameObject allyMeleePrefab;
        [SerializeField] private Camera worldCamera;
        // Lazily allocated. Twelve covers a full 3x3 AoE plus short overlap between casts.
        [SerializeField, Range(2, 12)] private int capacityPerType = 12;
        [SerializeField, Range(.2f, .8f)] private float projectileDuration = .45f;
        [SerializeField, Range(.05f, 2f)] private float projectileScale = .16f;
        [SerializeField, Range(.05f, 2f)] private float meleeScale = .12f;

        private readonly List<Instance> instances = new();
        private readonly Dictionary<long, float> recentSingleTarget = new();
        private readonly Dictionary<long, float> recentProjectile = new();

        public bool PlayProjectile(RectTransform source, RectTransform target, bool enemySource)
        {
            if (!source || !target) return false;
            return PlayProjectileInternal(source, target, Center(source), Center(target), enemySource);
        }

        public bool PlayProjectile(Transform source, Transform target, bool enemySource)
        {
            if (!source || !target) return false;
            return PlayProjectileInternal(source, target, source.position, target.position, enemySource);
        }

        private bool PlayProjectileInternal(Transform source, Transform target, Vector3 start, Vector3 end, bool enemySource)
        {
            var key = ((long)source.GetInstanceID() << 32) ^ (uint)target.GetInstanceID();
            var now = Time.unscaledTime;
            if (recentProjectile.TryGetValue(key, out var previous) && now - previous < .10f) return true;
            recentProjectile[key] = now;
            var kind = enemySource ? FxKind.EnemyProjectile : FxKind.AllyProjectile;
            if (!TryAcquire(kind, out var fx)) return false;
            if (!IsSafeWorldPoint(start) || !IsSafeWorldPoint(end)) return false;
            var distance = Vector3.Distance(start, end);
            fx.Start = start;
            fx.End = end;
            // Positions are world-space camera units, not 1080x1920 canvas pixels.
            // Keep the arc high enough to read without creating an invalid particle AABB.
            fx.Control = (start + end) * .5f + Vector3.up * Mathf.Clamp(distance * .55f, .8f, 2.4f);
            fx.Elapsed = 0f;
            fx.Duration = projectileDuration;
            fx.Hold = .35f;
            fx.Travelling = true;
            fx.Root.localPosition = start;
            var launchDirection = end - start;
            fx.Root.localRotation = launchDirection.sqrMagnitude > .001f
                ? Quaternion.Euler(0f, 0f, Mathf.Atan2(launchDirection.y, launchDirection.x) * Mathf.Rad2Deg - 90f)
                : Quaternion.identity;
            fx.Root.localScale = Vector3.one * projectileScale;
            ActivateAndRestart(fx);
            return true;
        }

        public bool PlayMelee(RectTransform source, RectTransform target)
        {
            if (!target) return false;
            return PlayMeleeInternal(source, target, source ? Center(source) : Center(target) + Vector3.down * .4f, Center(target));
        }

        public bool PlayMelee(Transform source, Transform target)
        {
            if (!target) return false;
            return PlayMeleeInternal(source, target, source ? source.position : target.position + Vector3.down * .4f, target.position);
        }

        private bool PlayMeleeInternal(Transform source, Transform target, Vector3 start, Vector3 end)
        {
            var sourceId = source ? source.GetInstanceID() : 0;
            var key = ((long)sourceId << 32) ^ (uint)target.GetInstanceID();
            var now = Time.unscaledTime;
            if (recentSingleTarget.TryGetValue(key, out var previous) && now - previous < .10f) return true;
            recentSingleTarget[key] = now;
            if (!TryAcquire(FxKind.AllyMelee, out var fx)) return false;
            if (!IsSafeWorldPoint(start) || !IsSafeWorldPoint(end)) return false;
            var direction = end - start;
            fx.Elapsed = 0f;
            fx.Duration = 0f;
            fx.Hold = .65f;
            fx.Travelling = false;
            fx.Root.localPosition = end;
            fx.Root.localRotation = Quaternion.Euler(0f, 0f,
                Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg - 35f);
            fx.Root.localScale = Vector3.one * meleeScale;
            ActivateAndRestart(fx);
            return true;
        }

        private void Update()
        {
            foreach (var fx in instances)
            {
                if (!fx.Active) continue;
                fx.Elapsed += Time.unscaledDeltaTime;
                if (fx.Travelling)
                {
                    var t = Mathf.Clamp01(fx.Elapsed / Mathf.Max(.01f, fx.Duration));
                    var eased = t * t * (3f - 2f * t);
                    var inv = 1f - eased;
                    fx.Root.localPosition = inv * inv * fx.Start + 2f * inv * eased * fx.Control + eased * eased * fx.End;
                    if (t < 1f) continue;
                    fx.Travelling = false;
                    fx.Elapsed = 0f;
                    fx.Actor.StopTrailEmission();
                }
                if (fx.Elapsed < fx.Hold) continue;
                Deactivate(fx);
            }
        }

        private bool TryAcquire(FxKind kind, out Instance result)
        {
            result = instances.Find(item => item.Kind == kind && !item.Active);
            if (result == null)
            {
                var count = instances.FindAll(item => item.Kind == kind).Count;
                if (count >= capacityPerType) return false;
                var prefab = PrefabFor(kind);
                if (!prefab) return false;
                result = Create(kind, prefab, count);
                instances.Add(result);
            }
            result.Active = true;
            return true;
        }

        private Instance Create(FxKind kind, GameObject prefab, int index)
        {
            var holder = new GameObject($"{kind}_{index:00}");
            var holderTransform = holder.transform;
            holderTransform.SetParent(transform, false);
            var visual = Instantiate(prefab, holderTransform, false);
            visual.name = prefab.name;
            visual.transform.localPosition = Vector3.zero;
            visual.transform.localRotation = Quaternion.identity;
            visual.transform.localScale = Vector3.one;
            var actor = holder.AddComponent<CommercialProjectileActor>();
            actor.Bind(visual, kind == FxKind.AllyProjectile);
            if (kind == FxKind.AllyProjectile) actor.ConfigureAllyGloryBody();
            SetLayerRecursively(holder, gameObject.layer);
            foreach (var renderer in visual.GetComponentsInChildren<Renderer>(true))
            {
                renderer.sortingOrder = 61;
                // The imported Feilong effects contain world-simulation particles whose
                // automatic bounds occasionally become non-finite when pooled and moved.
                // A fixed local bound is ample for these compact combat effects and keeps
                // camera sorting/culling stable on URP mobile targets.
                renderer.localBounds = new Bounds(Vector3.zero, Vector3.one * 16f);
            }
            holder.SetActive(false);
            return new Instance { Kind = kind, Root = holderTransform, Visual = visual, Actor = actor };
        }

        private GameObject PrefabFor(FxKind kind) => kind switch
        {
            FxKind.EnemyProjectile => enemyProjectilePrefab,
            FxKind.AllyProjectile => allyProjectilePrefab,
            _ => allyMeleePrefab
        };

        private Vector3 Center(RectTransform target)
        {
            if (!worldCamera) return Vector3.zero;
            var canvas = target.GetComponentInParent<Canvas>();
            var eventCamera = canvas && canvas.renderMode != RenderMode.ScreenSpaceOverlay ? canvas.worldCamera : null;
            var screen = RectTransformUtility.WorldToScreenPoint(eventCamera, target.TransformPoint(target.rect.center));
            var world = worldCamera.ScreenToWorldPoint(new Vector3(screen.x, screen.y, 4.7f));
            return transform.InverseTransformPoint(world);
        }

        private static bool IsSafeWorldPoint(Vector3 value) =>
            float.IsFinite(value.x) && float.IsFinite(value.y) && float.IsFinite(value.z) &&
            Mathf.Abs(value.x) < 20f && Mathf.Abs(value.y) < 20f && Mathf.Abs(value.z) < 20f;

        private static void ActivateAndRestart(Instance fx)
        {
            // Position/rotation/scale are assigned before activation so a pooled
            // TrailRenderer never draws a line from its previous target to the new start.
            fx.Root.gameObject.SetActive(true);
            fx.Root.SetAsLastSibling();
            fx.Actor.Begin();
        }

        private static void SetLayerRecursively(GameObject root, int layer)
        {
            root.layer = layer;
            foreach (Transform child in root.transform) SetLayerRecursively(child.gameObject, layer);
        }

        private static void Deactivate(Instance fx)
        {
            fx.Actor.ResetActor();
            fx.Active = false;
            fx.Root.gameObject.SetActive(false);
        }

        private void OnDisable()
        {
            foreach (var fx in instances) Deactivate(fx);
            recentSingleTarget.Clear();
            recentProjectile.Clear();
        }
    }
}

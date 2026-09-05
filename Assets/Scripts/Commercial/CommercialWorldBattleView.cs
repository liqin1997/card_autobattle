using System;
using System.Collections.Generic;
using System.Linq;
using DG.Tweening;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    /// <summary>World-space visual stage. Battle rules remain in CommercialBattleSession.</summary>
    [DisallowMultipleComponent]
    public sealed class CommercialWorldBattleView : MonoBehaviour
    {
        [SerializeField] private Camera battleCamera;
        [SerializeField] private Sprite heroSprite;
        [SerializeField] private Sprite minionSprite;
        [SerializeField] private Sprite eliteSprite;
        [SerializeField] private Sprite bossSprite;
        [SerializeField] private Sprite backgroundSprite;
        [SerializeField] private Sprite sceneryLeftSprite;
        [SerializeField] private Sprite sceneryRightSprite;
        [SerializeField] private Vector2 stageCenter = new(0f, .45f);
        [SerializeField] private Vector2 stageSize = new(18f, 34f);

        private readonly Dictionary<string, UnitVisual> units = new();
        private CommercialBattleArenaView uiAnchors;
        private CommercialBattleSession session;

        private sealed class UnitVisual
        {
            public GameObject Root;
            public Transform Body;
            public Transform ProjectileAnchor;
            public Transform WeaponAnchor;
            public Transform HitAnchor;
            public SpriteRenderer Renderer;
            public CommercialCombatant Runtime;
            public Vector3 Rest;
        }

        private void Awake()
        {
            if (!battleCamera) battleCamera = GetComponentInParent<Camera>();
            BuildBackground();
        }

        public void Bind(CommercialBattleSession battle, CommercialBattleArenaView anchors)
        {
            session = battle;
            uiAnchors = anchors;
            Refresh();
        }

        public void Refresh()
        {
            if (session == null || uiAnchors == null || battleCamera == null) return;
            var visible = session.Allies.Concat(session.Enemies)
                .Where(value => value.Alive && (!value.Enemy || session.Elapsed >= value.SpawnDelay)).ToArray();
            var heroRuntime = session.Hero;
            if (heroRuntime != null)
            {
                // Keep the hero inside the lower part of the unobstructed battlefield,
                // with enough room below the sprite before the 3x3 board begins.
                var cameraTarget = new Vector3(heroRuntime.Position.x, heroRuntime.Position.y + .15f, -10f);
                battleCamera.transform.position = Vector3.Lerp(battleCamera.transform.position, cameraTarget,
                    1f - Mathf.Exp(-Time.unscaledDeltaTime * 5f));
            }
            var aliveIds = new HashSet<string>(visible.Select(value => value.Id));
            foreach (var stale in units.Where(pair => !aliveIds.Contains(pair.Key)).Select(pair => pair.Key).ToArray())
            {
                KillVisualTweens(units[stale]);
                Destroy(units[stale].Root);
                units.Remove(stale);
            }
            foreach (var combatant in visible)
            {
                var anchor = uiAnchors.FindAnchor(combatant.Id);
                if (!anchor) continue;
                SyncUiAnchor(anchor, combatant.Position);
                if (!units.TryGetValue(combatant.Id, out var visual))
                {
                    visual = Create(combatant);
                    units.Add(combatant.Id, visual);
                }
                visual.Runtime = combatant;
                visual.Rest = new Vector3(combatant.Position.x, combatant.Position.y, 0f);
                visual.Root.transform.position = Vector3.Lerp(visual.Root.transform.position, visual.Rest,
                    1f - Mathf.Exp(-Time.unscaledDeltaTime * 12f));
                var order = combatant.EnemyTier switch
                {
                    CommercialEnemyTier.Boss => 360,
                    CommercialEnemyTier.Elite => 300,
                    _ => 220
                };
                if (!combatant.Enemy) order = combatant.IsHero ? 280 : 240;
                visual.Renderer.sortingOrder = order - Mathf.RoundToInt(visual.Root.transform.position.y * 10f);
            }
        }

        public Transform FindAnchor(string runtimeId) =>
            !string.IsNullOrEmpty(runtimeId) && units.TryGetValue(runtimeId, out var value) ? value.Body : null;
        public Transform FindProjectileAnchor(string runtimeId) => FindUnitAnchor(runtimeId, value => value.ProjectileAnchor);
        public Transform FindWeaponAnchor(string runtimeId) => FindUnitAnchor(runtimeId, value => value.WeaponAnchor);
        public Transform FindHitAnchor(string runtimeId) => FindUnitAnchor(runtimeId, value => value.HitAnchor);

        public void Recoil(string sourceId, string targetId)
        {
            if (!units.TryGetValue(sourceId ?? string.Empty, out var source)) return;
            var target = FindAnchor(targetId);
            var direction = target ? (source.Rest - target.position).normalized : Vector3.down;
            source.Body.DOKill();
            source.Body.localPosition = Vector3.zero;
            source.Body.DOLocalMove(direction * .16f, .07f).SetLoops(2, LoopType.Yoyo).SetUpdate(true);
        }

        public void Hit(string runtimeId, Vector2 worldDirection)
        {
            if (!units.TryGetValue(runtimeId ?? string.Empty, out var target)) return;
            var direction = worldDirection.sqrMagnitude > .001f ? -(Vector3)worldDirection.normalized : Vector3.down;
            target.Body.DOKill();
            target.Body.localPosition = Vector3.zero;
            target.Body.DOLocalMove(direction * .12f, .055f).SetLoops(2, LoopType.Yoyo).SetUpdate(true);
            target.Renderer.DOColor(new Color(1f, .45f, .4f, 1f), .045f).SetLoops(2, LoopType.Yoyo).SetUpdate(true);
        }

        private static void KillVisualTweens(UnitVisual visual)
        {
            if (visual == null) return;
            if (visual.Body) visual.Body.DOKill();
            if (visual.Renderer) visual.Renderer.DOKill();
            if (visual.Root) visual.Root.transform.DOKill();
        }

        private void OnDestroy()
        {
            foreach (var visual in units.Values) KillVisualTweens(visual);
            units.Clear();
        }

        private UnitVisual Create(CommercialCombatant combatant)
        {
            var root = new GameObject($"WorldUnit_{combatant.Id}");
            root.transform.SetParent(transform, false);
            var body = new GameObject("Body");
            body.transform.SetParent(root.transform, false);
            var renderer = body.AddComponent<SpriteRenderer>();
            renderer.sprite = SpriteFor(combatant);
            renderer.color = Color.white;
            renderer.sortingLayerName = "Default";
            var height = combatant.EnemyTier == CommercialEnemyTier.Boss ? 1.65f :
                combatant.EnemyTier == CommercialEnemyTier.Elite ? 1.20f : combatant.IsHero ? 1.22f :
                combatant.IsSummon ? .72f : .82f;
            if (renderer.sprite)
            {
                var boundsHeight = Mathf.Max(.01f, renderer.sprite.bounds.size.y);
                body.transform.localScale = Vector3.one * (height / boundsHeight);
            }
            root.transform.position = new Vector3(combatant.Position.x, combatant.Position.y, 0f);
            var facing = combatant.Enemy ? -1f : 1f;
            var projectileAnchor = NewAnchor(root.transform, "ProjectileSpawnAnchor",
                new Vector3(height * .20f, height * .14f * facing, 0f));
            var weaponAnchor = NewAnchor(root.transform, "WeaponAnchor",
                new Vector3(height * .24f, height * .02f * facing, 0f));
            var hitAnchor = NewAnchor(root.transform, "HitAnchor",
                new Vector3(0f, height * .08f, 0f));
            return new UnitVisual
            {
                Root = root, Body = body.transform, Renderer = renderer, Runtime = combatant,
                Rest = root.transform.position, ProjectileAnchor = projectileAnchor,
                WeaponAnchor = weaponAnchor, HitAnchor = hitAnchor
            };
        }

        private Transform FindUnitAnchor(string runtimeId, Func<UnitVisual, Transform> selector)
        {
            return !string.IsNullOrEmpty(runtimeId) && units.TryGetValue(runtimeId, out var value) ? selector(value) : null;
        }

        private static Transform NewAnchor(Transform parent, string anchorName, Vector3 position)
        {
            var anchor = new GameObject(anchorName).transform;
            anchor.SetParent(parent, false);
            anchor.localPosition = position;
            return anchor;
        }

        private Sprite SpriteFor(CommercialCombatant value)
        {
            if (value.IsHero) return heroSprite;
            if (value.IsSummon) return minionSprite;
            return value.EnemyTier switch
            {
                CommercialEnemyTier.Boss => bossSprite ? bossSprite : eliteSprite,
                CommercialEnemyTier.Elite => eliteSprite ? eliteSprite : minionSprite,
                _ => minionSprite
            };
        }

        private Vector3 ScreenAnchorToWorld(RectTransform anchor)
        {
            var screen = RectTransformUtility.WorldToScreenPoint(battleCamera, anchor.position);
            var world = battleCamera.ScreenToWorldPoint(new Vector3(screen.x, screen.y, 10f));
            world.z = 0f;
            return world;
        }

        private void SyncUiAnchor(RectTransform anchor, Vector2 worldPosition)
        {
            if (!(anchor.parent is RectTransform parent)) return;
            var screen = battleCamera.WorldToScreenPoint(new Vector3(worldPosition.x, worldPosition.y, 0f));
            if (RectTransformUtility.ScreenPointToLocalPointInRectangle(parent, screen, battleCamera, out var local))
            {
                var tracked = anchor.GetComponent<CommercialCombatantDiscView>();
                if (tracked) tracked.SetTrackedPosition(local);
                else anchor.anchoredPosition = local;
            }
        }

        private void BuildBackground()
        {
            if (!backgroundSprite || transform.Find("TowerDefenseBackground")) return;
            var go = new GameObject("TowerDefenseBackground");
            go.transform.SetParent(transform, false);
            go.transform.localPosition = new Vector3(stageCenter.x, stageCenter.y, 1f);
            var renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = backgroundSprite;
            renderer.color = new Color(.42f, .46f, .42f, 1f);
            renderer.sortingOrder = -500;
            var size = backgroundSprite.bounds.size;
            go.transform.localScale = new Vector3(stageSize.x / Mathf.Max(.01f, size.x), stageSize.y / Mathf.Max(.01f, size.y), 1f);
            AddScenery("SceneryLeft", sceneryLeftSprite, new Vector3(-4.05f, 1.25f, 0f), 3.1f, -420, false);
            AddScenery("SceneryRight", sceneryRightSprite, new Vector3(4.05f, 1.55f, 0f), 3.25f, -410, true);
        }

        private void AddScenery(string objectName, Sprite sprite, Vector3 position, float height, int order, bool flip)
        {
            if (!sprite) return;
            var go = new GameObject(objectName);
            go.transform.SetParent(transform, false);
            go.transform.localPosition = position;
            var renderer = go.AddComponent<SpriteRenderer>();
            renderer.sprite = sprite;
            renderer.flipX = flip;
            renderer.color = new Color(.42f, .46f, .45f, .92f);
            renderer.sortingOrder = order;
            var scale = height / Mathf.Max(.01f, sprite.bounds.size.y);
            go.transform.localScale = Vector3.one * scale;
        }
    }
}

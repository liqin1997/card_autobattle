using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialCombatantDiscView : MonoBehaviour
    {
        private RawImage portrait;
        private Image healthFill;
        private Image shieldFill;
        private Image selection;
        private Image flash;
        private Text healthText;
        private Text title;
        private Text hiddenCards;
        private Button button;
        private CommercialCombatant combatant;
        private string boundId;
        private Vector2 restPosition;
        private Coroutine hitRoutine;
        private bool entering;

        public CommercialCombatant Combatant => combatant;
        public RectTransform Rect => transform as RectTransform;

        private void Awake()
        {
            Cache();
            // Builder placeholders must never flash as solid circles before a runtime
            // combatant has actually reached its configured spawn time.
            gameObject.SetActive(false);
        }

        private void Cache()
        {
            if (button) return;
            button = GetComponent<Button>();
            portrait = Find("Portrait")?.GetComponent<RawImage>();
            healthFill = Find("HealthFill")?.GetComponent<Image>();
            shieldFill = Find("ShieldFill")?.GetComponent<Image>();
            selection = Find("Selection")?.GetComponent<Image>();
            flash = Find("HitFlash")?.GetComponent<Image>();
            healthText = Find("HealthText")?.GetComponent<Text>();
            title = Find("Title")?.GetComponent<Text>();
            hiddenCards = Find("HiddenCards")?.GetComponent<Text>();
        }

        public void Bind(CommercialCombatant value, bool focused, Action onClick, bool animateEntrance)
        {
            Cache();
            combatant = value;
            var newBinding = boundId != value?.Id;
            boundId = value?.Id;
            if (button)
            {
                button.onClick.RemoveAllListeners();
                if (onClick != null) button.onClick.AddListener(() => onClick());
                button.interactable = value?.Enemy == true;
            }
            if (title) title.text = value?.DisplayName ?? string.Empty;
            if (value?.Enemy == true)
            {
                var size = value.EnemyTier switch
                {
                    CommercialEnemyTier.Boss => 230f,
                    CommercialEnemyTier.Elite => 184f,
                    _ => 144f
                };
                Rect.sizeDelta = new Vector2(size, size);
            }
            if (hiddenCards)
            {
                hiddenCards.gameObject.SetActive(value?.Enemy == true);
                hiddenCards.text = value == null ? string.Empty : $"卡组 {value.HiddenCardCount}";
            }
            if (selection) selection.gameObject.SetActive(focused);
            if (portrait)
            {
                // Unit art now belongs to CommercialWorldBattleView. This RawImage remains
                // only as a legacy anchor so older card portraits cannot cover world units.
                portrait.texture = null;
                portrait.enabled = false;
                portrait.color = Color.white;
            }
            gameObject.SetActive(value != null && value.Alive);
            if (!gameObject.activeSelf) return;
            restPosition = Rect.anchoredPosition;
            if (newBinding && animateEntrance && value.Enemy)
            {
                var offset = value.ArenaSlot % 3 == 0 ? new Vector2(-420f, 80f) :
                    value.ArenaSlot % 3 == 1 ? new Vector2(0f, 360f) : new Vector2(420f, 80f);
                Rect.DOKill();
                Rect.anchoredPosition = restPosition + offset;
                Rect.localScale = Vector3.one * .72f;
                entering = true;
                Rect.DOAnchorPos(restPosition, .58f).SetEase(Ease.OutCubic).SetUpdate(true)
                    .OnComplete(() => { entering = false; Rect.anchoredPosition = restPosition; });
                Rect.DOScale(1f, .48f).SetEase(Ease.OutBack).SetUpdate(true);
            }
            else if (newBinding) entering = false;
            Refresh(focused);
        }

        public void Refresh(bool focused)
        {
            if (combatant == null) return;
            if (selection) selection.gameObject.SetActive(focused && combatant.Alive);
            if (!combatant.Alive)
            {
                gameObject.SetActive(false);
                return;
            }
            if (!gameObject.activeSelf) gameObject.SetActive(true);
            if (healthFill) healthFill.fillAmount = combatant.Health01;
            if (shieldFill) shieldFill.fillAmount = Mathf.Clamp01(combatant.Shield / Mathf.Max(1f, combatant.MaxHealth));
            if (healthText) healthText.text = combatant.Shield > .01f
                ? $"{Mathf.CeilToInt(combatant.Health)}/{Mathf.CeilToInt(combatant.MaxHealth)}  盾{Mathf.CeilToInt(combatant.Shield)}"
                : $"{Mathf.CeilToInt(combatant.Health)}/{Mathf.CeilToInt(combatant.MaxHealth)}";
        }

        public void FlashAction()
        {
            if (!gameObject.activeInHierarchy) return;
            Rect.DOPunchScale(Vector3.one * .10f, .25f, 5, .55f).SetUpdate(true);
        }

        public void SetTrackedPosition(Vector2 position)
        {
            restPosition = position;
            if (!entering) Rect.anchoredPosition = position;
        }

        public void Recoil(Vector2 attackDirection)
        {
            if (!gameObject.activeInHierarchy) return;
            // Do not interrupt the spawn-to-attack-position movement. Interrupting that tween
            // left enemies stranded near the viewport edge after their first attack.
            if (entering) return;
            var direction = attackDirection.sqrMagnitude > .01f ? attackDirection.normalized : Vector2.up;
            var start = restPosition;
            Rect.anchoredPosition = start;
            var returnPosition = restPosition;
            DOTween.Kill(Rect, false);
            DOTween.Sequence().SetUpdate(true).SetTarget(Rect)
                .Append(Rect.DOAnchorPos(start - direction * 14f, .07f).SetEase(Ease.OutQuad))
                .Append(Rect.DOAnchorPos(returnPosition, .13f).SetEase(Ease.OutBack));
            Rect.DOPunchScale(Vector3.one * .07f, .20f, 4, .45f).SetUpdate(true);
        }

        public void ReceiveHit(Vector2 direction)
        {
            if (!gameObject.activeInHierarchy) return;
            if (entering) return;
            if (hitRoutine != null) StopCoroutine(hitRoutine);
            hitRoutine = StartCoroutine(HitFeedback(direction));
        }

        private IEnumerator HitFeedback(Vector2 direction)
        {
            var start = restPosition;
            Rect.anchoredPosition = start;
            var returnPosition = restPosition;
            var normalized = direction.sqrMagnitude > .01f ? direction.normalized : Vector2.down;
            if (flash) flash.gameObject.SetActive(false);
            var portraitColor = portrait ? portrait.color : Color.white;
            const float pushDuration = .07f;
            const float returnDuration = .13f;
            for (var t = 0f; t < pushDuration; t += Time.unscaledDeltaTime)
            {
                var progress = Mathf.Clamp01(t / pushDuration);
                Rect.anchoredPosition = Vector2.Lerp(start, start + normalized * 18f, Mathf.SmoothStep(0f, 1f, progress));
                if (portrait) portrait.color = Color.Lerp(portraitColor, new Color(1f, .42f, .38f, 1f), progress * .65f);
                yield return null;
            }
            for (var t = 0f; t < returnDuration; t += Time.unscaledDeltaTime)
            {
                var progress = Mathf.Clamp01(t / returnDuration);
                Rect.anchoredPosition = Vector2.Lerp(start + normalized * 18f, returnPosition, Mathf.SmoothStep(0f, 1f, progress));
                if (portrait) portrait.color = Color.Lerp(new Color(1f, .42f, .38f, 1f), portraitColor, progress);
                yield return null;
            }
            Rect.anchoredPosition = returnPosition;
            if (portrait) portrait.color = portraitColor;
            if (flash) flash.gameObject.SetActive(false);
            hitRoutine = null;
        }

        private Transform Find(string childName) => GetComponentsInChildren<Transform>(true)
            .FirstOrDefault(item => item.name == childName);

        private static Texture2D ResolvePortrait(string key)
        {
            var path = $"Commercial/BattleUI/battle_card_art_{key}_544x336";
            // These textures are imported as Sprite assets, so loading them directly as
            // Texture2D returns null in a player build. RawImage uses the sprite's texture.
            var sprites = Resources.LoadAll<Sprite>(path);
            return sprites != null && sprites.Length > 0 ? sprites[0].texture : null;
        }

        private static string EnemyArt(int index) => (index % 5) switch
        {
            0 => "summon_skull", 1 => "defense_shield", 2 => "hero_swordsman",
            3 => "sword_relic", _ => "thunder_cannon"
        };
    }

    [DisallowMultipleComponent]
    internal sealed class CommercialBattleArenaViewLegacy : MonoBehaviour
    {
        private readonly Dictionary<string, CommercialCombatantDiscView> byId = new();
        private CommercialCombatantDiscView hero;
        private CommercialCombatantDiscView[] enemies;
        private CommercialCombatantDiscView[] summons;
        private CommercialBattleSession session;

        private void Awake() => Cache();

        private void Cache()
        {
            hero ??= Find("HeroDisc")?.GetComponent<CommercialCombatantDiscView>();
            enemies ??= Enumerable.Range(0, 8).Select(i => Find($"EnemyDisc_{i}")?.GetComponent<CommercialCombatantDiscView>()).ToArray();
            summons ??= Enumerable.Range(0, 3).Select(i => Find($"SummonDisc_{i}")?.GetComponent<CommercialCombatantDiscView>()).ToArray();
        }

        public void Bind(CommercialBattleSession battle, Action<CommercialCombatant> enemyClicked)
        {
            Cache();
            session = battle;
            byId.Clear();
            if (hero && battle?.Hero != null)
            {
                hero.Bind(battle.Hero, false, null, false);
                byId[battle.Hero.Id] = hero;
            }
            for (var i = 0; i < enemies.Length; i++)
            {
                var target = battle != null && i < battle.Enemies.Count ? battle.Enemies[i] : null;
                var view = enemies[i];
                if (!view) continue;
                if (target == null || battle.Elapsed < target.SpawnDelay) { view.gameObject.SetActive(false); continue; }
                var captured = target;
                view.Bind(target, battle.FocusedEnemyId == target.Id, () => enemyClicked?.Invoke(captured), true);
                byId[target.Id] = view;
                view.transform.SetSiblingIndex(target.EnemyTier switch
                {
                    CommercialEnemyTier.Boss => 99, CommercialEnemyTier.Elite => 70, _ => 30 + i
                });
            }
            Refresh(enemyClicked);
        }

        public void Refresh(Action<CommercialCombatant> enemyClicked)
        {
            if (session == null) return;
            if (hero) hero.Refresh(false);
            for (var i = 0; i < enemies.Length; i++)
            {
                var target = i < session.Enemies.Count ? session.Enemies[i] : null;
                var view = enemies[i];
                if (!view) continue;
                if (target != null && target.Alive && session.Elapsed >= target.SpawnDelay)
                {
                    if (view.Combatant != target)
                    {
                        var captured = target;
                        view.Bind(target, session.FocusedEnemyId == target.Id, () => enemyClicked?.Invoke(captured), true);
                        byId[target.Id] = view;
                    }
                    view.Refresh(session.FocusedEnemyId == target.Id);
                }
                else view.gameObject.SetActive(false);
            }
            var livingSummons = session.Allies.Where(value => value.IsSummon && value.Alive).Take(summons.Length).ToArray();
            for (var i = 0; i < summons.Length; i++)
            {
                var view = summons[i];
                if (!view) continue;
                var target = i < livingSummons.Length ? livingSummons[i] : null;
                if (target == null) { view.gameObject.SetActive(false); continue; }
                if (view.Combatant != target) view.Bind(target, false, null, false);
                view.Refresh(false);
                byId[target.Id] = view;
            }
        }

        public RectTransform FindAnchor(string runtimeId)
        {
            if (string.IsNullOrEmpty(runtimeId)) return null;
            return byId.TryGetValue(runtimeId, out var view) && view && view.gameObject.activeInHierarchy ? view.Rect : null;
        }

        public void Flash(string runtimeId) { if (byId.TryGetValue(runtimeId ?? string.Empty, out var view)) view?.FlashAction(); }
        public void Recoil(string sourceId, string targetId)
        {
            if (!byId.TryGetValue(sourceId ?? string.Empty, out var source) || !source) return;
            var target = FindAnchor(targetId);
            var direction = target ? (Vector2)(target.position - source.Rect.position) : Vector2.up;
            source.Recoil(direction);
        }
        public void Hit(string runtimeId, Vector2 direction) { if (byId.TryGetValue(runtimeId ?? string.Empty, out var view)) view?.ReceiveHit(direction); }

        private Transform Find(string childName) => GetComponentsInChildren<Transform>(true)
            .FirstOrDefault(item => item.name == childName);
    }
}

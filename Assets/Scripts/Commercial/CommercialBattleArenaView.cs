using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    [DisallowMultipleComponent]
    public sealed class CommercialBattleArenaView : MonoBehaviour
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
            Cache(); session = battle; byId.Clear();
            if (hero && battle?.Hero != null) { hero.Bind(battle.Hero, false, null, false); byId[battle.Hero.Id] = hero; }
            for (var i = 0; i < enemies.Length; i++)
            {
                var target = battle != null && i < battle.Enemies.Count ? battle.Enemies[i] : null;
                var view = enemies[i]; if (!view) continue;
                if (target == null || battle.Elapsed < target.SpawnDelay) { view.gameObject.SetActive(false); continue; }
                var captured = target;
                view.Bind(target, battle.FocusedEnemyId == target.Id, () => enemyClicked?.Invoke(captured), false);
                byId[target.Id] = view;
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
                var view = enemies[i]; if (!view) continue;
                if (target != null && target.Alive && session.Elapsed >= target.SpawnDelay)
                {
                    if (view.Combatant != target)
                    {
                        var captured = target;
                        view.Bind(target, session.FocusedEnemyId == target.Id, () => enemyClicked?.Invoke(captured), false);
                        byId[target.Id] = view;
                    }
                    view.Refresh(session.FocusedEnemyId == target.Id);
                }
                else view.gameObject.SetActive(false);
            }
            var livingSummons = session.Allies.Where(value => value.IsSummon && value.Alive).Take(summons.Length).ToArray();
            for (var i = 0; i < summons.Length; i++)
            {
                var view = summons[i]; if (!view) continue;
                var target = i < livingSummons.Length ? livingSummons[i] : null;
                if (target == null) { view.gameObject.SetActive(false); continue; }
                if (view.Combatant != target) view.Bind(target, false, null, false);
                view.Refresh(false); byId[target.Id] = view;
            }
        }
        public RectTransform FindAnchor(string runtimeId) => string.IsNullOrEmpty(runtimeId) ? null :
            byId.TryGetValue(runtimeId, out var view) && view && view.gameObject.activeInHierarchy ? view.Rect : null;
        public void Flash(string runtimeId) { if (byId.TryGetValue(runtimeId ?? string.Empty, out var view)) view?.FlashAction(); }
        public void Recoil(string sourceId, string targetId)
        {
            if (!byId.TryGetValue(sourceId ?? string.Empty, out var source) || !source) return;
            var target = FindAnchor(targetId);
            source.Recoil(target ? (Vector2)(target.position - source.Rect.position) : Vector2.up);
        }
        public void Hit(string runtimeId, Vector2 direction) { if (byId.TryGetValue(runtimeId ?? string.Empty, out var view)) view?.ReceiveHit(direction); }
        private Transform Find(string childName) => GetComponentsInChildren<Transform>(true).FirstOrDefault(item => item.name == childName);
    }
}

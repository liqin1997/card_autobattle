#if UNITY_EDITOR
using System;
using System.Linq;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEngine;

namespace CardAutobattle.Editor
{
    public static class CommercialBattleV2Acceptance
    {
        [MenuItem("Tools/Commercial/Validate Battle V2")]
        public static void Run()
        {
            var state = CommercialGameState.CreateDefault();
            state.EnsureCharacterData();
            Require(state.DraftFormation.Slots.All(id => id != CommercialGameState.HeroCardId), "Hero must not occupy a card slot.");
            Require(state.DraftFormation.Slots.Count(id => !string.IsNullOrEmpty(id)) == 9, "Default formation must use all nine slots.");

            var normal = new CommercialBattleSession(state, state.DraftFormation, 101,
                Encounter(WorldNodeKind.Idle, 1));
            Require(normal.Hero.GridIndex == -1, "Hero must be arena-only.");
            Require(normal.Enemies.All(enemy => enemy.HiddenCardCount == 1), "Minions must own one hidden card.");
            normal.Advance(.6f);
            var focused = normal.Enemies.First(enemy => enemy.Alive);
            Require(normal.TogglePriorityTarget(focused.Id) && normal.FocusedEnemyId == focused.Id, "Priority focus failed.");
            Require(normal.TrySwapPlayerGridPositions(0, 1), "Runtime card swap failed.");

            var elite = new CommercialBattleSession(state, state.DraftFormation, 102,
                Encounter(WorldNodeKind.Elite, 3));
            Require(elite.Enemies.First().HiddenCardCount is >= 2 and <= 5, "Elite hidden deck must contain 2-5 cards.");
            var boss = new CommercialBattleSession(state, state.DraftFormation, 103,
                Encounter(WorldNodeKind.Boss, 5));
            Require(boss.Enemies.First().HiddenCardCount is >= 6 and <= 9, "Boss hidden deck must contain 6-9 cards.");

            var summonFormation = new CommercialFormation();
            summonFormation.Slots[0] = "stone_guard";
            var summonBattle = new CommercialBattleSession(state, summonFormation, 104,
                Encounter(WorldNodeKind.Idle, 1));
            var summon = summonBattle.Cards.Single().Summon;
            Require(!summon.Alive, "Summon must be absent at battle start.");
            summonBattle.Advance(3.5f);
            Require(summon.Alive, "Completed CD must summon the unit.");
            summonBattle.Advance(3.5f);
            Require(summon.Shield > 0f || summonBattle.Hero.Shield > 0f, "Living summon must use its signature action.");
            summon.Health = 0f;
            summonBattle.Advance(3.5f);
            Require(summon.Alive && Mathf.Approximately(summon.Health, summon.MaxHealth), "Dead summon must return on the next CD.");

            foreach (var enemy in boss.Enemies) enemy.Health = 0f;
            boss.Advance(.1f);
            Require(boss.Result == CommercialBattleResult.Victory, "Eliminating every enemy must win the battle.");
            Debug.Log("[BattleV2 Acceptance] PASS: arena hero, hidden enemy decks, focus, swap, summon lifecycle and victory.");
        }

        private static CommercialWorldEncounter Encounter(WorldNodeKind kind, int stage) => new()
        {
            NodeId = kind == WorldNodeKind.Boss ? "boss_1" : kind == WorldNodeKind.Elite ? "elite_1" : "main_1",
            Chapter = 1,
            Stage = stage,
            Kind = kind,
            HealthScale = 1f,
            AttackScale = 1f
        };

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException("[BattleV2 Acceptance] " + message);
        }
    }
}
#endif

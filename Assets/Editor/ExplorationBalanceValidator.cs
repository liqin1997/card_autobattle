using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Exploration;
using CardAutobattle.Preparation;
using CardAutobattle.Prototype;
using UnityEditor;
using UnityEngine;

namespace CardAutobattle.EditorTools
{
    public static class ExplorationBalanceValidator
    {
        private sealed class SimUnit
        {
            public CardDefinition Definition;
            public int Level;
            public int Index;
            public bool Enemy;
            public float Cooldown;
            public float Remaining;
            public SlotModifierType Modifier;
        }

        private sealed class Side
        {
            public float Health;
            public float MaxHealth;
            public float Shield;
            public float Burn;
            public float Poison;
            public readonly List<SimUnit> Units = new();
        }

        public readonly struct AuditResult
        {
            public readonly bool Won;
            public readonly float PlayerHealth;
            public readonly float EnemyHealth;
            public readonly float Duration;

            public AuditResult(bool won, float playerHealth, float enemyHealth, float duration)
            {
                Won = won;
                PlayerHealth = playerHealth;
                EnemyHealth = enemyHealth;
                Duration = duration;
            }

            public override string ToString()
            {
                return $"won={Won}, playerHP={PlayerHealth:0.0}, enemyHP={EnemyHealth:0.0}, time={Duration:0.0}s";
            }
        }

        [MenuItem("Tools/Card Autobattle/Validate Difficulty 1 Balance")]
        public static void ValidateDifficultyOne()
        {
            var casual = RunBoss(new[]
            {
                Entry("blade", 0), Entry("bow", 2), Entry("dagger", 3), Entry("shield", 4),
                Entry("herbs", 6), Entry("poison", 7), Entry("thorns", 8)
            }, 4);
            var strategic = RunBoss(new[]
            {
                Entry("dagger", 0), Entry("bow", 1), Entry("poison", 2), Entry("bow", 3),
                Entry("blade", 4), Entry("thorns", 5), Entry("shield", 6), Entry("herbs", 7), Entry("herbs", 8)
            }, 4);

            var targetMet = (!casual.Won || casual.PlayerHealth <= 24f) &&
                            strategic.Won && strategic.PlayerHealth >= 48f;
            var message = $"[Difficulty1Audit] casual: {casual}; strategic: {strategic}; targetMet={targetMet}";
            if (targetMet)
                Debug.Log(message);
            else
                Debug.LogWarning(message);
        }

        public static AuditResult RunBoss((string id, int index)[] playerEntries, int enhancedSlot)
        {
            var encounter = ExplorationMapCatalog.Get(1).Encounters.Last();
            var player = new Side { MaxHealth = 118f, Health = 92f };
            foreach (var entry in playerEntries)
            {
                player.Units.Add(CreateUnit(PrototypeCardCatalog.Get(entry.id), 1, entry.index, false,
                    entry.index == enhancedSlot ? SlotModifierType.DirectDamage : SlotModifierType.None,
                    1f));
            }

            var enemy = new Side { MaxHealth = encounter.EnemyMaxHealth, Health = encounter.EnemyMaxHealth };
            var count = Mathf.Min(encounter.EnemyCardIds.Length, encounter.EnemyPositions.Length);
            for (var i = 0; i < count; i++)
            {
                enemy.Units.Add(CreateUnit(PrototypeCardCatalog.Get(encounter.EnemyCardIds[i]),
                    encounter.EnemyLevel, encounter.EnemyPositions[i], true, SlotModifierType.None,
                    encounter.EnemyCooldownMultiplier));
            }

            const float step = .02f;
            const float timeLimit = 45f;
            var statusTimer = 0f;
            var time = 0f;
            while (time < timeLimit && player.Health > 0f && enemy.Health > 0f)
            {
                TickSide(player, enemy, step, 1f);
                TickSide(enemy, player, step, encounter.EnemyPowerMultiplier);
                time += step;
                statusTimer += step;
                if (statusTimer < 1f)
                    continue;
                statusTimer -= 1f;
                TickStatuses(player);
                TickStatuses(enemy);
            }

            var won = enemy.Health <= 0f || (player.Health > 0f && player.Health >= enemy.Health);
            return new AuditResult(won, player.Health, enemy.Health, time);
        }

        private static (string id, int index) Entry(string id, int index) => (id, index);

        private static SimUnit CreateUnit(CardDefinition definition, int level, int index, bool enemy,
            SlotModifierType modifier, float cooldownMultiplier)
        {
            var cooldown = enemy
                ? definition.Cooldown * cooldownMultiplier
                : SlotModifierRules.ModifyCooldown(modifier, definition.Cooldown);
            return new SimUnit
            {
                Definition = definition,
                Level = level,
                Index = index,
                Enemy = enemy,
                Cooldown = Mathf.Max(.35f, cooldown),
                Remaining = definition.Effect == CardEffectKind.PassivePowerAura
                    ? float.PositiveInfinity
                    : Mathf.Max(.35f, cooldown),
                Modifier = modifier
            };
        }

        private static void TickSide(Side source, Side target, float deltaTime, float powerMultiplier)
        {
            for (var i = 0; i < source.Units.Count && source.Health > 0f && target.Health > 0f; i++)
            {
                var unit = source.Units[i];
                if (float.IsPositiveInfinity(unit.Remaining))
                    continue;
                unit.Remaining -= deltaTime;
                if (unit.Remaining > 0f)
                    continue;
                unit.Remaining += unit.Cooldown;
                Resolve(unit, source, target, powerMultiplier);
            }
        }

        private static void Resolve(SimUnit unit, Side source, Side target, float powerMultiplier)
        {
            var adjacent = source.Units.Count(other => other != unit &&
                CardEffectValueResolver.AreAdjacent(other.Index, unit.Index) &&
                (unit.Definition.AdjacentRequiredTag == CardTag.None ||
                 (other.Definition.Tags & unit.Definition.AdjacentRequiredTag) != 0));
            var multiplier = powerMultiplier;
            foreach (var aura in source.Units)
            {
                if (aura != unit && aura.Definition.Effect == CardEffectKind.PassivePowerAura &&
                    CardEffectValueResolver.AreAdjacent(aura.Index, unit.Index))
                    multiplier *= 1f + aura.Definition.Power * aura.Level;
            }
            CardEffectValueResolver.ResolveScaledPowers(unit.Definition, unit.Level, adjacent,
                multiplier, out var power, out var secondary);

            float Modified(SlotModifierType stat, float value) => unit.Enemy
                ? value
                : SlotModifierRules.ModifyValue(unit.Modifier, stat, value);
            switch (unit.Definition.Effect)
            {
                case CardEffectKind.Damage:
                case CardEffectKind.ChainDamage:
                    Damage(target, Modified(SlotModifierType.DirectDamage, power));
                    break;
                case CardEffectKind.Shield:
                    source.Shield += Modified(SlotModifierType.Shield, power);
                    break;
                case CardEffectKind.Heal:
                    source.Health = Mathf.Min(source.MaxHealth,
                        source.Health + Modified(SlotModifierType.Healing, power));
                    break;
                case CardEffectKind.DamageAndBurn:
                    Damage(target, Modified(SlotModifierType.DirectDamage, power));
                    target.Burn += Modified(SlotModifierType.FireDamage, secondary);
                    break;
                case CardEffectKind.DamageAndPoison:
                    Damage(target, Modified(SlotModifierType.DirectDamage, power));
                    target.Poison += Modified(SlotModifierType.PoisonDamage, secondary);
                    break;
                case CardEffectKind.DamageAndSlow:
                    Damage(target, Modified(SlotModifierType.DirectDamage, power));
                    foreach (var enemy in target.Units)
                        if (!float.IsPositiveInfinity(enemy.Remaining)) enemy.Remaining += secondary;
                    break;
                case CardEffectKind.HasteNeighbours:
                    foreach (var ally in source.Units)
                        if (ally != unit && CardEffectValueResolver.AreAdjacent(ally.Index, unit.Index) &&
                            !float.IsPositiveInfinity(ally.Remaining)) ally.Remaining -= power;
                    break;
                case CardEffectKind.HasteAll:
                    foreach (var ally in source.Units)
                        if (ally != unit && !float.IsPositiveInfinity(ally.Remaining)) ally.Remaining -= power;
                    break;
                case CardEffectKind.DamageAndHaste:
                    Damage(target, Modified(SlotModifierType.DirectDamage, power));
                    var candidate = source.Units.Where(ally => ally != unit && !float.IsPositiveInfinity(ally.Remaining))
                        .OrderByDescending(ally => ally.Remaining).FirstOrDefault();
                    if (candidate != null) candidate.Remaining -= secondary;
                    break;
                case CardEffectKind.ShieldAndDamage:
                    source.Shield += Modified(SlotModifierType.Shield, power);
                    Damage(target, Modified(SlotModifierType.DirectDamage, secondary));
                    break;
                case CardEffectKind.Drain:
                    Damage(target, Modified(SlotModifierType.DirectDamage, power));
                    source.Health = Mathf.Min(source.MaxHealth,
                        source.Health + Modified(SlotModifierType.Healing, secondary));
                    break;
                case CardEffectKind.ShieldAndVictoryGold:
                    source.Shield += Modified(SlotModifierType.Shield, power);
                    break;
                case CardEffectKind.ShieldAndHeal:
                    source.Shield += Modified(SlotModifierType.Shield, power);
                    source.Health = Mathf.Min(source.MaxHealth,
                        source.Health + Modified(SlotModifierType.Healing, secondary));
                    break;
            }
        }

        private static void TickStatuses(Side side)
        {
            Damage(side, side.Burn + side.Poison);
            side.Burn = Mathf.Max(0f, side.Burn - 1f);
            side.Poison = Mathf.Max(0f, side.Poison - .5f);
        }

        private static void Damage(Side side, float amount)
        {
            var blocked = Mathf.Min(side.Shield, amount);
            side.Shield -= blocked;
            side.Health = Mathf.Max(0f, side.Health - (amount - blocked));
        }
    }
}

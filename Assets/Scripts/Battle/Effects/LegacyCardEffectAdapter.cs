using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Preparation;
using CardAutobattle.Prototype;

namespace CardAutobattle.Battle
{
    /// <summary>Migration boundary for the existing CardDefinition/CardEffectKind catalog.</summary>
    public static class LegacyCardEffectAdapter
    {
        public static void Execute(CardRuntime card, BattleContext context, float externalMultiplier,
            int adjacentCount, SlotModifierType modifier, IReadOnlyList<CardRuntime> allies)
        {
            var definition = card.LegacyDefinition;
            CardEffectValueResolver.ResolveScaledPowers(definition, card.Level, adjacentCount,
                externalMultiplier, out var power, out var secondary);
            context.Events.Publish(new SimpleBattleEvent(BattleEventType.EffectStarted), context.Clock.BattleTime,
                context.NextTriggerId, card.Owner.RuntimeId, Target(card.Owner, context).RuntimeId);

            var target = Target(card.Owner, context);
            switch (definition.Effect)
            {
                case CardEffectKind.Damage:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power)); break;
                case CardEffectKind.Shield:
                    Shield(card.Owner, Modify(modifier, SlotModifierType.Shield, power)); break;
                case CardEffectKind.Heal:
                    Heal(card.Owner, Modify(modifier, SlotModifierType.Healing, power)); break;
                case CardEffectKind.DamageAndBurn:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power));
                    AddBurn(target, Modify(modifier, SlotModifierType.FireDamage, secondary), card.Owner); break;
                case CardEffectKind.DamageAndPoison:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power));
                    AddPoison(target, Modify(modifier, SlotModifierType.PoisonDamage, secondary), card.Owner); break;
                case CardEffectKind.DamageAndSlow:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power));
                    foreach (var ally in Opposite(card.Owner, context).Cards) ally.Advance(-secondary); break;
                case CardEffectKind.HasteNeighbours:
                    foreach (var ally in allies.Where(a => a != card && GridPosition.AreAdjacent(a.Position, card.Position))) ally.Advance(power); break;
                case CardEffectKind.HasteAll:
                    foreach (var ally in allies.Where(a => a != card)) ally.Advance(power); break;
                case CardEffectKind.DamageAndHaste:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power));
                    allies.Where(a => a != card).OrderByDescending(a => a.CooldownRemaining).FirstOrDefault()?.Advance(secondary); break;
                case CardEffectKind.ShieldAndDamage:
                    Shield(card.Owner, Modify(modifier, SlotModifierType.Shield, power));
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, secondary)); break;
                case CardEffectKind.Drain:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power));
                    Heal(card.Owner, Modify(modifier, SlotModifierType.Healing, secondary)); break;
                case CardEffectKind.ChainDamage:
                    Damage(target, Modify(modifier, SlotModifierType.DirectDamage, power)); break;
                case CardEffectKind.ShieldAndVictoryGold:
                    Shield(card.Owner, Modify(modifier, SlotModifierType.Shield, power)); break;
                case CardEffectKind.ShieldAndHeal:
                    Shield(card.Owner, Modify(modifier, SlotModifierType.Shield, power));
                    Heal(card.Owner, Modify(modifier, SlotModifierType.Healing, secondary)); break;
            }
        }

        public static void TickStatuses(BattleContext context)
        {
            Tick(context.Player, context.Enemy);
            Tick(context.Enemy, context.Player);
        }

        private static void Tick(BattleUnitRuntime owner, BattleUnitRuntime target)
        {
            var burn = owner.Buffs.GetStacks("burn");
            var poison = owner.Buffs.GetStacks("poison");
            if (burn > 0 || poison > 0) target.ApplyDamage(burn + poison * .5f);
            if (burn > 0) owner.Buffs.RemoveStacks("burn", 1);
            if (poison > 0) owner.Buffs.RemoveStacks("poison", 1);
        }

        private static BattleUnitRuntime Target(BattleUnitRuntime source, BattleContext context) =>
            source.Side == BattleSide.Player ? context.Enemy : context.Player;
        private static BattleUnitRuntime Opposite(BattleUnitRuntime source, BattleContext context) => Target(source, context);
        private static void Damage(BattleUnitRuntime target, float amount) => target.ApplyDamage(amount);
        private static void Heal(BattleUnitRuntime target, float amount) => target.Heal(amount);
        private static void Shield(BattleUnitRuntime target, float amount) => target.AddShield(amount);
        private static float Modify(SlotModifierType modifier, SlotModifierType requested, float value) =>
            SlotModifierRules.ModifyValue(modifier, requested, value);
        private static void AddBurn(BattleUnitRuntime target, float amount, BattleUnitRuntime source) =>
            target.Buffs.AddStacks("burn", UnityEngine.Mathf.RoundToInt(amount), source);
        private static void AddPoison(BattleUnitRuntime target, float amount, BattleUnitRuntime source) =>
            target.Buffs.AddStacks("poison", UnityEngine.Mathf.RoundToInt(amount * 2f), source);
    }
}

using System.Collections.Generic;
using CardAutobattle.Prototype;
using UnityEngine;

namespace CardAutobattle.Battle
{
    public enum BattleSide { Player, Enemy }

    public sealed class BattleStatsRuntime
    {
        public float MaxHealth { get; }
        public BattleStatsRuntime(float maxHealth) => MaxHealth = Mathf.Max(1f, maxHealth);
    }

    public sealed class BattleUnitRuntime
    {
        public int RuntimeId { get; }
        public BattleSide Side { get; }
        public BattleStatsRuntime Stats { get; }
        public float MaxHealth => Stats.MaxHealth;
        public float Health { get; private set; }
        public float Shield { get; private set; }
        public BuffController Buffs { get; }
        public IReadOnlyList<CardRuntime> Cards => cards;
        public BattleContext Context { get; }
        private readonly List<CardRuntime> cards = new();

        public BattleUnitRuntime(int id, BattleSide side, float maxHealth, BattleContext context)
        { RuntimeId = id; Side = side; Stats = new BattleStatsRuntime(maxHealth); Health = MaxHealth; Context = context; Buffs = new BuffController(this); }

        internal void AddCard(CardRuntime card) { if (card != null && !cards.Contains(card)) cards.Add(card); }
        public void SetHealth(float value) => Health = Mathf.Clamp(value, 0f, MaxHealth);
        public float ApplyDamage(float requested)
        {
            requested = Mathf.Max(0f, requested);
            var absorbed = Mathf.Min(Shield, requested);
            Shield -= absorbed;
            var damage = requested - absorbed;
            Health = Mathf.Max(0f, Health - damage);
            Context.Events.Publish(new DamageAppliedEvent { RequestedAmount = requested, ShieldAbsorbed = absorbed,
                HealthDamage = damage, RemainingHealth = Health }, Context.Clock.BattleTime, Context.NextTriggerId,
                0, RuntimeId);
            if (Health <= 0f) Context.Events.Publish(new SimpleBattleEvent(BattleEventType.UnitDefeated), Context.Clock.BattleTime,
                Context.NextTriggerId, 0, RuntimeId);
            return damage;
        }

        public float Heal(float requested)
        {
            requested = Mathf.Max(0f, requested);
            var before = Health;
            Health = Mathf.Min(MaxHealth, Health + requested);
            Context.Events.Publish(new HealAppliedEvent { RequestedAmount = requested, HealthRestored = Health - before,
                RemainingHealth = Health }, Context.Clock.BattleTime, Context.NextTriggerId, 0, RuntimeId);
            return Health - before;
        }

        public void AddShield(float amount)
        {
            var before = Shield;
            Shield = Mathf.Max(0f, Shield + Mathf.Max(0f, amount));
            Context.Events.Publish(new ShieldChangedEvent { PreviousShield = before, CurrentShield = Shield,
                ChangeAmount = Shield - before }, Context.Clock.BattleTime, Context.NextTriggerId, 0, RuntimeId);
        }
    }
}

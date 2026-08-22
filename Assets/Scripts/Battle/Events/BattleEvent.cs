using System;

namespace CardAutobattle.Battle
{
    public enum BattleEventType
    {
        BattleStarted, CardTriggered, EffectStarted, ProjectileRequested,
        DamageApplied, HealApplied, ShieldChanged, BuffApplied,
        BuffStacksChanged, BuffRemoved, UnitDefeated, BattleEnded
    }

    public abstract class BattleEvent
    {
        public long Sequence { get; internal set; }
        public float BattleTime { get; internal set; }
        public int TriggerId { get; internal set; }
        public int SourceUnitId { get; internal set; }
        public int TargetUnitId { get; internal set; }
        public abstract BattleEventType Type { get; }
    }

    public sealed class SimpleBattleEvent : BattleEvent
    {
        public override BattleEventType Type { get; }
        public SimpleBattleEvent(BattleEventType type) => Type = type;
    }

    public sealed class CardTriggeredEvent : BattleEvent
    {
        public int CardRuntimeId { get; internal set; }
        public string CardId { get; internal set; }
        public override BattleEventType Type => BattleEventType.CardTriggered;
    }

    public sealed class DamageAppliedEvent : BattleEvent
    {
        public float RequestedAmount { get; internal set; }
        public float ShieldAbsorbed { get; internal set; }
        public float HealthDamage { get; internal set; }
        public float RemainingHealth { get; internal set; }
        public override BattleEventType Type => BattleEventType.DamageApplied;
    }

    public sealed class HealAppliedEvent : BattleEvent
    {
        public float RequestedAmount { get; internal set; }
        public float HealthRestored { get; internal set; }
        public float RemainingHealth { get; internal set; }
        public override BattleEventType Type => BattleEventType.HealApplied;
    }

    public sealed class ShieldChangedEvent : BattleEvent
    {
        public float PreviousShield { get; internal set; }
        public float CurrentShield { get; internal set; }
        public float ChangeAmount { get; internal set; }
        public override BattleEventType Type => BattleEventType.ShieldChanged;
    }

    public sealed class BuffStacksChangedEvent : BattleEvent
    {
        public string BuffId { get; internal set; }
        public int PreviousStacks { get; internal set; }
        public int CurrentStacks { get; internal set; }
        public int ChangeAmount { get; internal set; }
        public int SourceRuntimeId { get; internal set; }
        public override BattleEventType Type => BattleEventType.BuffStacksChanged;
    }

    public sealed class BattleEventStream
    {
        public event Action<BattleEvent> EventRaised;
        public long NextSequence { get; private set; }
        public void Publish(BattleEvent battleEvent, float battleTime, int triggerId = 0,
            int sourceUnitId = 0, int targetUnitId = 0)
        {
            if (battleEvent == null) return;
            battleEvent.Sequence = ++NextSequence;
            battleEvent.BattleTime = battleTime;
            battleEvent.TriggerId = triggerId;
            battleEvent.SourceUnitId = sourceUnitId;
            battleEvent.TargetUnitId = targetUnitId;
            EventRaised?.Invoke(battleEvent);
        }
    }
}

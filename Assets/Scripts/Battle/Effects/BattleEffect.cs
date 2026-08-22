using CardAutobattle.Battle;
using UnityEngine;

namespace CardAutobattle.Battle
{
    public sealed class EffectContext
    {
        public BattleContext Battle { get; set; }
        public CardRuntime SourceCard { get; set; }
        public BattleUnitRuntime SourceUnit { get; set; }
        public BattleUnitRuntime PrimaryTarget { get; set; }
        public System.Collections.Generic.IReadOnlyList<BattleUnitRuntime> Targets { get; set; }
        public int TriggerId { get; set; }
        public int ChainDepth { get; set; }
        public int ConsumedStackCount { get; set; }
    }

    public abstract class BattleEffect : ScriptableObject
    { public abstract void Execute(EffectContext context); }

    public abstract class BattleCondition : ScriptableObject
    { public abstract bool Evaluate(EffectContext context); }

    public sealed class EffectSequence : BattleEffect
    {
        [SerializeField] private BattleEffect[] effects;
        public override void Execute(EffectContext context)
        { if (effects == null) return; foreach (var effect in effects) if (effect) effect.Execute(context); }
    }

    public sealed class DamageEffect : BattleEffect
    { [SerializeField] private float amount; public DamageEffect() { } public DamageEffect(float value) => amount = value; public override void Execute(EffectContext context) => context.PrimaryTarget?.ApplyDamage(amount); }
    public sealed class HealEffect : BattleEffect
    { [SerializeField] private float amount; public HealEffect() { } public HealEffect(float value) => amount = value; public override void Execute(EffectContext context) => context.PrimaryTarget?.Heal(amount); }
    public sealed class ShieldEffect : BattleEffect
    { [SerializeField] private float amount; public ShieldEffect() { } public ShieldEffect(float value) => amount = value; public override void Execute(EffectContext context) => context.PrimaryTarget?.AddShield(amount); }
}

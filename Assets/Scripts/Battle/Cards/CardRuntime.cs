using CardAutobattle.Prototype;
using UnityEngine;

namespace CardAutobattle.Battle
{
    public sealed class BattleCardDefinition
    {
        public CardDefinition Legacy { get; }
        public string Id => Legacy?.Id;
        public BattleCardDefinition(CardDefinition legacy) => Legacy = legacy;
    }

    public sealed class CardRuntime
    {
        public int RuntimeId { get; }
        public BattleCardDefinition Definition { get; }
        public BattleUnitRuntime Owner { get; }
        public GridPosition Position { get; }
        public float CooldownRemaining { get; private set; }
        public float CooldownDuration { get; }
        public bool Enabled { get; set; } = true;
        public int Level { get; }
        public CardDefinition LegacyDefinition => Definition.Legacy;

        public CardRuntime(int id, BattleCardDefinition definition, BattleUnitRuntime owner,
            GridPosition position, float cooldown, int level)
        { RuntimeId = id; Definition = definition; Owner = owner; Position = position; CooldownDuration = Mathf.Max(.01f, cooldown); CooldownRemaining = LegacyDefinition.Effect == CardEffectKind.PassivePowerAura ? float.PositiveInfinity : CooldownDuration; Level = level; owner.AddCard(this); }

        public bool Tick(float deltaTime)
        {
            if (!Enabled || float.IsPositiveInfinity(CooldownRemaining)) return false;
            CooldownRemaining -= Mathf.Max(0f, deltaTime);
            if (CooldownRemaining > 0f) return false;
            CooldownRemaining += CooldownDuration;
            return true;
        }

        public void Advance(float amount)
        { if (!float.IsPositiveInfinity(CooldownRemaining)) CooldownRemaining -= Mathf.Max(0f, amount); }
        public void ResetCooldown() => CooldownRemaining = CooldownDuration;
        public float Charge01 => float.IsPositiveInfinity(CooldownRemaining) ? 1f : 1f - Mathf.Clamp01(CooldownRemaining / CooldownDuration);
    }
}

using CardAutobattle.Prototype;
using UnityEngine;

namespace CardAutobattle.Battle
{
    public sealed class BuffStacksCondition : BattleCondition
    {
        [SerializeField] private string buffId;
        [SerializeField] private int minimumStacks = 1;
        public override bool Evaluate(EffectContext context) => context?.SourceUnit?.Buffs.HasStacks(buffId, minimumStacks) == true;
    }

    public sealed class HealthRatioCondition : BattleCondition
    {
        [SerializeField, Range(0f, 1f)] private float maximumRatio = 1f;
        public override bool Evaluate(EffectContext context) => context?.SourceUnit != null &&
            context.SourceUnit.Health / context.SourceUnit.MaxHealth <= maximumRatio;
    }

    public sealed class CardTagCondition : BattleCondition
    {
        [SerializeField] private CardTag requiredTag;
        public override bool Evaluate(EffectContext context) => context?.SourceCard?.LegacyDefinition != null &&
            (context.SourceCard.LegacyDefinition.Tags & requiredTag) != 0;
    }

    public sealed class AdjacentCardCondition : BattleCondition
    {
        [SerializeField] private int minimumCount = 1;
        public override bool Evaluate(EffectContext context)
        {
            if (context?.SourceCard?.Owner == null) return false;
            var count = 0;
            foreach (var card in context.SourceCard.Owner.Cards)
                if (card != context.SourceCard && GridPosition.AreAdjacent(card.Position, context.SourceCard.Position)) count++;
            return count >= minimumCount;
        }
    }
}

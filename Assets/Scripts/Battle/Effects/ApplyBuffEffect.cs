using UnityEngine;

namespace CardAutobattle.Battle
{
    public sealed class ApplyBuffEffect : BattleEffect
    {
        [SerializeField] private string buffId;
        [SerializeField] private int stacks = 1;
        public override void Execute(EffectContext context) => context?.PrimaryTarget?.Buffs.AddStacks(buffId, stacks, context.SourceUnit);
    }

    public sealed class ModifyCooldownEffect : BattleEffect
    {
        [SerializeField] private float seconds;
        public override void Execute(EffectContext context)
        {
            if (context?.Targets == null) return;
            foreach (var target in context.Targets)
                foreach (var card in target.Cards) card.Advance(seconds);
        }
    }
}

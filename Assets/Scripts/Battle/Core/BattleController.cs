using System;
using System.Collections.Generic;

namespace CardAutobattle.Battle
{
    /// <summary>Owns one deterministic runtime tick. Presentation is optional and never drives this class.</summary>
    public sealed class BattleController
    {
        private readonly BattleContext context;
        private readonly List<CardRuntime> cards = new();
        private readonly Action<CardRuntime> trigger;
        private float statusAccumulator;
        public BattleContext Context => context;
        public BattleController(BattleContext battleContext, Action<CardRuntime> onCardTriggered)
        { context = battleContext; trigger = onCardTriggered; }
        public void AddCard(CardRuntime card) { if (card != null) cards.Add(card); }
        public void Tick(float unityUnscaledDeltaTime)
        {
            if (context.Ended) return;
            var delta = context.Clock.Advance(unityUnscaledDeltaTime);
            context.Scheduler.Tick(context.Clock.BattleTime);
            foreach (var card in cards)
            {
                if (!card.Tick(delta)) continue;
                var triggerId = context.NextTriggerId;
                context.Events.Publish(new CardTriggeredEvent { CardRuntimeId = card.RuntimeId, CardId = card.Definition.Id },
                    context.Clock.BattleTime, triggerId, card.Owner.RuntimeId, card.Owner.RuntimeId);
                trigger?.Invoke(card);
            }
            statusAccumulator += delta;
            while (statusAccumulator >= 1f && !context.Ended)
            {
                statusAccumulator -= 1f;
                LegacyCardEffectAdapter.TickStatuses(context);
            }
            context.Player.Buffs.Tick(delta);
            context.Enemy.Buffs.Tick(delta);
        }
        public void SetPaused(bool paused) => context.Clock.SetPaused(paused);
        public void SetSpeed(float speed) => context.Clock.SetSpeed(speed);
    }
}

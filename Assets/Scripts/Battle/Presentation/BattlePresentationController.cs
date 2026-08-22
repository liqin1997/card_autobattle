using System;
using System.Collections.Generic;
using CardAutobattle.Prototype;

namespace CardAutobattle.Battle
{
    /// <summary>Consumes immutable battle events. It never writes runtime HP, shield, buffs or cooldowns.</summary>
    public sealed class BattlePresentationController : IDisposable
    {
        private sealed class CardBinding { public bool Enemy; public CardDefinition Definition; }
        private readonly BattleEventStream events;
        private readonly BattleSceneView view;
        private readonly Dictionary<int, CardBinding> cards = new();
        public BattlePresentationController(BattleEventStream stream, BattleSceneView battleView)
        { events = stream; view = battleView; events.EventRaised += OnEvent; }
        public void RegisterCard(CardRuntime card, bool enemy)
        { if (card != null) cards[card.RuntimeId] = new CardBinding { Enemy = enemy, Definition = card.LegacyDefinition }; }
        private void OnEvent(BattleEvent battleEvent)
        {
            if (!(battleEvent is CardTriggeredEvent triggered) || !cards.TryGetValue(triggered.CardRuntimeId, out var binding) || !view) return;
            view.PlayCardActivation(binding.Enemy, binding.Definition.Effect,
                Math.Max(binding.Definition.Power, binding.Definition.SecondaryPower));
        }
        public void Dispose() { if (events != null) events.EventRaised -= OnEvent; cards.Clear(); }
    }
}

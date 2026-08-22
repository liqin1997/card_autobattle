using System;
using System.Collections.Generic;
using CardAutobattle.Prototype;

namespace CardAutobattle.Battle
{
    public sealed class BattleContext
    {
        private int nextRuntimeId = 1;
        private int nextTriggerId = 1;
        public BattleClock Clock { get; } = new();
        public BattleEventStream Events { get; } = new();
        public BattleScheduler Scheduler { get; } = new();
        public System.Random Random { get; }
        public BattleUnitRuntime Player { get; }
        public BattleUnitRuntime Enemy { get; }
        public int NextTriggerId => nextTriggerId++;
        public bool Ended { get; private set; }

        public BattleContext(float playerMaxHealth, float enemyMaxHealth, int seed = 1)
        { Random = new System.Random(seed); Player = new BattleUnitRuntime(nextRuntimeId++, BattleSide.Player, playerMaxHealth, this); Enemy = new BattleUnitRuntime(nextRuntimeId++, BattleSide.Enemy, enemyMaxHealth, this); Events.Publish(new SimpleBattleEvent(BattleEventType.BattleStarted), 0f); }
        public int NextRuntimeId() => nextRuntimeId++;
        public void SetEnded() { Ended = true; Scheduler.Clear(); Events.Publish(new SimpleBattleEvent(BattleEventType.BattleEnded), Clock.BattleTime); }
        public BattleUnitRuntime UnitFor(BattleSide side) => side == BattleSide.Player ? Player : Enemy;
    }
}

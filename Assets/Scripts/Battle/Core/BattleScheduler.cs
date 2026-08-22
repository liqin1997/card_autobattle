using System;
using System.Collections.Generic;

namespace CardAutobattle.Battle
{
    public sealed class BattleScheduler
    {
        private sealed class Item { public float At; public long Order; public Action Action; }
        private readonly List<Item> items = new();
        private long order;
        public void Schedule(float executeAtBattleTime, Action action)
        { if (action != null) items.Add(new Item { At = executeAtBattleTime, Order = ++order, Action = action }); }
        public void ScheduleAfter(float delay, float now, Action action) => Schedule(now + Math.Max(0f, delay), action);
        public void Tick(float currentBattleTime)
        {
            items.Sort((a, b) => { var compare = a.At.CompareTo(b.At); return compare != 0 ? compare : a.Order.CompareTo(b.Order); });
            while (items.Count > 0 && items[0].At <= currentBattleTime)
            { var item = items[0]; items.RemoveAt(0); item.Action?.Invoke(); }
        }
        public void Clear() => items.Clear();
    }
}

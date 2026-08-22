using System.Collections.Generic;
using CardAutobattle.Battle;
using CardAutobattle.Prototype;
using UnityEngine;

namespace CardAutobattle.Battle
{
    public enum BuffStackPolicy { Add, RefreshDuration, Replace }

    public abstract class BuffDefinition : ScriptableObject
    {
        public string BuffId;
        public int MaxStacks = 99;
        public float Duration;
        public BuffStackPolicy StackPolicy = BuffStackPolicy.Add;
    }

    public sealed class RuntimeBuffDefinition
    {
        public readonly string BuffId;
        public readonly int MaxStacks;
        public readonly float Duration;
        public readonly BuffStackPolicy StackPolicy;
        public RuntimeBuffDefinition(string id, int maxStacks = 99, float duration = 0f,
            BuffStackPolicy policy = BuffStackPolicy.Add)
        { BuffId = id; MaxStacks = maxStacks; Duration = duration; StackPolicy = policy; }
    }

    public sealed class BuffRuntime
    {
        public RuntimeBuffDefinition Definition { get; }
        public BattleUnitRuntime Owner { get; }
        public BattleUnitRuntime Source { get; }
        public int Stacks { get; private set; }
        public float RemainingDuration { get; private set; }

        public BuffRuntime(RuntimeBuffDefinition definition, BattleUnitRuntime owner,
            BattleUnitRuntime source, int stacks)
        { Definition = definition; Owner = owner; Source = source; Stacks = Mathf.Clamp(stacks, 0, definition.MaxStacks); RemainingDuration = definition.Duration; }

        public int Add(int amount)
        {
            var previous = Stacks;
            Stacks = Mathf.Clamp(Stacks + amount, 0, Definition.MaxStacks);
            if (Definition.StackPolicy == BuffStackPolicy.RefreshDuration) RemainingDuration = Definition.Duration;
            if (Definition.StackPolicy == BuffStackPolicy.Replace) Stacks = Mathf.Clamp(amount, 0, Definition.MaxStacks);
            return Stacks - previous;
        }

        public int Remove(int amount)
        { var previous = Stacks; Stacks = Mathf.Max(0, Stacks - Mathf.Max(0, amount)); return Stacks - previous; }
        public void Refresh() => RemainingDuration = Definition.Duration;
        public bool Tick(float deltaTime)
        { if (Definition.Duration <= 0f) return false; RemainingDuration -= Mathf.Max(0f, deltaTime); return RemainingDuration <= 0f; }
    }

    public sealed class BuffController
    {
        private readonly BattleUnitRuntime owner;
        private readonly Dictionary<string, BuffRuntime> buffs = new();
        public BuffController(BattleUnitRuntime unit) => owner = unit;

        public int GetStacks(string buffId) => buffs.TryGetValue(buffId, out var buff) ? buff.Stacks : 0;
        public bool HasStacks(string buffId, int minimum = 1) => GetStacks(buffId) >= minimum;
        public BuffRuntime AddStacks(string buffId, int amount, BattleUnitRuntime source = null,
            int maxStacks = 99, float duration = 0f, BuffStackPolicy policy = BuffStackPolicy.Add)
        {
            if (string.IsNullOrEmpty(buffId) || amount == 0) return buffs.TryGetValue(buffId, out var existing) ? existing : null;
            if (!buffs.TryGetValue(buffId, out var runtime))
            {
                runtime = new BuffRuntime(new RuntimeBuffDefinition(buffId, maxStacks, duration, policy), owner, source, 0);
                buffs[buffId] = runtime;
                owner.Context.Events.Publish(new SimpleBattleEvent(BattleEventType.BuffApplied), owner.Context.Clock.BattleTime,
                    owner.Context.NextTriggerId, source?.RuntimeId ?? 0, owner.RuntimeId);
            }
            var previous = runtime.Stacks;
            var change = runtime.Add(amount);
            owner.Context.Events.Publish(new BuffStacksChangedEvent { BuffId = buffId, PreviousStacks = previous,
                CurrentStacks = runtime.Stacks, ChangeAmount = change, SourceRuntimeId = source?.RuntimeId ?? 0 },
                owner.Context.Clock.BattleTime, owner.Context.NextTriggerId, source?.RuntimeId ?? 0, owner.RuntimeId);
            return runtime;
        }

        public int RemoveStacks(string buffId, int amount)
        {
            if (!buffs.TryGetValue(buffId, out var runtime)) return 0;
            var previous = runtime.Stacks;
            var change = runtime.Remove(amount);
            owner.Context.Events.Publish(new BuffStacksChangedEvent { BuffId = buffId, PreviousStacks = previous,
                CurrentStacks = runtime.Stacks, ChangeAmount = change }, owner.Context.Clock.BattleTime,
                owner.Context.NextTriggerId, owner.RuntimeId, owner.RuntimeId);
            if (runtime.Stacks <= 0) RemoveBuff(buffId);
            return change;
        }

        public int ConsumeAllStacks(string buffId) => buffs.TryGetValue(buffId, out var runtime) ? RemoveStacks(buffId, runtime.Stacks) : 0;
        public void RemoveBuff(string buffId)
        {
            if (!buffs.Remove(buffId)) return;
            owner.Context.Events.Publish(new SimpleBattleEvent(BattleEventType.BuffRemoved), owner.Context.Clock.BattleTime,
                owner.Context.NextTriggerId, owner.RuntimeId, owner.RuntimeId);
        }

        public void Tick(float deltaTime)
        {
            var expired = new List<string>();
            foreach (var pair in buffs) if (pair.Value.Tick(deltaTime)) expired.Add(pair.Key);
            foreach (var id in expired) RemoveBuff(id);
        }
    }
}

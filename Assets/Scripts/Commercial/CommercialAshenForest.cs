using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    [Serializable] public sealed class AshenForestProgress
    {
        public int Step, Victories;
        public bool Accepted;
        public string TrackedNode;
    }
    [Serializable] public sealed class AshenQuestDefinition
    {
        public string Title, Story, Goal, Target, GearSet;
        public int Wins, Gold, Experience, GearSlot = -1, GearLevel;
        public InventoryAmount[] Items;
    }
    [Serializable] public sealed class AshenNodeDefinition
    {
        public string Id, Name, Description, Kind, Prerequisite, Action, Sprite;
        public float X, Y, Health = 1, Attack = 1;
        public int Step, Stage = 1;
        public InventoryAmount[] Rewards, Costs;
    }
    [Serializable] public sealed class AshenForestConfig
    {
        public AshenQuestDefinition[] Quests;
        public AshenNodeDefinition[] Nodes;
    }

    // Explicit discoveries, not camera movement, reveal the sample region.
    public static class CommercialAshenForest
    {
        private static AshenForestConfig config;
        public static AshenForestConfig Config => config ??= JsonUtility.FromJson<AshenForestConfig>(Resources.Load<TextAsset>("Commercial/World/AshenForest").text);
        public static AshenNodeDefinition Node(string id) => Config.Nodes.FirstOrDefault(n => n.Id == id);
        public static bool IsForest(string id) => Node(id) != null;
        public static bool Finished(CommercialGameState state) => state.World.Forest.Step >= Config.Quests.Length;
        public static AshenQuestDefinition Quest(CommercialGameState state) => Finished(state) ? null : Config.Quests[state.World.Forest.Step];
        public static bool Done(CommercialGameState state, string id) => state.World.CompletedNodes.Contains(id);
        public static string Title(CommercialGameState state) => Quest(state)?.Title ?? "灰烬森林 · 已完成";
        public static bool Accessible(CommercialGameState state, string id)
        {
            var node = Node(id); if (node == null) return true;
            return state.World.Forest.Step >= node.Step && (string.IsNullOrEmpty(node.Prerequisite) || Done(state, node.Prerequisite));
        }
        public static string LockedReason(CommercialGameState state, string id)
        {
            var n = Node(id); if (n == null) return "区域尚未解锁";
            if (state.World.Forest.Step < n.Step) return "先完成并领取前置任务奖励";
            return "先完成：" + (Node(n.Prerequisite)?.Name ?? "前置探索");
        }
        public static bool RevealAvailable(CommercialGameState state)
        {
            var changed = false;
            foreach (var n in Config.Nodes)
                if (Accessible(state, n.Id) && !state.World.RevealedNodes.Contains(n.Id)) { state.World.RevealedNodes.Add(n.Id); changed = true; }
            return changed;
        }
        public static void Populate(List<CommercialWorldNode> nodes)
        {
            foreach (var n in Config.Nodes)
            {
                var existing = nodes.FirstOrDefault(x => x.Id == n.Id);
                if (existing == null) { existing = new CommercialWorldNode { Id = n.Id, Chapter = 1 }; nodes.Add(existing); }
                existing.Name = n.Name; existing.Description = n.Description; existing.Kind = Enum.Parse<WorldNodeKind>(n.Kind);
                existing.Position = new Vector2(n.X, n.Y); existing.StageOverride = n.Stage;
                existing.HealthScale = n.Health; existing.AttackScale = n.Attack;
            }
        }
        public static bool Ready(CommercialGameState state)
        {
            var f = state.World.Forest; var q = Quest(state);
            if (q == null || !f.Accepted) return false;
            return q.Wins > 0 ? f.Victories >= q.Wins : Done(state, q.Target);
        }
        public static string Progress(CommercialGameState state)
        {
            var f = state.World.Forest; var q = Quest(state);
            if (q == null) return "鸦羽丘陵已解锁 · 点击前往";
            if (!f.Accepted) return "待接取 · " + q.Goal;
            if (Ready(state)) return "已完成 · 领取奖励";
            if (f.Step == 2) return $"木材 {CommercialInventoryService.Count(state, "forest_wood")}/8 · 铁矿 {CommercialInventoryService.Count(state, "iron_ore")}/4";
            return q.Wins > 0 ? $"营地清剿 {f.Victories}/{q.Wins}" : q.Goal;
        }
        public static string Target(CommercialGameState state)
        {
            if (Finished(state)) return "af_exit";
            if (!state.World.Forest.Accepted || Ready(state)) return "quest_1";
            if (state.World.Forest.Step == 1 && !Done(state, "af_scout")) return "af_scout";
            if (state.World.Forest.Step == 2 && CommercialInventoryService.Count(state, "iron_ore") < 4)
                return !Done(state, "af_orecache") ? "af_orecache" : "af_mine";
            return Quest(state).Target;
        }
        public static string Accept(CommercialGameState state)
        {
            if (Finished(state) || state.World.Forest.Accepted) return "任务已接取或已完成";
            state.World.Forest.Accepted = true; state.World.Forest.Victories = 0;
            state.World.Forest.TrackedNode = Target(state); RevealAvailable(state); return null;
        }
        public static InventoryRewardBundle Reward(CommercialGameState state)
        {
            var q = Quest(state); var r = new InventoryRewardBundle(); if (q == null) return r;
            r.Gold = q.Gold; r.Experience = q.Experience;
            foreach (var i in q.Items ?? Array.Empty<InventoryAmount>()) r.Add(i.Id, i.Count);
            if (q.GearSlot >= 0) r.Equipment.Add(CommercialEquipmentService.Generate(1, 1, 80719 + state.World.Forest.Step * 2917,
                (EquipmentSlot)q.GearSlot, state.World.Forest.Step == 3 ? EquipmentRarity.Purple : EquipmentRarity.Blue, q.GearSet, q.GearLevel));
            return r;
        }
        public static string RewardDescription(CommercialGameState state)
        {
            var q = Quest(state); if (q == null) return "鸦羽丘陵已开放";
            var items = q.Items == null ? "" : string.Join(" / ", q.Items.Select(i => CommercialInventoryCatalog.Name(i.Id) + "×" + i.Count));
            return $"金币 {q.Gold} · 经验 {q.Experience}\n" +
                (q.GearSlot >= 0 ? $"{(state.World.Forest.Step == 3 ? "史诗" : "稀有")}铁誓{CommercialEquipmentCatalog.SlotName((EquipmentSlot)q.GearSlot)} Lv.{q.GearLevel}（保证获得）\n" : "") + items;
        }
        public static string Claim(CommercialGameState state)
        {
            if (!Ready(state)) return "任务尚未完成";
            var step = state.World.Forest.Step;
            var error = CommercialInventoryService.Grant(state, Reward(state), "主线 · " + Title(state), "ashen:quest:" + step);
            if (error != null) return error;
            state.World.Forest.Step++; state.World.Forest.Accepted = false; state.World.Forest.Victories = 0;
            if (Finished(state))
            {
                var old = state.World.RegionTasks.First(q => q.Chapter == 1); old.IdleWins = 5; old.BossDefeated = true; old.Claimed = true;
            }
            RevealAvailable(state); state.World.Forest.TrackedNode = Target(state); return null;
        }
        public static void RecordVictory(CommercialGameState state, CommercialWorldEncounter encounter)
        {
            if (encounter.Chapter != 1) return;
            var q = Quest(state); var f = state.World.Forest;
            if (f.Accepted && q?.Wins > 0 && q.Target == encounter.NodeId) f.Victories = Mathf.Min(q.Wins, f.Victories + 1);
            RevealAvailable(state);
        }
        public static string Interact(CommercialGameState state, string id)
        {
            var node = Node(id);
            if (node == null || !Accessible(state, id) || !state.World.RevealedNodes.Contains(id)) return "此处尚未开放";
            if (Done(state, id)) return "已完成此事件";
            if (id == "af_bridge" && (state.World.Forest.Step != 2 || !state.World.Forest.Accepted)) return "请先接取「修复断桥」任务";
            if (node.Kind == "Idle" || node.Kind == "Boss" || node.Kind == "Elite" || node.Kind == "Quest" || node.Kind == "Exit") return "请使用对应交互入口";
            var reward = new InventoryRewardBundle();
            foreach (var i in node.Rewards ?? Array.Empty<InventoryAmount>()) reward.Add(i.Id, i.Count);
            var error = CommercialInventoryService.Grant(state, reward, "探索 · " + node.Name, "ashen:event:" + id, node.Costs);
            if (error != null) return error;
            state.World.CompletedNodes.Add(id); RevealAvailable(state); return null;
        }
        public static int Discovered(CommercialGameState state) => Config.Nodes.Count(n => state.World.RevealedNodes.Contains(n.Id));
        public static int Cleared(CommercialGameState state) => Config.Nodes.Count(n => Done(state, n.Id));
    }
}

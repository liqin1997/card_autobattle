using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    public enum WorldNodeKind { Idle, Quest, Elite, Boss, Chest, Survey, Gather, Bridge, Exit }

    [Serializable]
    public sealed class CommercialWorldProgress
    {
        public string CurrentNodeId = "main_1";
        public string IdleNodeId = "main_1";
        public string TrackedQuestId;
        public List<string> CompletedNodes = new();
        public List<string> RevealedNodes = new();
        public List<CommercialWorldQuestProgress> Quests = new();
        public List<CommercialWorldMainQuest> RegionTasks = new();
        public AshenForestProgress Forest = new();

        public void Ensure()
        {
            CompletedNodes ??= new(); RevealedNodes ??= new(); Quests ??= new();
            RegionTasks ??= new();
            Forest ??= new();
            for (var chapter = 1; chapter <= 5; chapter++)
                if (!RegionTasks.Any(q => q.Chapter == chapter)) RegionTasks.Add(new CommercialWorldMainQuest { Chapter = chapter });
            if (RegionTasks.Any(q => q.Chapter == 1 && q.Claimed)) Forest.Step = 4;
            if (CommercialWorldCatalog.Find(CurrentNodeId) == null) CurrentNodeId = "main_1";
            if (CommercialWorldCatalog.Find(IdleNodeId)?.Kind != WorldNodeKind.Idle) IdleNodeId = "main_1";
        }
    }

    [Serializable]
    public sealed class CommercialWorldMainQuest
    {
        public int Chapter;
        public int IdleWins;
        public bool BossDefeated;
        public bool Claimed;
        public bool Ready => IdleWins >= 5 && BossDefeated;
    }

    [Serializable]
    public sealed class CommercialWorldQuestProgress
    {
        public string Id;
        public bool Completed;
        public bool Claimed;
    }

    public sealed class CommercialWorldNode
    {
        public string Id, Name, Description;
        public int Chapter;
        public WorldNodeKind Kind;
        public Vector2 Position;
        public int StageOverride;
        public float HealthScale = 1, AttackScale = 1;
        public int GlobalStage => (Chapter - 1) * 20 + (StageOverride > 0 ? StageOverride : Kind == WorldNodeKind.Boss ? 5 : Kind == WorldNodeKind.Elite ? 3 : 1);
    }

    public sealed class CommercialWorldEncounter
    {
        public string NodeId;
        public int Chapter, Stage;
        public WorldNodeKind Kind;
        public float HealthScale = 1, AttackScale = 1;
    }

    public static class CommercialWorldCatalog
    {
        public static readonly string[] RegionNames = { "灰烬森林", "鸦羽丘陵", "荒沙古城", "霜落雪原", "终焉王座" };
        // Coordinates are shared by the SpriteRenderer map, event markers and fog.
        public static readonly Vector2[] RegionCenters = { new(-7, 1), new(6, 9), new(1, -13), new(-3, 23), new(7, 18) };
        public static readonly IReadOnlyList<CommercialWorldNode> Nodes = Build();
        private static List<CommercialWorldNode> Build()
        {
            var nodes = new List<CommercialWorldNode>();
            for (var chapter = 1; chapter <= 5; chapter++)
            {
                var center = RegionCenters[chapter - 1];
                Add(WorldNodeKind.Idle, "main", RegionNames[chapter - 1], Vector2.zero, "前往本区域挂机，反复挑战当地怪物并获取经验与装备。立即中断当前战斗，已累计的任务进度保留。");
                Add(WorldNodeKind.Quest, "quest", "旅人委托", new Vector2(-3, -3), "接取支线：击败本区域精英。接取后才记录击杀；完成后手动领取奖励。");
                Add(WorldNodeKind.Elite, "elite", "巡游精英", new Vector2(3, -2), "立即中断挂机并挑战精英，胜利计入已接取的区域委托。挑战结束后恢复原区域挂机。");
                Add(WorldNodeKind.Boss, "boss", "区域首领", new Vector2(2, 4), "立即中断当前战斗，挑战区域首领。首次胜利获得装备与金币，满足当前主线任务的讨伐目标。挑战结束后恢复原区域挂机。");
                Add(WorldNodeKind.Chest, "chest", "遗落宝箱", new Vector2(-3.5f, 3), "每个存档仅能领取一次。金币与经验立即获得，稀有装备箱和地区材料进入背包；装备箱可在背包中开启。");
                void Add(WorldNodeKind kind, string prefix, string name, Vector2 offset, string description) => nodes.Add(new CommercialWorldNode
                { Id = prefix + "_" + chapter, Chapter = chapter, Kind = kind, Name = name, Position = center + offset, Description = description });
            }
            CommercialAshenForest.Populate(nodes);
            return nodes;
        }
        public static CommercialWorldNode Find(string id) => Nodes.FirstOrDefault(n => n.Id == id);
        public static bool Unlocked(CommercialGameState state, CommercialWorldNode node) => node != null &&
            (node.Chapter == 1 ? CommercialAshenForest.Accessible(state, node.Id) : state.World.RegionTasks.Any(q => q.Chapter == node.Chapter - 1 && q.Claimed));
        public static bool Revealed(CommercialGameState state, CommercialWorldNode node) =>
            node != null && state.World.RevealedNodes.Contains(node.Id);

        public static bool RevealRegion(CommercialGameState state, int chapter)
        {
            if (chapter == 1) return CommercialAshenForest.RevealAvailable(state);
            var changed = false;
            foreach (var node in Nodes.Where(n => n.Chapter == chapter && Unlocked(state, n)))
                if (!state.World.RevealedNodes.Contains(node.Id)) { state.World.RevealedNodes.Add(node.Id); changed = true; }
            return changed;
        }

        public static bool AcceptQuest(CommercialGameState state, int chapter)
        {
            if (chapter == 1) return CommercialAshenForest.Accept(state) == null;
            var id = "quest_" + chapter;
            if (!Unlocked(state, Find(id)) || !Revealed(state, Find(id)) || state.World.Quests.Any(q => q.Id == id)) return false;
            state.World.Quests.Add(new CommercialWorldQuestProgress { Id = id });
            state.World.TrackedQuestId = id;
            return true;
        }

        public static bool ClaimQuest(CommercialGameState state, string id)
        {
            if (id == "quest_1") return CommercialAshenForest.Claim(state) == null;
            var q = state.World.Quests.FirstOrDefault(x => x.Id == id);
            var node = Find(id);
            if (q == null || node == null || !q.Completed || q.Claimed) return false;
            if (CommercialInventoryService.Grant(state, CommercialInventoryService.QuestReward(state, node.Chapter), "区域委托", "world:" + id) != null) return false;
            q.Claimed = true;
            if (state.World.TrackedQuestId == id) state.World.TrackedQuestId = null;
            return true;
        }

        public static int MainRewardTarget(CommercialGameState state)
        {
            for (var chapter = 1; chapter <= 5; chapter++)
                if (!state.World.RegionTasks.Any(q => q.Chapter == chapter && q.Claimed)) return chapter;
            return 0;
        }
        public static CommercialWorldMainQuest CurrentMainQuest(CommercialGameState state) =>
            state.World.RegionTasks.FirstOrDefault(q => !q.Claimed);
        public static bool ClaimMainReward(CommercialGameState state)
        {
            if (!CommercialAshenForest.Finished(state)) return CommercialAshenForest.Claim(state) == null;
            var target = MainRewardTarget(state);
            var quest = CurrentMainQuest(state);
            if (target == 0 || quest == null || !quest.Ready) return false;
            if (CommercialInventoryService.Grant(state, CommercialInventoryService.MainReward(target), "区域主线任务", "world:main_" + target) != null) return false;
            quest.Claimed = true;
            return true;
        }

        public static bool ClaimChest(CommercialGameState state, string id)
        {
            if (CommercialAshenForest.IsForest(id)) return Find(id)?.Kind == WorldNodeKind.Chest && CommercialAshenForest.Interact(state, id) == null;
            var node = Find(id);
            if (node?.Kind != WorldNodeKind.Chest || !Unlocked(state, node) || !Revealed(state, node) || state.World.CompletedNodes.Contains(id)) return false;
            if (CommercialInventoryService.Grant(state, CommercialInventoryService.MapChestReward(node.Chapter), "遗落宝箱", "world:" + id) != null) return false;
            state.World.CompletedNodes.Add(id);
            return true;
        }

        public static CommercialWorldEncounter CreateEncounter(CommercialGameState state, string id)
        {
            var node = Find(id);
            if (!Unlocked(state, node) || !Revealed(state, node) ||
                (node.Kind != WorldNodeKind.Idle && node.Kind != WorldNodeKind.Elite && node.Kind != WorldNodeKind.Boss)) return null;
            return new CommercialWorldEncounter { NodeId = id, Chapter = node.Chapter,
                Stage = node.GlobalStage - (node.Chapter - 1) * 20, Kind = node.Kind, HealthScale = node.HealthScale, AttackScale = node.AttackScale };
        }

        public static void RecordVictory(CommercialGameState state, CommercialWorldEncounter encounter)
        {
            if (encounter == null) return;
            var first = !state.World.CompletedNodes.Contains(encounter.NodeId);
            var error = CommercialInventoryService.Grant(state, CommercialInventoryService.BattleReward(state, encounter, first),
                encounter.Kind == WorldNodeKind.Idle ? "挂机战利品" : "事件战利品");
            if (error != null) throw new InvalidOperationException(error);
            state.DropSequence++;
            if (first && encounter.Kind != WorldNodeKind.Idle) state.World.CompletedNodes.Add(encounter.NodeId);
            CommercialAshenForest.RecordVictory(state, encounter);
            if (encounter.Kind == WorldNodeKind.Idle)
            {
                var task = CurrentMainQuest(state);
                if (task != null && task.Chapter == encounter.Chapter) task.IdleWins = Mathf.Min(5, task.IdleWins + 1);
            }
            if (encounter.Kind == WorldNodeKind.Boss)
            {
                var task = CurrentMainQuest(state);
                if (task != null && task.Chapter == encounter.Chapter) task.BossDefeated = true;
            }
            if (encounter.Kind == WorldNodeKind.Elite)
                foreach (var quest in state.World.Quests.Where(q => q.Id == "quest_" + encounter.Chapter && !q.Claimed)) quest.Completed = true;
        }
    }
}

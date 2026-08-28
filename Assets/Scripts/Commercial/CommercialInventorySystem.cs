using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    [Serializable] public sealed class WarehouseDefinition { public string Id, Name, Description; }
    [Serializable] public sealed class InventoryAmount
    {
        public string Id;
        public int Count;
        public InventoryAmount() { }
        public InventoryAmount(string id, int count) { Id = id; Count = count; }
    }
    [Serializable] public sealed class InventoryRewardSpec
    {
        public string Kind, Id;
        public int Count, Rarity;
    }
    [Serializable] public sealed class InventoryItemDefinition
    {
        public string Id, Name, WarehouseId, Category, Icon, Description, Source, SourceNode;
        public int Quality;
        public InventoryRewardSpec[] UseRewards;
        public bool CanUse => UseRewards != null && UseRewards.Length > 0;
    }
    [Serializable] public sealed class InventoryBalance
    {
        public WarehouseDefinition[] Warehouses;
        public InventoryItemDefinition[] Items;
        public string[] RegionMaterials;
        public float IdleEquipmentChance = .58f, IdleSupplyChance = .06f;
    }
    [Serializable] public sealed class InventoryStack
    {
        public string ItemId;
        public int Count, Acquired;
    }
    [Serializable] public sealed class InventoryReceipt
    {
        public string Source, Summary;
    }
    [Serializable] public sealed class CommercialInventoryProgress
    {
        public int Version, Revision, Sequence, UseSequence;
        public List<InventoryStack> Stacks = new();
        public List<string> ClaimedReceipts = new();
        public List<InventoryReceipt> Recent = new();
        public void Ensure() { Stacks ??= new(); ClaimedReceipts ??= new(); Recent ??= new(); }
    }

    public sealed class InventoryRewardBundle
    {
        public int Gold, Experience;
        public readonly List<InventoryAmount> Items = new();
        public readonly List<EquipmentItem> Equipment = new();
        public InventoryRewardBundle Add(string id, int count) { Items.Add(new InventoryAmount(id, count)); return this; }
    }

    public static class CommercialInventoryCatalog
    {
        private static InventoryBalance balance;
        private static Dictionary<string, InventoryItemDefinition> items;
        public static InventoryBalance Balance
        {
            get
            {
                if (balance != null) return balance;
                var asset = Resources.Load<TextAsset>("Commercial/Inventory/inventory_config");
                if (!asset) throw new InvalidOperationException("Missing inventory_config.json");
                var parsed = JsonUtility.FromJson<InventoryBalance>(asset.text);
                var error = Validate(parsed);
                if (error != null) throw new InvalidOperationException(error);
                items = parsed.Items.ToDictionary(x => x.Id, StringComparer.Ordinal);
                return balance = parsed;
            }
        }
        public static string Validate(InventoryBalance data)
        {
            if (data?.Warehouses == null || data.Items == null) return "仓库配置缺失";
            var warehouses = new HashSet<string>(); var ids = new HashSet<string>();
            foreach (var w in data.Warehouses)
                if (w == null || string.IsNullOrWhiteSpace(w.Id) || !warehouses.Add(w.Id)) return "仓库编号重复或为空";
            if (!warehouses.Contains("equipment") || !warehouses.Contains("special") || !warehouses.Contains("materials")) return "基础仓库缺失";
            foreach (var item in data.Items)
                if (item == null || string.IsNullOrWhiteSpace(item.Id) || !ids.Add(item.Id) || !warehouses.Contains(item.WarehouseId) || item.WarehouseId == "equipment") return "物品编号或分类无效";
            foreach (var item in data.Items)
                foreach (var r in item.UseRewards ?? Array.Empty<InventoryRewardSpec>())
                    if (r.Count <= 0 || r.Count > 1000000 ||
                        (r.Kind != "gold" && r.Kind != "xp" && r.Kind != "item" && r.Kind != "equipment") ||
                        (r.Kind == "item" && (!ids.Contains(r.Id) || r.Id == item.Id)) ||
                        (r.Kind == "equipment" && (r.Rarity < 0 || r.Rarity > 3))) return "物品使用奖励无效：" + item.Id;
            if (data.RegionMaterials?.Length != 5 || data.RegionMaterials.Any(id => !ids.Contains(id))) return "区域材料掉落配置无效";
            return null;
        }
        public static InventoryItemDefinition Get(string id) { _ = Balance; return id != null && items.TryGetValue(id, out var value) ? value : null; }
        public static string WarehouseFor(string id) => Get(id)?.WarehouseId ?? "special";
        public static string Name(string id) => Get(id)?.Name ?? ("未知物品 · " + id);
        public static string RegionMaterial(int chapter) => Balance.RegionMaterials[Mathf.Clamp(chapter - 1, 0, 4)];
    }

    // Equipment remains in state.Inventory. Forge dust remains in state.Equipment.Dust.
    // All other warehouse entries are stacks; warehouse IDs come from configuration, not an enum.
    public static class CommercialInventoryService
    {
        public const string ForgeDust = "forge_dust";
        public static void Migrate(CommercialGameState state)
        {
            state.Storage ??= new CommercialInventoryProgress(); state.Storage.Ensure();
            state.SaveVersion = Mathf.Max(5, state.SaveVersion);
            state.Storage.Version = 1;
        }
        public static int Count(CommercialGameState state, string id) => id == ForgeDust ? state.Equipment.Dust :
            (int)Math.Min(int.MaxValue, state.Storage.Stacks.Where(s => s.ItemId == id).Sum(s => (long)s.Count));

        public static List<InventoryStack> Entries(CommercialGameState state, string warehouse)
        {
            var result = state.Storage.Stacks.Where(s => s.Count > 0 && s.ItemId != ForgeDust && CommercialInventoryCatalog.WarehouseFor(s.ItemId) == warehouse)
                .GroupBy(s => s.ItemId).Select(g => new InventoryStack { ItemId = g.Key, Count = Count(state, g.Key), Acquired = g.Max(s => s.Acquired) }).ToList();
            if (warehouse == CommercialInventoryCatalog.WarehouseFor(ForgeDust) && state.Equipment.Dust > 0)
                result.Add(new InventoryStack { ItemId = ForgeDust, Count = state.Equipment.Dust, Acquired = state.Storage.Sequence });
            return result;
        }

        // A non-null result is an error. Validation happens before any cost, currency or gear is changed.
        // receiptId is mandatory for purchase delivery; use the authoritative order ID, not a UI-generated ID.
        public static string GrantPurchase(CommercialGameState state, InventoryRewardBundle rewards, string orderId) =>
            string.IsNullOrWhiteSpace(orderId) ? "缺少订单编号" : Grant(state, rewards, "购买奖励", "order:" + orderId);

        public static string Grant(CommercialGameState state, InventoryRewardBundle rewards, string source,
            string receiptId = null, IReadOnlyList<InventoryAmount> costs = null)
        {
            if (state == null || rewards == null) return "奖励数据缺失";
            state.EnsureCharacterData();
            if (!string.IsNullOrEmpty(receiptId) && state.Storage.ClaimedReceipts.Contains(receiptId)) return "该奖励已领取";
            if (rewards.Gold < 0 || rewards.Experience < 0 || (long)state.Gold + rewards.Gold > int.MaxValue ||
                (long)state.Experience + rewards.Experience > int.MaxValue) return "货币或经验数量无效";
            var gains = new Dictionary<string, long>(); var spent = new Dictionary<string, long>();
            foreach (var amount in rewards.Items)
            {
                if (amount == null || amount.Count <= 0 || CommercialInventoryCatalog.Get(amount.Id) == null) return "奖励包含无效物品";
                gains[amount.Id] = gains.GetValueOrDefault(amount.Id) + amount.Count;
            }
            foreach (var amount in costs ?? Array.Empty<InventoryAmount>())
            {
                if (amount == null || amount.Count <= 0 || CommercialInventoryCatalog.Get(amount.Id) == null) return "消耗包含无效物品";
                spent[amount.Id] = spent.GetValueOrDefault(amount.Id) + amount.Count;
            }
            foreach (var pair in spent) if (Count(state, pair.Key) < pair.Value) return CommercialInventoryCatalog.Name(pair.Key) + "数量不足";
            foreach (var pair in gains)
                if ((long)Count(state, pair.Key) - spent.GetValueOrDefault(pair.Key) + pair.Value > int.MaxValue) return "物品数量超出上限";
            var gearIds = new HashSet<string>(state.Inventory.Select(x => x.Id));
            foreach (var gear in rewards.Equipment)
                if (gear == null || string.IsNullOrEmpty(gear.Id) || !gearIds.Add(gear.Id) || gear.EquipmentVersion <= 0) return "装备数据无效或重复入库";

            foreach (var id in spent.Keys.Union(gains.Keys))
            {
                var next = (int)(Count(state, id) - spent.GetValueOrDefault(id) + gains.GetValueOrDefault(id));
                if (id == ForgeDust) state.Equipment.Dust = next;
                else
                {
                    var stack = state.Storage.Stacks.FirstOrDefault(s => s.ItemId == id);
                    var acquired = gains.ContainsKey(id) ? ++state.Storage.Sequence : stack?.Acquired ?? 0;
                    state.Storage.Stacks.RemoveAll(s => s.ItemId == id);
                    if (next > 0) state.Storage.Stacks.Add(new InventoryStack { ItemId = id, Count = next, Acquired = acquired });
                }
            }
            state.Gold += rewards.Gold; state.GainExperience(rewards.Experience);
            state.Inventory.AddRange(rewards.Equipment);
            if (rewards.Equipment.Count > 0 || gains.ContainsKey(ForgeDust) || spent.ContainsKey(ForgeDust)) state.Equipment.Revision++;
            state.Storage.Revision++;
            if (!string.IsNullOrEmpty(receiptId)) state.Storage.ClaimedReceipts.Add(receiptId);
            var summary = Describe(rewards);
            if (!string.IsNullOrEmpty(summary))
            {
                state.Storage.Recent.Insert(0, new InventoryReceipt { Source = source, Summary = summary });
                if (state.Storage.Recent.Count > 20) state.Storage.Recent.RemoveRange(20, state.Storage.Recent.Count - 20);
            }
            return null;
        }

        public static string ConsumeMaterials(CommercialGameState state, IReadOnlyList<InventoryAmount> costs) =>
            Grant(state, new InventoryRewardBundle(), "材料提交", costs: costs);

        public static string Use(CommercialGameState state, string id, int quantity, out string message)
        {
            message = null;
            var item = CommercialInventoryCatalog.Get(id);
            if (item?.CanUse != true) return "该物品不可直接使用";
            if (quantity < 1 || quantity > 99 || Count(state, id) < quantity) return "使用数量无效";
            var rewards = new InventoryRewardBundle();
            var chapter = CommercialWorldCatalog.Find(state.World.IdleNodeId)?.Chapter ?? 1;
            var seed = unchecked(38971 + state.Storage.UseSequence * 7919);
            foreach (var r in item.UseRewards)
            {
                var total = checked(r.Count * quantity);
                switch (r.Kind)
                {
                    case "gold": rewards.Gold = checked(rewards.Gold + total); break;
                    case "xp": rewards.Experience = checked(rewards.Experience + total); break;
                    case "item": rewards.Add(r.Id, total); break;
                    case "equipment":
                        for (var i = 0; i < total; i++) rewards.Equipment.Add(CommercialEquipmentService.Generate(chapter, 1, seed++,
                            forcedRarity: (EquipmentRarity)r.Rarity, forcedLevel: Mathf.Clamp(state.PlayerLevel, 1, 50)));
                        break;
                }
            }
            var error = Grant(state, rewards, "使用 · " + item.Name, costs: new[] { new InventoryAmount(id, quantity) });
            if (error != null) return error;
            state.Storage.UseSequence++;
            message = Describe(rewards); return null;
        }

        public static string Describe(InventoryRewardBundle rewards)
        {
            var parts = new List<string>();
            if (rewards.Gold > 0) parts.Add("金币 ×" + rewards.Gold);
            if (rewards.Experience > 0) parts.Add("经验 ×" + rewards.Experience);
            parts.AddRange(rewards.Items.GroupBy(x => x.Id).Select(g => CommercialInventoryCatalog.Name(g.Key) + " ×" + g.Sum(x => x.Count)));
            if (rewards.Equipment.Count > 0) parts.Add("装备 ×" + rewards.Equipment.Count);
            return string.Join("  /  ", parts);
        }
        public static string UsePreview(InventoryItemDefinition item, int count = 1) => string.Join("\n", (item.UseRewards ?? Array.Empty<InventoryRewardSpec>()).Select(r =>
            r.Kind == "equipment" ? $"{new[] { "普通", "稀有", "史诗", "传说" }[r.Rarity]}装备 ×{r.Count * count}（随机部位，随当前等级生成） → 装备仓库" :
            $"{(r.Kind == "gold" ? "金币" : r.Kind == "xp" ? "经验" : CommercialInventoryCatalog.Name(r.Id))} ×{r.Count * count}"));

        public static InventoryRewardBundle QuestReward(CommercialGameState state, int chapter)
        {
            var reward = new InventoryRewardBundle { Gold = 160 + chapter * 80, Experience = 40 + chapter * 20 };
            reward.Add(CommercialInventoryCatalog.RegionMaterial(chapter), 4).Add(ForgeDust, 2);
            reward.Equipment.Add(CommercialEquipmentService.Generate(chapter, 3, 51079 + chapter * 307, forcedRarity: EquipmentRarity.Blue));
            return reward;
        }
        public static InventoryRewardBundle MainReward(int chapter) => new InventoryRewardBundle { Gold = 200 + chapter * 100, Experience = 60 + chapter * 30 }
            .Add(ForgeDust, 4).Add("rare_equipment_chest", 1).Add("quest_seal", 1);
        public static InventoryRewardBundle MapChestReward(int chapter) => new InventoryRewardBundle { Gold = 80 + chapter * 60, Experience = 25 + chapter * 10 }
            .Add("equipment_chest", 1).Add(CommercialInventoryCatalog.RegionMaterial(chapter), 3);
        public static InventoryRewardBundle BattleReward(CommercialGameState state, CommercialWorldEncounter encounter, bool first)
        {
            var chapter = encounter.Chapter;
            var seed = unchecked(9109 + state.DropSequence * 37);
            var random = new System.Random(seed);
            var reward = new InventoryRewardBundle { Gold = 15 + chapter * 8, Experience = 10 + chapter * 5 };
            reward.Add(encounter.NodeId == "af_mine" ? "iron_ore" : CommercialInventoryCatalog.RegionMaterial(chapter), encounter.Kind == WorldNodeKind.Idle ? random.Next(1, 4) : 4);
            if (encounter.Kind == WorldNodeKind.Idle)
            {
                if (random.NextDouble() < CommercialInventoryCatalog.Balance.IdleEquipmentChance)
                    reward.Equipment.Add(EquipmentGenerator.Generate(chapter, encounter.Stage, seed));
                if (random.NextDouble() < CommercialInventoryCatalog.Balance.IdleSupplyChance) reward.Add("supply_chest", 1);
            }
            else if (first)
            {
                reward.Gold += 100 * chapter;
                reward.Equipment.Add(EquipmentGenerator.Generate(chapter, encounter.Stage, 24071 + state.DropSequence));
            }
            if (encounter.Kind == WorldNodeKind.Boss) reward.Add("boss_essence", 1);
            return reward;
        }
    }
}

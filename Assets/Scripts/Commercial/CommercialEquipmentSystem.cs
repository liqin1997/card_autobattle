using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    public enum EquipmentStat
    {
        Strength, Dexterity, Intelligence, Vitality, AbilityPower, Health, Armor,
        HealthPercent, ArmorPercent, CritChance, CritDamage, HeroAttackSpeed, DamageBonus,
        BasicAttackBonus, ProjectileBonus, MagicBonus, HealingBonus, ShieldBonus,
        SummonHealthBonus, SummonDamageBonus, StartingShield
    }
    [Serializable] public sealed class EquipmentStatValue
    {
        public string Stat;
        public float Value;
        public EquipmentStatValue() { }
        public EquipmentStatValue(EquipmentStat stat, float value) { Stat = stat.ToString(); Value = value; }
        public EquipmentStat Kind => Enum.TryParse<EquipmentStat>(Stat, out var kind) ? kind : EquipmentStat.AbilityPower;
    }
    [Serializable] public sealed class EquipmentAffix
    {
        public string Stat;
        public float Value, Min, Max;
        public EquipmentStat Kind => Enum.TryParse<EquipmentStat>(Stat, out var kind) ? kind : EquipmentStat.AbilityPower;
        public float Quality => Mathf.InverseLerp(Min, Max, Value);
    }
    [Serializable] public sealed class EquipmentPendingRoll
    { public string ItemId; public int Index; public EquipmentAffix Candidate; }
    [Serializable] public sealed class EquipmentLoadout
    { public string Name; public string[] ItemIds = new string[6]; }
    [Serializable] public sealed class EquipmentProgress
    {
        public int Dust;
        public int Revision;
        public int[] SlotUpgrades = new int[6];
        public EquipmentLoadout[] Loadouts = new EquipmentLoadout[3];
        public EquipmentPendingRoll PendingRoll;
        public int CraftSequence;
        public void Ensure()
        {
            if (SlotUpgrades?.Length != 6) SlotUpgrades = new int[6];
            if (Loadouts?.Length != 3) Loadouts = new EquipmentLoadout[3];
            for (var i = 0; i < 3; i++)
            {
                Loadouts[i] ??= new EquipmentLoadout { Name = "方案 " + (i + 1) };
                if (Loadouts[i].ItemIds?.Length != 6) Loadouts[i].ItemIds = new string[6];
            }
            Dust = Mathf.Max(0, Dust);
            for (var i = 0; i < 6; i++) SlotUpgrades[i] = Mathf.Clamp(SlotUpgrades[i], 0, 20);
        }
    }
    [Serializable] public sealed class EquipmentRarityRule { public string Name; public float Quality; public int AffixCount, Salvage, IconTier; }
    [Serializable] public sealed class EquipmentSlotRule { public string Name; public int IconPart; public float MainAttribute, Health, Armor, Power; }
    [Serializable] public sealed class EquipmentSetBonus { public int Pieces; public EquipmentStatValue[] Stats; }
    [Serializable] public sealed class EquipmentSetRule { public string Id, Name, Theme, Attribute, Weapon; public EquipmentSetBonus[] Bonuses; }
    [Serializable] public sealed class EquipmentAffixRule { public string Stat; public float Min, Max, LevelScale; public int Weight; }
    [Serializable] public sealed class EquipmentDropRule { public int White, Blue, Purple, Gold; }
    [Serializable] public sealed class EquipmentBalance
    {
        public int Version, MaxItemLevel, MaxUpgradeLevel;
        public float UpgradeBaseStep;
        public EquipmentRarityRule[] Rarities;
        public EquipmentSlotRule[] Slots;
        public EquipmentSetRule[] Sets;
        public EquipmentAffixRule[] Affixes;
        public EquipmentDropRule[] RegionDrops;
        public int UpgradeGoldBase, UpgradeGoldStep, UpgradeDustBase, ReforgeGoldBase, ReforgeGoldPerLevel, ReforgeDust;
        public int[] CraftGold, CraftGoldPerLevel, CraftDust;
    }
    public static class CommercialEquipmentCatalog
    {
        private static EquipmentBalance balance;
        public static EquipmentBalance Balance => balance ??= Load();
        private static EquipmentBalance Load()
        {
            var asset = Resources.Load<TextAsset>("Commercial/Equipment/equipment_balance");
            if (!asset) throw new InvalidOperationException("Equipment balance config missing.");
            var config = JsonUtility.FromJson<EquipmentBalance>(asset.text);
            if (config?.Slots?.Length != 6 || config.Rarities?.Length != 4 || config.Sets?.Length != 5 || config.Affixes?.Length < 1)
                throw new InvalidOperationException("Invalid equipment balance config.");
            foreach (var affix in config.Affixes)
                if (!Enum.TryParse<EquipmentStat>(affix.Stat, out _) || affix.Max < affix.Min || affix.Weight <= 0)
                    throw new InvalidOperationException("Invalid equipment affix: " + affix.Stat);
            return config;
        }
        public static void Reload() => balance = null;
        public static EquipmentSetRule Set(string id) => Balance.Sets.FirstOrDefault(s => s.Id == id);
        public static string SlotName(EquipmentSlot slot) => Balance.Slots[(int)slot].Name;
        private static readonly string[] Names = { "力量", "敏捷", "智力", "体质", "效果强度", "生命", "护甲", "生命加成", "护甲加成", "暴击率", "暴击伤害", "主角攻速", "伤害加成", "普攻伤害", "投射物伤害", "魔法伤害", "治疗效果", "护盾效果", "召唤物生命", "召唤物伤害", "开场护盾" };
        public static string Name(EquipmentStat stat) => Names[(int)stat];
        public static bool IsPercent(EquipmentStat stat) => (int)stat >= (int)EquipmentStat.HealthPercent;
        public static string Format(EquipmentStat stat, float value, bool sign = true) =>
            (sign && value >= 0 ? "+" : "") + (IsPercent(stat) ? $"{value * 100:0.#}%" : $"{value:0.#}");
        public static string IconKey(EquipmentItem item)
        {
            var tier = Balance.Rarities[(int)item.Rarity].IconTier;
            var part = Balance.Slots[(int)item.Slot].IconPart;
            return item.Slot == EquipmentSlot.MainWeapon ? $"icon_{Set(item.SetId)?.Weapon ?? "sword"}_{tier:00}" : $"equip_{tier}000{part}";
        }
    }
    public sealed class EquipmentStatBlock
    {
        private readonly float[] values = new float[21];
        public float this[EquipmentStat stat] => values[(int)stat];
        public void Add(EquipmentStat stat, float value) { if (!float.IsNaN(value) && !float.IsInfinity(value)) values[(int)stat] += value; }
        public void Add(EquipmentStatBlock other) { for (var i = 0; i < values.Length; i++) values[i] += other.values[i]; }
        public float DamageMultiplier(CommercialCardTag tags, bool summon = false, bool basic = false) => 1 +
            this[EquipmentStat.DamageBonus] + (basic ? this[EquipmentStat.BasicAttackBonus] : 0) +
            ((tags & CommercialCardTag.Projectile) != 0 ? this[EquipmentStat.ProjectileBonus] : 0) +
            ((tags & CommercialCardTag.Magic) != 0 ? this[EquipmentStat.MagicBonus] : 0) +
            (summon ? this[EquipmentStat.SummonDamageBonus] : 0);
    }

    public static class CommercialEquipmentService
    {
        public static void Migrate(CommercialGameState state)
        {
            state.Equipment ??= new EquipmentProgress(); state.Equipment.Ensure();
            state.Inventory ??= new List<EquipmentItem>(); state.Equipped ??= new List<EquippedItemEntry>();
            state.Inventory.RemoveAll(i => i == null);
            // JsonUtility duplicates nested item objects. Rebind equipment to canonical inventory identities.
            foreach (var entry in state.Equipped.Where(e => e?.Item != null))
            {
                var canonical = state.Inventory.FirstOrDefault(i => i.Id == entry.Item.Id);
                if (canonical == null) { canonical = entry.Item; state.Inventory.Add(canonical); }
                entry.Item = canonical; entry.Slot = canonical.Slot;
            }
            state.Equipped = state.Equipped.Where(e => e?.Item != null).GroupBy(e => e.Slot).Select(g => g.Last()).ToList();
            var ids = new HashSet<string>();
            foreach (var item in state.Inventory)
            {
                if (string.IsNullOrEmpty(item.Id) || !ids.Add(item.Id)) { item.Id = "eq_" + Guid.NewGuid().ToString("N"); ids.Add(item.Id); }
                item.BaseStats ??= new List<EquipmentStatValue>(); item.Affixes ??= new List<EquipmentAffix>();
                if (item.EquipmentVersion > 0) continue;
                item.BaseStats.Add(new EquipmentStatValue(EquipmentStat.AbilityPower, item.Attack));
                item.BaseStats.Add(new EquipmentStatValue(EquipmentStat.Armor, item.Defense));
                item.BaseStats.Add(new EquipmentStatValue(EquipmentStat.Health, item.Health));
                item.BaseStats.Add(new EquipmentStatValue(EquipmentStat.HeroAttackSpeed, item.AttackSpeed));
                item.RequiredLevel = 1; item.Legacy = true; item.EquipmentVersion = 1;
            }
            var pending = state.Equipment.PendingRoll;
            if (pending != null)
            {
                var item = state.Inventory.FirstOrDefault(i => i.Id == pending.ItemId);
                if (item == null || pending.Candidate == null || pending.Index < 0 || pending.Index >= item.Affixes.Count)
                    state.Equipment.PendingRoll = null;
            }
            state.SaveVersion = Mathf.Max(4, state.SaveVersion);
        }

        public static EquipmentItem Generate(int chapter, int stage, int seed, EquipmentSlot? forcedSlot = null,
            EquipmentRarity? forcedRarity = null, string forcedSet = null, int? forcedLevel = null)
        {
            var c = CommercialEquipmentCatalog.Balance; var random = new System.Random(seed);
            var drop = c.RegionDrops[Mathf.Clamp(chapter - 1, 0, 4)];
            var roll = random.Next(drop.White + drop.Blue + drop.Purple + drop.Gold);
            var rarity = forcedRarity ?? (roll < drop.White ? EquipmentRarity.White : roll < drop.White + drop.Blue ? EquipmentRarity.Blue :
                roll < drop.White + drop.Blue + drop.Purple ? EquipmentRarity.Purple : EquipmentRarity.Gold);
            var slot = forcedSlot ?? (EquipmentSlot)random.Next(6);
            var set = rarity == EquipmentRarity.White ? null : CommercialEquipmentCatalog.Set(forcedSet) ??
                c.Sets[random.NextDouble() < .6 ? Mathf.Clamp(chapter - 1, 0, 4) : random.Next(5)];
            var level = Mathf.Clamp(forcedLevel ?? (1 + (chapter - 1) * 8 + (stage - 1) / 3), 1, c.MaxItemLevel);
            var item = new EquipmentItem { Id = "eq_" + Guid.NewGuid().ToString("N"), EquipmentVersion = 1, Slot = slot, Rarity = rarity,
                ItemLevel = level, RequiredLevel = Mathf.Max(1, level / 2), SetId = set?.Id,
                DisplayName = (set?.Name ?? "旅者") + "·" + c.Slots[(int)slot].Name, RollSeed = seed };
            var quality = c.Rarities[(int)rarity].Quality * (1 + (level - 1) * .035f);
            var rule = c.Slots[(int)slot];
            Add(EquipmentStat.Health, rule.Health); Add(EquipmentStat.Armor, rule.Armor); Add(EquipmentStat.AbilityPower, rule.Power);
            var primary = set == null ? (EquipmentStat)random.Next(4) : Enum.Parse<EquipmentStat>(set.Attribute);
            Add(primary, rule.MainAttribute);
            for (var i = 0; i < c.Rarities[(int)rarity].AffixCount; i++) item.Affixes.Add(RollAffix(item, random, -1));
            return item;
            void Add(EquipmentStat stat, float value) { if (value > 0) item.BaseStats.Add(new EquipmentStatValue(stat, Mathf.Round(value * quality * 10) / 10)); }
        }
        private static EquipmentAffix RollAffix(EquipmentItem item, System.Random random, int replacing)
        {
            var excluded = new HashSet<string>(item.Affixes.Where((_, i) => i != replacing).Select(a => a.Stat));
            var rules = CommercialEquipmentCatalog.Balance.Affixes.Where(r => !excluded.Contains(r.Stat)).ToArray();
            var roll = random.Next(rules.Sum(r => r.Weight)); var chosen = rules[0];
            foreach (var rule in rules) { roll -= rule.Weight; if (roll < 0) { chosen = rule; break; } }
            var scale = 1 + (item.ItemLevel - 1) * chosen.LevelScale;
            var min = chosen.Min * scale; var max = chosen.Max * scale;
            var value = min + (float)random.NextDouble() * (max - min);
            var percent = CommercialEquipmentCatalog.IsPercent(Enum.Parse<EquipmentStat>(chosen.Stat));
            var precision = percent ? 1000f : 10f;
            min = Mathf.Ceil(min * precision) / precision; max = Mathf.Floor(max * precision) / precision;
            return new EquipmentAffix { Stat = chosen.Stat, Min = min, Max = max, Value = Mathf.Clamp(Mathf.Round(value * precision) / precision, min, max) };
        }
        public static EquipmentStatBlock ItemStats(EquipmentItem item, int upgrade = 0)
        {
            var result = new EquipmentStatBlock(); if (item == null) return result;
            if (item.EquipmentVersion == 0)
            {
                result.Add(EquipmentStat.AbilityPower, item.Attack); result.Add(EquipmentStat.Armor, item.Defense);
                result.Add(EquipmentStat.Health, item.Health); result.Add(EquipmentStat.HeroAttackSpeed, item.AttackSpeed);
                return result;
            }
            foreach (var stat in item.BaseStats)
                result.Add(stat.Kind, stat.Value * (1 + upgrade * CommercialEquipmentCatalog.Balance.UpgradeBaseStep));
            foreach (var affix in item.Affixes) result.Add(affix.Kind, affix.Value);
            return result;
        }
        public static EquipmentStatBlock Aggregate(CommercialGameState state, EquipmentSlot? replaceSlot = null, EquipmentItem replacement = null)
        {
            var stats = new EquipmentStatBlock(); var sets = new Dictionary<string, int>();
            for (var i = 0; i < 6; i++)
            {
                var slot = (EquipmentSlot)i;
                var item = replaceSlot == slot ? replacement : state.GetEquipped(slot);
                if (item == null) continue;
                var upgrade = state.Equipment?.SlotUpgrades?.Length == 6 ? state.Equipment.SlotUpgrades[i] : 0;
                stats.Add(ItemStats(item, upgrade));
                if (!string.IsNullOrEmpty(item.SetId)) sets[item.SetId] = sets.GetValueOrDefault(item.SetId) + 1;
            }
            foreach (var entry in sets)
            {
                var definition = CommercialEquipmentCatalog.Set(entry.Key); if (definition == null) continue;
                foreach (var bonus in definition.Bonuses.Where(b => entry.Value >= b.Pieces))
                    foreach (var stat in bonus.Stats) stats.Add(stat.Kind, stat.Value);
            }
            return stats;
        }
        public static int SetCount(CommercialGameState state, string id) => state.Equipped.Count(e => e.Item?.SetId == id);
        public static float ItemScore(EquipmentItem item)
        {
            var s = ItemStats(item); var value = 0f;
            foreach (EquipmentStat stat in Enum.GetValues(typeof(EquipmentStat)))
                value += s[stat] * (CommercialEquipmentCatalog.IsPercent(stat) ? 180 : stat == EquipmentStat.Health ? .5f : 5);
            return value;
        }
        public static string Equip(CommercialGameState state, EquipmentItem item)
        {
            if (item == null || !state.Inventory.Contains(item)) return "装备不存在";
            if (state.PlayerLevel < item.RequiredLevel) return $"需要角色 Lv.{item.RequiredLevel}";
            state.Equipped.RemoveAll(e => e.Slot == item.Slot);
            state.Equipped.Add(new EquippedItemEntry { Slot = item.Slot, Item = item }); Touch(state); return null;
        }
        public static void Unequip(CommercialGameState state, EquipmentSlot slot) { state.Equipped.RemoveAll(e => e.Slot == slot); Touch(state); }
        public static void Touch(CommercialGameState state) => state.Equipment.Revision++;
        public static string ProtectedReason(CommercialGameState state, EquipmentItem item)
        {
            if (item == null || !state.Inventory.Contains(item)) return "装备不存在";
            if (state.Equipped.Any(e => e.Item.Id == item.Id)) return "已穿戴装备不能分解";
            if (item.Locked) return "锁定装备不能分解";
            if (state.Equipment.PendingRoll?.ItemId == item.Id) return "请先处理待确认重铸";
            if (state.Equipment.Loadouts.Any(l => l.ItemIds.Contains(item.Id))) return "保存的配装正在使用该装备";
            return null;
        }
        public static int SalvageValue(EquipmentItem item) => CommercialEquipmentCatalog.Balance.Rarities[(int)item.Rarity].Salvage + item.ItemLevel / 10;
        public static string Salvage(CommercialGameState state, EquipmentItem item)
        {
            var reason = ProtectedReason(state, item); if (reason != null) return reason;
            state.Inventory.Remove(item); state.Equipment.Dust += SalvageValue(item); Touch(state); return null;
        }
        public static (int Gold, int Dust) UpgradeCost(CommercialGameState state, EquipmentSlot slot)
        {
            var c = CommercialEquipmentCatalog.Balance; var next = state.Equipment.SlotUpgrades[(int)slot] + 1;
            return (c.UpgradeGoldBase + next * c.UpgradeGoldStep, c.UpgradeDustBase + next / 4);
        }
        public static string Upgrade(CommercialGameState state, EquipmentSlot slot)
        {
            var level = state.Equipment.SlotUpgrades[(int)slot];
            if (level >= Mathf.Min(CommercialEquipmentCatalog.Balance.MaxUpgradeLevel, state.PlayerLevel + 2)) return "已达强化上限，提升角色等级可继续";
            var cost = UpgradeCost(state, slot); if (state.Gold < cost.Gold || state.Equipment.Dust < cost.Dust) return "金币或锻造尘不足";
            state.Gold -= cost.Gold; state.Equipment.Dust -= cost.Dust; state.Equipment.SlotUpgrades[(int)slot]++; Touch(state); return null;
        }
        public static (int Gold, int Dust) ReforgeCost(EquipmentItem item) =>
            (CommercialEquipmentCatalog.Balance.ReforgeGoldBase + item.ItemLevel * CommercialEquipmentCatalog.Balance.ReforgeGoldPerLevel,
                CommercialEquipmentCatalog.Balance.ReforgeDust);
        public static string BeginReforge(CommercialGameState state, EquipmentItem item, int index)
        {
            if (item == null || !state.Inventory.Contains(item) || index < 0 || index >= item.Affixes.Count) return "选择一条可重铸的随机词条";
            if (state.Equipment.PendingRoll != null) return "请先保留或放弃上次重铸结果";
            var cost = ReforgeCost(item); if (state.Gold < cost.Gold || state.Equipment.Dust < cost.Dust) return "金币或锻造尘不足";
            var candidate = RollAffix(item, new System.Random(unchecked(item.RollSeed + (++item.ReforgeCount) * 7919)), index);
            state.Gold -= cost.Gold; state.Equipment.Dust -= cost.Dust;
            state.Equipment.PendingRoll = new EquipmentPendingRoll { ItemId = item.Id, Index = index, Candidate = candidate };
            Touch(state); return null;
        }
        public static string FinishReforge(CommercialGameState state, bool accept)
        {
            var pending = state.Equipment.PendingRoll; if (pending == null) return "没有待确认结果";
            var item = state.Inventory.FirstOrDefault(i => i.Id == pending.ItemId);
            if (item == null || pending.Index < 0 || pending.Index >= item.Affixes.Count) return "原装备或词条不存在";
            if (accept) item.Affixes[pending.Index] = pending.Candidate;
            state.Equipment.PendingRoll = null; Touch(state); return null;
        }
        public static (int Gold, int Dust) CraftCost(CommercialGameState state, EquipmentRarity rarity)
        {
            var c = CommercialEquipmentCatalog.Balance; var q = (int)rarity;
            return (c.CraftGold[q] + Mathf.Min(state.PlayerLevel, c.MaxItemLevel) * c.CraftGoldPerLevel[q], c.CraftDust[q]);
        }
        public static string Craft(CommercialGameState state, string setId, EquipmentSlot slot, EquipmentRarity rarity, out EquipmentItem item)
        {
            item = null;
            if (rarity == EquipmentRarity.White || (int)rarity < 0 || (int)rarity > 3 || (int)slot < 0 || (int)slot > 5 || CommercialEquipmentCatalog.Set(setId) == null) return "无效锻造配方";
            var cost = CraftCost(state, rarity); if (state.Gold < cost.Gold || state.Equipment.Dust < cost.Dust) return "金币或锻造尘不足";
            item = Generate(1, 1, 19001 + (++state.Equipment.CraftSequence) * 48611, slot, rarity, setId, state.PlayerLevel);
            state.Gold -= cost.Gold; state.Equipment.Dust -= cost.Dust; state.Inventory.Add(item); Touch(state); return null;
        }
        public static void SaveLoadout(CommercialGameState state, int index)
        {
            if (index < 0 || index >= 3) return;
            for (var i = 0; i < 6; i++) state.Equipment.Loadouts[index].ItemIds[i] = state.GetEquipped((EquipmentSlot)i)?.Id;
            Touch(state);
        }
        public static string ApplyLoadout(CommercialGameState state, int index)
        {
            if (index < 0 || index >= 3) return "无效方案";
            var ids = state.Equipment.Loadouts[index].ItemIds;
            if (ids.All(string.IsNullOrEmpty)) return "该方案尚未保存";
            var chosen = new List<EquippedItemEntry>();
            for (var i = 0; i < 6; i++)
            {
                if (string.IsNullOrEmpty(ids[i])) continue;
                var item = state.Inventory.FirstOrDefault(t => t.Id == ids[i]);
                if (item == null || item.Slot != (EquipmentSlot)i || item.RequiredLevel > state.PlayerLevel) return "方案中装备缺失或等级不足，未更换任何装备";
                chosen.Add(new EquippedItemEntry { Slot = (EquipmentSlot)i, Item = item });
            }
            state.Equipped = chosen; Touch(state); return null;
        }
    }
}

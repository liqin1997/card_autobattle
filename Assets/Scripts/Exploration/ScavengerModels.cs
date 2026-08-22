using System;
using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Preparation;
using CardAutobattle.Prototype;
using UnityEngine;

namespace CardAutobattle.Exploration
{
    public enum TalentRarity
    {
        Green,
        Blue,
        Purple,
        Gold,
        Red
    }

    public enum TalentScope
    {
        None,
        AllCards,
        Weapon,
        Magic,
        Defense,
        Support,
        DirectDamage,
        Burn,
        Poison,
        Shield,
        Healing
    }

    [Serializable]
    public sealed class ScavengerStats
    {
        public float Might;
        public float Intellect;
        public float Defense;
        public float Vitality;

        public ScavengerStats() { }

        public ScavengerStats(float might, float intellect, float defense, float vitality)
        {
            Might = might;
            Intellect = intellect;
            Defense = defense;
            Vitality = vitality;
        }
    }

    [Serializable]
    public sealed class ScavengerDeckEntry
    {
        public string CardId;
        public int Level;
        public int SlotIndex;
        public SlotModifierType SlotModifier;
    }

    [Serializable]
    public sealed class TalentDefinition
    {
        public string Id;
        public string DisplayName;
        public string Description;
        public TalentRarity Rarity;
        public TalentScope Scope;
        public float EffectBonus;
        public float MightPercent;
        public float IntellectPercent;
        public float DefensePercent;
        public float VitalityPercent;
        public float MightGrowthPercent;
        public float IntellectGrowthPercent;
        public float DefenseGrowthPercent;
        public float VitalityGrowthPercent;
        public float CooldownReduction;

        public TalentDefinition(string id, string displayName, string description, TalentRarity rarity,
            TalentScope scope = TalentScope.None, float effectBonus = 0f,
            float mightPercent = 0f, float intellectPercent = 0f, float defensePercent = 0f,
            float vitalityPercent = 0f, float mightGrowthPercent = 0f, float intellectGrowthPercent = 0f,
            float defenseGrowthPercent = 0f, float vitalityGrowthPercent = 0f, float cooldownReduction = 0f)
        {
            Id = id;
            DisplayName = displayName;
            Description = description;
            Rarity = rarity;
            Scope = scope;
            EffectBonus = effectBonus;
            MightPercent = mightPercent;
            IntellectPercent = intellectPercent;
            DefensePercent = defensePercent;
            VitalityPercent = vitalityPercent;
            MightGrowthPercent = mightGrowthPercent;
            IntellectGrowthPercent = intellectGrowthPercent;
            DefenseGrowthPercent = defenseGrowthPercent;
            VitalityGrowthPercent = vitalityGrowthPercent;
            CooldownReduction = cooldownReduction;
        }

        public bool AppliesTo(CardDefinition definition)
        {
            return Scope switch
            {
                TalentScope.AllCards => true,
                TalentScope.Weapon => (definition.Tags & CardTag.Weapon) != 0,
                TalentScope.Magic => (definition.Tags & CardTag.Magic) != 0,
                TalentScope.Defense => (definition.Tags & CardTag.Defense) != 0,
                TalentScope.Support => (definition.Tags & CardTag.Support) != 0,
                TalentScope.DirectDamage => IsDirectDamage(definition.Effect),
                TalentScope.Burn => definition.Effect == CardEffectKind.DamageAndBurn,
                TalentScope.Poison => definition.Effect == CardEffectKind.DamageAndPoison,
                TalentScope.Shield => definition.Effect is CardEffectKind.Shield or CardEffectKind.ShieldAndDamage or
                    CardEffectKind.ShieldAndVictoryGold or CardEffectKind.ShieldAndHeal,
                TalentScope.Healing => definition.Effect is CardEffectKind.Heal or CardEffectKind.Drain or
                    CardEffectKind.ShieldAndHeal,
                _ => false
            };
        }

        private static bool IsDirectDamage(CardEffectKind effect)
        {
            return effect is CardEffectKind.Damage or CardEffectKind.DamageAndBurn or
                CardEffectKind.DamageAndPoison or CardEffectKind.DamageAndSlow or
                CardEffectKind.DamageAndHaste or CardEffectKind.ShieldAndDamage or
                CardEffectKind.Drain or CardEffectKind.ChainDamage;
        }
    }

    public static class ScavengerTalentCatalog
    {
        private static readonly List<TalentDefinition> Definitions = new()
        {
            new("mechanical_arm", "机械臂", "武力+8%", TalentRarity.Green, mightPercent: .08f),
            new("rapid_thinking", "快速思考", "智力+8%", TalentRarity.Green, intellectPercent: .08f),
            new("wasteland_armor", "废土护甲", "防御+8%", TalentRarity.Green, defensePercent: .08f),
            new("strong_body", "强健体魄", "体力+8%", TalentRarity.Green, vitalityPercent: .08f),
            new("field_repair", "临时改装", "全部卡牌效果+5%", TalentRarity.Green, TalentScope.AllCards, .05f),

            new("weapon_expert", "武器专家", "武器卡效果+15%", TalentRarity.Blue, TalentScope.Weapon, .15f),
            new("combustion_theory", "燃烧学识", "火焰效果+18%", TalentRarity.Blue, TalentScope.Burn, .18f),
            new("toxin_mixing", "毒素调配", "毒效果+18%", TalentRarity.Blue, TalentScope.Poison, .18f),
            new("protection_engineer", "防护工程", "护盾效果+18%", TalentRarity.Blue, TalentScope.Shield, .18f),
            new("field_medic", "战地医疗", "治疗效果+18%", TalentRarity.Blue, TalentScope.Healing, .18f),

            new("coordinated_strike", "协同打击", "直接伤害+12%，武力成长+10%", TalentRarity.Purple,
                TalentScope.DirectDamage, .12f, mightGrowthPercent: .10f),
            new("thermal_diffusion", "热能扩散", "火焰效果+24%", TalentRarity.Purple, TalentScope.Burn, .24f),
            new("biochemical_cycle", "生化循环", "毒效果+24%", TalentRarity.Purple, TalentScope.Poison, .24f),
            new("defense_array", "防御阵列", "护盾效果+24%", TalentRarity.Purple, TalentScope.Shield, .24f),
            new("central_core", "中枢核心", "全部卡牌效果+10%", TalentRarity.Purple, TalentScope.AllCards, .10f),

            new("chain_arsenal", "连锁武装", "武器卡效果+22%，CD缩短3%", TalentRarity.Gold,
                TalentScope.Weapon, .22f, cooldownReduction: .03f),
            new("overload_burning", "过载燃烧", "火焰效果+30%", TalentRarity.Gold, TalentScope.Burn, .30f),
            new("toxic_symbiosis", "毒素共生", "毒效果+30%", TalentRarity.Gold, TalentScope.Poison, .30f),
            new("energy_barrier", "能量壁垒", "护盾效果+30%", TalentRarity.Gold, TalentScope.Shield, .30f),
            new("tactical_reorg", "战术重组", "全部卡牌效果+15%", TalentRarity.Gold, TalentScope.AllCards, .15f),

            new("arms_dominion", "军火统治", "武器效果+35%，武力成长+30%", TalentRarity.Red,
                TalentScope.Weapon, .35f, mightGrowthPercent: .30f),
            new("incineration_protocol", "焚城协议", "火焰效果+40%，智力成长+25%", TalentRarity.Red,
                TalentScope.Burn, .40f, intellectGrowthPercent: .25f),
            new("immortal_strain", "永生毒株", "毒效果+40%，智力成长+25%", TalentRarity.Red,
                TalentScope.Poison, .40f, intellectGrowthPercent: .25f),
            new("absolute_defense", "绝对防线", "护盾效果+35%，防御成长+30%", TalentRarity.Red,
                TalentScope.Shield, .35f, defenseGrowthPercent: .30f),
            new("neural_overclock", "神经超频", "全部效果+15%，CD缩短8%", TalentRarity.Red,
                TalentScope.AllCards, .15f, cooldownReduction: .08f)
        };

        private static readonly Dictionary<string, TalentDefinition> Lookup =
            Definitions.ToDictionary(definition => definition.Id, StringComparer.Ordinal);

        public static IReadOnlyList<TalentDefinition> All => Definitions;

        public static TalentDefinition Get(string id)
        {
            return id != null && Lookup.TryGetValue(id, out var definition) ? definition : Definitions[0];
        }

        public static IReadOnlyList<TalentDefinition> GetByRarity(TalentRarity rarity)
        {
            return Definitions.Where(definition => definition.Rarity == rarity).ToArray();
        }

        public static Color RarityColor(TalentRarity rarity)
        {
            return rarity switch
            {
                TalentRarity.Green => new Color(.30f, .92f, .48f),
                TalentRarity.Blue => new Color(.22f, .62f, 1f),
                TalentRarity.Purple => new Color(.68f, .34f, 1f),
                TalentRarity.Gold => new Color(1f, .74f, .18f),
                TalentRarity.Red => new Color(1f, .22f, .20f),
                _ => Color.white
            };
        }

        public static string RarityName(TalentRarity rarity)
        {
            return rarity switch
            {
                TalentRarity.Green => "绿色",
                TalentRarity.Blue => "蓝色",
                TalentRarity.Purple => "紫色",
                TalentRarity.Gold => "金色",
                TalentRarity.Red => "红色",
                _ => rarity.ToString()
            };
        }
    }

    [Serializable]
    public sealed class ScavengerRecord
    {
        public string Id;
        public string DisplayName;
        public string Archetype;
        public int Level = 1;
        public int Experience;
        public int TalentSlots;
        public ScavengerStats BaseStats = new();
        public ScavengerStats Growth = new();
        public List<string> TalentIds = new();
        public bool ExplorationCompleted;
        public string CompletedMapId;
        public List<ScavengerDeckEntry> LockedDeck = new();

        public IEnumerable<TalentDefinition> Talents => TalentIds.Select(ScavengerTalentCatalog.Get);

        public ScavengerStats GetCurrentStats()
        {
            var mightGrowth = Growth.Might * (1f + Talents.Sum(talent => talent.MightGrowthPercent));
            var intellectGrowth = Growth.Intellect * (1f + Talents.Sum(talent => talent.IntellectGrowthPercent));
            var defenseGrowth = Growth.Defense * (1f + Talents.Sum(talent => talent.DefenseGrowthPercent));
            var vitalityGrowth = Growth.Vitality * (1f + Talents.Sum(talent => talent.VitalityGrowthPercent));
            return new ScavengerStats(
                (BaseStats.Might + mightGrowth * (Level - 1)) * (1f + Talents.Sum(talent => talent.MightPercent)),
                (BaseStats.Intellect + intellectGrowth * (Level - 1)) * (1f + Talents.Sum(talent => talent.IntellectPercent)),
                (BaseStats.Defense + defenseGrowth * (Level - 1)) * (1f + Talents.Sum(talent => talent.DefensePercent)),
                (BaseStats.Vitality + vitalityGrowth * (Level - 1)) * (1f + Talents.Sum(talent => talent.VitalityPercent)));
        }

        public float GetMaxHealth()
        {
            return 72f + GetCurrentStats().Vitality * 3.2f;
        }

        public float GetCardMultiplier(CardDefinition definition)
        {
            var stats = GetCurrentStats();
            var relevant = (definition.Tags & CardTag.Weapon) != 0 ? stats.Might :
                (definition.Tags & CardTag.Defense) != 0 ? stats.Defense : stats.Intellect;
            var multiplier = Mathf.Max(.75f, 1f + (relevant - 10f) * .025f);
            foreach (var talent in Talents)
                if (talent.AppliesTo(definition))
                    multiplier *= 1f + talent.EffectBonus;
            return multiplier;
        }

        public float GetCooldownMultiplier(CardDefinition definition)
        {
            var reduction = Talents.Where(talent => talent.CooldownReduction > 0f &&
                (talent.Scope == TalentScope.AllCards || talent.AppliesTo(definition)))
                .Sum(talent => talent.CooldownReduction);
            return Mathf.Clamp(1f - reduction, .70f, 1f);
        }
    }

    public static class ScavengerGenerator
    {
        private static readonly string[] Names =
        {
            "灰隼", "扳手", "零号", "赤砂", "渡鸦", "旧梦", "铁锈", "白噪", "岚", "回声"
        };

        public static ScavengerRecord[] GenerateCandidates(int seed)
        {
            var random = new System.Random(seed);
            var records = new ScavengerRecord[3];
            for (var i = 0; i < records.Length; i++)
                records[i] = Generate(random, i);
            return records;
        }

        private static ScavengerRecord Generate(System.Random random, int index)
        {
            var archetype = random.Next(4);
            var stats = archetype switch
            {
                0 => new ScavengerStats(16, 9, 11, 11),
                1 => new ScavengerStats(9, 16, 11, 11),
                2 => new ScavengerStats(10, 10, 16, 14),
                _ => new ScavengerStats(12, 12, 12, 12)
            };
            stats.Might += random.Next(-2, 3);
            stats.Intellect += random.Next(-2, 3);
            stats.Defense += random.Next(-2, 3);
            stats.Vitality += random.Next(-2, 3);

            var record = new ScavengerRecord
            {
                Id = Guid.NewGuid().ToString("N"),
                DisplayName = Names[(random.Next(Names.Length) + index) % Names.Length],
                Archetype = archetype switch { 0 => "强袭者", 1 => "工程师", 2 => "守卫者", _ => "流浪者" },
                TalentSlots = index == 0 ? random.Next(2, 4) :
                    index == 1 ? random.Next(3, 6) : random.Next(5, 7),
                BaseStats = stats,
                Growth = new ScavengerStats(
                    .45f + (float)random.NextDouble() * .95f,
                    .45f + (float)random.NextDouble() * .95f,
                    .35f + (float)random.NextDouble() * .75f,
                    2.8f + (float)random.NextDouble() * 4.7f)
            };
            while (record.TalentIds.Count < record.TalentSlots)
            {
                var rarity = RollRarity(random);
                var pool = ScavengerTalentCatalog.GetByRarity(rarity);
                var talent = pool[random.Next(pool.Count)];
                if (!record.TalentIds.Contains(talent.Id))
                    record.TalentIds.Add(talent.Id);
            }
            return record;
        }

        private static TalentRarity RollRarity(System.Random random)
        {
            var roll = random.Next(1000);
            if (roll < 20) return TalentRarity.Red;
            if (roll < 80) return TalentRarity.Gold;
            if (roll < 200) return TalentRarity.Purple;
            if (roll < 450) return TalentRarity.Blue;
            return TalentRarity.Green;
        }
    }

    public static class ExplorationRunContext
    {
        public static ScavengerRecord SelectedScavenger { get; private set; }

        public static void Select(ScavengerRecord record)
        {
            SelectedScavenger = record;
        }
    }

    public static class ScavengerRosterRepository
    {
        [Serializable]
        private sealed class SaveData
        {
            public List<ScavengerRecord> Records = new();
        }

        private const string SaveKey = "CardAutobattle.ScavengerRoster.v1";
        private static SaveData data;

        public static IReadOnlyList<ScavengerRecord> Records
        {
            get
            {
                EnsureLoaded();
                return data.Records;
            }
        }

        public static void AddOrUpdate(ScavengerRecord record)
        {
            if (record == null)
                return;
            EnsureLoaded();
            var index = data.Records.FindIndex(entry => entry.Id == record.Id);
            if (index >= 0) data.Records[index] = record;
            else data.Records.Insert(0, record);
            PlayerPrefs.SetString(SaveKey, JsonUtility.ToJson(data));
            PlayerPrefs.Save();
        }

        public static void Reload()
        {
            data = null;
            EnsureLoaded();
        }

        private static void EnsureLoaded()
        {
            if (data != null)
                return;
            var json = PlayerPrefs.GetString(SaveKey, string.Empty);
            data = string.IsNullOrEmpty(json) ? new SaveData() : JsonUtility.FromJson<SaveData>(json);
            data ??= new SaveData();
            data.Records ??= new List<ScavengerRecord>();
        }
    }
}

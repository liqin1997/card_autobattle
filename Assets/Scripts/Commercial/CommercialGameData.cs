using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    public enum CommercialCardType { Active, Passive, Summon }
    public enum CommercialCardEffect
    {
        Damage, DoubleStrike, ShieldHero, HealHero, Burn, Poison, SlowEnemy, HasteAdjacent, HasteAll,
        PassiveAdjacentPower, PassiveGlobalPower, DamageAndHaste, ShieldAndDamage,
        Drain, ChainDamage, Vulnerability, SummonGuard, SummonStriker, SummonHealer
    }

    [Flags]
    public enum CommercialCardTag
    {
        None = 0, Weapon = 1 << 0, Defense = 1 << 1, Support = 1 << 2,
        Magic = 1 << 3, Summon = 1 << 4
    }

    [Serializable]
    public sealed class CommercialCardDefinition
    {
        public string Id;
        public string DisplayName;
        public string Description;
        public CommercialCardType Type;
        public CommercialCardEffect Effect;
        public CommercialCardTag Tags;
        public float Cooldown;
        public float Power;
        public float SecondaryPower;
        public float SummonHealth;
        public float AdjacentBonus;
        public CommercialCardTag AdjacentRequiredTag;

        public CommercialCardDefinition(string id, string displayName, string description,
            CommercialCardType type, CommercialCardEffect effect, CommercialCardTag tags,
            float cooldown, float power, float secondaryPower = 0f, float summonHealth = 0f,
            float adjacentBonus = 0f, CommercialCardTag adjacentRequiredTag = CommercialCardTag.None)
        {
            Id = id;
            DisplayName = displayName;
            Description = description;
            Type = type;
            Effect = effect;
            Tags = tags;
            Cooldown = cooldown;
            Power = power;
            SecondaryPower = secondaryPower;
            SummonHealth = summonHealth;
            AdjacentBonus = adjacentBonus;
            AdjacentRequiredTag = adjacentRequiredTag;
        }
    }

    public static class CommercialCardCatalog
    {
        private static readonly List<CommercialCardDefinition> Cards = new()
        {
            new("iron_blade", "斩铁剑", "造成9点伤害；每个相邻卡牌使伤害+3。", CommercialCardType.Active,
                CommercialCardEffect.Damage, CommercialCardTag.Weapon, 3.2f, 9f, adjacentBonus: 3f),
            new("quick_dagger", "迅影匕", "连续攻击同一目标2次，总计造成4点伤害。", CommercialCardType.Active,
                CommercialCardEffect.DoubleStrike, CommercialCardTag.Weapon, 1.8f, 4f),
            new("war_hammer", "破城锤", "造成18点重击伤害。", CommercialCardType.Active,
                CommercialCardEffect.Damage, CommercialCardTag.Weapon, 5.2f, 18f),
            new("longbow", "连珠弓", "造成8点伤害；每个相邻武器额外+3。", CommercialCardType.Active,
                CommercialCardEffect.ChainDamage, CommercialCardTag.Weapon, 3.8f, 8f,
                adjacentBonus: 3f, adjacentRequiredTag: CommercialCardTag.Weapon),
            new("oak_shield", "橡木盾", "为主角获得11点护盾。", CommercialCardType.Active,
                CommercialCardEffect.ShieldHero, CommercialCardTag.Defense, 4f, 11f),
            new("plate_armor", "荆棘甲", "获得9点护盾并反击4点伤害。", CommercialCardType.Active,
                CommercialCardEffect.ShieldAndDamage, CommercialCardTag.Defense, 5.4f, 9f, 4f),
            new("healing_potion", "圣愈药", "为主角恢复12点生命。", CommercialCardType.Active,
                CommercialCardEffect.HealHero, CommercialCardTag.Support, 5.5f, 12f),
            new("fire_flask", "灼热瓶", "造成7点伤害并附加燃烧。", CommercialCardType.Active,
                CommercialCardEffect.Burn, CommercialCardTag.Magic, 4.8f, 7f, 3f),
            new("venom_vial", "蛇毒瓶", "造成2点伤害并附加中毒。", CommercialCardType.Active,
                CommercialCardEffect.Poison, CommercialCardTag.Magic, 4.6f, 2f, 4f),
            new("frost_rune", "寒霜符", "造成5点伤害并减缓敌方行动。", CommercialCardType.Active,
                CommercialCardEffect.SlowEnemy, CommercialCardTag.Magic, 5f, 5f, .18f),
            new("war_drum", "战鼓", "推进相邻卡牌1.4秒冷却。", CommercialCardType.Active,
                CommercialCardEffect.HasteAdjacent, CommercialCardTag.Support, 6.5f, 1.4f),
            new("hourglass", "时漏", "推进全部友方卡牌0.9秒冷却。", CommercialCardType.Active,
                CommercialCardEffect.HasteAll, CommercialCardTag.Support | CommercialCardTag.Magic, 7f, .9f),
            new("battle_banner", "军团旗", "常驻：相邻卡牌效果提高25%。", CommercialCardType.Passive,
                CommercialCardEffect.PassiveAdjacentPower, CommercialCardTag.Support, 0f, .25f),
            new("command_core", "指挥核心", "常驻：全部己方卡牌效果提高10%。", CommercialCardType.Passive,
                CommercialCardEffect.PassiveGlobalPower, CommercialCardTag.Support | CommercialCardTag.Magic, 0f, .10f),
            new("arc_battery", "雷能核心", "造成6点伤害，并推进相邻卡牌0.8秒。", CommercialCardType.Active,
                CommercialCardEffect.DamageAndHaste, CommercialCardTag.Magic | CommercialCardTag.Support, 4.5f, 6f, .8f),
            new("blood_fang", "血牙", "造成8点伤害并为主角恢复5点生命。", CommercialCardType.Active,
                CommercialCardEffect.Drain, CommercialCardTag.Weapon | CommercialCardTag.Magic, 4f, 8f, 5f),
            new("armor_break", "破甲印", "造成4点伤害，使目标承伤提高15%。", CommercialCardType.Active,
                CommercialCardEffect.Vulnerability, CommercialCardTag.Magic, 5.2f, 4f, .15f),
            new("stone_guard", "石像守卫", "召唤：高生命守卫，周期攻击并优先承伤。", CommercialCardType.Summon,
                CommercialCardEffect.SummonGuard, CommercialCardTag.Summon | CommercialCardTag.Defense, 3.4f, 5f, 0f, 95f),
            new("frost_wolf", "霜狼", "召唤：快速攻击敌人的近战单位。", CommercialCardType.Summon,
                CommercialCardEffect.SummonStriker, CommercialCardTag.Summon | CommercialCardTag.Weapon, 2.4f, 8f, 0f, 58f),
            new("vine_priest", "灵藤祭司", "召唤：周期治疗主角和受伤召唤物。", CommercialCardType.Summon,
                CommercialCardEffect.SummonHealer, CommercialCardTag.Summon | CommercialCardTag.Support, 3.6f, 7f, 0f, 52f)
        };

        private static readonly Dictionary<string, CommercialCardDefinition> Lookup =
            Cards.ToDictionary(card => card.Id, StringComparer.Ordinal);

        public static IReadOnlyList<CommercialCardDefinition> All => Cards;
        public static CommercialCardDefinition Get(string id) =>
            id != null && Lookup.TryGetValue(id, out var definition) ? definition : null;
    }

    public enum EquipmentSlot { Head, Hands, Armor, Legs, Shoes, MainWeapon }
    public enum EquipmentRarity { White, Blue, Purple, Gold }

    [Serializable]
    public sealed class EquipmentItem
    {
        public string Id;
        public string DisplayName;
        public EquipmentSlot Slot;
        public EquipmentRarity Rarity;
        public int ItemLevel;
        public float Attack;
        public float Defense;
        public float Health;
        public float AttackSpeed;

        public float Power => Attack * 8f + Defense * 6f + Health * .65f + AttackSpeed * 120f;
    }

    [Serializable]
    public sealed class EquippedItemEntry
    {
        public EquipmentSlot Slot;
        public EquipmentItem Item;
    }

    public static class EquipmentGenerator
    {
        private static readonly string[] SlotNames = { "头冠", "护手", "护甲", "长裤", "战靴", "主武器" };
        private static readonly string[] RarityNames = { "白", "蓝", "紫", "金" };

        public static EquipmentItem Generate(int chapter, int stage, int seed)
        {
            var globalStage = Mathf.Max(1, (chapter - 1) * 20 + stage);
            var random = new System.Random(seed);
            var roll = random.NextDouble();
            var goldChance = Mathf.Min(.02f + globalStage * .0015f, .12f);
            var purpleChance = Mathf.Min(.10f + globalStage * .002f, .28f);
            var blueChance = Mathf.Min(.36f + globalStage * .002f, .56f);
            var rarity = roll < goldChance ? EquipmentRarity.Gold :
                roll < purpleChance ? EquipmentRarity.Purple :
                roll < blueChance ? EquipmentRarity.Blue : EquipmentRarity.White;
            var slot = (EquipmentSlot)random.Next(0, 6);
            var quality = rarity switch
            {
                EquipmentRarity.Blue => 1.45f,
                EquipmentRarity.Purple => 2.05f,
                EquipmentRarity.Gold => 2.9f,
                _ => 1f
            };
            var levelScale = 1f + globalStage * .075f;
            var primary = (4.2f + (float)random.NextDouble() * 2.3f) * quality * levelScale;
            var item = new EquipmentItem
            {
                Id = $"eq_{globalStage}_{seed:X8}",
                DisplayName = $"{RarityNames[(int)rarity]}色·{SlotNames[(int)slot]}",
                Slot = slot,
                Rarity = rarity,
                ItemLevel = globalStage
            };
            if (slot == EquipmentSlot.MainWeapon || slot == EquipmentSlot.Hands)
                item.Attack = primary;
            else if (slot == EquipmentSlot.Shoes)
            {
                item.Defense = primary * .35f;
                item.AttackSpeed = .025f * quality;
            }
            else
            {
                item.Defense = primary * .62f;
                item.Health = primary * 4.4f;
            }
            return item;
        }

        public static Color RarityColor(EquipmentRarity rarity) => rarity switch
        {
            EquipmentRarity.Blue => new Color(.20f, .57f, 1f),
            EquipmentRarity.Purple => new Color(.65f, .32f, 1f),
            EquipmentRarity.Gold => new Color(1f, .72f, .18f),
            _ => new Color(.78f, .82f, .84f)
        };
    }

    [Serializable]
    public sealed class CommercialFormation
    {
        public string[] Slots = new string[9];

        public CommercialFormation Clone()
        {
            var clone = new CommercialFormation();
            Array.Copy(Slots, clone.Slots, Slots.Length);
            return clone;
        }

        public int HeroIndex => Array.IndexOf(Slots, CommercialGameState.HeroCardId);
    }

    [Serializable]
    public sealed class CommercialGameState
    {
        public const string HeroCardId = "hero";
        public int PlayerLevel = 1;
        public int Experience;
        public int Chapter = 1;
        public int Stage = 1;
        public int Gold = 500;
        public int Gems = 128;
        public int PremiumCurrency = 3690;
        public int MainQuestTargetStage = 5;
        public List<string> OwnedCardIds = new();
        public CommercialFormation DraftFormation = new();
        public List<EquipmentItem> Inventory = new();
        public List<EquippedItemEntry> Equipped = new();
        public int DropSequence;

        public int ExperienceToNextLevel => 40 + PlayerLevel * 25;
        public int GlobalStage => (Chapter - 1) * 20 + Stage;

        public static CommercialGameState CreateDefault()
        {
            var state = new CommercialGameState();
            state.OwnedCardIds.AddRange(CommercialCardCatalog.All.Select(card => card.Id));
            state.DraftFormation.Slots[0] = "stone_guard";
            state.DraftFormation.Slots[1] = "oak_shield";
            state.DraftFormation.Slots[3] = "iron_blade";
            state.DraftFormation.Slots[4] = HeroCardId;
            state.DraftFormation.Slots[5] = "frost_wolf";
            state.DraftFormation.Slots[7] = "healing_potion";
            state.DraftFormation.Slots[8] = "battle_banner";
            return state;
        }

        public EquipmentItem GetEquipped(EquipmentSlot slot) =>
            Equipped.FirstOrDefault(entry => entry.Slot == slot)?.Item;

        public void Equip(EquipmentItem item)
        {
            if (item == null || !Inventory.Contains(item)) return;
            Equipped.RemoveAll(entry => entry.Slot == item.Slot);
            Equipped.Add(new EquippedItemEntry { Slot = item.Slot, Item = item });
        }

        public void Unequip(EquipmentSlot slot) => Equipped.RemoveAll(entry => entry.Slot == slot);

        public float EquipmentAttack => Equipped.Sum(entry => entry.Item?.Attack ?? 0f);
        public float EquipmentDefense => Equipped.Sum(entry => entry.Item?.Defense ?? 0f);
        public float EquipmentHealth => Equipped.Sum(entry => entry.Item?.Health ?? 0f);
        public float EquipmentAttackSpeed => Equipped.Sum(entry => entry.Item?.AttackSpeed ?? 0f);
        public float CombatPower => 100f + PlayerLevel * 32f + Equipped.Sum(entry => entry.Item?.Power ?? 0f);

        public void GainExperience(int amount)
        {
            Experience += Mathf.Max(0, amount);
            while (Experience >= ExperienceToNextLevel)
            {
                Experience -= ExperienceToNextLevel;
                PlayerLevel++;
            }
        }

        public EquipmentItem ApplyStageVictory(int seed)
        {
            Gold += 18 + GlobalStage * 3;
            GainExperience(15 + GlobalStage * 2);
            EquipmentItem drop = null;
            var guaranteed = Stage % 5 == 0;
            var random = new System.Random(seed ^ (DropSequence++ * 486187739));
            if (guaranteed || random.NextDouble() < .58)
            {
                drop = EquipmentGenerator.Generate(Chapter, Stage, seed ^ DropSequence);
                Inventory.Add(drop);
            }
            Stage++;
            if (Stage > 20)
            {
                Stage = 1;
                Chapter = Mathf.Min(5, Chapter + 1);
            }
            if (GlobalStage >= MainQuestTargetStage)
                MainQuestTargetStage = Mathf.Min(100, MainQuestTargetStage + 5);
            return drop;
        }
    }

    public static class CommercialSaveService
    {
        private const string Key = "CardAutobattle.CommercialSave.v1";
        public static CommercialGameState Load()
        {
            var json = PlayerPrefs.GetString(Key, string.Empty);
            if (string.IsNullOrEmpty(json)) return CommercialGameState.CreateDefault();
            try
            {
                var state = JsonUtility.FromJson<CommercialGameState>(json);
                return state?.DraftFormation?.Slots?.Length == 9 ? state : CommercialGameState.CreateDefault();
            }
            catch { return CommercialGameState.CreateDefault(); }
        }

        public static void Save(CommercialGameState state)
        {
            if (state == null) return;
            PlayerPrefs.SetString(Key, JsonUtility.ToJson(state));
            PlayerPrefs.Save();
        }

        public static void Reset() => PlayerPrefs.DeleteKey(Key);
    }
}

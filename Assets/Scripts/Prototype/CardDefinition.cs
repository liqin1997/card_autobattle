using System;
using System.Collections.Generic;

namespace CardAutobattle.Prototype
{
    [Flags]
    public enum CardTag
    {
        None = 0,
        Weapon = 1 << 0,
        Defense = 1 << 1,
        Support = 1 << 2,
        Magic = 1 << 3,
        Economy = 1 << 4
    }

    public enum CardEffectKind
    {
        Damage,
        Shield,
        Heal,
        DamageAndBurn,
        DamageAndPoison,
        DamageAndSlow,
        HasteNeighbours,
        HasteAll,
        PassivePowerAura,
        DamageAndHaste,
        ShieldAndDamage,
        Drain,
        ChainDamage,
        ShieldAndVictoryGold,
        ShieldAndHeal
    }

    public enum AdjacentScalingKind
    {
        None,
        AddPerAdjacent,
        MultiplyByAdjacentCount
    }

    [Serializable]
    public sealed class CardDefinition
    {
        public string Id;
        public string DisplayName;
        public string Description;
        public int Cost;
        public float Cooldown;
        public float Power;
        public float SecondaryPower;
        public CardTag Tags;
        public CardEffectKind Effect;
        public AdjacentScalingKind AdjacentScaling;
        public float AdjacentPowerBonus;
        public CardTag AdjacentRequiredTag;

        public CardDefinition(string id, string name, string description, int cost, float cooldown,
            float power, float secondaryPower, CardTag tags, CardEffectKind effect,
            AdjacentScalingKind adjacentScaling = AdjacentScalingKind.None,
            float adjacentPowerBonus = 0f,
            CardTag adjacentRequiredTag = CardTag.None)
        {
            Id = id;
            DisplayName = name;
            Description = description;
            Cost = cost;
            Cooldown = cooldown;
            Power = power;
            SecondaryPower = secondaryPower;
            Tags = tags;
            Effect = effect;
            AdjacentScaling = adjacentScaling;
            AdjacentPowerBonus = adjacentPowerBonus;
            AdjacentRequiredTag = adjacentRequiredTag;
        }
    }

    public static class PrototypeCardCatalog
    {
        private static readonly List<CardDefinition> Cards = new()
        {
            new("blade", "Iron Blade", "Deal 9 damage, +3 per adjacent card.", 4, 3.2f, 9, 0,
                CardTag.Weapon, CardEffectKind.Damage, AdjacentScalingKind.AddPerAdjacent, 3),
            new("dagger", "Quick Dagger", "Deal 4 damage. Triggers quickly.", 3, 1.8f, 4, 0, CardTag.Weapon, CardEffectKind.Damage),
            new("hammer", "War Hammer", "Deal 18 damage.", 6, 5.2f, 18, 0, CardTag.Weapon, CardEffectKind.Damage),
            new("bow", "Longbow", "Deal 8 damage, +3 per adjacent Weapon.", 5, 3.8f, 8, 3,
                CardTag.Weapon, CardEffectKind.ChainDamage, AdjacentScalingKind.AddPerAdjacent, 3, CardTag.Weapon),
            new("shield", "Oak Shield", "Gain 11 shield.", 4, 4.0f, 11, 0, CardTag.Defense, CardEffectKind.Shield),
            new("armor", "Plate Armor", "Gain 18 shield.", 6, 6.0f, 18, 0, CardTag.Defense, CardEffectKind.Shield),
            new("potion", "Red Potion", "Heal 12 health.", 4, 5.5f, 12, 0, CardTag.Support, CardEffectKind.Heal),
            new("herbs", "Healing Herbs", "Heal 7, +2 per adjacent Support.", 3, 4.2f, 7, 2,
                CardTag.Support, CardEffectKind.Heal, AdjacentScalingKind.AddPerAdjacent, 2, CardTag.Support),
            new("fire", "Fire Flask", "Deal 7 damage and apply 3 Burn.", 5, 4.8f, 7, 3, CardTag.Magic, CardEffectKind.DamageAndBurn),
            new("poison", "Venom Vial", "Deal 2 damage and apply 4 Poison.", 5, 4.6f, 2, 4, CardTag.Magic, CardEffectKind.DamageAndPoison),
            new("frost", "Frost Rune", "Deal 5 damage and slow enemy cooldowns.", 5, 5.0f, 5, 1, CardTag.Magic, CardEffectKind.DamageAndSlow),
            new("drum", "War Drum", "Advance adjacent cards' cooldowns.", 6, 6.5f, 1.4f, 0, CardTag.Support, CardEffectKind.HasteNeighbours),
            new("hourglass", "Hourglass", "Advance every allied cooldown.", 7, 7.0f, 0.9f, 0, CardTag.Support | CardTag.Magic, CardEffectKind.HasteAll),
            new("banner", "Battle Banner", "Adjacent cards gain 25% power.", 6, 0, .25f, 0, CardTag.Support, CardEffectKind.PassivePowerAura),
            new("battery", "Arc Battery", "Deal 6 damage and advance an ally.", 5, 4.5f, 6, .8f, CardTag.Magic | CardTag.Support, CardEffectKind.DamageAndHaste),
            new("thorns", "Thorn Mail", "Gain 9 shield and deal 4 damage.", 5, 5.4f, 9, 4, CardTag.Defense, CardEffectKind.ShieldAndDamage),
            new("vampire", "Blood Fang", "Deal 8 damage and heal 5.", 6, 4.0f, 8, 5, CardTag.Weapon | CardTag.Magic, CardEffectKind.Drain),
            new("spark", "Chain Spark", "Deal 7 damage for each adjacent ally.", 7, 5.0f, 7, 0,
                CardTag.Magic, CardEffectKind.ChainDamage, AdjacentScalingKind.MultiplyByAdjacentCount),
            new("coin", "Lucky Coin", "Gain 3 shield. Earn +1 gold on victory.", 3, 6.0f, 3, 1, CardTag.Economy | CardTag.Support, CardEffectKind.ShieldAndVictoryGold),
            new("core", "Guardian Core", "Gain 14 shield and heal 8.", 8, 7.5f, 14, 8, CardTag.Defense | CardTag.Support, CardEffectKind.ShieldAndHeal)
        };

        private static readonly Dictionary<string, CardDefinition> ById = BuildLookup();

        public static IReadOnlyList<CardDefinition> All => Cards;

        public static CardDefinition Get(string id)
        {
            return id != null && ById.TryGetValue(id, out var card) ? card : Cards[0];
        }

        public static CardDefinition GetShopOffer(int round, int offerIndex)
        {
            var earlyPool = Math.Min(Cards.Count, 10 + Math.Max(0, round - 1) * 2);
            var index = Math.Abs(round * 7 + offerIndex * 5 + offerIndex * offerIndex) % earlyPool;
            return Cards[index];
        }

        public static float QualityMultiplier(int level)
        {
            return level <= 1 ? 1f : level == 2 ? 1.65f : 2.5f;
        }

        public static string QualityName(int level)
        {
            return level <= 1 ? "Bronze" : level == 2 ? "Silver" : "Gold";
        }

        private static Dictionary<string, CardDefinition> BuildLookup()
        {
            var lookup = new Dictionary<string, CardDefinition>(StringComparer.Ordinal);
            foreach (var card in Cards)
                lookup[card.Id] = card;
            return lookup;
        }
    }
}

using CardAutobattle.Prototype;

namespace CardAutobattle.Preparation
{
    public enum SlotModifierType
    {
        None = 0,
        FireDamage = 1,
        DirectDamage = 2,
        Healing = 3,
        Shield = 4,
        PoisonDamage = 5,
        CooldownReduction = 6
    }

    public static class SlotModifierRules
    {
        public const float PowerBonus = .10f;
        public const float CooldownReduction = .10f;

        public static float ModifyValue(SlotModifierType modifier, SlotModifierType requestedStat, float value)
        {
            return modifier == requestedStat ? value * (1f + PowerBonus) : value;
        }

        public static float ModifyCooldown(SlotModifierType modifier, float cooldown)
        {
            return modifier == SlotModifierType.CooldownReduction
                ? cooldown * (1f - CooldownReduction)
                : cooldown;
        }

        public static string DisplayName(SlotModifierType modifier)
        {
            return modifier switch
            {
                SlotModifierType.FireDamage => "炽焰格",
                SlotModifierType.DirectDamage => "强攻格",
                SlotModifierType.Healing => "复苏格",
                SlotModifierType.Shield => "壁垒格",
                SlotModifierType.PoisonDamage => "剧毒格",
                SlotModifierType.CooldownReduction => "加速格",
                _ => "普通格"
            };
        }

        public static string Description(SlotModifierType modifier)
        {
            return modifier switch
            {
                SlotModifierType.FireDamage => "该格卡牌造成的灼烧伤害提高10%",
                SlotModifierType.DirectDamage => "该格卡牌造成的直接伤害提高10%",
                SlotModifierType.Healing => "该格卡牌造成的治疗量提高10%",
                SlotModifierType.Shield => "该格卡牌提供的护盾量提高10%",
                SlotModifierType.PoisonDamage => "该格卡牌造成的中毒伤害提高10%",
                SlotModifierType.CooldownReduction => "该格卡牌的基础CD缩短10%",
                _ => "没有额外强化"
            };
        }

        public static string Glyph(SlotModifierType modifier)
        {
            return modifier switch
            {
                SlotModifierType.FireDamage => "火",
                SlotModifierType.DirectDamage => "攻",
                SlotModifierType.Healing => "愈",
                SlotModifierType.Shield => "盾",
                SlotModifierType.PoisonDamage => "毒",
                SlotModifierType.CooldownReduction => "速",
                _ => string.Empty
            };
        }

        public static bool SupportsCard(SlotModifierType modifier, CardDefinition card)
        {
            if (modifier == SlotModifierType.None || card == null)
                return true;

            return modifier switch
            {
                SlotModifierType.FireDamage => card.Effect == CardEffectKind.DamageAndBurn,
                SlotModifierType.PoisonDamage => card.Effect == CardEffectKind.DamageAndPoison,
                SlotModifierType.DirectDamage => card.Effect is CardEffectKind.Damage or
                    CardEffectKind.DamageAndBurn or CardEffectKind.DamageAndPoison or
                    CardEffectKind.DamageAndSlow or CardEffectKind.DamageAndHaste or
                    CardEffectKind.ShieldAndDamage or CardEffectKind.Drain or CardEffectKind.ChainDamage,
                SlotModifierType.Healing => card.Effect is CardEffectKind.Heal or
                    CardEffectKind.Drain or CardEffectKind.ShieldAndHeal,
                SlotModifierType.Shield => card.Effect is CardEffectKind.Shield or
                    CardEffectKind.ShieldAndDamage or CardEffectKind.ShieldAndVictoryGold or
                    CardEffectKind.ShieldAndHeal,
                SlotModifierType.CooldownReduction => card.Effect != CardEffectKind.PassivePowerAura,
                _ => false
            };
        }
    }
}

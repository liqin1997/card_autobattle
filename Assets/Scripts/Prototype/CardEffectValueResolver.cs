using CardAutobattle.Preparation;

namespace CardAutobattle.Prototype
{
    public enum CardValueKind
    {
        None,
        Damage,
        Shield,
        Burn,
        Healing,
        Poison,
        Haste,
        Slow,
        Gold
    }

    public readonly struct CardValueEntry
    {
        public CardValueEntry(CardValueKind kind, float value)
        {
            Kind = kind;
            Value = value;
        }

        public CardValueKind Kind { get; }
        public float Value { get; }
        public bool Visible => Kind != CardValueKind.None && Value > 0f;
    }

    public readonly struct ResolvedCardValues
    {
        public ResolvedCardValues(CardValueEntry primary, CardValueEntry secondary)
        {
            Primary = primary;
            Secondary = secondary;
        }

        public CardValueEntry Primary { get; }
        public CardValueEntry Secondary { get; }
        public int VisibleCount => (Primary.Visible ? 1 : 0) + (Secondary.Visible ? 1 : 0);
    }

    public static class CardEffectValueResolver
    {
        public static bool AreAdjacent(int a, int b)
        {
            return System.Math.Abs(a / 3 - b / 3) + System.Math.Abs(a % 3 - b % 3) == 1;
        }

        public static void ResolveScaledPowers(CardDefinition definition, int level, int adjacentCount,
            float externalMultiplier, out float primary, out float secondary)
        {
            var scale = PrototypeCardCatalog.QualityMultiplier(level) * externalMultiplier;
            primary = definition.Power * scale;
            secondary = definition.SecondaryPower * scale;

            switch (definition.AdjacentScaling)
            {
                case AdjacentScalingKind.AddPerAdjacent:
                    primary += adjacentCount * definition.AdjacentPowerBonus * scale;
                    break;
                case AdjacentScalingKind.MultiplyByAdjacentCount:
                    primary *= System.Math.Max(1, adjacentCount);
                    break;
            }
        }

        public static ResolvedCardValues ResolveDisplay(CardDefinition definition, int level, int adjacentCount,
            float externalMultiplier = 1f, SlotModifierType modifier = SlotModifierType.None)
        {
            ResolveScaledPowers(definition, level, adjacentCount, externalMultiplier,
                out var primary, out var secondary);
            var values = MapEffect(definition.Effect, primary, secondary);
            return new ResolvedCardValues(
                ApplySlotModifier(values.Primary, modifier),
                ApplySlotModifier(values.Secondary, modifier));
        }

        private static ResolvedCardValues MapEffect(CardEffectKind effect, float primary, float secondary)
        {
            return effect switch
            {
                CardEffectKind.Damage => One(CardValueKind.Damage, primary),
                CardEffectKind.Shield => One(CardValueKind.Shield, primary),
                CardEffectKind.Heal => One(CardValueKind.Healing, primary),
                CardEffectKind.DamageAndBurn => Two(CardValueKind.Damage, primary, CardValueKind.Burn, secondary),
                CardEffectKind.DamageAndPoison => Two(CardValueKind.Damage, primary, CardValueKind.Poison, secondary),
                CardEffectKind.DamageAndSlow => Two(CardValueKind.Damage, primary, CardValueKind.Slow, secondary),
                CardEffectKind.HasteNeighbours => One(CardValueKind.Haste, primary),
                CardEffectKind.HasteAll => One(CardValueKind.Haste, primary),
                CardEffectKind.PassivePowerAura => default,
                CardEffectKind.DamageAndHaste => Two(CardValueKind.Damage, primary, CardValueKind.Haste, secondary),
                CardEffectKind.ShieldAndDamage => Two(CardValueKind.Shield, primary, CardValueKind.Damage, secondary),
                CardEffectKind.Drain => Two(CardValueKind.Damage, primary, CardValueKind.Healing, secondary),
                CardEffectKind.ChainDamage => One(CardValueKind.Damage, primary),
                CardEffectKind.ShieldAndVictoryGold => Two(CardValueKind.Shield, primary, CardValueKind.Gold, secondary),
                CardEffectKind.ShieldAndHeal => Two(CardValueKind.Shield, primary, CardValueKind.Healing, secondary),
                _ => default
            };
        }

        private static ResolvedCardValues One(CardValueKind kind, float value)
        {
            return new ResolvedCardValues(new CardValueEntry(kind, value), default);
        }

        private static ResolvedCardValues Two(CardValueKind firstKind, float firstValue,
            CardValueKind secondKind, float secondValue)
        {
            return new ResolvedCardValues(
                new CardValueEntry(firstKind, firstValue),
                new CardValueEntry(secondKind, secondValue));
        }

        private static CardValueEntry ApplySlotModifier(CardValueEntry entry, SlotModifierType modifier)
        {
            if (!entry.Visible)
                return entry;

            var stat = entry.Kind switch
            {
                CardValueKind.Damage => SlotModifierType.DirectDamage,
                CardValueKind.Shield => SlotModifierType.Shield,
                CardValueKind.Burn => SlotModifierType.FireDamage,
                CardValueKind.Healing => SlotModifierType.Healing,
                CardValueKind.Poison => SlotModifierType.PoisonDamage,
                _ => SlotModifierType.None
            };
            return stat == SlotModifierType.None
                ? entry
                : new CardValueEntry(entry.Kind, SlotModifierRules.ModifyValue(modifier, stat, entry.Value));
        }
    }
}

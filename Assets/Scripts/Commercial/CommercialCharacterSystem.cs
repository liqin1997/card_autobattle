using System;
using System.Collections.Generic;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    public enum CommercialProfessionId { Warrior, Ranger, Mage }
    public enum CommercialAttributeType { Strength, Dexterity, Intelligence, Vitality }

    [Serializable]
    public sealed class CommercialCharacterProgress
    {
        public CommercialProfessionId Profession = CommercialProfessionId.Warrior;
        public int StrengthPoints;
        public int DexterityPoints;
        public int IntelligencePoints;
        public int VitalityPoints;
        public int AdvancementTier = 1;

        public int AllocatedPoints => StrengthPoints + DexterityPoints + IntelligencePoints + VitalityPoints;
        public int PointsFor(CommercialAttributeType type) => type switch
        {
            CommercialAttributeType.Strength => StrengthPoints,
            CommercialAttributeType.Dexterity => DexterityPoints,
            CommercialAttributeType.Intelligence => IntelligencePoints,
            _ => VitalityPoints
        };

        public void AddPoint(CommercialAttributeType type)
        {
            switch (type)
            {
                case CommercialAttributeType.Strength: StrengthPoints++; break;
                case CommercialAttributeType.Dexterity: DexterityPoints++; break;
                case CommercialAttributeType.Intelligence: IntelligencePoints++; break;
                case CommercialAttributeType.Vitality: VitalityPoints++; break;
            }
        }
    }

    public sealed class CommercialProfessionDefinition
    {
        public CommercialProfessionId Id;
        public string DisplayName;
        public string PathName;
        public string ResourceName;
        public string ShortDescription;
        public string TriggerDescription;
        public string ReadyDescription;
        public float StrengthToAp;
        public float DexterityToAp;
        public float IntelligenceToAp;
        public float VitalityToAp;
        public int MaxResource;
        public Color Accent;
    }

    public static class CommercialProfessionCatalog
    {
        private static readonly CommercialProfessionDefinition[] Definitions =
        {
            new()
            {
                Id = CommercialProfessionId.Warrior, DisplayName = "战士", PathName = "铁誓",
                ResourceName = "怒气", ShortDescription = "普通攻击积累怒气，满层强化下一击",
                TriggerDescription = "主角普通攻击命中获得 2 怒气",
                ReadyDescription = "满层：下一次普通攻击伤害 ×1.6",
                StrengthToAp = 1f, DexterityToAp = .3f, IntelligenceToAp = .2f, VitalityToAp = .1f,
                MaxResource = 10, Accent = new Color(.76f, .28f, .20f, 1f)
            },
            new()
            {
                Id = CommercialProfessionId.Ranger, DisplayName = "游侠", PathName = "逐风",
                ResourceName = "精准", ShortDescription = "投射物积累精准，满层追加一次追击",
                TriggerDescription = "Projectile 卡牌触发获得 1 精准",
                ReadyDescription = "满层：下一张投射物卡追加 45% 追击",
                StrengthToAp = .3f, DexterityToAp = 1f, IntelligenceToAp = .3f, VitalityToAp = .1f,
                MaxResource = 6, Accent = new Color(.28f, .82f, .58f, 1f)
            },
            new()
            {
                Id = CommercialProfessionId.Mage, DisplayName = "法师", PathName = "秘仪",
                ResourceName = "元素共鸣", ShortDescription = "魔法卡积累共鸣，满层过载当前魔法",
                TriggerDescription = "Magic / Lightning 卡牌触发获得 1 共鸣",
                ReadyDescription = "满层：下一张魔法卡效果 ×1.5",
                StrengthToAp = .2f, DexterityToAp = .3f, IntelligenceToAp = 1f, VitalityToAp = .1f,
                MaxResource = 5, Accent = new Color(.32f, .60f, 1f, 1f)
            }
        };

        public static IReadOnlyList<CommercialProfessionDefinition> All => Definitions;
        public static CommercialProfessionDefinition Get(CommercialProfessionId id) => Definitions[(int)id];
    }

    public readonly struct CommercialCharacterSnapshot
    {
        public readonly CommercialProfessionId Profession;
        public readonly int Strength;
        public readonly int Dexterity;
        public readonly int Intelligence;
        public readonly int Vitality;
        public readonly float AbilityPower;
        public readonly float MaxHealth;
        public readonly float Armor;
        public readonly float CritChance;
        public readonly float CritDamage;
        public readonly float HeroAttackInterval;
        public readonly EquipmentStatBlock Equipment;

        public CommercialCharacterSnapshot(CommercialProfessionId profession, int strength, int dexterity,
            int intelligence, int vitality, float abilityPower, float maxHealth, float armor,
            float critChance, float critDamage, float heroAttackInterval, EquipmentStatBlock equipment = null)
        {
            Profession = profession;
            Strength = strength;
            Dexterity = dexterity;
            Intelligence = intelligence;
            Vitality = vitality;
            AbilityPower = abilityPower;
            MaxHealth = maxHealth;
            Armor = armor;
            CritChance = critChance;
            CritDamage = critDamage;
            HeroAttackInterval = heroAttackInterval;
            Equipment = equipment ?? new EquipmentStatBlock();
        }
    }

    public static class CommercialCharacterCalculator
    {
        public const float PowerConstant = 180f;

        public static CommercialCharacterSnapshot BuildSnapshot(CommercialGameState state,
            CommercialProfessionId? professionOverride = null, EquipmentStatBlock equipmentOverride = null)
        {
            state.EnsureCharacterData();
            var character = state.Character;
            var profession = professionOverride ?? character.Profession;
            var definition = CommercialProfessionCatalog.Get(profession);
            var gear = equipmentOverride ?? CommercialEquipmentService.Aggregate(state);
            var baseAttribute = 10 + Mathf.Max(0, state.PlayerLevel - 1);
            var strength = baseAttribute + character.StrengthPoints + Mathf.RoundToInt(gear[EquipmentStat.Strength]);
            var dexterity = baseAttribute + character.DexterityPoints + Mathf.RoundToInt(gear[EquipmentStat.Dexterity]);
            var intelligence = baseAttribute + character.IntelligencePoints + Mathf.RoundToInt(gear[EquipmentStat.Intelligence]);
            var vitality = baseAttribute + character.VitalityPoints + Mathf.RoundToInt(gear[EquipmentStat.Vitality]);
            var ap = strength * definition.StrengthToAp + dexterity * definition.DexterityToAp +
                     intelligence * definition.IntelligenceToAp + vitality * definition.VitalityToAp +
                     gear[EquipmentStat.AbilityPower];
            var maxHealth = (95f + vitality * 4.5f + gear[EquipmentStat.Health]) * (1 + gear[EquipmentStat.HealthPercent]);
            var armor = (gear[EquipmentStat.Armor] + vitality * .32f) * (1 + gear[EquipmentStat.ArmorPercent]);
            var crit = Mathf.Clamp(.05f + dexterity * .0022f +
                                   (profession == CommercialProfessionId.Ranger ? .04f : 0f) + gear[EquipmentStat.CritChance], .05f, .75f);
            var interval = Mathf.Max(1.1f, 3f / (1f + gear[EquipmentStat.HeroAttackSpeed]));
            return new CommercialCharacterSnapshot(profession, strength, dexterity, intelligence, vitality,
                ap, maxHealth, armor, crit, 1.5f + gear[EquipmentStat.CritDamage], interval, gear);
        }

        public static float CharacterScaling(float abilityPower, float coefficient) =>
            1f + Mathf.Max(0f, abilityPower) / PowerConstant * Mathf.Max(0f, coefficient);

        public static float HeroBasicAttack(CommercialCharacterSnapshot snapshot) =>
            10f * CharacterScaling(snapshot.AbilityPower, 1f) *
            (snapshot.Equipment?.DamageMultiplier(CommercialCardTag.BasicAttack, basic: true) ?? 1f);

        public static float CombatPower(CommercialGameState state,
            CommercialProfessionId? professionOverride = null)
        {
            var stats = BuildSnapshot(state, professionOverride);
            return PowerScore(stats, state.PlayerLevel);
        }

        public static float PowerScore(CommercialCharacterSnapshot stats, int level)
        {
            var bonus = 0f;
            for (var i = (int)EquipmentStat.DamageBonus; i <= (int)EquipmentStat.StartingShield; i++)
                bonus += stats.Equipment[(EquipmentStat)i];
            return stats.MaxHealth * .55f + stats.AbilityPower * 6.5f + stats.Armor * 5f +
                   stats.CritChance * 260f + level * 18f + bonus * 180 +
                   (stats.CritDamage - 1.5f) * 100 + (3f / stats.HeroAttackInterval - 1) * 120;
        }
    }

    public readonly struct CommercialResolvedCardValues
    {
        public readonly float Primary;
        public readonly float Secondary;
        public readonly float BuildBonus;

        public CommercialResolvedCardValues(float primary, float secondary, float buildBonus)
        { Primary = primary; Secondary = secondary; BuildBonus = buildBonus; }
    }

    public static class CommercialCardValueCalculator
    {
        public static CommercialResolvedCardValues Resolve(CommercialCardDefinition definition,
            CommercialCharacterSnapshot character, float buildBonus)
        {
            if (definition == null) return default;
            var primary = definition.Power * CommercialCharacterCalculator.CharacterScaling(
                character.AbilityPower, definition.ScalingCoefficient);
            var secondary = definition.SecondaryPower * CommercialCharacterCalculator.CharacterScaling(
                character.AbilityPower, definition.SecondaryScalingCoefficient);
            if (definition.ScalesWithBuild)
            {
                var buildMultiplier = 1f + Mathf.Max(-.8f, buildBonus);
                primary *= buildMultiplier;
                secondary *= buildMultiplier;
            }
            var gear = character.Equipment;
            if (gear != null)
            {
                var damage = gear.DamageMultiplier(definition.Tags, definition.Type == CommercialCardType.Summon);
                var heal = 1 + gear[EquipmentStat.HealingBonus];
                var shield = 1 + gear[EquipmentStat.ShieldBonus];
                switch (definition.Effect)
                {
                    case CommercialCardEffect.HealHero:
                    case CommercialCardEffect.SummonHealer: primary *= heal; break;
                    case CommercialCardEffect.ShieldHero: primary *= shield; break;
                    case CommercialCardEffect.ShieldAndDamage: primary *= shield; secondary *= damage; break;
                    case CommercialCardEffect.Drain: primary *= damage; secondary *= heal; break;
                    case CommercialCardEffect.Burn:
                    case CommercialCardEffect.Poison: primary *= damage; secondary *= damage; break;
                    case CommercialCardEffect.HasteAdjacent:
                    case CommercialCardEffect.HasteAll:
                    case CommercialCardEffect.PassiveAdjacentPower:
                    case CommercialCardEffect.PassiveGlobalPower: break;
                    default: primary *= damage; break; // Secondary cooldown/debuff durations are not damage.
                }
            }
            return new CommercialResolvedCardValues(primary, secondary, buildBonus);
        }
    }

    public enum CommercialDomainEventType
    {
        HeroBasicAttackStarted, HeroBasicAttackHit, HeroBasicAttackCrit, HeroBasicAttackEnded,
        CardTriggered, CriticalHit, UnitDefeated
    }

    public readonly struct CommercialDomainEvent
    {
        public readonly CommercialDomainEventType Type;
        public readonly string SourceId;
        public readonly CommercialCardTag Tags;
        public readonly int TriggerId;
        public readonly float Amount;

        public CommercialDomainEvent(CommercialDomainEventType type, string sourceId,
            CommercialCardTag tags, int triggerId, float amount = 0f)
        { Type = type; SourceId = sourceId; Tags = tags; TriggerId = triggerId; Amount = amount; }
    }

    public sealed class CommercialDomainEventStream
    {
        public event Action<CommercialDomainEvent> Raised;
        public void Publish(CommercialDomainEvent value) => Raised?.Invoke(value);
    }

    public readonly struct CommercialProfessionProc
    {
        public readonly float Multiplier;
        public readonly float FollowupRatio;
        public readonly bool ConsumedReady;

        public CommercialProfessionProc(float multiplier, float followupRatio, bool consumedReady)
        { Multiplier = multiplier; FollowupRatio = followupRatio; ConsumedReady = consumedReady; }

        public static CommercialProfessionProc Normal => new(1f, 0f, false);
    }

    public sealed class CommercialProfessionRuntime
    {
        private readonly CommercialProfessionDefinition definition;
        private readonly CommercialCombatant hero;
        private int resource;

        public CommercialProfessionId Id => definition.Id;
        public int Resource => resource;
        public int MaxResource => definition.MaxResource;

        public CommercialProfessionRuntime(CommercialProfessionId profession, CommercialCombatant hero,
            CommercialDomainEventStream events)
        {
            definition = CommercialProfessionCatalog.Get(profession);
            this.hero = hero;
            events.Raised += OnDomainEvent;
            SyncHero();
        }

        public CommercialProfessionProc BeginHeroBasicAttack()
        {
            if (Id != CommercialProfessionId.Warrior || resource < MaxResource)
                return CommercialProfessionProc.Normal;
            resource = 0;
            SyncHero();
            return new CommercialProfessionProc(1.6f, 0f, true);
        }

        public CommercialProfessionProc BeginCardTrigger(CommercialCardDefinition card)
        {
            if (card == null) return CommercialProfessionProc.Normal;
            if (Id == CommercialProfessionId.Ranger &&
                (card.Tags & CommercialCardTag.Projectile) != 0 && resource >= MaxResource)
            {
                resource = 0;
                SyncHero();
                return new CommercialProfessionProc(1f, .45f, true);
            }
            if (Id == CommercialProfessionId.Mage &&
                (card.Tags & (CommercialCardTag.Magic | CommercialCardTag.Lightning)) != 0 &&
                resource >= MaxResource)
            {
                resource = 0;
                SyncHero();
                return new CommercialProfessionProc(1.5f, 0f, true);
            }
            return CommercialProfessionProc.Normal;
        }

        private void OnDomainEvent(CommercialDomainEvent value)
        {
            switch (Id)
            {
                case CommercialProfessionId.Warrior
                    when value.Type == CommercialDomainEventType.HeroBasicAttackHit:
                    Gain(2);
                    break;
                case CommercialProfessionId.Ranger
                    when value.Type == CommercialDomainEventType.CardTriggered &&
                         (value.Tags & CommercialCardTag.Projectile) != 0:
                    Gain(1);
                    break;
                case CommercialProfessionId.Mage
                    when value.Type == CommercialDomainEventType.CardTriggered &&
                         (value.Tags & (CommercialCardTag.Magic | CommercialCardTag.Lightning)) != 0:
                    Gain(1);
                    break;
            }
        }

        private void Gain(int amount)
        {
            resource = Mathf.Clamp(resource + Mathf.Max(0, amount), 0, MaxResource);
            SyncHero();
        }

        private void SyncHero()
        {
            if (hero == null) return;
            hero.Profession = definition.Id;
            hero.ProfessionResourceName = definition.ResourceName;
            hero.ProfessionResource = resource;
            hero.ProfessionResourceMax = MaxResource;
            hero.ProfessionReady = resource >= MaxResource;
        }
    }
}

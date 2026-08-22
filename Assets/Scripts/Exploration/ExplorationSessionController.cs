using System;
using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Prototype;
using UnityEngine;

namespace CardAutobattle.Exploration
{
    [DisallowMultipleComponent]
    public sealed class ExplorationSessionController : MonoBehaviour
    {
        [Header("Difficulty 1 Runtime")]
        [SerializeField, Min(1)] private int difficulty = 1;
        [SerializeField, Min(1f)] private float baseMaxHealth = 118f;
        [SerializeField, Range(0f, 1f)] private float victoryRepairRatio = .12f;

        private ExplorationMapDefinition map;
        private ExplorationEventDirector eventDirector;
        private int encounterIndex;
        private int coins;
        private float currentHealth;
        private float maxHealth;
        private int scavengerLevel;
        private int scavengerExperience;
        private ExplorationProtocolKind protocol;
        private ExpeditionEquipment equipment;
        private ScavengerRecord scavenger;
        private float bonusMaxHealth;
        private bool completed;
        private bool initialized;

        public ExplorationMapDefinition Map => map;
        public ExplorationEncounterDefinition CurrentEncounter =>
            map != null && encounterIndex >= 0 && encounterIndex < map.Encounters.Count
                ? map.Encounters[encounterIndex]
                : null;
        public int EncounterIndex => encounterIndex;
        public int EncounterNumber => Mathf.Min(encounterIndex + 1, EncounterCount);
        public int EncounterCount => map?.Encounters.Count ?? 0;
        public int Coins => coins;
        public float CurrentHealth => currentHealth;
        public float MaxHealth => maxHealth;
        public int ScavengerLevel => scavengerLevel;
        public int ScavengerExperience => scavengerExperience;
        public int ExperienceToNextLevel => 30 + scavengerLevel * 20;
        public ExplorationProtocolKind Protocol => protocol;
        public ExpeditionEquipment Equipment => equipment;
        public ScavengerRecord Scavenger => scavenger;
        public bool IsCompleted => completed;
        public bool IsInitialized => initialized;

        public void BeginNewRun(int startingCoins, int randomSeed = 0)
        {
            map = ExplorationMapCatalog.Get(difficulty);
            scavenger = ExplorationRunContext.SelectedScavenger ??
                ScavengerGenerator.GenerateCandidates(randomSeed == 0 ? Environment.TickCount : randomSeed)[0];
            encounterIndex = 0;
            coins = Mathf.Max(0, startingCoins);
            bonusMaxHealth = 0f;
            maxHealth = scavenger != null ? scavenger.GetMaxHealth() : baseMaxHealth;
            currentHealth = maxHealth;
            scavengerLevel = scavenger?.Level ?? 1;
            scavengerExperience = scavenger?.Experience ?? 0;
            protocol = ExplorationProtocolKind.None;
            equipment = ExpeditionEquipment.None;
            completed = false;
            initialized = true;
            eventDirector = new ExplorationEventDirector(randomSeed == 0 ? Environment.TickCount : randomSeed);
        }

        public bool TrySpendCoins(int amount)
        {
            amount = Mathf.Max(0, amount);
            if (coins < amount)
                return false;
            coins -= amount;
            return true;
        }

        public void AddCoins(int amount)
        {
            coins = Mathf.Max(0, coins + amount);
        }

        public void Heal(float amount)
        {
            currentHealth = Mathf.Clamp(currentHealth + Mathf.Max(0f, amount), 1f, maxHealth);
        }

        public void IncreaseMaxHealth(float amount)
        {
            amount = Mathf.Max(0f, amount);
            maxHealth += amount;
            currentHealth += amount;
        }

        public void GainExperience(int amount)
        {
            scavengerExperience += Mathf.Max(0, amount);
            while (scavengerExperience >= ExperienceToNextLevel)
            {
                scavengerExperience -= ExperienceToNextLevel;
                var previousMaxHealth = maxHealth;
                scavengerLevel++;
                if (scavenger != null)
                {
                    scavenger.Level = scavengerLevel;
                    scavenger.Experience = scavengerExperience;
                    maxHealth = scavenger.GetMaxHealth() + bonusMaxHealth;
                    currentHealth += Mathf.Max(0f, maxHealth - previousMaxHealth);
                }
            }
            if (scavenger != null)
                scavenger.Experience = scavengerExperience;
        }

        public void SetProtocol(ExplorationProtocolKind value)
        {
            protocol = value;
        }

        public void AddEquipment(ExpeditionEquipment value)
        {
            if ((equipment & value) != 0)
                return;
            equipment |= value;
            if (value == ExpeditionEquipment.LifeSupport)
            {
                bonusMaxHealth += 18f;
                IncreaseMaxHealth(18f);
            }
        }

        public float GetPlayerEffectMultiplier(CardDefinition definition)
        {
            var multiplier = scavenger?.GetCardMultiplier(definition) ?? 1f;
            if (protocol == ExplorationProtocolKind.Assault && (definition.Tags & CardTag.Weapon) != 0)
                multiplier *= 1.15f;
            if (protocol == ExplorationProtocolKind.Survival &&
                (definition.Tags & (CardTag.Defense | CardTag.Support)) != 0)
                multiplier *= 1.18f;
            if (protocol == ExplorationProtocolKind.Anomaly && (definition.Tags & CardTag.Magic) != 0)
                multiplier *= 1.18f;

            if ((equipment & ExpeditionEquipment.PowerArm) != 0 && (definition.Tags & CardTag.Weapon) != 0)
                multiplier *= 1.10f;
            if ((equipment & ExpeditionEquipment.AegisModule) != 0 && (definition.Tags & CardTag.Defense) != 0)
                multiplier *= 1.12f;
            if ((equipment & ExpeditionEquipment.LifeSupport) != 0 && definition.Effect == CardEffectKind.Heal)
                multiplier *= 1.10f;
            return multiplier;
        }

        public float GetPlayerCooldownMultiplier(CardDefinition definition)
        {
            return scavenger?.GetCooldownMultiplier(definition) ?? 1f;
        }

        public void CompleteScavenger(IEnumerable<ScavengerDeckEntry> lockedDeck)
        {
            if (scavenger == null)
                return;
            scavenger.Level = scavengerLevel;
            scavenger.Experience = scavengerExperience;
            scavenger.ExplorationCompleted = true;
            scavenger.CompletedMapId = map?.Id;
            scavenger.LockedDeck = lockedDeck?.ToList() ?? new List<ScavengerDeckEntry>();
            ScavengerRosterRepository.AddOrUpdate(scavenger);
        }

        public ExplorationBattleResolution ResolveBattle(bool won, float remainingHealth, int bonusGold)
        {
            var encounter = CurrentEncounter;
            if (encounter == null)
                return new ExplorationBattleResolution(false, completed, PreparationEventType.None, 0, 0);

            if (!won)
            {
                // Difficulty 1 supports formation retries without destroying the run.
                currentHealth = Mathf.Max(maxHealth * .45f, 1f);
                return new ExplorationBattleResolution(false, false, PreparationEventType.None, 0, 0);
            }

            currentHealth = Mathf.Clamp(remainingHealth, 1f, maxHealth);
            Heal(maxHealth * victoryRepairRatio);
            var gold = encounter.GoldReward + Mathf.Max(0, bonusGold);
            AddCoins(gold);
            GainExperience(encounter.ExperienceReward);

            var completedEncounterKind = encounter.Kind;
            encounterIndex++;
            if (completedEncounterKind == ExplorationEncounterKind.Boss || encounterIndex >= EncounterCount)
            {
                completed = true;
                return new ExplorationBattleResolution(true, true, PreparationEventType.None,
                    gold, encounter.ExperienceReward);
            }

            var nextEvent = completedEncounterKind == ExplorationEncounterKind.Elite
                ? eventDirector.NextAfterElite()
                : PreparationEventType.None;
            return new ExplorationBattleResolution(true, false, nextEvent, gold, encounter.ExperienceReward);
        }

        public string BuildProgressLabel()
        {
            if (!initialized || map == null)
                return string.Empty;
            var encounter = CurrentEncounter;
            var encounterName = completed ? "探索完成" : encounter?.DisplayName ?? "整备";
            var scavengerName = scavenger != null ? scavenger.DisplayName : "未命名拾荒者";
            return $"{map.DisplayName}  难度{map.Difficulty}   {EncounterNumber}/{EncounterCount}  {encounterName}  ·  {scavengerName}";
        }

        private sealed class ExplorationEventDirector
        {
            private readonly System.Random random;
            private PreparationEventType lastEvent = PreparationEventType.Merchant;
            private int eventOrdinal = 1;
            private bool equipmentSeen;

            public ExplorationEventDirector(int seed)
            {
                random = new System.Random(seed);
            }

            public PreparationEventType NextAfterElite()
            {
                if (eventOrdinal++ == 1)
                {
                    lastEvent = PreparationEventType.EnhanceSlot;
                    return lastEvent;
                }

                // Difficulty 1 is also the feature-onboarding map: the third event must demonstrate
                // a new event family instead of rolling back into Merchant/EnhanceSlot.
                if (eventOrdinal == 3)
                {
                    lastEvent = PreparationEventType.CardWorkshop;
                    return lastEvent;
                }

                var weighted = new List<(PreparationEventType type, int weight)>
                {
                    (PreparationEventType.WastelandCamp, 30),
                    (PreparationEventType.TacticalProtocol, 25),
                    (PreparationEventType.RuinsExploration, 25)
                };
                if (!equipmentSeen)
                    weighted.Add((PreparationEventType.EquipmentCache, 20));
                weighted.RemoveAll(entry => entry.type == lastEvent);

                var total = 0;
                foreach (var entry in weighted)
                    total += entry.weight;
                var roll = random.Next(total);
                foreach (var entry in weighted)
                {
                    if (roll < entry.weight)
                    {
                        lastEvent = entry.type;
                        if (lastEvent == PreparationEventType.EquipmentCache)
                            equipmentSeen = true;
                        return lastEvent;
                    }
                    roll -= entry.weight;
                }

                lastEvent = PreparationEventType.WastelandCamp;
                return lastEvent;
            }
        }
    }
}

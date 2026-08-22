using System;
using System.Collections.Generic;
using CardAutobattle.Prototype;

namespace CardAutobattle.Exploration
{
    public enum ExplorationEncounterKind
    {
        Normal,
        Elite,
        Boss
    }

    public enum ExplorationProtocolKind
    {
        None,
        Assault,
        Survival,
        Anomaly
    }

    [Flags]
    public enum ExpeditionEquipment
    {
        None = 0,
        PowerArm = 1 << 0,
        AegisModule = 1 << 1,
        LifeSupport = 1 << 2
    }

    [Serializable]
    public sealed class ExplorationEncounterDefinition
    {
        public string Id;
        public string DisplayName;
        public ExplorationEncounterKind Kind;
        public int EnemyLevel;
        public float EnemyMaxHealth;
        public float EnemyPowerMultiplier;
        public float EnemyCooldownMultiplier;
        public int GoldReward;
        public int ExperienceReward;
        public string[] EnemyCardIds;
        public int[] EnemyPositions;

        public ExplorationEncounterDefinition(string id, string displayName, ExplorationEncounterKind kind,
            int enemyLevel, float enemyMaxHealth, float enemyPowerMultiplier, float enemyCooldownMultiplier,
            int goldReward, int experienceReward, string[] enemyCardIds, int[] enemyPositions)
        {
            Id = id;
            DisplayName = displayName;
            Kind = kind;
            EnemyLevel = enemyLevel;
            EnemyMaxHealth = enemyMaxHealth;
            EnemyPowerMultiplier = enemyPowerMultiplier;
            EnemyCooldownMultiplier = enemyCooldownMultiplier;
            GoldReward = goldReward;
            ExperienceReward = experienceReward;
            EnemyCardIds = enemyCardIds;
            EnemyPositions = enemyPositions;
        }
    }

    [Serializable]
    public sealed class ExplorationMapDefinition
    {
        public string Id;
        public string DisplayName;
        public int Difficulty;
        public IReadOnlyList<ExplorationEncounterDefinition> Encounters;

        public ExplorationMapDefinition(string id, string displayName, int difficulty,
            IReadOnlyList<ExplorationEncounterDefinition> encounters)
        {
            Id = id;
            DisplayName = displayName;
            Difficulty = difficulty;
            Encounters = encounters;
        }
    }

    public static class ExplorationMapCatalog
    {
        private static readonly ExplorationMapDefinition DifficultyOne = new(
            "ash_frontier_d1",
            "灰烬边境",
            1,
            new List<ExplorationEncounterDefinition>
            {
                new("d1_01", "外围游荡者", ExplorationEncounterKind.Normal,
                    1, 76f, .72f, 1.08f, 5, 12,
                    new[] { "dagger", "shield", "herbs" }, new[] { 0, 4, 8 }),
                new("d1_02", "精英·掠夺小队", ExplorationEncounterKind.Elite,
                    1, 92f, .80f, 1.04f, 8, 20,
                    new[] { "blade", "fire", "shield", "dagger" }, new[] { 1, 3, 4, 5 }),
                new("d1_03", "污染拾荒者", ExplorationEncounterKind.Normal,
                    1, 86f, .78f, 1.05f, 6, 14,
                    new[] { "poison", "shield", "bow", "herbs" }, new[] { 0, 2, 6, 8 }),
                new("d1_04", "精英·热能卫队", ExplorationEncounterKind.Elite,
                    1, 105f, .88f, 1.01f, 9, 22,
                    new[] { "fire", "shield", "armor", "battery", "dagger" }, new[] { 0, 1, 4, 7, 8 }),
                new("d1_05", "废城巡逻队", ExplorationEncounterKind.Normal,
                    1, 96f, .84f, 1.03f, 7, 16,
                    new[] { "frost", "thorns", "dagger", "herbs", "blade" }, new[] { 0, 2, 4, 6, 8 }),
                new("d1_06", "精英·生化守卫", ExplorationEncounterKind.Elite,
                    1, 116f, .94f, 1.00f, 10, 24,
                    new[] { "poison", "fire", "shield", "thorns", "battery", "herbs" }, new[] { 0, 1, 3, 4, 5, 7 }),
                new("d1_07", "首领·荒原核心", ExplorationEncounterKind.Boss,
                    1, 132f, .90f, 1.02f, 15, 35,
                    new[] { "core", "armor", "blade", "fire", "poison", "battery" }, new[] { 0, 2, 3, 4, 5, 7 })
            });

        public static ExplorationMapDefinition Get(int difficulty)
        {
            // First commercial slice only ships difficulty 1. Higher difficulties can be data assets later.
            return DifficultyOne;
        }
    }

    public readonly struct ExplorationBattleResolution
    {
        public readonly bool Won;
        public readonly bool MapCompleted;
        public readonly PreparationEventType NextEvent;
        public readonly int GoldGranted;
        public readonly int ExperienceGranted;

        public ExplorationBattleResolution(bool won, bool mapCompleted, PreparationEventType nextEvent,
            int goldGranted, int experienceGranted)
        {
            Won = won;
            MapCompleted = mapCompleted;
            NextEvent = nextEvent;
            GoldGranted = goldGranted;
            ExperienceGranted = experienceGranted;
        }
    }
}

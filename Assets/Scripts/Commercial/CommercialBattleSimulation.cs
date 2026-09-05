using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    public enum CommercialBattleResult { Running, Victory, Defeat }
    public enum BattleVisualEventKind
    {
        Action, Projectile, Melee, Summon, Damage, CriticalDamage, Heal, Shield, Buff, Defeat, BattleEnded
    }
    public enum CommercialEnemyTier { Minion, Elite, Boss }

    public readonly struct BattleVisualEvent
    {
        public readonly BattleVisualEventKind Kind;
        public readonly string SourceId;
        public readonly string TargetId;
        public readonly float Amount;
        public readonly int SourceGrid;
        public readonly int TargetGrid;

        public BattleVisualEvent(BattleVisualEventKind kind, string sourceId, string targetId,
            float amount, int sourceGrid, int targetGrid)
        {
            Kind = kind;
            SourceId = sourceId;
            TargetId = targetId;
            Amount = amount;
            SourceGrid = sourceGrid;
            TargetGrid = targetGrid;
        }
    }

    public sealed class CommercialCombatant
    {
        public string Id;
        public string DisplayName;
        public int GridIndex;
        public bool Enemy;
        public bool IsHero;
        public bool IsSummon;
        public CommercialEnemyTier EnemyTier;
        public int HiddenCardCount;
        public int ArenaSlot;
        public float SpawnDelay;
        public Vector2 Position;
        public float MoveSpeed;
        public float AttackRange;
        public float PreferredRange;
        public float PersonalRadius;
        public float Threat;
        public float MaxHealth;
        public float Health;
        public float Shield;
        public float Attack;
        public float AttackInterval;
        public float NextAction;
        public float Vulnerability;
        public float Burn;
        public float Poison;
        public float Armor;
        public float CritChance;
        public float CritDamage = 1.5f;
        public CommercialProfessionId Profession;
        public string ProfessionResourceName;
        public int ProfessionResource;
        public int ProfessionResourceMax;
        public bool ProfessionReady;
        public bool Alive => Health > 0f;
        public float Health01 => MaxHealth <= 0f ? 0f : Mathf.Clamp01(Health / MaxHealth);
        public float ActionCharge01 => !Alive || AttackInterval <= 0f
            ? 0f : Mathf.Clamp01(1f - NextAction / AttackInterval);
    }

    public sealed class CommercialCardRuntime
    {
        public CommercialCardDefinition Definition;
        public int GridIndex;
        public float Cooldown;
        public float Remaining;
        public CommercialCombatant Summon;
        public bool Enabled => Definition != null && Definition.Type != CommercialCardType.Passive;
        public float Charge01 => Cooldown <= 0f || float.IsInfinity(Remaining)
            ? 1f : Mathf.Clamp01(1f - Remaining / Cooldown);
    }

    public sealed class CommercialBattleSession
    {
        private const float FixedStep = .05f;
        public const float ProjectileTravelDuration = .45f;

        private sealed class PendingImpact
        {
            public CommercialCombatant Source;
            public string SourceId;
            public int SourceGrid;
            public CommercialCombatant Target;
            public float Amount;
            public float LaunchRemaining;
            public float Remaining;
            public bool Launched;
            public Action<CommercialCombatant> AfterImpact;
            public CommercialCardTag Tags;
            public bool AllowCrit;
            public bool HeroBasicAttack;
            public int TriggerId;
            public BattleVisualEventKind PresentationKind;
        }

        private readonly CommercialCharacterSnapshot characterSnapshot;
        private readonly CommercialGameState gameState;
        private readonly CommercialProfessionRuntime professionRuntime;
        private readonly CommercialDomainEventStream domainEvents = new();
        private readonly Queue<BattleVisualEvent> visualEvents = new();
        private readonly List<PendingImpact> pendingImpacts = new();
        private readonly List<CommercialCardRuntime> cards = new();
        private readonly List<CommercialCombatant> allies = new();
        private readonly List<CommercialCombatant> enemies = new();
        private readonly System.Random random;
        private float statusTickRemaining = 1f;
        private float elapsed;
        private int nextTriggerId = 1;
        private readonly WorldNodeKind encounterKind;

        public CommercialFormation FormationSnapshot { get; }
        public IReadOnlyList<CommercialCardRuntime> Cards => cards;
        public IReadOnlyList<CommercialCombatant> Allies => allies;
        public IReadOnlyList<CommercialCombatant> Enemies => enemies;
        public CommercialCombatant Hero { get; }
        public CommercialBattleResult Result { get; private set; } = CommercialBattleResult.Running;
        public float Elapsed => elapsed;
        public int Chapter { get; }
        public int Stage { get; }
        public int GlobalStage => (Chapter - 1) * 20 + Stage;
        public int LivingEnemyCount => enemies.Count(enemy => enemy.Alive);
        public string FocusedEnemyId { get; private set; }
        public bool Completed => Result != CommercialBattleResult.Running;
        public CommercialCharacterSnapshot CharacterSnapshot => characterSnapshot;
        public CommercialProfessionRuntime ProfessionRuntime => professionRuntime;
        public CommercialDomainEventStream DomainEvents => domainEvents;

        public CommercialBattleSession(CommercialGameState state, CommercialFormation formation, int seed,
            CommercialWorldEncounter encounter = null)
        {
            if (state == null) throw new ArgumentNullException(nameof(state));
            gameState = state;
            characterSnapshot = CommercialCharacterCalculator.BuildSnapshot(state);
            FormationSnapshot = (formation ?? state.DraftFormation).Clone();
            Chapter = Mathf.Clamp(encounter?.Chapter ?? state.Chapter, 1, 5);
            Stage = Mathf.Clamp(encounter?.Stage ?? state.Stage, 1, 20);
            random = new System.Random(seed);

            encounterKind = encounter?.Kind ?? (Stage % 5 == 0 ? WorldNodeKind.Boss : WorldNodeKind.Idle);
            for (var i = 0; i < FormationSnapshot.Slots.Length; i++)
                if (FormationSnapshot.Slots[i] == CommercialGameState.HeroCardId) FormationSnapshot.Slots[i] = null;
            var heroHealth = characterSnapshot.MaxHealth;
            Hero = new CommercialCombatant
            {
                Id = CommercialGameState.HeroCardId,
                DisplayName = "主角",
                GridIndex = -1,
                IsHero = true,
                MaxHealth = heroHealth,
                Health = heroHealth,
                Shield = heroHealth * characterSnapshot.Equipment[EquipmentStat.StartingShield],
                Attack = CommercialCharacterCalculator.HeroBasicAttack(characterSnapshot),
                AttackInterval = characterSnapshot.HeroAttackInterval,
                NextAction = characterSnapshot.HeroAttackInterval,
                Armor = characterSnapshot.Armor,
                CritChance = characterSnapshot.CritChance,
                CritDamage = characterSnapshot.CritDamage,
                Threat = 100f
                ,Position = new Vector2(0f, -2f)
                ,MoveSpeed = 1.25f
                ,AttackRange = 1.3f
                ,PreferredRange = 1.05f
                ,PersonalRadius = .45f
            };
            allies.Add(Hero);
            professionRuntime = new CommercialProfessionRuntime(characterSnapshot.Profession, Hero, domainEvents);
            BuildCards();
            BuildEnemies();
            if (encounter != null && encounter.Kind != WorldNodeKind.Idle)
            {
                var boss = encounter.Kind == WorldNodeKind.Boss;
                for (var i = 0; i < enemies.Count; i++)
                {
                    var enemy = enemies[i];
                    enemy.DisplayName = i == 0 ? (CommercialWorldCatalog.Find(encounter.NodeId)?.Name ?? (boss ? "区域首领" : "巡游精英")) : "随从 " + i;
                    enemy.MaxHealth *= i == 0 ? (boss ? 1.8f : 1.3f) : 1f;
                    enemy.Health = enemy.MaxHealth;
                }
            }
            if (encounter != null)
                foreach (var enemy in enemies)
                {
                    enemy.MaxHealth *= encounter.HealthScale; enemy.Health = enemy.MaxHealth;
                    enemy.Attack *= encounter.AttackScale;
                }
        }

        public void Advance(float realSeconds)
        {
            if (Completed || realSeconds <= 0f) return;
            var remaining = Mathf.Min(realSeconds, 600f);
            while (remaining > 0f && !Completed)
            {
                var step = Mathf.Min(FixedStep, remaining);
                Tick(step);
                remaining -= step;
            }
        }

        public bool TryDequeueVisualEvent(out BattleVisualEvent value)
        {
            if (visualEvents.Count > 0)
            {
                value = visualEvents.Dequeue();
                return true;
            }
            value = default;
            return false;
        }

        public CommercialCardRuntime GetCardAt(int gridIndex) =>
            cards.FirstOrDefault(card => card.GridIndex == gridIndex);
        public CommercialCombatant GetEnemyAt(int gridIndex) =>
            enemies.FirstOrDefault(enemy => enemy.GridIndex == gridIndex);
        public CommercialCombatant GetAllyAt(int gridIndex) =>
            allies.FirstOrDefault(ally => ally.GridIndex == gridIndex && ally.Alive);
        public float GetCurrentResolvedPower(int gridIndex)
        {
            var runtime = GetCardAt(gridIndex);
            return runtime == null ? 0f : ResolveCardValues(runtime).Primary;
        }

        public bool TogglePriorityTarget(string enemyId)
        {
            var target = enemies.FirstOrDefault(enemy => enemy.Id == enemyId && enemy.Alive && HasEntered(enemy));
            if (target == null) return false;
            FocusedEnemyId = FocusedEnemyId == enemyId ? null : enemyId;
            return true;
        }

        /// <summary>
        /// Repositions the current battle snapshot only.  DraftFormation is deliberately untouched,
        /// while all adjacency and target calculations immediately read the new runtime positions.
        /// </summary>
        public bool TrySwapPlayerGridPositions(int sourceGrid, int targetGrid)
        {
            if (Completed || sourceGrid < 0 || sourceGrid >= 9 || targetGrid < 0 || targetGrid >= 9 ||
                sourceGrid == targetGrid) return false;
            var sourceId = FormationSnapshot.Slots[sourceGrid];
            if (string.IsNullOrEmpty(sourceId)) return false;
            var targetId = FormationSnapshot.Slots[targetGrid];
            var sourceRuntime = cards.FirstOrDefault(card => card.GridIndex == sourceGrid);
            var targetRuntime = cards.FirstOrDefault(card => card.GridIndex == targetGrid);
            FormationSnapshot.Slots[sourceGrid] = targetId;
            FormationSnapshot.Slots[targetGrid] = sourceId;
            MoveRuntimeOccupant(sourceRuntime, targetGrid);
            MoveRuntimeOccupant(targetRuntime, sourceGrid);
            return true;
        }

        private static void MoveRuntimeOccupant(CommercialCardRuntime runtime, int toGrid)
        {
            if (runtime == null) return;
            runtime.GridIndex = toGrid;
            if (runtime.Summon != null) runtime.Summon.GridIndex = toGrid;
        }

        private void BuildCards()
        {
            for (var i = 0; i < FormationSnapshot.Slots.Length; i++)
            {
                var cardId = FormationSnapshot.Slots[i];
                if (string.IsNullOrEmpty(cardId) || cardId == CommercialGameState.HeroCardId) continue;
                var definition = CommercialCardCatalog.Get(cardId);
                if (definition == null) continue;
                var runtime = new CommercialCardRuntime
                {
                    Definition = definition,
                    GridIndex = i,
                    Cooldown = definition.Type == CommercialCardType.Passive ? float.PositiveInfinity : definition.Cooldown,
                    Remaining = definition.Type == CommercialCardType.Passive ? float.PositiveInfinity : definition.Cooldown
                };
                if (definition.Type == CommercialCardType.Summon)
                {
                    var levelScale = (1f + Mathf.Max(0, characterSnapshot.AbilityPower) / 360f) *
                                     gameState.CardLevelMultiplier(definition.Id) *
                                     (1 + characterSnapshot.Equipment[EquipmentStat.SummonHealthBonus]);
                    runtime.Summon = new CommercialCombatant
                    {
                        Id = $"summon_{definition.Id}_{i}",
                        DisplayName = definition.DisplayName,
                        GridIndex = i,
                        IsSummon = true,
                        MaxHealth = definition.SummonHealth * levelScale,
                        Health = 0f,
                        Attack = CommercialCardValueCalculator.Resolve(definition, characterSnapshot, 0).Primary *
                                 gameState.CardLevelMultiplier(definition.Id),
                        AttackInterval = definition.Cooldown,
                        NextAction = definition.Cooldown,
                        Threat = definition.Effect == CommercialCardEffect.SummonGuard ? 180f :
                            definition.Effect == CommercialCardEffect.SummonHealer ? 125f : 80f
                        ,Position = new Vector2((i % 3 - 1) * .75f, -2.8f - i * .12f)
                        ,MoveSpeed = definition.Effect == CommercialCardEffect.SummonStriker ? 1.45f : 1.05f
                        ,AttackRange = definition.Effect == CommercialCardEffect.SummonHealer ? 3.8f : 1.15f
                        ,PreferredRange = definition.Effect == CommercialCardEffect.SummonHealer ? 3.1f : .9f
                        ,PersonalRadius = .34f
                    };
                    allies.Add(runtime.Summon);
                }
                cards.Add(runtime);
            }
        }

        private void BuildEnemies()
        {
            var global = GlobalStage;
            var boss = encounterKind == WorldNodeKind.Boss || Stage % 5 == 0;
            var elite = encounterKind == WorldNodeKind.Elite;
            var count = Mathf.Clamp(3 + global / 7 + (boss ? 1 : 0), 3, 8);
            var positions = Enumerable.Range(0, 9).OrderBy(_ => random.Next()).Take(count).OrderBy(i => i).ToArray();
            var healthScale = (1f + (global - 1) * .13f) * (boss ? 1.32f : 1f);
            var attackScale = (1f + (global - 1) * .105f) * (boss ? 1.18f : 1f);
            for (var i = 0; i < positions.Length; i++)
            {
                var hpVariance = .9f + (float)random.NextDouble() * .2f;
                var attackVariance = .9f + (float)random.NextDouble() * .2f;
                var maxHealth = 34f * healthScale * hpVariance;
                var tier = i == 0 && boss ? CommercialEnemyTier.Boss :
                    i == 0 && elite ? CommercialEnemyTier.Elite : CommercialEnemyTier.Minion;
                var hiddenCards = tier == CommercialEnemyTier.Boss ? Mathf.Clamp(6 + global / 15, 6, 9) :
                    tier == CommercialEnemyTier.Elite ? Mathf.Clamp(2 + global / 18, 2, 5) : 1;
                // Demo hidden decks alternate melee / medium / long-range behaviours.
                // This becomes a direct aggregate of configured enemy cards once their
                // full hidden deck definitions are authored.
                var rangeProfile = (positions[i] + hiddenCards) % 3;
                var attackRange = rangeProfile == 0 ? 1.15f : rangeProfile == 1 ? 3.1f : 4.65f;
                enemies.Add(new CommercialCombatant
                {
                    Id = $"enemy_{global}_{i}",
                    DisplayName = boss && i == 0 ? "关卡首领" : $"敌人 {i + 1}",
                    GridIndex = positions[i],
                    Enemy = true,
                    EnemyTier = tier,
                    HiddenCardCount = hiddenCards,
                    ArenaSlot = i,
                    SpawnDelay = .35f + i * .28f,
                    MaxHealth = maxHealth,
                    Health = maxHealth,
                    Attack = 4.6f * attackScale * attackVariance * (1f + (hiddenCards - 1) * .055f),
                    AttackInterval = Mathf.Max(2.05f, 3.75f - global * .018f) / (1f + (hiddenCards - 1) * .025f),
                    NextAction = 1.8f + i * .16f,
                    Threat = 0f
                    ,Position = new Vector2((i % 3 - 1) * 2.05f + (i / 3) * .2f, 2.15f + (i / 3) * .36f)
                    ,MoveSpeed = tier == CommercialEnemyTier.Boss ? .62f : tier == CommercialEnemyTier.Elite ? .78f : .92f
                    ,AttackRange = attackRange
                    ,PreferredRange = attackRange * .82f
                    ,PersonalRadius = tier == CommercialEnemyTier.Boss ? .9f : tier == CommercialEnemyTier.Elite ? .58f : .38f
                });
            }
        }

        private void Tick(float delta)
        {
            elapsed += delta;
            ResolvePendingImpacts(delta);
            UpdateMovement(delta);
            Hero.NextAction -= delta;
            if (Hero.Alive && Hero.NextAction <= 0f)
            {
                Hero.NextAction += Hero.AttackInterval;
                var triggerId = nextTriggerId++;
                var proc = professionRuntime.BeginHeroBasicAttack();
                domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.HeroBasicAttackStarted,
                    Hero.Id, CommercialCardTag.BasicAttack | CommercialCardTag.Melee, triggerId));
                var target = SelectEnemy(Hero.Position, Hero.AttackRange);
                if (target != null)
                    LaunchProjectile(Hero, target, Hero.Attack * proc.Multiplier,
                        heroBasicAttack: true, triggerId: triggerId,
                        presentationKind: BattleVisualEventKind.Melee);
            }

            foreach (var card in cards)
            {
                if (!card.Enabled) continue;
                card.Remaining -= delta;
                if (card.Remaining > 0f) continue;
                card.Remaining += card.Cooldown;
                TriggerCard(card);
            }

            foreach (var enemy in enemies)
            {
                if (!enemy.Alive || !HasEntered(enemy)) continue;
                var target = SelectEnemyTarget();
                if (target == null || Vector2.Distance(enemy.Position, target.Position) > enemy.AttackRange) continue;
                enemy.NextAction -= delta;
                if (enemy.NextAction > 0f) continue;
                enemy.NextAction += enemy.AttackInterval;
                visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Action, enemy.Id,
                    target.Id, enemy.Attack, enemy.GridIndex, target.GridIndex));
                LaunchProjectile(enemy, target, enemy.Attack,
                    presentationKind: enemy.EnemyTier == CommercialEnemyTier.Minion
                        ? BattleVisualEventKind.Melee : BattleVisualEventKind.Projectile);
            }

            statusTickRemaining -= delta;
            if (statusTickRemaining <= 0f)
            {
                statusTickRemaining += 1f;
                foreach (var enemy in enemies.Where(enemy => enemy.Alive))
                {
                    if (enemy.Burn > 0f)
                    {
                        ApplyDamage(null, enemy, enemy.Burn);
                        enemy.Burn = Mathf.Max(0f, enemy.Burn - 1f);
                    }
                    if (enemy.Poison > 0f)
                    {
                        ApplyDamage(null, enemy, enemy.Poison * .55f);
                        enemy.Poison = Mathf.Max(0f, enemy.Poison - .35f);
                    }
                }
            }

            if (!Hero.Alive) End(CommercialBattleResult.Defeat);
            else if (enemies.All(enemy => !enemy.Alive)) End(CommercialBattleResult.Victory);
            else if (elapsed >= 90f) End(CommercialBattleResult.Defeat);
        }

        private void TriggerCard(CommercialCardRuntime card)
        {
            var definition = card.Definition;
            var triggerId = nextTriggerId++;
            var values = ResolveCardValues(card);
            var proc = professionRuntime.BeginCardTrigger(definition);
            var primary = values.Primary * proc.Multiplier;
            var secondary = values.Secondary * proc.Multiplier;
            domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.CardTriggered,
                definition.Id, definition.Tags, triggerId, primary));
            visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Action, definition.Id, string.Empty,
                primary, card.GridIndex, -1));

            var followupLaunched = false;
            void LaunchCardProjectile(CommercialCombatant projectileTarget, float amount,
                Action<CommercialCombatant> afterImpact = null, float launchDelay = 0f)
            {
                var presentation = definition.Tags.HasFlag(CommercialCardTag.Melee)
                    ? BattleVisualEventKind.Melee : BattleVisualEventKind.Projectile;
                LaunchProjectile(definition.Id, card.GridIndex, projectileTarget, amount, afterImpact,
                    null, launchDelay, definition.Tags, true, false, triggerId, presentation);
                if (followupLaunched || proc.FollowupRatio <= 0f || projectileTarget == null) return;
                followupLaunched = true;
                LaunchProjectile(definition.Id, card.GridIndex, projectileTarget,
                    primary * proc.FollowupRatio, null, null, Mathf.Max(.12f, launchDelay + .12f),
                    definition.Tags, true, false, triggerId, presentation);
            }

            if (definition.Type == CommercialCardType.Summon)
            {
                if (card.Summon == null) return;
                if (!card.Summon.Alive)
                {
                    card.Summon.Health = card.Summon.MaxHealth;
                    card.Summon.Shield = 0f;
                    card.Summon.NextAction = card.Cooldown;
                    visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Summon, definition.Id,
                        card.Summon.Id, card.Summon.MaxHealth, card.GridIndex, card.Summon.GridIndex));
                    return;
                }
                switch (definition.Effect)
                {
                    case CommercialCardEffect.SummonGuard:
                        AddShield(card, card.Summon, primary * 1.15f);
                        AddShield(card, Hero, primary * .55f);
                        break;
                    case CommercialCardEffect.SummonHealer:
                        HealLowestAlly(card, primary * 1.2f);
                        break;
                    default:
                        AttackEnemy(card.Summon, primary * 1.35f, BattleVisualEventKind.Melee);
                        break;
                }
                return;
            }

            var target = SelectEnemy(Hero.Position, CardAttackRange(definition));
            switch (definition.Effect)
            {
                case CommercialCardEffect.Damage:
                    if (target != null) LaunchCardProjectile(target, primary); break;
                case CommercialCardEffect.DoubleStrike:
                    if (target != null)
                    {
                        var hit = primary * .5f;
                        LaunchCardProjectile(target, hit);
                        LaunchCardProjectile(target, hit, launchDelay: .12f);
                    }
                    break;
                case CommercialCardEffect.ShieldHero:
                    AddShield(card, Hero, primary); break;
                case CommercialCardEffect.HealHero:
                    Heal(card, Hero, primary); break;
                case CommercialCardEffect.Burn:
                    if (target != null) LaunchCardProjectile(target, primary,
                        impacted => impacted.Burn += secondary); break;
                case CommercialCardEffect.Poison:
                    if (target != null) LaunchCardProjectile(target, primary,
                        impacted => impacted.Poison += secondary); break;
                case CommercialCardEffect.SlowEnemy:
                    if (target != null)
                    {
                        LaunchCardProjectile(target, primary, impacted =>
                        {
                            impacted.AttackInterval *= 1f + Mathf.Clamp(secondary, 0f, .35f);
                            visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Buff, definition.Id,
                                impacted.Id, secondary, card.GridIndex, impacted.GridIndex));
                        });
                    }
                    break;
                case CommercialCardEffect.HasteAdjacent:
                    foreach (var other in cards.Where(other => other != card && AreAdjacent(other.GridIndex, card.GridIndex)))
                        other.Remaining = Mathf.Max(0f, other.Remaining - primary);
                    break;
                case CommercialCardEffect.HasteAll:
                    foreach (var other in cards.Where(other => other != card))
                        other.Remaining = Mathf.Max(0f, other.Remaining - primary);
                    break;
                case CommercialCardEffect.DamageAndHaste:
                    if (target != null) LaunchCardProjectile(target, primary);
                    foreach (var other in cards.Where(other => other != card && AreAdjacent(other.GridIndex, card.GridIndex)))
                        other.Remaining = Mathf.Max(0f, other.Remaining - secondary);
                    break;
                case CommercialCardEffect.ShieldAndDamage:
                    AddShield(card, Hero, primary);
                    if (target != null) LaunchCardProjectile(target, secondary);
                    break;
                case CommercialCardEffect.Drain:
                    if (target != null) LaunchCardProjectile(target, primary,
                        _ => Heal(card, Hero, secondary));
                    break;
                case CommercialCardEffect.ChainDamage:
                    foreach (var enemy in enemies.Where(enemy => enemy.Alive && HasEntered(enemy) &&
                                 Vector2.Distance(Hero.Position, enemy.Position) <= CardAttackRange(definition)).Take(3).ToArray())
                        LaunchCardProjectile(enemy, primary);
                    break;
                case CommercialCardEffect.Vulnerability:
                    if (target != null)
                    {
                        LaunchCardProjectile(target, primary,
                            impacted => impacted.Vulnerability = Mathf.Max(impacted.Vulnerability, secondary));
                    }
                    break;
            }
        }

        private CommercialResolvedCardValues ResolveCardValues(CommercialCardRuntime source)
        {
            var buildBonus = 0f;
            foreach (var passive in cards.Where(card => card.Definition.Type == CommercialCardType.Passive))
            {
                if (passive.Definition.Effect == CommercialCardEffect.PassiveGlobalPower)
                    buildBonus += passive.Definition.Power * gameState.CardLevelMultiplier(passive.Definition.Id);
                else if (AreAdjacent(passive.GridIndex, source.GridIndex))
                    buildBonus += passive.Definition.Power * gameState.CardLevelMultiplier(passive.Definition.Id);
            }
            if (source.Definition.AdjacentBonus > 0f)
            {
                var count = cards.Count(other => other != source && AreAdjacent(other.GridIndex, source.GridIndex) &&
                    (source.Definition.AdjacentRequiredTag == CommercialCardTag.None ||
                     (other.Definition.Tags & source.Definition.AdjacentRequiredTag) != 0));
                buildBonus += source.Definition.AdjacentBonus * count / Mathf.Max(1f, source.Definition.Power);
            }
            var resolved = CommercialCardValueCalculator.Resolve(source.Definition, characterSnapshot, buildBonus);
            var levelMultiplier = gameState.CardLevelMultiplier(source.Definition.Id);
            return new CommercialResolvedCardValues(resolved.Primary * levelMultiplier,
                resolved.Secondary * levelMultiplier, resolved.BuildBonus);
        }

        private CommercialCombatant SelectEnemy()
        {
            return SelectEnemy(Hero.Position, float.PositiveInfinity);
        }

        private CommercialCombatant SelectEnemy(Vector2 origin, float range)
        {
            var focused = enemies.FirstOrDefault(enemy => enemy.Id == FocusedEnemyId && enemy.Alive && HasEntered(enemy) &&
                Vector2.Distance(origin, enemy.Position) <= range);
            if (focused != null) return focused;
            if (!string.IsNullOrEmpty(FocusedEnemyId) && enemies.All(enemy => enemy.Id != FocusedEnemyId || !enemy.Alive)) FocusedEnemyId = null;
            return enemies.Where(enemy => enemy.Alive && HasEntered(enemy))
                .Where(enemy => Vector2.Distance(origin, enemy.Position) <= range)
                .OrderByDescending(enemy => enemy.EnemyTier).ThenBy(enemy => Vector2.Distance(origin, enemy.Position)).FirstOrDefault();
        }

        private bool HasEntered(CommercialCombatant enemy) => enemy != null && elapsed >= enemy.SpawnDelay;

        private CommercialCombatant SelectEnemyTarget()
        {
            return allies.Where(ally => ally.Alive)
                .OrderByDescending(ally => ally.Threat)
                .ThenBy(ally => ally.Health01)
                .FirstOrDefault();
        }

        private void AttackEnemy(CommercialCombatant source, float amount, BattleVisualEventKind visualKind)
        {
            var target = SelectEnemy(source.Position, Mathf.Max(1f, source.AttackRange));
            if (target == null) return;
            LaunchProjectile(source, target, amount, presentationKind: visualKind);
        }

        private float CardAttackRange(CommercialCardDefinition definition)
        {
            if (definition == null) return 0f;
            if ((definition.Tags & CommercialCardTag.Melee) != 0) return 1.45f;
            if ((definition.Tags & CommercialCardTag.Projectile) != 0) return 5.4f;
            if ((definition.Tags & CommercialCardTag.Magic) != 0) return 4.7f;
            return 4.2f;
        }

        private void UpdateMovement(float delta)
        {
            var entered = enemies.Where(enemy => enemy.Alive && HasEntered(enemy)).ToArray();
            var nearest = entered.OrderBy(enemy => Vector2.Distance(Hero.Position, enemy.Position)).FirstOrDefault();
            var heroRange = cards.Where(card => card.Enabled && card.Definition.Effect is CommercialCardEffect.Damage or
                    CommercialCardEffect.DoubleStrike or CommercialCardEffect.Burn or CommercialCardEffect.Poison or
                    CommercialCardEffect.SlowEnemy or CommercialCardEffect.DamageAndHaste or
                    CommercialCardEffect.ShieldAndDamage or CommercialCardEffect.Drain or
                    CommercialCardEffect.ChainDamage or CommercialCardEffect.Vulnerability)
                .Select(card => CardAttackRange(card.Definition)).DefaultIfEmpty(Hero.PreferredRange).Max();
            if (nearest != null) MoveToward(Hero, nearest.Position, Mathf.Max(1.05f, heroRange * .72f), delta);

            foreach (var ally in allies.Where(value => value.IsSummon && value.Alive))
            {
                var target = entered.OrderBy(enemy => Vector2.Distance(ally.Position, enemy.Position)).FirstOrDefault();
                if (target != null) MoveToward(ally, target.Position, ally.PreferredRange, delta);
                else MoveToward(ally, Hero.Position, .9f, delta);
            }
            foreach (var enemy in entered)
            {
                var target = SelectEnemyTarget();
                if (target != null) MoveToward(enemy, target.Position, enemy.PreferredRange, delta);
            }
            ApplySeparation(allies.Where(value => value.Alive).Concat(entered).ToArray());
            KeepActorsInsideCombatViewport(entered);
        }

        private static void MoveToward(CommercialCombatant unit, Vector2 destination, float stopDistance, float delta)
        {
            var offset = destination - unit.Position;
            var distance = offset.magnitude;
            if (distance <= stopDistance || distance <= .001f) return;
            unit.Position += offset / distance * Mathf.Min(distance - stopDistance, unit.MoveSpeed * delta);
        }

        private void KeepActorsInsideCombatViewport(IEnumerable<CommercialCombatant> enteredEnemies)
        {
            // Camera follows Hero. This moving safe rectangle is the unobstructed world
            // area below the HUD and above the 3x3 board.
            var center = Hero.Position;
            foreach (var unit in allies.Where(value => value.IsSummon && value.Alive).Concat(enteredEnemies))
            {
                var radius = Mathf.Max(.18f, unit.PersonalRadius);
                unit.Position = new Vector2(
                    Mathf.Clamp(unit.Position.x, center.x - 2.42f + radius, center.x + 2.42f - radius),
                    Mathf.Clamp(unit.Position.y, center.y - .12f + radius, center.y + 3.25f - radius));
            }
        }

        private static void ApplySeparation(IReadOnlyList<CommercialCombatant> units)
        {
            for (var i = 0; i < units.Count; i++)
            for (var j = i + 1; j < units.Count; j++)
            {
                var a = units[i]; var b = units[j];
                var offset = b.Position - a.Position;
                var minimum = a.PersonalRadius + b.PersonalRadius;
                var distance = offset.magnitude;
                if (distance >= minimum) continue;
                var direction = distance > .001f ? offset / distance : new Vector2((i & 1) == 0 ? 1f : -1f, .2f).normalized;
                var correction = direction * ((minimum - distance) * .5f);
                a.Position -= correction; b.Position += correction;
            }
        }

        private void LaunchProjectile(CommercialCombatant source, CommercialCombatant target, float amount,
            Action<CommercialCombatant> afterImpact = null, float launchDelay = 0f,
            bool heroBasicAttack = false, int triggerId = 0,
            BattleVisualEventKind presentationKind = BattleVisualEventKind.Projectile)
        {
            var tags = source?.IsHero == true
                ? CommercialCardTag.BasicAttack | CommercialCardTag.Melee
                : source?.IsSummon == true ? CommercialCardTag.Summon : CommercialCardTag.None;
            LaunchProjectile(source?.Id, source?.GridIndex ?? -1, target, amount, afterImpact, source,
                launchDelay, tags, source != null && !source.Enemy, heroBasicAttack, triggerId, presentationKind);
        }

        private void LaunchProjectile(string sourceId, int sourceGrid, CommercialCombatant target, float amount,
            Action<CommercialCombatant> afterImpact = null, CommercialCombatant source = null,
            float launchDelay = 0f, CommercialCardTag tags = CommercialCardTag.None,
            bool allowCrit = true, bool heroBasicAttack = false, int triggerId = 0,
            BattleVisualEventKind presentationKind = BattleVisualEventKind.Projectile)
        {
            if (target == null || !target.Alive) return;
            var impact = new PendingImpact
            {
                Source = source,
                SourceId = sourceId,
                SourceGrid = sourceGrid,
                Target = target,
                Amount = amount,
                LaunchRemaining = Mathf.Max(0f, launchDelay),
                Remaining = ProjectileTravelDuration,
                Launched = launchDelay <= 0f,
                AfterImpact = afterImpact,
                Tags = tags,
                AllowCrit = allowCrit,
                HeroBasicAttack = heroBasicAttack,
                TriggerId = triggerId,
                PresentationKind = presentationKind
            };
            if (impact.Launched) EnqueueProjectile(impact);
            pendingImpacts.Add(impact);
        }

        private void EnqueueProjectile(PendingImpact impact)
        {
            visualEvents.Enqueue(new BattleVisualEvent(impact.PresentationKind, impact.SourceId,
                impact.Target?.Id, impact.Amount, impact.SourceGrid, impact.Target?.GridIndex ?? -1));
        }

        private void ResolvePendingImpacts(float delta)
        {
            for (var i = pendingImpacts.Count - 1; i >= 0; i--)
            {
                var impact = pendingImpacts[i];
                if (!impact.Launched)
                {
                    impact.LaunchRemaining -= delta;
                    if (impact.LaunchRemaining > 0f) continue;
                    impact.Launched = true;
                    impact.Remaining = ProjectileTravelDuration;
                    EnqueueProjectile(impact);
                    continue;
                }
                impact.Remaining -= delta;
                if (impact.Remaining > 0f) continue;
                pendingImpacts.RemoveAt(i);
                if (impact.Target == null || !impact.Target.Alive)
                {
                    if (impact.HeroBasicAttack)
                        domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.HeroBasicAttackEnded,
                            impact.SourceId, impact.Tags, impact.TriggerId));
                    continue;
                }
                var critical = ApplyDamage(impact.Source, impact.Target, impact.Amount, impact.SourceId, impact.SourceGrid,
                    impact.Tags, impact.AllowCrit, impact.TriggerId);
                if (impact.HeroBasicAttack)
                {
                    domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.HeroBasicAttackHit,
                        impact.SourceId, impact.Tags, impact.TriggerId, impact.Amount));
                    if (critical)
                        domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.HeroBasicAttackCrit,
                            impact.SourceId, impact.Tags, impact.TriggerId, impact.Amount));
                    domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.HeroBasicAttackEnded,
                        impact.SourceId, impact.Tags, impact.TriggerId, impact.Amount));
                }
                if (impact.Target.Alive) impact.AfterImpact?.Invoke(impact.Target);
            }
        }

        private bool ApplyDamage(CommercialCombatant source, CommercialCombatant target, float amount,
            string sourceIdOverride = null, int sourceGridOverride = -1,
            CommercialCardTag tags = CommercialCardTag.None, bool allowCrit = false, int triggerId = 0)
        {
            if (target == null || !target.Alive) return false;
            amount = Mathf.Max(0f, amount);
            var playerSource = target.Enemy && (source == null || !source.Enemy);
            var critical = allowCrit && playerSource && random.NextDouble() < characterSnapshot.CritChance;
            if (critical) amount *= characterSnapshot.CritDamage;
            amount *= 1f + target.Vulnerability;
            if (target.IsHero && target.Armor > 0f)
                amount *= 100f / (100f + target.Armor);
            var shieldDamage = Mathf.Min(target.Shield, amount);
            target.Shield -= shieldDamage;
            var healthDamage = Mathf.Max(0f, amount - shieldDamage);
            target.Health = Mathf.Max(0f, target.Health - healthDamage);
            var sourceId = sourceIdOverride ?? source?.Id;
            var sourceGrid = sourceGridOverride >= 0 ? sourceGridOverride : source?.GridIndex ?? -1;
            if (shieldDamage > 0f)
                visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Shield, sourceId, target.Id,
                    -shieldDamage, sourceGrid, target.GridIndex));
            if (healthDamage > 0f)
                visualEvents.Enqueue(new BattleVisualEvent(critical
                        ? BattleVisualEventKind.CriticalDamage : BattleVisualEventKind.Damage, sourceId, target.Id,
                    healthDamage, sourceGrid, target.GridIndex));
            if (critical)
                domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.CriticalHit,
                    sourceId, tags, triggerId, healthDamage));
            if (!target.Alive)
            {
                visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Defeat, sourceId, target.Id,
                    0f, sourceGrid, target.GridIndex));
                domainEvents.Publish(new CommercialDomainEvent(CommercialDomainEventType.UnitDefeated,
                    sourceId, tags, triggerId));
            }
            return critical;
        }

        private void Heal(CommercialCardRuntime source, CommercialCombatant target, float amount)
        {
            if (target == null || !target.Alive) return;
            var applied = Mathf.Min(amount, target.MaxHealth - target.Health);
            target.Health += applied;
            visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Heal, source?.Definition.Id,
                target.Id, applied, source?.GridIndex ?? -1, target.GridIndex));
        }

        private void HealLowestAlly(CommercialCardRuntime source, float amount)
        {
            var target = allies.Where(ally => ally.Alive).OrderBy(ally => ally.Health01).FirstOrDefault();
            Heal(source, target, amount);
        }

        private void AddShield(CommercialCardRuntime source, CommercialCombatant target, float amount)
        {
            target.Shield += Mathf.Max(0f, amount);
            visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.Shield, source?.Definition.Id,
                target.Id, amount, source?.GridIndex ?? -1, target.GridIndex));
        }

        private void End(CommercialBattleResult result)
        {
            if (Completed) return;
            Result = result;
            visualEvents.Enqueue(new BattleVisualEvent(BattleVisualEventKind.BattleEnded,
                string.Empty, string.Empty, (float)result, -1, -1));
        }

        private static bool AreAdjacent(int a, int b) =>
            Mathf.Abs(a / 3 - b / 3) + Mathf.Abs(a % 3 - b % 3) == 1;
    }
}

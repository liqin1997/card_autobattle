using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DefaultExecutionOrder(-300)]
    [DisallowMultipleComponent]
    public sealed class CommercialPrototypeController : MonoBehaviour
    {
        private enum ScreenTab { Backpack, Formation, City, Explore, Equipment, Activities }

        [SerializeField] private bool resetSaveOnStart;
        [SerializeField, Range(.5f, 8f)] private float battleSpeed = 2f;
        private readonly GameObject[] pages = new GameObject[6];
        private readonly Button[] navButtons = new Button[6];
        private readonly Image[] navBackgrounds = new Image[6];
        private readonly Text[] navLabels = new Text[6];
        private readonly Text[] navIcons = new Text[6];
        private readonly CommercialBattleCardView[] playerViews = new CommercialBattleCardView[9];
        private readonly CommercialBattleCardView[] enemyViews = new CommercialBattleCardView[9];
        private readonly Button[] formationSlots = new Button[9];
        private readonly Text[] formationSlotLabels = new Text[9];
        private readonly Button[] equipmentSlots = new Button[6];
        private readonly Text[] equipmentSlotLabels = new Text[6];
        private readonly Button[] inventoryButtons = new Button[12];
        private readonly Text[] inventoryLabels = new Text[12];

        private CommercialGameState state;
        private CommercialBattleSession battle;
        private CommercialFloatingTextPool floatingTextPool;
        private CommercialProjectilePool projectilePool;
        private RectTransform formationDragLayer;
        private RectTransform battleDragLayer;
        private GameObject battlePresentationRoot;
        private Camera battleEventCamera;
        private ScreenTab currentTab = ScreenTab.Explore;
        private string pendingDeployCardId;
        private float nextBattleDelay;
        private bool blocked;
        private float uiRefreshRemaining;
        private Text detailTitle;
        private Text detailBody;
        private Button detailActionButton;
        private Text detailActionLabel;
        private GameObject detailPopup;
        private GameObject professionPage;
        private CommercialProfessionId selectedProfession;
        private CommercialWorldEncounter worldEncounter;
        private bool worldMapMode;
        private bool battleSettled;
        private WorldNodeKind CurrentWorldKind => CommercialWorldCatalog.Find(state?.World?.CurrentNodeId)?.Kind ?? WorldNodeKind.Idle;
        public string CurrentWorldLocation => battle == null ? "灰烬森林 · 灰烬营地" :
            (CommercialWorldCatalog.Find(state.World.CurrentNodeId)?.Name ?? CommercialWorldCatalog.RegionNames[battle.Chapter - 1]) +
            (CurrentWorldKind == WorldNodeKind.Boss ? " · 首领挑战" : CurrentWorldKind == WorldNodeKind.Elite ? " · 精英遭遇" : " · 挂机中");

        public void SetWorldMapMode(bool visible)
        {
            worldMapMode = visible;
            FindDeep(transform, "StaticPageCanvas")?.gameObject.SetActive(!visible);
            FindDeep(transform, "NavigationCanvas")?.gameObject.SetActive(!visible);
            if (battlePresentationRoot) battlePresentationRoot.SetActive(!visible && currentTab == ScreenTab.Explore);
            if (visible) { CloseDetail(); GetComponent<CommercialEquipmentView>()?.CloseModals(); GetComponent<CommercialInventoryView>()?.CloseModals(); }
        }

        public void ReturnFromWorldMap() => SelectTab(currentTab);
        public void OpenEquipmentFromMap() => SelectTab(ScreenTab.Equipment);
        public bool AwaitingFirstQuest => state.World.Forest.Step == 0 && !state.World.Forest.Accepted && state.DropSequence == 0;

        public bool RequestWorldEncounter(string nodeId)
        {
            var encounter = CommercialWorldCatalog.CreateEncounter(state, nodeId);
            if (encounter == null) return false;
            // Replacing the session discards all pending impacts; an interrupted fight never settles.
            worldEncounter = encounter;
            if (encounter.Kind == WorldNodeKind.Idle) state.World.IdleNodeId = nodeId;
            if (battlePresentationRoot) battlePresentationRoot.SetActive(false);
            SelectTab(ScreenTab.Explore);
            StartNextBattle();
            CommercialSaveService.Save(state);
            return true;
        }

        private static readonly Color NavNormal = new(.035f, .055f, .07f, 1f);
        private static readonly Color NavSelected = new(.25f, .20f, .09f, 1f);
        private static readonly Color TextNormal = new(.57f, .69f, .75f, 1f);
        private static readonly Color TextSelected = new(1f, .80f, .33f, 1f);

        public CommercialGameState State => state;
        public CommercialBattleSession Battle => battle;
        public RectTransform FormationDragLayer => formationDragLayer;
        public Camera FormationEventCamera => null;
        public RectTransform BattleDragLayer => battleDragLayer;
        public Camera BattleEventCamera => battleEventCamera;

        private void Awake()
        {
            Application.runInBackground = true;
            if (resetSaveOnStart) CommercialSaveService.Reset();
            state = CommercialSaveService.Load();
            selectedProfession = state.Character.Profession;
            CacheHierarchy();
            BindNavigation();
            BindFormation();
            BindEquipment();
            BindProfession();
            BindCommonButtons();
        }

        private void Start()
        {
            SelectTab(ScreenTab.Explore);
            RefreshAllStaticUI();
            if (!AwaitingFirstQuest) StartNextBattle();
        }

        private void Update()
        {
            if (battle != null)
            {
                if (!battle.Completed)
                {
                    battle.Advance(Time.unscaledDeltaTime * battleSpeed);
                    ConsumeVisualEvents();
                    if (battle.Completed) ResolveBattle();
                }
                else if (!blocked && nextBattleDelay > 0f)
                {
                    nextBattleDelay -= Time.unscaledDeltaTime;
                    if (nextBattleDelay <= 0f) StartNextBattle();
                }

                // Keep presentation animation alive after battle logic completes so health
                // trails and final empty/dead states cannot freeze on stale values.
                RefreshBattleViews();
            }

            uiRefreshRemaining -= Time.unscaledDeltaTime;
            if (uiRefreshRemaining <= 0f)
            {
                uiRefreshRemaining = .15f;
                RefreshTopAndQuest();
                if (professionPage && professionPage.activeSelf) RefreshProfessionPage();
            }
        }

        private void CacheHierarchy()
        {
            var root = transform.root;
            var pageNames = new[] { "Page_Backpack", "Page_Formation", "Page_City", "Page_Explore", "Page_Equipment", "Page_Activities" };
            for (var i = 0; i < pages.Length; i++) pages[i] = FindDeep(root, pageNames[i])?.gameObject;
            for (var i = 0; i < navButtons.Length; i++)
            {
                var nav = FindDeep(root, $"Nav_{i}");
                navButtons[i] = nav?.GetComponent<Button>();
                navBackgrounds[i] = nav?.GetComponent<Image>();
                // Legacy buttons also contain an empty helper Label. Select the visible label.
                navLabels[i] = nav?.GetComponentsInChildren<Text>(true).FirstOrDefault(t => t.name == "Label" && !string.IsNullOrEmpty(t.text));
                navIcons[i] = FindDeep(nav, "Icon")?.GetComponent<Text>();
            }
            for (var i = 0; i < 9; i++)
            {
                playerViews[i] = FindDeep(root, $"PlayerCard_{i}")?.GetComponent<CommercialBattleCardView>();
                enemyViews[i] = FindDeep(root, $"EnemyCard_{i}")?.GetComponent<CommercialBattleCardView>();
                var slot = FindDeep(root, $"FormationSlot_{i}");
                formationSlots[i] = slot?.GetComponent<Button>();
                formationSlotLabels[i] = FindDeep(slot, "Label")?.GetComponent<Text>();
            }
            for (var i = 0; i < 6; i++)
            {
                var slot = FindDeep(root, $"EquipmentSlot_{i}");
                equipmentSlots[i] = slot?.GetComponent<Button>();
                equipmentSlotLabels[i] = FindDeep(slot, "Label")?.GetComponent<Text>();
            }
            for (var i = 0; i < inventoryButtons.Length; i++)
            {
                var item = FindDeep(root, $"Inventory_{i:00}");
                inventoryButtons[i] = item?.GetComponent<Button>();
                inventoryLabels[i] = FindDeep(item, "Label")?.GetComponent<Text>();
            }
            floatingTextPool = FindDeep(root, "DamageTextLayer")?.GetComponent<CommercialFloatingTextPool>();
            var projectileLayer = FindDeep(root, "ProjectileLayer");
            if (projectileLayer)
                projectilePool = projectileLayer.GetComponent<CommercialProjectilePool>() ??
                                 projectileLayer.gameObject.AddComponent<CommercialProjectilePool>();
            formationDragLayer = FindDeep(root, "FormationDragLayer") as RectTransform ??
                                 FindDeep(root, "PopupCanvas") as RectTransform;
            battleDragLayer = FindDeep(root, "BattleDragLayer") as RectTransform ??
                              FindDeep(root, "PopupCanvas") as RectTransform;
            battlePresentationRoot = FindDeep(root, "BattlePresentationRoot")?.gameObject;
            battleEventCamera = FindDeep(root, "BattleUICamera")?.GetComponent<Camera>();
            detailPopup = FindDeep(root, "CardDetailPopup")?.gameObject;
            detailTitle = FindDeep(detailPopup?.transform, "DetailTitle")?.GetComponent<Text>();
            detailBody = FindDeep(detailPopup?.transform, "DetailBody")?.GetComponent<Text>();
            detailActionButton = FindDeep(detailPopup?.transform, "DetailAction")?.GetComponent<Button>();
            detailActionLabel = FindDeep(detailActionButton?.transform, "Label")?.GetComponent<Text>();
            professionPage = FindDeep(root, "Page_Profession")?.gameObject;
            if (detailPopup) detailPopup.SetActive(false);
            if (professionPage) professionPage.SetActive(false);
        }

        private void BindNavigation()
        {
            for (var i = 0; i < navButtons.Length; i++)
            {
                var index = i;
                navButtons[i]?.onClick.AddListener(() => SelectTab((ScreenTab)index));
            }
        }

        private void BindFormation()
        {
            for (var i = 0; i < CommercialCardCatalog.All.Count; i++)
            {
                var definition = CommercialCardCatalog.All[i];
                var button = FindDeep(transform.root, $"LibraryCard_{i:00}")?.GetComponent<Button>();
                var label = FindDeep(button?.transform, "Label")?.GetComponent<Text>();
                if (label) label.text = $"{definition.DisplayName}\n{TypeName(definition.Type)} · {(definition.Type == CommercialCardType.Passive ? "常驻" : $"{definition.Cooldown:0.0}s")}";
                button?.onClick.AddListener(() => ShowCardDetail(definition, true));
                ConfigureDrag(button, definition.Id, -1);
            }
            var heroButton = FindDeep(transform.root, "HeroLibraryButton")?.GetComponent<Button>();
            heroButton?.onClick.AddListener(ShowHeroDeployDetail);
            ConfigureDrag(heroButton, CommercialGameState.HeroCardId, -1);
            for (var i = 0; i < formationSlots.Length; i++)
            {
                var index = i;
                formationSlots[i]?.onClick.AddListener(() => ClickFormationSlot(index));
                ConfigureDrag(formationSlots[i], null, index);
            }
            FindDeep(transform.root, "ClearFormationSelection")?.GetComponent<Button>()?.onClick
                .AddListener(() => pendingDeployCardId = null);
        }

        private void BindEquipment()
        {
            if (GetComponent<CommercialEquipmentView>()) return;
            for (var i = 0; i < equipmentSlots.Length; i++)
            {
                var slot = (EquipmentSlot)i;
                equipmentSlots[i]?.onClick.AddListener(() =>
                {
                    state.Unequip(slot);
                    CommercialSaveService.Save(state);
                    RefreshEquipmentPage();
                });
            }
            for (var i = 0; i < inventoryButtons.Length; i++)
            {
                var index = i;
                inventoryButtons[i]?.onClick.AddListener(() =>
                {
                    if (index >= state.Inventory.Count) return;
                    state.Equip(state.Inventory[index]);
                    CommercialSaveService.Save(state);
                    RefreshEquipmentPage();
                });
            }
        }

        private void BindProfession()
        {
            FindDeep(transform.root, "TopProfessionButton")?.GetComponent<Button>()?.onClick
                .AddListener(OpenProfessionPage);
            FindDeep(transform.root, "CloseProfessionPanel")?.GetComponent<Button>()?.onClick
                .AddListener(CloseProfessionPage);

            foreach (CommercialProfessionId profession in Enum.GetValues(typeof(CommercialProfessionId)))
            {
                var captured = profession;
                FindDeep(transform.root, $"ProfessionButton_{profession}")?.GetComponent<Button>()?.onClick
                    .AddListener(() =>
                    {
                        selectedProfession = captured;
                        RefreshProfessionPage();
                    });
            }

            var attributeNames = new[] { "Strength", "Dexterity", "Intelligence", "Vitality" };
            for (var i = 0; i < attributeNames.Length; i++)
            {
                var captured = (CommercialAttributeType)i;
                FindDeep(transform.root, $"AddAttribute_{attributeNames[i]}")?.GetComponent<Button>()?.onClick
                    .AddListener(() =>
                    {
                        if (!state.TryAllocateAttribute(captured)) return;
                        CommercialSaveService.Save(state);
                        RefreshAllStaticUI();
                        RefreshProfessionPage();
                    });
            }

            FindDeep(transform.root, "ProfessionSwitchButton")?.GetComponent<Button>()?.onClick
                .AddListener(() =>
                {
                    if (state.Character.Profession == selectedProfession) return;
                    state.SwitchProfession(selectedProfession);
                    CommercialSaveService.Save(state);
                    RefreshAllStaticUI();
                    RefreshProfessionPage();
                });
        }

        private void OpenProfessionPage()
        {
            GetComponent<CommercialEquipmentView>()?.CloseModals();
            GetComponent<CommercialInventoryView>()?.CloseModals();
            GetComponent<CommercialWorldMapView>()?.Hide();
            SetWorldMapMode(false);
            if (!professionPage) return;
            selectedProfession = state.Character.Profession;
            for (var i = 0; i < pages.Length; i++) if (pages[i]) pages[i].SetActive(false);
            if (battlePresentationRoot) battlePresentationRoot.SetActive(false);
            professionPage.SetActive(true);
            RefreshProfessionPage();
        }

        private void CloseProfessionPage()
        {
            if (professionPage) professionPage.SetActive(false);
            SelectTab(currentTab);
        }

        private void BindCommonButtons()
        {
            FindDeep(transform.root, "CloseDetail")?.GetComponent<Button>()?.onClick.AddListener(CloseDetail);
            FindDeep(transform.root, "RetryBattleButton")?.GetComponent<Button>()?.onClick.AddListener(() =>
            {
                blocked = false;
                StartNextBattle();
            });
            FindDeep(transform.root, "ResetPrototypeButton")?.GetComponent<Button>()?.onClick.AddListener(() =>
            {
                CommercialSaveService.Reset();
                state = CommercialGameState.CreateDefault();
                worldEncounter = null;
                battle = null;
                nextBattleDelay = 0f;
                blocked = false;
                RefreshAllStaticUI();
                CommercialWorldCatalog.RevealRegion(state, 1);
                CommercialSaveService.Save(state);
                var map = GetComponent<CommercialWorldMapView>();
                if (map) { map.Open(); map.FocusNode("quest_1"); }
            });
        }

        private void SelectTab(ScreenTab tab)
        {
            GetComponent<CommercialEquipmentView>()?.CloseModals();
            GetComponent<CommercialInventoryView>()?.CloseModals();
            GetComponent<CommercialWorldMapView>()?.Hide();
            SetWorldMapMode(false);
            currentTab = tab;
            if (professionPage) professionPage.SetActive(false);
            for (var i = 0; i < pages.Length; i++) if (pages[i]) pages[i].SetActive(i == (int)tab);
            if (battlePresentationRoot) battlePresentationRoot.SetActive(tab == ScreenTab.Explore);
            for (var i = 0; i < navButtons.Length; i++)
            {
                var selected = i == (int)tab;
                if (navBackgrounds[i]) navBackgrounds[i].color = selected ? NavSelected : NavNormal;
                if (navLabels[i]) navLabels[i].color = selected ? TextSelected : TextNormal;
                if (navIcons[i]) navIcons[i].color = selected ? TextSelected : TextNormal;
            }
            if (tab == ScreenTab.Formation) RefreshFormationPage();
            if (tab == ScreenTab.Equipment) RefreshEquipmentPage();
            if (tab == ScreenTab.Backpack) GetComponent<CommercialInventoryView>()?.Refresh();
            if (tab == ScreenTab.Explore) RefreshBattleViews();
        }

        private void StartNextBattle()
        {
            battleSettled = false;
            nextBattleDelay = 0f;
            blocked = false;
            CommercialWorldCatalog.RevealRegion(state, 1);
            worldEncounter ??= CommercialWorldCatalog.CreateEncounter(state, state.World.IdleNodeId) ??
                               CommercialWorldCatalog.CreateEncounter(state, "main_1");
            state.World.CurrentNodeId = worldEncounter.NodeId;
            CommercialWorldCatalog.RevealRegion(state, worldEncounter.Chapter);
            battle = new CommercialBattleSession(state, state.DraftFormation,
                17041 + state.GlobalStage * 7919 + state.DropSequence, worldEncounter);
            BindBattleViews();
            RefreshBattleViews();
            SetText("BattleStatus", "战斗中");
            SetText("BattleResultHint", string.Empty);
            var retry = FindDeep(transform.root, "RetryBattleButton")?.gameObject;
            if (retry) retry.SetActive(false);
        }

        private void ResolveBattle()
        {
            if (battleSettled || battle == null || !battle.Completed) return;
            battleSettled = true;
            if (battle.Result == CommercialBattleResult.Victory)
            {
                CommercialWorldCatalog.RecordVictory(state, worldEncounter);
                CommercialSaveService.Save(state);
                SetText("BattleStatus", "胜利");
                SetText("BattleResultHint", "战斗奖励已入账 · 继续区域挂机");
                if (worldEncounter.Kind != WorldNodeKind.Idle) worldEncounter = null;
                nextBattleDelay = 1.25f;
                RefreshAllStaticUI();
            }
            else
            {
                blocked = true;
                SetText("BattleStatus", "战力受阻");
                SetText("BattleResultHint", "战力受阻：换装、升级后重试，或前往地图选择其他区域");
                var retry = FindDeep(transform.root, "RetryBattleButton")?.gameObject;
                if (retry) retry.SetActive(true);
                if (worldEncounter != null && worldEncounter.Kind != WorldNodeKind.Idle)
                {
                    worldEncounter = null;
                    blocked = false;
                    nextBattleDelay = 3f;
                    SetText("BattleResultHint", "挑战失败 · 即将恢复原区域挂机");
                }
            }
        }

        private void BindBattleViews(IReadOnlyDictionary<string, float> previousValues = null)
        {
            for (var i = 0; i < 9; i++)
            {
                var playerIndex = i;
                var ally = battle.GetAllyAt(i);
                var card = battle.GetCardAt(i);
                if (ally?.IsHero == true)
                {
                    playerViews[i]?.BindHero(ally, i, () => ShowHeroBattleDetail());
                    playerViews[i]?.SetPrimaryValue(ally.Attack, CommercialPrimaryValueKind.Damage);
                }
                else if (card != null)
                {
                    playerViews[i]?.BindCard(card, i, () => ShowCardDetail(card.Definition, false));
                    var previous = 0f;
                    var hasPrevious = previousValues != null &&
                                      previousValues.TryGetValue(card.Definition.Id, out previous);
                    playerViews[i]?.SetPrimaryValue(battle.GetCurrentResolvedPower(i),
                        PrimaryValueKind(card.Definition), hasPrevious ? (float?)previous : null);
                }
                else if (playerViews[i]) playerViews[i].gameObject.SetActive(false);
                ConfigureBattleDrag(playerViews[i], playerIndex);

                var enemy = battle.GetEnemyAt(i);
                if (enemy != null)
                {
                    enemyViews[i]?.BindEnemy(enemy, i, () => ShowEnemyDetail(enemy));
                    enemyViews[i]?.SetPrimaryValue(enemy.Attack, CommercialPrimaryValueKind.Damage);
                }
                else if (enemyViews[i]) enemyViews[i].gameObject.SetActive(false);
            }
        }

        private void RefreshBattleViews()
        {
            foreach (var view in playerViews) view?.Refresh();
            foreach (var view in enemyViews) view?.Refresh();
            if (battle == null) return;
            SetText("LivingEnemyCount", $"{battle.LivingEnemyCount} / {battle.Enemies.Count}");
            SetText("BattleTimer", $"{battle.Elapsed:00.0}s");
            var progress = FindDeep(transform.root, "StageProgressFill")?.GetComponent<Image>();
            if (progress) progress.fillAmount = Mathf.Clamp01((state.Stage - 1) / 20f);
        }

        private void ConsumeVisualEvents()
        {
            while (battle.TryDequeueVisualEvent(out var value))
            {
                var view = FindBattleView(value.TargetId, value.TargetGrid);
                var sourceView = FindBattleView(value.SourceId, value.SourceGrid);
                if (value.Kind == BattleVisualEventKind.Projectile)
                {
                    var enemySource = value.SourceId != null && value.SourceId.StartsWith("enemy_", StringComparison.Ordinal);
                    projectilePool?.Play(sourceView ? (RectTransform)sourceView.transform : null,
                        view ? (RectTransform)view.transform : null,
                        enemySource ? new Color(1f, .25f, .18f) : new Color(.18f, 1f, .86f));
                }
                if ((value.Kind == BattleVisualEventKind.Damage ||
                     value.Kind == BattleVisualEventKind.CriticalDamage) && value.Amount > 0f)
                {
                    floatingTextPool?.Show(view ? (RectTransform)view.transform : null,
                        value.Kind == BattleVisualEventKind.CriticalDamage
                            ? $"暴击 -{Mathf.CeilToInt(value.Amount)}"
                            : $"-{Mathf.CeilToInt(value.Amount)}",
                        value.Kind == BattleVisualEventKind.CriticalDamage
                            ? new Color(1f, .82f, .22f)
                            : new Color(1f, .35f, .30f));
                    if (view)
                    {
                        var direction = sourceView
                            ? (Vector2)(view.transform.position - sourceView.transform.position)
                            : Vector2.down;
                        view.ReceiveHit(direction);
                    }
                }
                else if (value.Kind == BattleVisualEventKind.Heal && value.Amount > 0f)
                    floatingTextPool?.Show(view ? (RectTransform)view.transform : null,
                        $"+{Mathf.CeilToInt(value.Amount)}", new Color(.30f, 1f, .62f));
                else if (value.Kind == BattleVisualEventKind.Shield && Mathf.Abs(value.Amount) > .01f)
                    floatingTextPool?.Show(view ? (RectTransform)view.transform : null,
                        value.Amount > 0f
                            ? $"盾 +{Mathf.CeilToInt(value.Amount)}"
                            : $"盾 -{Mathf.CeilToInt(-value.Amount)}",
                        value.Amount > 0f ? new Color(.28f, .82f, 1f) : new Color(.34f, .64f, 1f));
                if (value.Kind == BattleVisualEventKind.Action) sourceView?.FlashAction();
            }
        }

        public bool CanBeginBattleDrag(CommercialBattleBoardDragItem item)
        {
            if (!item || worldMapMode || currentTab != ScreenTab.Explore || battle == null || battle.Completed) return false;
            var grid = item.SourceGrid;
            return grid >= 0 && grid < 9 &&
                   (battle.Hero.GridIndex == grid || battle.GetCardAt(grid) != null);
        }

        public void BeginBattleDrag(CommercialBattleBoardDragItem item)
        {
            SetText("PlayerRule", "战斗中可拖拽换位 · 效果立即重算");
        }

        public void EndBattleDrag(CommercialBattleBoardDragItem item, Vector2 screenPosition)
        {
            var target = FindBattleDropTarget(screenPosition);
            var previousValues = battle?.Cards.ToDictionary(card => card.Definition.Id,
                card => battle.GetCurrentResolvedPower(card.GridIndex));
            var changed = target >= 0 && battle != null &&
                          battle.TrySwapPlayerGridPositions(item.SourceGrid, target);
            SetText("PlayerRule", "主角阵亡即失败");
            if (!changed)
            {
                RefreshBattleViews();
                return;
            }
            BindBattleViews(previousValues);
            RefreshBattleViews();
            StartCoroutine(PunchBattleSlot(target));
        }

        private int FindBattleDropTarget(Vector2 screenPosition)
        {
            var nearest = -1;
            var nearestDistance = float.MaxValue;
            for (var i = 0; i < playerViews.Length; i++)
            {
                if (!playerViews[i]) continue;
                var rect = (RectTransform)playerViews[i].transform;
                if (RectTransformUtility.RectangleContainsScreenPoint(rect, screenPosition, BattleEventCamera))
                    return i;
                var screen = RectTransformUtility.WorldToScreenPoint(BattleEventCamera, rect.position);
                var distance = Vector2.Distance(screenPosition, screen);
                if (distance >= nearestDistance) continue;
                nearestDistance = distance;
                nearest = i;
            }
            var canvas = playerViews.FirstOrDefault(view => view)?.GetComponentInParent<Canvas>();
            return nearestDistance <= 105f * (canvas ? canvas.scaleFactor : 1f) ? nearest : -1;
        }

        private void ConfigureBattleDrag(CommercialBattleCardView view, int gridIndex)
        {
            if (!view) return;
            if (!view.TryGetComponent<CanvasGroup>(out var group)) group = view.gameObject.AddComponent<CanvasGroup>();
            group.alpha = 1f;
            group.blocksRaycasts = true;
            var drag = view.GetComponent<CommercialBattleBoardDragItem>() ??
                       view.gameObject.AddComponent<CommercialBattleBoardDragItem>();
            drag.Configure(this, gridIndex);
        }

        private IEnumerator PunchBattleSlot(int index)
        {
            if (index < 0 || index >= playerViews.Length || !playerViews[index]) yield break;
            var rect = (RectTransform)playerViews[index].transform;
            for (var elapsed = 0f; elapsed < .18f; elapsed += Time.unscaledDeltaTime)
            {
                var t = elapsed / .18f;
                rect.localScale = Vector3.one * (1f + Mathf.Sin(t * Mathf.PI) * .10f);
                yield return null;
            }
            rect.localScale = Vector3.one;
        }

        private CommercialBattleCardView FindBattleView(string runtimeId, int gridIndex)
        {
            if (runtimeId == CommercialGameState.HeroCardId)
                return playerViews.FirstOrDefault(candidate => candidate && candidate.GridIndex == battle.Hero.GridIndex);
            if (!string.IsNullOrEmpty(runtimeId) && runtimeId.StartsWith("enemy_", StringComparison.Ordinal))
                return enemyViews.FirstOrDefault(candidate => candidate && candidate.GridIndex == gridIndex);
            return playerViews.FirstOrDefault(candidate => candidate && candidate.GridIndex == gridIndex);
        }

        private void ClickFormationSlot(int index)
        {
            if (!string.IsNullOrEmpty(pendingDeployCardId))
            {
                ApplyLibraryDrop(pendingDeployCardId, index);
                pendingDeployCardId = null;
                return;
            }
            var id = state.DraftFormation.Slots[index];
            if (id == CommercialGameState.HeroCardId) ShowHeroDeployDetail();
            else if (!string.IsNullOrEmpty(id)) ShowCardDetail(CommercialCardCatalog.Get(id), true);
        }

        public bool CanBeginFormationDrag(CommercialFormationDragItem item)
        {
            if (!item) return false;
            if (item.FormationIndex < 0) return !string.IsNullOrEmpty(item.LibraryCardId);
            return item.FormationIndex < state.DraftFormation.Slots.Length &&
                   !string.IsNullOrEmpty(state.DraftFormation.Slots[item.FormationIndex]);
        }

        public void BeginFormationDrag(CommercialFormationDragItem item)
        {
            var cardId = item.FormationIndex >= 0
                ? state.DraftFormation.Slots[item.FormationIndex]
                : item.LibraryCardId;
            for (var i = 0; i < formationSlots.Length; i++)
            {
                if (formationSlots[i]?.targetGraphic is not Image image) continue;
                var invalidHeroReplacement = state.DraftFormation.Slots[i] == CommercialGameState.HeroCardId &&
                                             cardId != CommercialGameState.HeroCardId &&
                                             !HasHeroRelocationSlot(cardId, i);
                image.color = invalidHeroReplacement
                    ? new Color(.30f, .08f, .09f, 1f)
                    : new Color(.08f, .32f, .34f, 1f);
            }
        }

        public void EndFormationDrag(CommercialFormationDragItem item, Vector2 screenPosition)
        {
            var target = FindFormationDropTarget(screenPosition);
            var changed = false;
            if (target >= 0)
            {
                if (item.FormationIndex >= 0)
                    changed = ApplyFormationMove(item.FormationIndex, target);
                else
                    changed = ApplyLibraryDrop(item.LibraryCardId, target);
            }
            RestoreFormationSlotColors();
            if (changed) StartCoroutine(PunchFormationSlot(target));
            else RefreshFormationPage();
        }

        private bool ApplyFormationMove(int source, int target)
        {
            if (source < 0 || source >= 9 || target < 0 || target >= 9 || source == target) return false;
            var moving = state.DraftFormation.Slots[source];
            if (string.IsNullOrEmpty(moving)) return false;
            var displaced = state.DraftFormation.Slots[target];
            state.DraftFormation.Slots[target] = moving;
            state.DraftFormation.Slots[source] = displaced;
            SaveFormationChange();
            return true;
        }

        private bool ApplyLibraryDrop(string cardId, int target)
        {
            if (string.IsNullOrEmpty(cardId) || target < 0 || target >= 9) return false;
            var existing = Array.IndexOf(state.DraftFormation.Slots, cardId);
            var displaced = state.DraftFormation.Slots[target];
            if (existing == target) return false;

            var heroRelocation = -1;
            if (displaced == CommercialGameState.HeroCardId && cardId != CommercialGameState.HeroCardId)
            {
                heroRelocation = existing >= 0 ? existing : FirstEmptyFormationSlot(target);
                if (heroRelocation < 0) return false;
            }

            if (existing >= 0) state.DraftFormation.Slots[existing] = null;
            if (heroRelocation >= 0) state.DraftFormation.Slots[heroRelocation] = CommercialGameState.HeroCardId;
            state.DraftFormation.Slots[target] = cardId;
            SaveFormationChange();
            return true;
        }

        private void SaveFormationChange()
        {
            pendingDeployCardId = null;
            CommercialSaveService.Save(state);
            RefreshFormationPage();
        }

        private int FindFormationDropTarget(Vector2 screenPosition)
        {
            var nearest = -1;
            var nearestDistance = float.MaxValue;
            for (var i = 0; i < formationSlots.Length; i++)
            {
                if (!formationSlots[i]) continue;
                var rect = (RectTransform)formationSlots[i].transform;
                if (RectTransformUtility.RectangleContainsScreenPoint(rect, screenPosition, FormationEventCamera))
                    return i;
                var screen = RectTransformUtility.WorldToScreenPoint(FormationEventCamera, rect.position);
                var distance = Vector2.Distance(screenPosition, screen);
                if (distance >= nearestDistance) continue;
                nearestDistance = distance;
                nearest = i;
            }
            var canvas = formationSlots.FirstOrDefault(button => button)?.GetComponentInParent<Canvas>();
            return nearestDistance <= 100f * (canvas ? canvas.scaleFactor : 1f) ? nearest : -1;
        }

        private bool HasHeroRelocationSlot(string incomingCardId, int target)
        {
            return Array.IndexOf(state.DraftFormation.Slots, incomingCardId) >= 0 ||
                   FirstEmptyFormationSlot(target) >= 0;
        }

        private int FirstEmptyFormationSlot(int excluded)
        {
            for (var i = 0; i < state.DraftFormation.Slots.Length; i++)
                if (i != excluded && string.IsNullOrEmpty(state.DraftFormation.Slots[i])) return i;
            return -1;
        }

        private IEnumerator PunchFormationSlot(int index)
        {
            if (index < 0 || index >= formationSlots.Length || !formationSlots[index]) yield break;
            var rect = (RectTransform)formationSlots[index].transform;
            for (var elapsed = 0f; elapsed < .16f; elapsed += Time.unscaledDeltaTime)
            {
                var t = elapsed / .16f;
                rect.localScale = Vector3.one * (1f + Mathf.Sin(t * Mathf.PI) * .09f);
                yield return null;
            }
            rect.localScale = Vector3.one;
        }

        private void RestoreFormationSlotColors()
        {
            foreach (var button in formationSlots)
                if (button?.targetGraphic is Image image) image.color = new Color(.06f, .15f, .17f, 1f);
        }

        private void ConfigureDrag(Button button, string libraryCardId, int sourceIndex)
        {
            if (!button) return;
            if (!button.TryGetComponent<CanvasGroup>(out var group)) group = button.gameObject.AddComponent<CanvasGroup>();
            group.alpha = 1f;
            group.blocksRaycasts = true;
            var drag = button.GetComponent<CommercialFormationDragItem>() ??
                       button.gameObject.AddComponent<CommercialFormationDragItem>();
            drag.Configure(this, libraryCardId, sourceIndex);
        }

        private void RefreshFormationPage()
        {
            for (var i = 0; i < 9; i++)
            {
                var id = state.DraftFormation.Slots[i];
                if (formationSlotLabels[i]) formationSlotLabels[i].text = id == CommercialGameState.HeroCardId
                    ? $"主角\n{CommercialCharacterCalculator.BuildSnapshot(state).HeroAttackInterval:0.0}s · 含生命条"
                    : CommercialCardCatalog.Get(id) is { } card
                        ? $"{card.DisplayName}\n{TypeName(card.Type)}"
                        : "空部署位";
            }
            SetText("FormationHint", string.IsNullOrEmpty(pendingDeployCardId)
                ? "点击卡牌查看详情；从详情选择部署，再点击3×3格子"
                : $"已选择：{(pendingDeployCardId == CommercialGameState.HeroCardId ? "主角" : CommercialCardCatalog.Get(pendingDeployCardId)?.DisplayName)}，请选择格子");
        }

        private void RefreshEquipmentPage()
        {
            var equipmentView = GetComponent<CommercialEquipmentView>();
            if (equipmentView) { equipmentView.Refresh(); return; }
            for (var i = 0; i < 6; i++)
            {
                var slot = (EquipmentSlot)i;
                var item = state.GetEquipped(slot);
                if (equipmentSlotLabels[i]) equipmentSlotLabels[i].text = item == null
                    ? $"{SlotName(slot)}\n未装备"
                    : $"{SlotName(slot)}\n{item.DisplayName}\n战力 {item.Power:0}";
                if (equipmentSlots[i]?.targetGraphic is Image image)
                    image.color = item == null ? new Color(.06f, .09f, .12f) : EquipmentGenerator.RarityColor(item.Rarity) * .52f;
            }
            for (var i = 0; i < inventoryButtons.Length; i++)
            {
                var visible = i < state.Inventory.Count;
                if (inventoryButtons[i]) inventoryButtons[i].gameObject.SetActive(visible);
                if (!visible) continue;
                var item = state.Inventory[i];
                if (inventoryLabels[i]) inventoryLabels[i].text = $"{item.DisplayName}\nLv.{item.ItemLevel} · 战力 {item.Power:0}";
                if (inventoryButtons[i].targetGraphic is Image image) image.color = EquipmentGenerator.RarityColor(item.Rarity) * .42f;
            }
            SetText("PlayerPower", $"主角 Lv.{state.PlayerLevel}  ·  战力 {state.CombatPower:0}");
        }

        private void RefreshAllStaticUI()
        {
            RefreshFormationPage();
            RefreshEquipmentPage();
            RefreshTopAndQuest();
            GetComponent<CommercialInventoryView>()?.Refresh();
            if (professionPage && professionPage.activeSelf) RefreshProfessionPage();
        }

        public void NotifyEquipmentChanged()
        {
            // Current session owns an immutable stat snapshot. Never restart it on a gear change.
            CommercialSaveService.Save(state);
            RefreshAllStaticUI();
        }

        private void RefreshTopAndQuest()
        {
            state.EnsureCharacterData();
            var profession = CommercialProfessionCatalog.Get(state.Character.Profession);
            SetText("ResourceEnergy", state.Gems.ToString());
            SetText("ResourceGold", state.Gold.ToString());
            SetText("ResourcePremium", state.PremiumCurrency.ToString());
            SetText("LocationTitle", CurrentWorldLocation);
            SetText("TopProfessionAvatar", ProfessionGlyph(profession.Id));
            SetText("TopProfessionName", $"{profession.DisplayName} · {profession.PathName}");
            SetText("TopProfessionLevel", $"Lv.{state.PlayerLevel}");
            SetText("TopProfessionExpText", $"EXP {state.Experience}/{state.ExperienceToNextLevel}");
            SetImageAnchorProgress("TopProfessionExpFill",
                state.Experience / (float)Mathf.Max(1, state.ExperienceToNextLevel));
            var task = CommercialWorldCatalog.CurrentMainQuest(state);
            var tracked = state.World.Quests.FirstOrDefault(q => q.Id == state.World.TrackedQuestId && !q.Claimed);
            SetText("MainQuestTitle", tracked != null ? "支线 · 讨伐巡游精英" : task == null ? "区域任务已完成" : "主线 · 探索" + CommercialWorldCatalog.RegionNames[task.Chapter - 1]);
            SetText("MainQuestProgress", tracked != null ? (tracked.Completed ? "已完成 · 点击领取奖励" : "击败精英 0/1 · 点击追踪") :
                task == null ? "全部完成" : $"挂机 {task.IdleWins}/5 · 首领 {(task.BossDefeated ? 1 : 0)}/1\n" + (task.Ready ? "可领奖 · 解锁新区域" : "点击查看任务"));
            if (!CommercialAshenForest.Finished(state) || CommercialWorldCatalog.Find(state.World.CurrentNodeId)?.Chapter == 1)
            {
                SetText("MainQuestTitle", "主线 · " + CommercialAshenForest.Title(state));
                SetText("MainQuestProgress", CommercialAshenForest.Progress(state));
            }
        }

        private void RefreshProfessionPage()
        {
            if (!professionPage) return;
            state.EnsureCharacterData();
            var current = state.Character.Profession;
            var definition = CommercialProfessionCatalog.Get(selectedProfession);
            var snapshot = CommercialCharacterCalculator.BuildSnapshot(state, selectedProfession);

            foreach (CommercialProfessionId profession in Enum.GetValues(typeof(CommercialProfessionId)))
            {
                var button = FindDeep(professionPage.transform, $"ProfessionButton_{profession}")?.GetComponent<Button>();
                if (!button) continue;
                var selected = profession == selectedProfession;
                var equipped = profession == current;
                button.image.color = selected
                    ? CommercialProfessionCatalog.Get(profession).Accent * .82f
                    : new Color(.11f, .11f, .10f, 1f);
                var label = button.GetComponentInChildren<Text>();
                if (label) label.text = ProfessionCardText(profession) + (equipped ? "\n当前" : string.Empty);
            }

            SetText("AvailableAttributePoints", $"可用点数 {state.AvailableAttributePoints}");
            SetText("AttributeValue_Strength", snapshot.Strength.ToString());
            SetText("AttributeValue_Dexterity", snapshot.Dexterity.ToString());
            SetText("AttributeValue_Intelligence", snapshot.Intelligence.ToString());
            SetText("AttributeValue_Vitality", snapshot.Vitality.ToString());
            SetText("ProfessionDerivedAP", snapshot.AbilityPower.ToString("0.0"));
            SetText("ProfessionDerivedHP", snapshot.MaxHealth.ToString("0"));
            SetText("ProfessionDerivedArmor", snapshot.Armor.ToString("0.0"));
            SetText("ProfessionDerivedCrit", $"{snapshot.CritChance * 100f:0.0}%");
            SetText("ProfessionDerivedAttackInterval", $"{snapshot.HeroAttackInterval:0.00}s");
            SetText("ProfessionDerivedPower",
                CommercialCharacterCalculator.CombatPower(state, selectedProfession).ToString("0"));

            SetText("ProfessionPreviewName", $"{definition.DisplayName} · {definition.PathName}");
            SetText("ProfessionResourceName", $"职业资源：{definition.ResourceName}");
            SetText("ProfessionTriggerDescription", definition.TriggerDescription);
            SetText("ProfessionReadyDescription", definition.ReadyDescription);
            var currentRuntime = battle != null && battle.CharacterSnapshot.Profession == selectedProfession
                ? battle.ProfessionRuntime : null;
            var resource = currentRuntime?.Resource ?? 0;
            SetImageAnchorProgress("ProfessionResourceProgress", resource / (float)Mathf.Max(1, definition.MaxResource));
            SetText("ProfessionResourceProgressText", $"{resource} / {definition.MaxResource}");

            var switchButton = FindDeep(professionPage.transform, "ProfessionSwitchButton")?.GetComponent<Button>();
            if (switchButton)
            {
                switchButton.interactable = selectedProfession != current;
                var label = switchButton.GetComponentInChildren<Text>();
                if (label) label.text = selectedProfession == current ? "当前职业" : "设为当前职业 · 下一场生效";
            }
            var addNames = new[] { "Strength", "Dexterity", "Intelligence", "Vitality" };
            foreach (var name in addNames)
            {
                var button = FindDeep(professionPage.transform, $"AddAttribute_{name}")?.GetComponent<Button>();
                if (button) button.interactable = state.AvailableAttributePoints > 0;
            }
        }

        private void SetImageAnchorProgress(string objectName, float progress)
        {
            var image = FindDeep(transform.root, objectName)?.GetComponent<Image>();
            if (!image) return;
            var rect = image.rectTransform;
            rect.anchorMin = Vector2.zero;
            rect.anchorMax = new Vector2(Mathf.Clamp01(progress), 1f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
        }

        private static string ProfessionGlyph(CommercialProfessionId profession) => profession switch
        {
            CommercialProfessionId.Ranger => "游",
            CommercialProfessionId.Mage => "法",
            _ => "战"
        };

        private static string ProfessionCardText(CommercialProfessionId profession) => profession switch
        {
            CommercialProfessionId.Ranger => "游侠\n逐风\n投射物积累精准",
            CommercialProfessionId.Mage => "法师\n秘仪\n魔法积累共鸣",
            _ => "战士\n铁誓\n普攻积累怒气"
        };

        private void ShowCardDetail(CommercialCardDefinition definition, bool allowDeploy)
        {
            if (definition == null || !detailPopup) return;
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = definition.DisplayName;
            if (detailBody) detailBody.text = $"类型：{TypeName(definition.Type)}\n标签：{definition.Tags}\n" +
                $"行动间隔：{(definition.Type == CommercialCardType.Passive ? "常驻" : $"{definition.Cooldown:0.0} 秒")}\n\n{definition.Description}\n\n" +
                $"角色属性倍率：{definition.ScalingCoefficient:0.00}\n" +
                (definition.Type == CommercialCardType.Summon
                    ? $"召唤基础生命：{definition.SummonHealth:0}"
                    : "该卡牌不显示独立生命条");
            Action deployAction = null;
            if (allowDeploy) deployAction = () =>
            {
                pendingDeployCardId = definition.Id;
                CloseDetail();
                RefreshFormationPage();
            };
            ConfigureDetailAction(allowDeploy ? "选择部署" : string.Empty, deployAction);
        }

        private void ShowHeroDeployDetail()
        {
            if (!detailPopup) return;
            var snapshot = CommercialCharacterCalculator.BuildSnapshot(state);
            var profession = CommercialProfessionCatalog.Get(snapshot.Profession);
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = $"主角 · {profession.DisplayName}";
            if (detailBody) detailBody.text = $"战败核心单位\n等级：{state.PlayerLevel}\n职业：{profession.DisplayName} · {profession.PathName}\n" +
                $"能力强度：{snapshot.AbilityPower:0.0}\n生命：{snapshot.MaxHealth:0}\n护甲：{snapshot.Armor:0.0}\n" +
                $"暴击：{snapshot.CritChance * 100f:0.0}%\n普攻间隔：{snapshot.HeroAttackInterval:0.00}秒\n战力：{state.CombatPower:0}\n\n" +
                "主角死亡立即失败；职业、装备、加点和等级只在下一场战斗创建快照时生效。";
            ConfigureDetailAction("选择部署", () =>
            {
                pendingDeployCardId = CommercialGameState.HeroCardId;
                CloseDetail();
                RefreshFormationPage();
            });
        }

        private void ShowHeroBattleDetail()
        {
            if (!detailPopup || battle == null) return;
            var profession = CommercialProfessionCatalog.Get(battle.CharacterSnapshot.Profession);
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = $"主角 · {profession.DisplayName} · 当前战斗快照";
            if (detailBody) detailBody.text = $"生命：{battle.Hero.Health:0}/{battle.Hero.MaxHealth:0}\n" +
                $"攻击：{battle.Hero.Attack:0.0}\n能力强度：{battle.CharacterSnapshot.AbilityPower:0.0}\n" +
                $"护甲：{battle.Hero.Armor:0.0}\n暴击：{battle.Hero.CritChance * 100f:0.0}%\n" +
                $"行动间隔：{battle.Hero.AttackInterval:0.00}秒\n护盾：{battle.Hero.Shield:0}\n" +
                $"{battle.Hero.ProfessionResourceName}：{battle.Hero.ProfessionResource}/{battle.Hero.ProfessionResourceMax}";
            ConfigureDetailAction(string.Empty, null);
        }

        private void ShowEnemyDetail(CommercialCombatant enemy)
        {
            if (!detailPopup || enemy == null) return;
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = enemy.DisplayName;
            if (detailBody) detailBody.text = $"生命：{enemy.Health:0}/{enemy.MaxHealth:0}\n攻击：{enemy.Attack:0.0}\n" +
                $"行动间隔：{enemy.AttackInterval:0.00}秒\n燃烧：{enemy.Burn:0.0}  中毒：{enemy.Poison:0.0}";
            ConfigureDetailAction(string.Empty, null);
        }

        private void ConfigureDetailAction(string label, Action action)
        {
            if (!detailActionButton) return;
            detailActionButton.gameObject.SetActive(action != null);
            detailActionButton.onClick.RemoveAllListeners();
            if (action != null) detailActionButton.onClick.AddListener(() => action());
            if (detailActionLabel) detailActionLabel.text = label;
        }

        private void CloseDetail()
        {
            if (detailPopup) detailPopup.SetActive(false);
        }

        private void SetText(string name, string value)
        {
            var text = FindDeep(transform.root, name)?.GetComponent<Text>();
            if (text) text.text = value;
        }

        private static string TypeName(CommercialCardType type) => type switch
        {
            CommercialCardType.Passive => "被动",
            CommercialCardType.Summon => "召唤",
            _ => "主动"
        };

        private static CommercialPrimaryValueKind PrimaryValueKind(CommercialCardDefinition definition)
        {
            if (definition == null) return CommercialPrimaryValueKind.Damage;
            return definition.Effect switch
            {
                CommercialCardEffect.ShieldHero or CommercialCardEffect.ShieldAndDamage =>
                    CommercialPrimaryValueKind.Shield,
                CommercialCardEffect.HealHero or CommercialCardEffect.SummonHealer =>
                    CommercialPrimaryValueKind.Heal,
                CommercialCardEffect.HasteAdjacent or CommercialCardEffect.HasteAll =>
                    CommercialPrimaryValueKind.CooldownAdvance,
                CommercialCardEffect.PassiveAdjacentPower or CommercialCardEffect.PassiveGlobalPower =>
                    CommercialPrimaryValueKind.BuffPercent,
                _ => CommercialPrimaryValueKind.Damage
            };
        }

        private static string SlotName(EquipmentSlot slot) => slot switch
        {
            EquipmentSlot.Head => "头部",
            EquipmentSlot.Hands => "手部",
            EquipmentSlot.Armor => "护甲",
            EquipmentSlot.Legs => "裤子",
            EquipmentSlot.Shoes => "鞋子",
            EquipmentSlot.MainWeapon => "主武器",
            _ => slot.ToString()
        };

        public static Transform FindDeep(Transform root, string objectName)
        {
            if (!root) return null;
            if (root.name == objectName) return root;
            for (var i = 0; i < root.childCount; i++)
            {
                var found = FindDeep(root.GetChild(i), objectName);
                if (found) return found;
            }
            return null;
        }
    }
}

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
        private enum ScreenTab { Gacha, Formation, City, Explore, Equipment, Activities }

        [SerializeField] private bool resetSaveOnStart;
        [SerializeField, Range(.5f, 8f)] private float battleSpeed = 2f;
        private readonly GameObject[] pages = new GameObject[6];
        private readonly Button[] navButtons = new Button[6];
        private readonly Image[] navBackgrounds = new Image[6];
        private readonly Text[] navLabels = new Text[6];
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

        private static readonly Color NavNormal = new(.035f, .055f, .07f, 1f);
        private static readonly Color NavSelected = new(.25f, .20f, .09f, 1f);
        private static readonly Color TextNormal = new(.57f, .69f, .75f, 1f);
        private static readonly Color TextSelected = new(1f, .80f, .33f, 1f);

        public CommercialGameState State => state;
        public CommercialBattleSession Battle => battle;
        public RectTransform FormationDragLayer => formationDragLayer;
        public Camera FormationEventCamera => null;
        public RectTransform BattleDragLayer => battleDragLayer;
        public Camera BattleEventCamera => null;

        private void Awake()
        {
            Application.runInBackground = true;
            if (resetSaveOnStart) CommercialSaveService.Reset();
            state = CommercialSaveService.Load();
            CacheHierarchy();
            BindNavigation();
            BindFormation();
            BindEquipment();
            BindCommonButtons();
        }

        private void Start()
        {
            SelectTab(ScreenTab.Explore);
            RefreshAllStaticUI();
            StartNextBattle();
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
            }
        }

        private void CacheHierarchy()
        {
            var root = transform.root;
            var pageNames = new[] { "Page_Gacha", "Page_Formation", "Page_City", "Page_Explore", "Page_Equipment", "Page_Activities" };
            for (var i = 0; i < pages.Length; i++) pages[i] = FindDeep(root, pageNames[i])?.gameObject;
            for (var i = 0; i < navButtons.Length; i++)
            {
                var nav = FindDeep(root, $"Nav_{i}");
                navButtons[i] = nav?.GetComponent<Button>();
                navBackgrounds[i] = nav?.GetComponent<Image>();
                navLabels[i] = FindDeep(nav, "Label")?.GetComponent<Text>();
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
            detailPopup = FindDeep(root, "CardDetailPopup")?.gameObject;
            detailTitle = FindDeep(detailPopup?.transform, "DetailTitle")?.GetComponent<Text>();
            detailBody = FindDeep(detailPopup?.transform, "DetailBody")?.GetComponent<Text>();
            detailActionButton = FindDeep(detailPopup?.transform, "DetailAction")?.GetComponent<Button>();
            detailActionLabel = FindDeep(detailActionButton?.transform, "Label")?.GetComponent<Text>();
            if (detailPopup) detailPopup.SetActive(false);
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
                blocked = false;
                RefreshAllStaticUI();
                StartNextBattle();
            });
        }

        private void SelectTab(ScreenTab tab)
        {
            currentTab = tab;
            for (var i = 0; i < pages.Length; i++) if (pages[i]) pages[i].SetActive(i == (int)tab);
            for (var i = 0; i < navButtons.Length; i++)
            {
                var selected = i == (int)tab;
                if (navBackgrounds[i]) navBackgrounds[i].color = selected ? NavSelected : NavNormal;
                if (navLabels[i]) navLabels[i].color = selected ? TextSelected : TextNormal;
            }
            if (tab == ScreenTab.Formation) RefreshFormationPage();
            if (tab == ScreenTab.Equipment) RefreshEquipmentPage();
            if (tab == ScreenTab.Explore) RefreshBattleViews();
        }

        private void StartNextBattle()
        {
            nextBattleDelay = 0f;
            blocked = false;
            battle = new CommercialBattleSession(state, state.DraftFormation,
                17041 + state.GlobalStage * 7919 + state.DropSequence);
            BindBattleViews();
            RefreshBattleViews();
            SetText("BattleStatus", "战斗中");
            SetText("BattleResultHint", string.Empty);
            var retry = FindDeep(transform.root, "RetryBattleButton")?.gameObject;
            if (retry) retry.SetActive(false);
        }

        private void ResolveBattle()
        {
            if (battle.Result == CommercialBattleResult.Victory)
            {
                var completedChapter = state.Chapter;
                var completedStage = state.Stage;
                var drop = state.ApplyStageVictory(9109 + state.GlobalStage * 37 + state.DropSequence);
                CommercialSaveService.Save(state);
                SetText("BattleStatus", "胜利");
                SetText("BattleResultHint", drop == null
                    ? $"已通过 {completedChapter}-{completedStage:00}，正在进入下一关"
                    : $"掉落：{drop.DisplayName}，已放入装备背包");
                nextBattleDelay = 1.25f;
                RefreshAllStaticUI();
            }
            else
            {
                blocked = true;
                SetText("BattleStatus", "战力受阻");
                SetText("BattleResultHint", $"停留在 {state.Chapter}-{state.Stage:00}，升级、换装或调整阵容后重试");
                var retry = FindDeep(transform.root, "RetryBattleButton")?.gameObject;
                if (retry) retry.SetActive(true);
            }
        }

        private void BindBattleViews()
        {
            for (var i = 0; i < 9; i++)
            {
                var playerIndex = i;
                var ally = battle.GetAllyAt(i);
                var card = battle.GetCardAt(i);
                if (ally?.IsHero == true)
                    playerViews[i]?.BindHero(ally, i, () => ShowHeroBattleDetail());
                else if (card != null)
                    playerViews[i]?.BindCard(card, i, () => ShowCardDetail(card.Definition, false));
                else if (playerViews[i]) playerViews[i].gameObject.SetActive(false);
                ConfigureBattleDrag(playerViews[i], playerIndex);

                var enemy = battle.GetEnemyAt(i);
                if (enemy != null)
                    enemyViews[i]?.BindEnemy(enemy, i, () => ShowEnemyDetail(enemy));
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
                if (value.Kind == BattleVisualEventKind.Damage && value.Amount > 0f)
                {
                    floatingTextPool?.Show(view ? (RectTransform)view.transform : null,
                        $"-{Mathf.CeilToInt(value.Amount)}", new Color(1f, .35f, .30f));
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
            if (!item || currentTab != ScreenTab.Explore || battle == null || battle.Completed) return false;
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
            var changed = target >= 0 && battle != null &&
                          battle.TrySwapPlayerGridPositions(item.SourceGrid, target);
            SetText("PlayerRule", "主角阵亡即失败");
            if (!changed)
            {
                RefreshBattleViews();
                return;
            }
            BindBattleViews();
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
                    ? "主角\n3.0s · 含生命条"
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
        }

        private void RefreshTopAndQuest()
        {
            SetText("ResourceEnergy", state.Gems.ToString());
            SetText("ResourceGold", state.Gold.ToString());
            SetText("ResourcePremium", state.PremiumCurrency.ToString());
            SetText("StageTitle", $"第 {state.Chapter} 章 · 关卡 {state.Stage:00} / 20");
            SetText("PlayerLevel", $"Lv.{state.PlayerLevel}  EXP {state.Experience}/{state.ExperienceToNextLevel}");
            SetText("MainQuestTitle", $"主线任务 · 通关 {state.Chapter}-{state.MainQuestTargetStage:00}");
            var progress = Mathf.Clamp(state.GlobalStage, 0, state.MainQuestTargetStage);
            SetText("MainQuestProgress", $"{progress} / {state.MainQuestTargetStage}   奖励：金币 ×{120 + state.MainQuestTargetStage * 8}");
        }

        private void ShowCardDetail(CommercialCardDefinition definition, bool allowDeploy)
        {
            if (definition == null || !detailPopup) return;
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = definition.DisplayName;
            if (detailBody) detailBody.text = $"类型：{TypeName(definition.Type)}\n标签：{definition.Tags}\n" +
                $"行动间隔：{(definition.Type == CommercialCardType.Passive ? "常驻" : $"{definition.Cooldown:0.0} 秒")}\n\n{definition.Description}\n\n" +
                (definition.Type == CommercialCardType.Summon ? $"召唤生命：{definition.SummonHealth:0}" : "该卡牌不显示独立生命条");
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
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = "主角";
            if (detailBody) detailBody.text = $"战败核心单位\n基础行动间隔：3.0秒\n当前等级：{state.PlayerLevel}\n" +
                $"战力：{state.CombatPower:0}\n\n主角死亡立即失败；装备和等级只在下一场战斗创建快照时生效。";
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
            detailPopup.SetActive(true);
            if (detailTitle) detailTitle.text = "主角 · 当前战斗快照";
            if (detailBody) detailBody.text = $"生命：{battle.Hero.Health:0}/{battle.Hero.MaxHealth:0}\n" +
                $"攻击：{battle.Hero.Attack:0.0}\n行动间隔：{battle.Hero.AttackInterval:0.00}秒\n护盾：{battle.Hero.Shield:0}";
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

        private static Transform FindDeep(Transform root, string objectName)
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

using System;
using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Battle;
using CardAutobattle.Exploration;
using CardAutobattle.Preparation;
using CardAutobattle.UI;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Prototype
{
    [DefaultExecutionOrder(-200)]
    [DisallowMultipleComponent]
    public sealed class PrototypeGameFlowController : MonoBehaviour
    {
        private sealed class BattleUnit
        {
            public CardDefinition Definition;
            public int Level;
            public int Index;
            public bool Enemy;
            public BattleCardView View;
            public SlotModifierType Modifier;
            public CardRuntime Runtime;
            public float Cooldown => Runtime != null ? Runtime.CooldownDuration : 0f;
            public float Remaining => Runtime != null ? Runtime.CooldownRemaining : 0f;
        }

        [Header("Prototype Run")]
        [SerializeField] private int startingCoins = 16;
        [SerializeField] private float battleSpeed = 2.25f;
        [SerializeField] private float battleTimeLimit = 45f;

        private PreparationBoardController boardController;
        private readonly List<PreparationSlotUI> shopSlots = new();
        private readonly List<PreparationSlotUI> warehouseSlots = new();
        private readonly List<PreparationSlotUI> boardSlots = new();
        private Text runHud;
        private Text toast;
        private GameObject preparationRoot;
        private GameObject inputLayer;
        private GameObject visualLayer;
        private GameObject backgroundLayer;
        private GameObject authoredBattleBackdrop;
        private GameObject battleRoot;
        private BattleSceneView battleSceneView;
        private Canvas preparationCanvas;
        private GraphicRaycaster preparationRaycaster;
        private GameObject detailPopup;
        private GameObject hoverTooltip;
        private PreparationCardInput hoveredCard;
        private Button startBattleButton;
        private GameObject shopSection;
        private Text phaseBadgeLabel;
        private SlotEnhancementEventView slotEnhancementView;
        private ExplorationChoiceEventView choiceEventView;
        private ExplorationCompleteView completeView;
        private ExplorationSessionController explorationSession;
        private SlotModifierType[] offeredSlotModifiers;
        private SlotModifierType pendingSlotModifier;
        private PreparationSlotUI pendingModifierSlot;
        private bool selectingModifierSlot;
        private PreparationEventType currentEvent;

        private readonly List<BattleUnit> playerUnits = new();
        private readonly List<BattleUnit> enemyUnits = new();
        private float playerMaxHealth;
        private float enemyMaxHealth;
        private BattleContext battleContext;
        private BattleController battleController;
        private BattlePresentationController battlePresentation;
        private bool battling;
        private bool battleEnded;
        private bool lastBattleWon;
        private int pendingReward;

        public int Coins => explorationSession ? explorationSession.Coins : 0;
        public int Round => explorationSession ? explorationSession.EncounterNumber : 1;
        public bool ExplorationCompleted => explorationSession && explorationSession.IsCompleted;
        public string CurrentScavengerId => explorationSession?.Scavenger?.Id;

        private void Awake()
        {
            boardController = GetComponent<PreparationBoardController>();
            explorationSession = GetComponent<ExplorationSessionController>();
            if (!explorationSession)
                explorationSession = gameObject.AddComponent<ExplorationSessionController>();
            CacheSlots();
        }

        private void Start()
        {
            preparationRoot = FindDeep(transform, "PreparationRoot")?.gameObject;
            inputLayer = FindDeep(transform, "CardInputLayer")?.gameObject;
            visualLayer = FindDeep(transform, "CardVisualLayer")?.gameObject;
            backgroundLayer = FindDeep(transform.root, "BackgroundLayer")?.gameObject;
            authoredBattleBackdrop = GameObject.Find("BattleBG");
            preparationCanvas = GetComponentInParent<Canvas>();
            preparationRaycaster = preparationCanvas ? preparationCanvas.GetComponent<GraphicRaycaster>() : null;
            startBattleButton = FindDeep(transform, "StartBattleButton")?.GetComponent<Button>();
            shopSection = FindDeep(transform, "ShopSection")?.gameObject;
            phaseBadgeLabel = FindDeep(FindDeep(transform, "PhaseBadge"), "Text")?.GetComponent<Text>();
            if (startBattleButton)
            {
                startBattleButton.onClick.RemoveAllListeners();
                startBattleButton.onClick.AddListener(StartBattle);
            }

            CreatePreparationHud();
            BeginNewExploration();
        }

        public void BeginNewExploration()
        {
            if (battling)
                return;

            if (slotEnhancementView)
                Destroy(slotEnhancementView.gameObject);
            if (choiceEventView)
                Destroy(choiceEventView.gameObject);
            if (completeView)
                Destroy(completeView.gameObject);
            slotEnhancementView = null;
            choiceEventView = null;
            completeView = null;

            RemoveAuthoredDemoCards();
            foreach (var slot in boardSlots)
                slot.SetModifier(SlotModifierType.None);
            explorationSession.BeginNewRun(startingCoins);
            SeedStartingCards();
            EnterPreparationEvent(PreparationEventType.Merchant);
        }

        private void Update()
        {
            if (!battling || battleEnded || battleController == null)
                return;

            battleController.SetSpeed(battleSpeed);
            battleController.Tick(Time.unscaledDeltaTime);
            foreach (var unit in playerUnits.Concat(enemyUnits))
                unit.View?.SetCooldown(unit.Runtime.Charge01);

            UpdateBattleHud();
            if (battleContext.Player.Health <= 0f || battleContext.Enemy.Health <= 0f ||
                battleContext.Clock.BattleTime >= battleTimeLimit)
                FinishBattle();
        }

        private void CacheSlots()
        {
            shopSlots.Clear();
            warehouseSlots.Clear();
            boardSlots.Clear();
            foreach (var slot in GetComponentsInChildren<PreparationSlotUI>(true))
            {
                var list = slot.Zone == PreparationZone.Shop ? shopSlots :
                    slot.Zone == PreparationZone.Warehouse ? warehouseSlots : boardSlots;
                list.Add(slot);
            }
            shopSlots.Sort((a, b) => a.Index.CompareTo(b.Index));
            warehouseSlots.Sort((a, b) => a.Index.CompareTo(b.Index));
            boardSlots.Sort((a, b) => a.Index.CompareTo(b.Index));
        }

        private void RemoveAuthoredDemoCards()
        {
            foreach (var card in GetComponentsInChildren<PreparationCardInput>(true))
            {
                card.CurrentSlot?.SetOccupant(null);
                card.AssignSlot(null, false);
                card.gameObject.SetActive(false);
                Destroy(card.gameObject);
            }
        }

        private void SeedStartingCards()
        {
            SpawnOwned(boardSlots[0], "blade");
            SpawnOwned(boardSlots[4], "shield");
            SpawnOwned(boardSlots[8], "herbs");
            SpawnOwned(warehouseSlots[0], "dagger");
        }

        private void SpawnOwned(PreparationSlotUI slot, string id, int level = 1)
        {
            if (slot && !slot.Occupant)
                boardController.SpawnCard(slot, id, level, false, 0);
        }

        private void RefreshShop()
        {
            foreach (var slot in shopSlots)
            {
                if (slot.Occupant)
                    boardController.RemoveCard(slot.Occupant);
                var definition = PrototypeCardCatalog.GetShopOffer(Round, slot.Index);
                boardController.SpawnCard(slot, definition.Id, 1, true, definition.Cost);
            }
            UpdateRunHud($"第 {Round} 战商店已刷新");
        }

        private void ClearShopOffers()
        {
            foreach (var slot in shopSlots)
                if (slot.Occupant)
                    boardController.RemoveCard(slot.Occupant);
        }

        private void EnterPreparationEvent(PreparationEventType eventType)
        {
            EndModifierSlotSelection();
            if (slotEnhancementView)
                Destroy(slotEnhancementView.gameObject);
            if (choiceEventView)
                Destroy(choiceEventView.gameObject);
            slotEnhancementView = null;
            choiceEventView = null;

            currentEvent = eventType;
            switch (currentEvent)
            {
                case PreparationEventType.None:
                    ClearShopOffers();
                    if (shopSection) shopSection.SetActive(false);
                    if (startBattleButton) startBattleButton.interactable = true;
                    SetPhaseBadge("阵型整备");
                    UpdateRunHud("可调整卡牌排布，然后进入下一场战斗");
                    break;

                case PreparationEventType.Merchant:
                    if (shopSection) shopSection.SetActive(true);
                    if (startBattleButton) startBattleButton.interactable = true;
                    SetPhaseBadge("商人事件");
                    RefreshShop();
                    UpdateRunHud(Round == 1 ? "首次事件：购买并部署卡牌" : "商人带来了新的卡牌");
                    break;

                case PreparationEventType.EnhanceSlot:
                    ClearShopOffers();
                    if (shopSection) shopSection.SetActive(false);
                    if (startBattleButton) startBattleButton.interactable = false;
                    SetPhaseBadge("强化槽位");
                    OpenSlotEnhancementEvent();
                    UpdateRunHud("强化事件：三选一并改造一个3×3槽位");
                    break;

                case PreparationEventType.CardWorkshop:
                case PreparationEventType.WastelandCamp:
                case PreparationEventType.TacticalProtocol:
                case PreparationEventType.RuinsExploration:
                case PreparationEventType.EquipmentCache:
                    ClearShopOffers();
                    if (shopSection) shopSection.SetActive(false);
                    if (startBattleButton) startBattleButton.interactable = false;
                    OpenChoiceEvent(currentEvent);
                    break;
            }
        }

        private void OpenSlotEnhancementEvent()
        {
            var prefab = Resources.Load<SlotEnhancementEventView>("UI/Events/SlotEnhancementEvent");
            if (!prefab)
            {
                Debug.LogError("[CardAutobattle] Missing UI/Events/SlotEnhancementEvent.prefab");
                if (startBattleButton) startBattleButton.interactable = true;
                return;
            }

            offeredSlotModifiers = CreateModifierChoices();
            var popupLayer = FindDeep(transform.root, "PopupLayer") ?? transform.root;
            slotEnhancementView = Instantiate(prefab, popupLayer);
            slotEnhancementView.name = "SlotEnhancementEvent";
            slotEnhancementView.Open(offeredSlotModifiers, BeginModifierSlotSelection, ReturnToModifierChoices);
        }

        private static SlotModifierType[] CreateModifierChoices()
        {
            var pool = new List<SlotModifierType>
            {
                SlotModifierType.FireDamage,
                SlotModifierType.DirectDamage,
                SlotModifierType.Healing,
                SlotModifierType.Shield,
                SlotModifierType.PoisonDamage,
                SlotModifierType.CooldownReduction
            };
            for (var i = pool.Count - 1; i > 0; i--)
            {
                var swap = UnityEngine.Random.Range(0, i + 1);
                (pool[i], pool[swap]) = (pool[swap], pool[i]);
            }
            return pool.Take(3).ToArray();
        }

        private void BeginModifierSlotSelection(SlotModifierType modifier)
        {
            pendingSlotModifier = modifier;
            pendingModifierSlot = null;
            selectingModifierSlot = true;
            inputLayer?.SetActive(false);
            foreach (var slot in boardSlots)
                slot.SetEnhancementTargetMode(true);
            slotEnhancementView?.BeginTargeting(modifier);
            UpdateRunHud($"选择要改造成{SlotModifierRules.DisplayName(modifier)}的格子");
        }

        public bool TryPreviewSlotEnhancement(PreparationSlotUI slot)
        {
            if (!selectingModifierSlot || !slot || slot.Zone != PreparationZone.Board)
                return false;

            pendingModifierSlot = slot;
            foreach (var boardSlot in boardSlots)
                boardSlot.SetEnhancementTargetMode(true, boardSlot == slot);
            slotEnhancementView?.PreviewTarget(pendingSlotModifier, slot.Index, ConfirmSlotEnhancement);
            return true;
        }

        private void ConfirmSlotEnhancement()
        {
            if (!pendingModifierSlot)
                return;

            var appliedSlot = pendingModifierSlot;
            var appliedModifier = pendingSlotModifier;
            appliedSlot.SetModifier(appliedModifier);
            EndModifierSlotSelection();
            if (slotEnhancementView)
                Destroy(slotEnhancementView.gameObject);
            slotEnhancementView = null;
            if (startBattleButton) startBattleButton.interactable = true;
            SetPhaseBadge("强化完成");
            UpdateRunHud($"格子 {appliedSlot.Index + 1} 已变为{SlotModifierRules.DisplayName(appliedModifier)}");
        }

        private void ReturnToModifierChoices()
        {
            EndModifierSlotSelection();
            slotEnhancementView?.ShowChoices();
            UpdateRunHud("重新选择一种槽位强化");
        }

        private void EndModifierSlotSelection()
        {
            selectingModifierSlot = false;
            pendingModifierSlot = null;
            pendingSlotModifier = SlotModifierType.None;
            foreach (var slot in boardSlots)
                slot.SetEnhancementTargetMode(false);
            if (!battling)
                inputLayer?.SetActive(true);
        }

        private void OpenChoiceEvent(PreparationEventType eventType)
        {
            var resourcePath = eventType switch
            {
                PreparationEventType.CardWorkshop => "UI/Events/CardWorkshopEvent",
                PreparationEventType.WastelandCamp => "UI/Events/WastelandCampEvent",
                PreparationEventType.TacticalProtocol => "UI/Events/TacticalProtocolEvent",
                PreparationEventType.RuinsExploration => "UI/Events/RuinsExplorationEvent",
                PreparationEventType.EquipmentCache => "UI/Events/EquipmentCacheEvent",
                _ => null
            };
            var prefab = string.IsNullOrEmpty(resourcePath)
                ? null
                : Resources.Load<ExplorationChoiceEventView>(resourcePath);
            if (!prefab)
            {
                Debug.LogError($"[Exploration] Missing Resources/{resourcePath}.prefab");
                if (startBattleButton) startBattleButton.interactable = true;
                return;
            }

            var popupLayer = FindDeep(transform.root, "PopupLayer") ?? transform.root;
            choiceEventView = Instantiate(prefab, popupLayer);
            choiceEventView.name = eventType.ToString();
            switch (eventType)
            {
                case PreparationEventType.CardWorkshop:
                    OpenCardWorkshop();
                    break;
                case PreparationEventType.WastelandCamp:
                    OpenWastelandCamp();
                    break;
                case PreparationEventType.TacticalProtocol:
                    OpenTacticalProtocol();
                    break;
                case PreparationEventType.RuinsExploration:
                    OpenRuinsExploration();
                    break;
                case PreparationEventType.EquipmentCache:
                    OpenEquipmentCache();
                    break;
            }
        }

        private void OpenCardWorkshop()
        {
            SetPhaseBadge("废土改装台");
            var candidates = boardSlots.Concat(warehouseSlots)
                .Select(slot => slot.Occupant)
                .Where(card => card && !card.IsShopOffer && card.Level < 3)
                .OrderBy(card => card.Level)
                .ThenBy(card => card.Definition.Cost)
                .Take(3)
                .ToArray();

            if (candidates.Length == 0)
            {
                choiceEventView.Open("废土改装台", "当前卡牌均无法继续改造。",
                    new Color(.95f, .48f, .16f),
                    new[]
                    {
                        new ExplorationEventChoice("拆解废料", "获得8金币", "无可升级卡牌时的保底收益")
                    }, _ =>
                    {
                        explorationSession.AddCoins(8);
                        FinishChoiceEvent("回收废料，获得8金币");
                    });
                return;
            }

            var choices = candidates.Select(card => new ExplorationEventChoice(
                card.Definition.DisplayName,
                $"品质 {PrototypeCardCatalog.QualityName(card.Level)} → {PrototypeCardCatalog.QualityName(card.Level + 1)}",
                "卡牌实例永久保留该品质")).ToArray();
            choiceEventView.Open("废土改装台", "选择一张现有卡牌进行品质强化。",
                new Color(.95f, .48f, .16f), choices, index =>
                {
                    candidates[index].Upgrade();
                    FinishChoiceEvent($"{candidates[index].Definition.DisplayName} 已完成改造");
                });
        }

        private void OpenWastelandCamp()
        {
            SetPhaseBadge("流浪者营地");
            choiceEventView.Open("流浪者营地", "在下一场战斗前选择一种整备方式。",
                new Color(.20f, .82f, .58f),
                new[]
                {
                    new ExplorationEventChoice("紧急治疗", "恢复45%最大生命", "适合低生命状态"),
                    new ExplorationEventChoice("战斗训练", "获得30点拾荒者经验", "升级会提高最大生命"),
                    new ExplorationEventChoice("整理物资", "获得7金币", "用于下一次商店购买")
                }, index =>
                {
                    if (index == 0) explorationSession.Heal(explorationSession.MaxHealth * .45f);
                    else if (index == 1) explorationSession.GainExperience(30);
                    else explorationSession.AddCoins(7);
                    FinishChoiceEvent(index == 0 ? "生命状态已修复" : index == 1 ? "拾荒者获得30经验" : "获得7金币");
                });
        }

        private void OpenTacticalProtocol()
        {
            SetPhaseBadge("战术数据终端");
            choiceEventView.Open("战术数据终端", "协议持续到本次探索结束，新协议会替换旧协议。",
                new Color(.18f, .72f, 1f),
                new[]
                {
                    new ExplorationEventChoice("火力协议", "武器标签卡牌效果+15%", "适合直接伤害构筑"),
                    new ExplorationEventChoice("生存协议", "防御与支援标签卡牌效果+18%", "适合护盾治疗构筑"),
                    new ExplorationEventChoice("异常协议", "科技/异常标签卡牌效果+18%", "适合火焰与毒构筑")
                }, index =>
                {
                    explorationSession.SetProtocol((ExplorationProtocolKind)(index + 1));
                    boardController.RefreshAllCardValues();
                    FinishChoiceEvent("战术协议已载入");
                });
        }

        private void OpenRuinsExploration()
        {
            SetPhaseBadge("废墟探索");
            choiceEventView.Open("废墟探索", "难度1采用可预期的属性检定结果。",
                new Color(.72f, .50f, .94f),
                new[]
                {
                    new ExplorationEventChoice("武力·强行破门", "获得7金币", "推荐武力 10"),
                    new ExplorationEventChoice("智力·破解终端", "获得一张免费科技卡", "推荐智力 10"),
                    new ExplorationEventChoice("防御·稳固遗迹", "最大生命+12", "推荐防御 10")
                }, index =>
                {
                    if (index == 0)
                    {
                        explorationSession.AddCoins(7);
                        FinishChoiceEvent("破门成功，获得7金币");
                    }
                    else if (index == 1)
                    {
                        var granted = TryGrantFreeCard("battery");
                        if (!granted) explorationSession.AddCoins(6);
                        FinishChoiceEvent(granted ? "破解成功，获得弧光电池" : "没有空位，转化为6金币");
                    }
                    else
                    {
                        explorationSession.IncreaseMaxHealth(12f);
                        FinishChoiceEvent("遗迹结构已转化为防护资源，最大生命+12");
                    }
                });
        }

        private void OpenEquipmentCache()
        {
            SetPhaseBadge("军用装备货柜");
            choiceEventView.Open("军用装备货柜", "选择的装备立即生效，并进入本次探索结算记录。",
                new Color(1f, .76f, .22f),
                new[]
                {
                    new ExplorationEventChoice("动力义肢", "武器卡效果+10%", "永久装备框架：PowerArm"),
                    new ExplorationEventChoice("神盾模组", "防御卡效果+12%", "永久装备框架：AegisModule"),
                    new ExplorationEventChoice("生命维持器", "最大生命+18，治疗效果+10%", "永久装备框架：LifeSupport")
                }, index =>
                {
                    var equipment = index == 0 ? ExpeditionEquipment.PowerArm :
                        index == 1 ? ExpeditionEquipment.AegisModule : ExpeditionEquipment.LifeSupport;
                    explorationSession.AddEquipment(equipment);
                    boardController.RefreshAllCardValues();
                    FinishChoiceEvent("装备已装配");
                });
        }

        private bool TryGrantFreeCard(string cardId)
        {
            var target = warehouseSlots.FirstOrDefault(slot => !slot.Occupant) ??
                boardSlots.FirstOrDefault(slot => !slot.Occupant);
            if (!target)
                return false;
            boardController.SpawnCard(target, cardId, 1, false, 0);
            return true;
        }

        private void FinishChoiceEvent(string message)
        {
            if (choiceEventView)
                Destroy(choiceEventView.gameObject);
            choiceEventView = null;
            currentEvent = PreparationEventType.None;
            if (startBattleButton) startBattleButton.interactable = true;
            SetPhaseBadge("事件完成 · 下一战");
            UpdateRunHud(message);
        }

        private void SetPhaseBadge(string text)
        {
            if (phaseBadgeLabel)
                phaseBadgeLabel.text = text;
        }

        public bool IsValidDrop(PreparationCardInput card, PreparationSlotUI target)
        {
            if (!card || !target || target == card.CurrentSlot)
                return false;
            if (target.Zone == PreparationZone.Shop)
                return false;

            var occupant = target.Occupant;
            if (card.IsShopOffer)
            {
                if (Coins < card.PurchasePrice)
                    return false;
                return !occupant || CanMerge(card, occupant);
            }

            return !occupant || occupant == card || CanMerge(card, occupant) || target.Zone != PreparationZone.Shop;
        }

        public bool TryHandleDrop(PreparationCardInput card, PreparationSlotUI target)
        {
            if (!IsValidDrop(card, target))
            {
                UpdateRunHud(card.IsShopOffer && Coins < card.PurchasePrice
                    ? $"Not enough gold: need {card.PurchasePrice}"
                    : "That card cannot be placed there");
                card.ReturnToSlot();
                return false;
            }

            var targetCard = target.Occupant;
            var buying = card.IsShopOffer;
            if (buying)
            {
                if (!explorationSession.TrySpendCoins(card.PurchasePrice))
                {
                    card.ReturnToSlot();
                    UpdateRunHud($"金币不足：需要 {card.PurchasePrice}");
                    return false;
                }
                card.MarkPurchased();
            }

            if (targetCard && CanMerge(card, targetCard))
            {
                card.CurrentSlot?.SetOccupant(null);
                targetCard.Upgrade();
                boardController.RemoveCard(card);
                UpdateRunHud($"Merged into {PrototypeCardCatalog.QualityName(targetCard.Level)} {targetCard.Definition.DisplayName}");
            }
            else
            {
                boardController.CommitMoveOrSwap(card, target);
                UpdateRunHud(buying ? $"Purchased {card.Definition.DisplayName}" : "Formation updated");
            }

            UpdateRunHud();
            return true;
        }

        private static bool CanMerge(PreparationCardInput a, PreparationCardInput b)
        {
            return a && b && !b.IsShopOffer && a.CardId == b.CardId && a.Level == b.Level && b.Level < 3;
        }

        public void ShowCardDetails(PreparationCardInput card)
        {
            if (!card)
                return;

            HideCardHover(card);

            if (detailPopup)
                Destroy(detailPopup);

            var popupLayer = FindDeep(transform.root, "PopupLayer") ?? transform.root;
            var blocker = CardPresentationUtility.CreateImage("CardDetailPopup", popupLayer, new Color(.015f, .025f, .04f, .78f));
            detailPopup = blocker.gameObject;
            blocker.raycastTarget = true;
            var button = blocker.gameObject.AddComponent<Button>();
            button.transition = Selectable.Transition.None;
            button.onClick.AddListener(() =>
            {
                if (detailPopup)
                    Destroy(detailPopup);
            });

            var panel = CardPresentationUtility.CreateImage("DetailPanel", blocker.transform, new Color(.07f, .10f, .14f, .98f));
            panel.rectTransform.anchorMin = new Vector2(.08f, .30f);
            panel.rectTransform.anchorMax = new Vector2(.92f, .70f);
            panel.rectTransform.offsetMin = Vector2.zero;
            panel.rectTransform.offsetMax = Vector2.zero;
            panel.raycastTarget = false;

            var text = CardPresentationUtility.CreateText("Details", panel.transform, 36, TextAnchor.MiddleCenter, Color.white);
            text.rectTransform.offsetMin = new Vector2(38, 38);
            text.rectTransform.offsetMax = new Vector2(-38, -38);
            var d = card.Definition;
            text.text = $"{d.DisplayName}\n\n{PrototypeCardCatalog.QualityName(card.Level)}  |  CD {d.Cooldown:0.0}s\n\n{d.Description}\n\n" +
                (card.IsShopOffer ? $"Price: {card.PurchasePrice} Gold" : "Owned card") + "\n\nTap outside to close";
        }

        public void ShowCardHover(PreparationCardInput card)
        {
            if (!card || battling || detailPopup)
                return;

            HideCardHover(null);
            hoveredCard = card;
            var popupLayer = FindDeep(transform.root, "PopupLayer") ?? transform.root;
            var tooltip = CardPresentationUtility.CreateImage("CardHoverTooltip", popupLayer,
                new Color(.035f, .055f, .075f, .97f));
            hoverTooltip = tooltip.gameObject;
            tooltip.raycastTarget = false;
            tooltip.rectTransform.anchorMin = tooltip.rectTransform.anchorMax = new Vector2(.5f, .5f);
            tooltip.rectTransform.sizeDelta = new Vector2(470f, 184f);

            var popupRect = popupLayer as RectTransform;
            var screenPoint = RectTransformUtility.WorldToScreenPoint(null, card.transform.position);
            if (popupRect && RectTransformUtility.ScreenPointToLocalPointInRectangle(popupRect, screenPoint, null, out var localPoint))
            {
                localPoint.y += 128f;
                var half = tooltip.rectTransform.sizeDelta * .5f;
                localPoint.x = Mathf.Clamp(localPoint.x, popupRect.rect.xMin + half.x + 12f, popupRect.rect.xMax - half.x - 12f);
                localPoint.y = Mathf.Clamp(localPoint.y, popupRect.rect.yMin + half.y + 12f, popupRect.rect.yMax - half.y - 12f);
                tooltip.rectTransform.anchoredPosition = localPoint;
            }

            var label = CardPresentationUtility.CreateText("TooltipText", tooltip.transform, 25,
                TextAnchor.MiddleLeft, Color.white);
            label.rectTransform.offsetMin = new Vector2(24, 16);
            label.rectTransform.offsetMax = new Vector2(-24, -16);
            var definition = card.Definition;
            label.text = $"{definition.DisplayName}  ·  {PrototypeCardCatalog.QualityName(card.Level)}\n" +
                $"{definition.Description}\n" +
                (card.IsShopOffer ? $"Price {card.PurchasePrice} Gold" : $"Cooldown {definition.Cooldown:0.0}s");
        }

        public void HideCardHover(PreparationCardInput card)
        {
            if (card && hoveredCard && hoveredCard != card)
                return;
            hoveredCard = null;
            if (hoverTooltip)
                Destroy(hoverTooltip);
            hoverTooltip = null;
        }

        public float GetPlayerEffectMultiplier(CardDefinition definition)
        {
            return explorationSession ? explorationSession.GetPlayerEffectMultiplier(definition) : 1f;
        }

        public void StartBattle()
        {
            if (battling)
                return;
            if (currentEvent == PreparationEventType.EnhanceSlot && slotEnhancementView)
            {
                UpdateRunHud("请先完成槽位强化");
                return;
            }
            var deployed = boardSlots.Where(s => s.Occupant && !s.Occupant.IsShopOffer).ToList();
            if (deployed.Count == 0)
            {
                UpdateRunHud("Deploy at least one card before battle");
                return;
            }

            var encounter = explorationSession.CurrentEncounter;
            if (encounter == null)
            {
                UpdateRunHud("当前地图没有可进入的战斗节点");
                return;
            }

            battling = true;
            HideCardHover(null);
            battleEnded = false;
            playerMaxHealth = explorationSession.MaxHealth;
            enemyMaxHealth = encounter.EnemyMaxHealth;
            battleContext = new BattleContext(playerMaxHealth, enemyMaxHealth,
                Round * 7919 + (explorationSession.CurrentEncounter?.EnemyLevel ?? 1));
            battleContext.Player.SetHealth(Mathf.Clamp(explorationSession.CurrentHealth, 1f, playerMaxHealth));
            battleController = new BattleController(battleContext, OnCardTriggered);

            preparationRoot?.SetActive(false);
            inputLayer?.SetActive(false);
            visualLayer?.SetActive(false);
            backgroundLayer?.SetActive(false);
            authoredBattleBackdrop?.SetActive(false);
            if (preparationCanvas)
                preparationCanvas.enabled = false;
            if (preparationRaycaster)
                preparationRaycaster.enabled = false;
            if (!BuildBattleView())
            {
                battling = false;
                preparationRoot?.SetActive(true);
                inputLayer?.SetActive(true);
                visualLayer?.SetActive(true);
                backgroundLayer?.SetActive(true);
                authoredBattleBackdrop?.SetActive(true);
                if (preparationCanvas)
                    preparationCanvas.enabled = true;
                if (preparationRaycaster)
                    preparationRaycaster.enabled = true;
                UpdateRunHud("Battle prefab is missing");
                return;
            }
            battlePresentation = new BattlePresentationController(battleContext.Events, battleSceneView);
            CreateBattleUnits(deployed);
            UpdateBattleHud();
        }

        private bool BuildBattleView()
        {
            if (battleRoot)
                Destroy(battleRoot);
            var prefab = Resources.Load<BattleSceneView>("Battle/BattleScene");
            if (!prefab)
            {
                Debug.LogError("[CardAutobattle] Missing Resources/Battle/BattleScene.prefab");
                return false;
            }

            battleSceneView = Instantiate(prefab);
            battleRoot = battleSceneView.gameObject;
            battleRoot.name = "BattleScene";
            battleSceneView.Initialize(Round, ReturnToPreparation);
            return true;
        }

        private void CreateBattleUnits(List<PreparationSlotUI> deployed)
        {
            playerUnits.Clear();
            enemyUnits.Clear();
            var playerMap = deployed.ToDictionary(s => s.Index, s => s);
            for (var i = 0; i < 9; i++)
            {
                var cell = battleSceneView.GetPlayerCell(i);
                var cellModifierView = cell ? cell.GetComponent<SlotModifierView>() : null;
                if (playerMap.TryGetValue(i, out var slot))
                {
                    var card = slot.Occupant;
                    cellModifierView?.SetModifier(slot.Modifier);
                    cellModifierView?.SetConditionActive(SlotModifierRules.SupportsCard(slot.Modifier, card.Definition));
                    playerUnits.Add(CreateUnit(card.Definition, card.Level, i, false, cell, slot.Modifier));
                }
                else
                {
                    var sourceSlot = boardSlots.FirstOrDefault(s => s.Index == i);
                    cellModifierView?.SetModifier(sourceSlot ? sourceSlot.Modifier : SlotModifierType.None);
                }
            }

            var encounter = explorationSession.CurrentEncounter;
            var enemyMap = new Dictionary<int, CardDefinition>();
            var enemyCount = Mathf.Min(encounter.EnemyCardIds.Length, encounter.EnemyPositions.Length);
            for (var i = 0; i < enemyCount; i++)
                enemyMap[encounter.EnemyPositions[i]] = PrototypeCardCatalog.Get(encounter.EnemyCardIds[i]);
            for (var i = 0; i < 9; i++)
            {
                if (enemyMap.TryGetValue(i, out var definition))
                    enemyUnits.Add(CreateUnit(definition, encounter.EnemyLevel, i, true, null, SlotModifierType.None));
            }
            RefreshBattleValueDisplays(playerUnits);
            RefreshBattleValueDisplays(enemyUnits);
        }

        private BattleUnit CreateUnit(CardDefinition definition, int level, int index, bool enemy, Transform cell,
            SlotModifierType modifier)
        {
            BattleCardView view = null;
            if (cell)
            {
                var visual = Instantiate(boardController.VisualCardPrefab, cell);
                visual.name = $"BattleCard_{definition.Id}";
                var rect = (RectTransform)visual.transform;
                rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
                rect.anchoredPosition = Vector2.zero;
                rect.localScale = Vector3.one;
                foreach (var graphic in visual.GetComponentsInChildren<Graphic>(true))
                    graphic.raycastTarget = false;
                view = visual.GetComponent<BattleCardView>() ?? visual.AddComponent<BattleCardView>();
                view.Bind(definition, level, enemy);
            }
            var modifiedBaseCooldown = enemy
                ? definition.Cooldown
                : SlotModifierRules.ModifyCooldown(modifier, definition.Cooldown) *
                  explorationSession.GetPlayerCooldownMultiplier(definition);
            var cooldown = Mathf.Max(.35f, modifiedBaseCooldown *
                (enemy ? explorationSession.CurrentEncounter.EnemyCooldownMultiplier : 1f));
#if UNITY_EDITOR
            if (!enemy && modifier == SlotModifierType.CooldownReduction)
                Debug.Log($"[SlotModifier] slot={index} CD {definition.Cooldown:0.###} -> {cooldown:0.###}");
#endif
            var owner = enemy ? battleContext.Enemy : battleContext.Player;
            var runtime = new CardRuntime(battleContext.NextRuntimeId(), new BattleCardDefinition(definition), owner,
                GridPosition.FromIndex(index), cooldown, level);
            battleController.AddCard(runtime);
            battlePresentation?.RegisterCard(runtime, enemy);
            return new BattleUnit
            {
                Definition = definition,
                Level = level,
                Index = index,
                Enemy = enemy,
                View = view,
                Modifier = modifier,
                Runtime = runtime
            };
        }

        private void OnCardTriggered(CardRuntime runtime)
        {
            var unit = (runtime.Owner.Side == BattleSide.Player ? playerUnits : enemyUnits)
                .FirstOrDefault(candidate => candidate.Runtime == runtime);
            if (unit == null) return;
            var allies = runtime.Owner.Side == BattleSide.Player
                ? playerUnits.Select(candidate => candidate.Runtime).ToList()
                : enemyUnits.Select(candidate => candidate.Runtime).ToList();
            var adjacentCount = CountRelevantAdjacent(runtime.Owner.Side == BattleSide.Player ? playerUnits : enemyUnits, unit);
            LegacyCardEffectAdapter.Execute(runtime, battleContext,
                GetExternalPowerMultiplier(runtime.Owner.Side == BattleSide.Player ? playerUnits : enemyUnits, unit),
                adjacentCount, unit.Modifier, allies);
            unit.View?.SetCooldown(runtime.Charge01);
            unit.View?.TriggerPulse();
        }

        private void RefreshBattleValueDisplays(List<BattleUnit> units)
        {
            foreach (var unit in units)
            {
                var adjacentCount = CountRelevantAdjacent(units, unit);
                unit.View?.SetEffectValues(CardEffectValueResolver.ResolveDisplay(
                    unit.Definition,
                    unit.Level,
                    adjacentCount,
                    GetExternalPowerMultiplier(units, unit),
                    unit.Modifier));
            }
        }

        private float GetExternalPowerMultiplier(List<BattleUnit> units, BattleUnit source)
        {
            var multiplier = source.Enemy
                ? explorationSession.CurrentEncounter.EnemyPowerMultiplier
                : explorationSession.GetPlayerEffectMultiplier(source.Definition);
            foreach (var aura in units)
                if (aura != source && aura.Definition.Effect == CardEffectKind.PassivePowerAura &&
                    AreAdjacent(aura.Index, source.Index))
                    multiplier *= 1f + aura.Definition.Power * aura.Level;
            return multiplier;
        }

        private static int CountRelevantAdjacent(List<BattleUnit> units, BattleUnit source)
        {
            var requiredTag = source.Definition.AdjacentRequiredTag;
            return units.Count(other => other != source && AreAdjacent(other.Index, source.Index) &&
                (requiredTag == CardTag.None || (other.Definition.Tags & requiredTag) != 0));
        }

        private static bool AreAdjacent(int a, int b)
        {
            return Mathf.Abs(a / 3 - b / 3) + Mathf.Abs(a % 3 - b % 3) == 1;
        }

        private void FinishBattle()
        {
            if (battleEnded)
                return;
            battleEnded = true;
            battleContext?.SetEnded();
            lastBattleWon = battleContext.Enemy.Health <= 0 ||
                (battleContext.Player.Health > 0 && battleContext.Player.Health >= battleContext.Enemy.Health);
            var bonus = lastBattleWon
                ? playerUnits.Count(u => u.Definition.Effect == CardEffectKind.ShieldAndVictoryGold)
                : 0;
            pendingReward = lastBattleWon ? explorationSession.CurrentEncounter.GoldReward + bonus : 0;
            battleSceneView?.ShowResult(lastBattleWon, pendingReward);
        }

        public void ReturnToPreparation()
        {
            if (!battleEnded)
                return;
            var victoryGoldBonus = lastBattleWon
                ? Mathf.Max(0, pendingReward - explorationSession.CurrentEncounter.GoldReward)
                : 0;
            var resolution = explorationSession.ResolveBattle(lastBattleWon, battleContext.Player.Health, victoryGoldBonus);
            battling = false;
            battleEnded = false;
            playerUnits.Clear();
            enemyUnits.Clear();
            if (battleRoot)
                Destroy(battleRoot);
            battlePresentation?.Dispose();
            battlePresentation = null;
            battleController = null;
            battleContext = null;
            battleSceneView = null;
            preparationRoot?.SetActive(true);
            inputLayer?.SetActive(true);
            visualLayer?.SetActive(true);
            backgroundLayer?.SetActive(true);
            authoredBattleBackdrop?.SetActive(true);
            if (preparationCanvas)
                preparationCanvas.enabled = true;
            if (preparationRaycaster)
                preparationRaycaster.enabled = true;

            if (resolution.MapCompleted)
            {
                explorationSession.CompleteScavenger(boardSlots
                    .Where(slot => slot.Occupant && !slot.Occupant.IsShopOffer)
                    .Select(slot => new ScavengerDeckEntry
                    {
                        CardId = slot.Occupant.CardId,
                        Level = slot.Occupant.Level,
                        SlotIndex = slot.Index,
                        SlotModifier = slot.Modifier
                    }));
                ClearShopOffers();
                if (shopSection) shopSection.SetActive(false);
                if (startBattleButton) startBattleButton.interactable = false;
                SetPhaseBadge("地图通关");
                OpenExplorationComplete();
                UpdateRunHud("灰烬边境·难度1 已完整通关");
                return;
            }

            EnterPreparationEvent(resolution.NextEvent);
            UpdateRunHud(resolution.Won
                ? resolution.NextEvent == PreparationEventType.None
                    ? "战斗胜利，调整阵型后进入下一节点"
                    : $"精英战胜利，触发{GetEventDisplayName(resolution.NextEvent)}"
                : "战斗失败：已恢复45%生命，可重新部署后挑战当前节点");
        }

        private void OpenExplorationComplete()
        {
            var prefab = Resources.Load<ExplorationCompleteView>("UI/Events/ExplorationComplete");
            if (!prefab)
            {
                Debug.LogError("[Exploration] Missing Resources/UI/Events/ExplorationComplete.prefab");
                return;
            }

            var popupLayer = FindDeep(transform.root, "PopupLayer") ?? transform.root;
            completeView = Instantiate(prefab, popupLayer);
            completeView.name = "ExplorationComplete";
            completeView.Open(explorationSession.Map.DisplayName,
                explorationSession.Scavenger?.DisplayName ?? "未命名",
                explorationSession.ScavengerLevel,
                explorationSession.ScavengerExperience,
                explorationSession.Coins,
                ReturnCompletedRunToHub);
        }

        private void ReturnCompletedRunToHub()
        {
            if (completeView)
                Destroy(completeView.gameObject);
            completeView = null;
            GameUIRoot.Instance?.Screens.Open(UIScreenId.MainHub, null, false);
        }

        private static string GetEventDisplayName(PreparationEventType eventType)
        {
            return eventType switch
            {
                PreparationEventType.Merchant => "商人事件",
                PreparationEventType.EnhanceSlot => "槽位强化事件",
                PreparationEventType.CardWorkshop => "废土改装台",
                PreparationEventType.WastelandCamp => "流浪者营地",
                PreparationEventType.TacticalProtocol => "战术数据终端",
                PreparationEventType.RuinsExploration => "废墟探索",
                PreparationEventType.EquipmentCache => "军用装备货柜",
                _ => "阵型整备"
            };
        }

        private void UpdateBattleHud()
        {
            if (!battleSceneView || battleContext == null)
                return;
            battleSceneView.SetHud(battleContext.Player.Health, battleContext.Player.MaxHealth, battleContext.Player.Shield,
                battleContext.Enemy.Health, battleContext.Enemy.MaxHealth, battleContext.Enemy.Shield,
                battleTimeLimit - battleContext.Clock.BattleTime, battleSpeed);
        }

        private void CreatePreparationHud()
        {
            var header = FindDeep(transform, "Header") ?? transform;
            runHud = CardPresentationUtility.CreateText("RunHUD", header, 28, TextAnchor.UpperRight, new Color(1f, .86f, .35f));
            runHud.rectTransform.anchorMin = new Vector2(.55f, .05f);
            runHud.rectTransform.anchorMax = new Vector2(.98f, .95f);
            runHud.rectTransform.offsetMin = Vector2.zero;
            runHud.rectTransform.offsetMax = Vector2.zero;
            toast = CardPresentationUtility.CreateText("Toast", header, 19, TextAnchor.LowerRight, new Color(.7f, .84f, .88f));
            toast.rectTransform.anchorMin = new Vector2(.42f, -.1f);
            toast.rectTransform.anchorMax = new Vector2(.98f, .38f);
            toast.rectTransform.offsetMin = Vector2.zero;
            toast.rectTransform.offsetMax = Vector2.zero;
        }

        private void UpdateRunHud(string message = null)
        {
            if (runHud)
                runHud.text = $"{explorationSession.BuildProgressLabel()}\n" +
                    $"拾荒者 Lv.{explorationSession.ScavengerLevel}  EXP {explorationSession.ScavengerExperience}/{explorationSession.ExperienceToNextLevel}" +
                    $"   HP {Mathf.CeilToInt(explorationSession.CurrentHealth)}/{Mathf.CeilToInt(explorationSession.MaxHealth)}   GOLD {Coins}";
            if (toast && !string.IsNullOrEmpty(message))
                toast.text = message;
        }

        private static Button CreateButton(string name, Transform parent, string label, Vector2 anchor, Vector2 size)
        {
            var image = CardPresentationUtility.CreateImage(name, parent, new Color(.08f, .62f, .48f, 1f));
            image.raycastTarget = true;
            image.rectTransform.anchorMin = anchor;
            image.rectTransform.anchorMax = anchor;
            image.rectTransform.sizeDelta = size;
            var button = image.gameObject.AddComponent<Button>();
            button.targetGraphic = image;
            var text = CardPresentationUtility.CreateText("Text", image.transform, 30, TextAnchor.MiddleCenter, Color.white);
            text.text = label;
            return button;
        }

        private static Transform FindDeep(Transform root, string name)
        {
            if (!root)
                return null;
            if (root.name == name)
                return root;
            for (var i = 0; i < root.childCount; i++)
            {
                var result = FindDeep(root.GetChild(i), name);
                if (result)
                    return result;
            }
            return null;
        }
    }
}

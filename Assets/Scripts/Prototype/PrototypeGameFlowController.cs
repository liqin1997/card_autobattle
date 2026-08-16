using System;
using System.Collections.Generic;
using System.Linq;
using CardAutobattle.Preparation;
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
            public float Cooldown;
            public float Remaining;
            public BattleCardView View;
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

        private readonly List<BattleUnit> playerUnits = new();
        private readonly List<BattleUnit> enemyUnits = new();
        private int coins;
        private int round = 1;
        private float playerHealth;
        private float enemyHealth;
        private float playerMaxHealth;
        private float enemyMaxHealth;
        private float playerShield;
        private float enemyShield;
        private float playerBurn;
        private float enemyBurn;
        private float playerPoison;
        private float enemyPoison;
        private float statusTick;
        private float battleTime;
        private bool battling;
        private bool battleEnded;
        private int pendingReward;

        public int Coins => coins;
        public int Round => round;

        private void Awake()
        {
            boardController = GetComponent<PreparationBoardController>();
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
            if (startBattleButton)
            {
                startBattleButton.onClick.RemoveAllListeners();
                startBattleButton.onClick.AddListener(StartBattle);
            }

            RemoveAuthoredDemoCards();
            coins = startingCoins;
            CreatePreparationHud();
            SeedStartingCards();
            RefreshShop();
            UpdateRunHud("Drag a Shop card to buy it");
        }

        private void Update()
        {
            if (!battling || battleEnded)
                return;

            var dt = Time.deltaTime * battleSpeed;
            battleTime += dt;
            statusTick += dt;

            TickUnits(playerUnits, dt);
            TickUnits(enemyUnits, dt);

            while (statusTick >= 1f && !battleEnded)
            {
                statusTick -= 1f;
                TickStatuses();
            }

            UpdateBattleHud();
            if (playerHealth <= 0f || enemyHealth <= 0f || battleTime >= battleTimeLimit)
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
                var definition = PrototypeCardCatalog.GetShopOffer(round, slot.Index);
                boardController.SpawnCard(slot, definition.Id, 1, true, definition.Cost);
            }
            UpdateRunHud($"Round {round} shop refreshed");
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
                if (coins < card.PurchasePrice)
                    return false;
                return !occupant || CanMerge(card, occupant);
            }

            return !occupant || occupant == card || CanMerge(card, occupant) || target.Zone != PreparationZone.Shop;
        }

        public bool TryHandleDrop(PreparationCardInput card, PreparationSlotUI target)
        {
            if (!IsValidDrop(card, target))
            {
                UpdateRunHud(card.IsShopOffer && coins < card.PurchasePrice
                    ? $"Not enough gold: need {card.PurchasePrice}"
                    : "That card cannot be placed there");
                card.ReturnToSlot();
                return false;
            }

            var targetCard = target.Occupant;
            var buying = card.IsShopOffer;
            if (buying)
            {
                coins -= card.PurchasePrice;
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

        public void StartBattle()
        {
            if (battling)
                return;
            var deployed = boardSlots.Where(s => s.Occupant && !s.Occupant.IsShopOffer).ToList();
            if (deployed.Count == 0)
            {
                UpdateRunHud("Deploy at least one card before battle");
                return;
            }

            battling = true;
            HideCardHover(null);
            battleEnded = false;
            battleTime = 0f;
            statusTick = 0f;
            playerShield = enemyShield = playerBurn = enemyBurn = playerPoison = enemyPoison = 0f;
            playerMaxHealth = 90f + round * 10f;
            enemyMaxHealth = 72f + round * 18f;
            playerHealth = playerMaxHealth;
            enemyHealth = enemyMaxHealth;

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
            battleSceneView.Initialize(round, ReturnToPreparation);
            return true;
        }

        private void CreateBattleUnits(List<PreparationSlotUI> deployed)
        {
            playerUnits.Clear();
            enemyUnits.Clear();
            var playerMap = deployed.ToDictionary(s => s.Index, s => s.Occupant);
            for (var i = 0; i < 9; i++)
            {
                var cell = battleSceneView.GetPlayerCell(i);
                if (playerMap.TryGetValue(i, out var card))
                    playerUnits.Add(CreateUnit(card.Definition, card.Level, i, false, cell));
            }

            var enemyCount = Mathf.Clamp(2 + round, 3, 9);
            var enemyIds = new[] { "dagger", "shield", "fire", "blade", "herbs", "hammer", "frost", "thorns", "core" };
            var enemyPositions = new[] { 4, 0, 8, 2, 6, 1, 7, 3, 5 };
            var enemyMap = new Dictionary<int, CardDefinition>();
            for (var i = 0; i < enemyCount; i++)
                enemyMap[enemyPositions[i]] = PrototypeCardCatalog.Get(enemyIds[(i + round - 1) % enemyIds.Length]);
            var enemyLevel = Mathf.Clamp(1 + (round - 1) / 2, 1, 3);
            for (var i = 0; i < 9; i++)
            {
                if (enemyMap.TryGetValue(i, out var definition))
                    enemyUnits.Add(CreateUnit(definition, enemyLevel, i, true, null));
            }
        }

        private BattleUnit CreateUnit(CardDefinition definition, int level, int index, bool enemy, Transform cell)
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
            var cooldown = Mathf.Max(.35f, definition.Cooldown * (enemy ? Mathf.Max(.72f, 1f - (round - 1) * .04f) : 1f));
            return new BattleUnit
            {
                Definition = definition,
                Level = level,
                Index = index,
                Enemy = enemy,
                Cooldown = cooldown,
                Remaining = definition.Effect == CardEffectKind.PassivePowerAura ? float.PositiveInfinity : cooldown,
                View = view
            };
        }

        private void TickUnits(List<BattleUnit> units, float dt)
        {
            for (var i = 0; i < units.Count && !battleEnded; i++)
            {
                var unit = units[i];
                if (float.IsPositiveInfinity(unit.Remaining))
                {
                    unit.View?.SetCooldown(1f);
                    continue;
                }

                unit.Remaining -= dt;
                unit.View?.SetCooldown(1f - Mathf.Clamp01(unit.Remaining / unit.Cooldown));
                if (unit.Remaining > 0f)
                    continue;

                unit.Remaining += unit.Cooldown;
                ResolveUnit(unit);
                unit.View?.TriggerPulse();
            }
        }

        private void ResolveUnit(BattleUnit unit)
        {
            var allies = unit.Enemy ? enemyUnits : playerUnits;
            var powerScale = PrototypeCardCatalog.QualityMultiplier(unit.Level) * (unit.Enemy ? 1f + (round - 1) * .18f : 1f);
            foreach (var aura in allies)
                if (aura.Definition.Effect == CardEffectKind.PassivePowerAura && AreAdjacent(aura.Index, unit.Index))
                    powerScale *= 1f + aura.Definition.Power * aura.Level;

            var power = unit.Definition.Power * powerScale;
            var secondary = unit.Definition.SecondaryPower * powerScale;
            switch (unit.Definition.Effect)
            {
                case CardEffectKind.Damage:
                    DealDamage(unit.Enemy, power);
                    break;
                case CardEffectKind.Shield:
                    GainShield(unit.Enemy, power);
                    break;
                case CardEffectKind.Heal:
                    if (unit.Definition.Id == "herbs")
                        power += CountAdjacent(allies, unit, CardTag.Support) * secondary;
                    Heal(unit.Enemy, power);
                    break;
                case CardEffectKind.DamageAndBurn:
                    DealDamage(unit.Enemy, power);
                    AddStatus(unit.Enemy, true, secondary);
                    break;
                case CardEffectKind.DamageAndPoison:
                    DealDamage(unit.Enemy, power);
                    AddStatus(unit.Enemy, false, secondary);
                    break;
                case CardEffectKind.DamageAndSlow:
                    DealDamage(unit.Enemy, power);
                    foreach (var enemy in unit.Enemy ? playerUnits : enemyUnits)
                        if (!float.IsPositiveInfinity(enemy.Remaining)) enemy.Remaining += secondary;
                    break;
                case CardEffectKind.HasteNeighbours:
                    foreach (var ally in allies)
                        if (ally != unit && AreAdjacent(ally.Index, unit.Index) && !float.IsPositiveInfinity(ally.Remaining))
                            ally.Remaining -= power;
                    break;
                case CardEffectKind.HasteAll:
                    foreach (var ally in allies)
                        if (ally != unit && !float.IsPositiveInfinity(ally.Remaining)) ally.Remaining -= power;
                    break;
                case CardEffectKind.DamageAndHaste:
                    DealDamage(unit.Enemy, power);
                    var candidate = allies.Where(a => a != unit && !float.IsPositiveInfinity(a.Remaining))
                        .OrderByDescending(a => a.Remaining).FirstOrDefault();
                    if (candidate != null) candidate.Remaining -= secondary;
                    break;
                case CardEffectKind.ShieldAndDamage:
                    GainShield(unit.Enemy, power);
                    DealDamage(unit.Enemy, secondary);
                    break;
                case CardEffectKind.Drain:
                    DealDamage(unit.Enemy, power);
                    Heal(unit.Enemy, secondary);
                    break;
                case CardEffectKind.ChainDamage:
                    var count = unit.Definition.Id == "bow"
                        ? CountAdjacent(allies, unit, CardTag.Weapon)
                        : Mathf.Max(1, CountAdjacent(allies, unit, CardTag.None));
                    DealDamage(unit.Enemy, power + (unit.Definition.Id == "bow" ? count * secondary : (count - 1) * power));
                    break;
                case CardEffectKind.ShieldAndVictoryGold:
                    GainShield(unit.Enemy, power);
                    break;
                case CardEffectKind.ShieldAndHeal:
                    GainShield(unit.Enemy, power);
                    Heal(unit.Enemy, secondary);
                    break;
            }
            battleSceneView?.PlayCardActivation(unit.Enemy, unit.Definition.Effect, Mathf.Max(power, secondary));
        }

        private static int CountAdjacent(List<BattleUnit> units, BattleUnit source, CardTag requiredTag)
        {
            return units.Count(other => other != source && AreAdjacent(other.Index, source.Index) &&
                (requiredTag == CardTag.None || (other.Definition.Tags & requiredTag) != 0));
        }

        private static bool AreAdjacent(int a, int b)
        {
            return Mathf.Abs(a / 3 - b / 3) + Mathf.Abs(a % 3 - b % 3) == 1;
        }

        private void DealDamage(bool attackerIsEnemy, float amount)
        {
            if (attackerIsEnemy)
                ApplyDamage(ref playerHealth, ref playerShield, amount);
            else
                ApplyDamage(ref enemyHealth, ref enemyShield, amount);
        }

        private static void ApplyDamage(ref float health, ref float shield, float amount)
        {
            var blocked = Mathf.Min(shield, amount);
            shield -= blocked;
            health = Mathf.Max(0, health - (amount - blocked));
        }

        private void GainShield(bool enemy, float amount)
        {
            if (enemy) enemyShield += amount;
            else playerShield += amount;
        }

        private void Heal(bool enemy, float amount)
        {
            if (enemy) enemyHealth = Mathf.Min(enemyMaxHealth, enemyHealth + amount);
            else playerHealth = Mathf.Min(playerMaxHealth, playerHealth + amount);
        }

        private void AddStatus(bool attackerIsEnemy, bool burn, float amount)
        {
            if (attackerIsEnemy)
            {
                if (burn) playerBurn += amount;
                else playerPoison += amount;
            }
            else
            {
                if (burn) enemyBurn += amount;
                else enemyPoison += amount;
            }
        }

        private void TickStatuses()
        {
            ApplyDamage(ref playerHealth, ref playerShield, playerBurn + playerPoison);
            ApplyDamage(ref enemyHealth, ref enemyShield, enemyBurn + enemyPoison);
            playerBurn = Mathf.Max(0, playerBurn - 1f);
            enemyBurn = Mathf.Max(0, enemyBurn - 1f);
            playerPoison = Mathf.Max(0, playerPoison - .5f);
            enemyPoison = Mathf.Max(0, enemyPoison - .5f);
        }

        private void FinishBattle()
        {
            if (battleEnded)
                return;
            battleEnded = true;
            var won = enemyHealth <= 0 || (playerHealth > 0 && playerHealth >= enemyHealth);
            var bonus = won ? playerUnits.Count(u => u.Definition.Effect == CardEffectKind.ShieldAndVictoryGold) : 0;
            pendingReward = won ? 6 + round * 2 + bonus : 3;
            battleSceneView?.ShowResult(won, pendingReward);
        }

        public void ReturnToPreparation()
        {
            if (!battleEnded)
                return;
            coins += pendingReward;
            round++;
            battling = false;
            battleEnded = false;
            playerUnits.Clear();
            enemyUnits.Clear();
            if (battleRoot)
                Destroy(battleRoot);
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
            RefreshShop();
            UpdateRunHud($"Round {round}: enemy power increased");
        }

        private void UpdateBattleHud()
        {
            if (!battleSceneView)
                return;
            battleSceneView.SetHud(playerHealth, playerMaxHealth, playerShield,
                enemyHealth, enemyMaxHealth, enemyShield,
                battleTimeLimit - battleTime, battleSpeed);
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
                runHud.text = $"ROUND {round}    GOLD {coins}";
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

using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using CardAutobattle.Prototype;

namespace CardAutobattle.Preparation
{
    [DisallowMultipleComponent]
    public sealed class PreparationBoardController : MonoBehaviour
    {
        [SerializeField] private RectTransform cardInputLayer;
        [SerializeField] private RectTransform cardVisualLayer;
        [SerializeField] private GameObject visualCardPrefab;
        [SerializeField] private List<PreparationSlotUI> slots = new();

        private Canvas rootCanvas;
        private PrototypeGameFlowController gameFlow;

        public RectTransform CardInputLayer => cardInputLayer;
        public RectTransform CardVisualLayer => cardVisualLayer;
        public GameObject VisualCardPrefab => visualCardPrefab;
        public Camera EventCamera => rootCanvas && rootCanvas.renderMode != RenderMode.ScreenSpaceOverlay
            ? rootCanvas.worldCamera
            : null;

        private void Awake()
        {
            rootCanvas = GetComponentInParent<Canvas>();
            gameFlow = GetComponent<PrototypeGameFlowController>();
            if (!gameFlow)
                gameFlow = GetComponentInParent<PrototypeGameFlowController>();
            if (slots.Count == 0)
                slots.AddRange(GetComponentsInChildren<PreparationSlotUI>(true));
        }

        private void Start()
        {
            foreach (var card in GetComponentsInChildren<PreparationCardInput>(true))
            {
                if (!card.CurrentSlot)
                    continue;

                card.CurrentSlot.SetOccupant(card);
                card.Initialize(this, card.CurrentSlot, visualCardPrefab, cardVisualLayer);
            }
        }

        public void Configure(RectTransform inputLayer, RectTransform visualLayer, GameObject cardPrefab, IEnumerable<PreparationSlotUI> allSlots)
        {
            cardInputLayer = inputLayer;
            cardVisualLayer = visualLayer;
            visualCardPrefab = cardPrefab;
            slots.Clear();
            slots.AddRange(allSlots);
            rootCanvas = GetComponentInParent<Canvas>();
        }

        public void RegisterCard(PreparationCardInput card, PreparationSlotUI slot)
        {
            if (!card || !slot)
                return;

            slot.SetOccupant(card);
            card.AssignSlot(slot, true);
        }

        public void BeginDrag(PreparationCardInput card)
        {
            foreach (var slot in slots)
                slot.SetHighlight(true, !gameFlow || gameFlow.IsValidDrop(card, slot));
        }

        public void EndDrag(PreparationCardInput card, Vector2 screenPosition)
        {
            var target = FindDropTarget(screenPosition);
            foreach (var slot in slots)
                slot.SetHighlight(false, true);

            if (!target || target == card.CurrentSlot)
            {
                card.ReturnToSlot();
                return;
            }

            if (gameFlow && gameFlow.TryHandleDrop(card, target))
                return;

            card.ReturnToSlot();
        }

        public void CardClicked(PreparationCardInput card)
        {
            gameFlow?.ShowCardDetails(card);
        }

        public void CardHoverChanged(PreparationCardInput card, bool hovered)
        {
            if (hovered)
                gameFlow?.ShowCardHover(card);
            else
                gameFlow?.HideCardHover(card);
        }

        public PreparationCardInput SpawnCard(PreparationSlotUI slot, string cardId, int level, bool shopOffer, int price)
        {
            var go = new GameObject($"{(shopOffer ? "Shop" : "Owned")}_{cardId}_{slot.Index}",
                typeof(RectTransform), typeof(CanvasRenderer), typeof(Image), typeof(CanvasGroup), typeof(PreparationCardInput));
            var rect = (RectTransform)go.transform;
            rect.SetParent(cardInputLayer, false);
            rect.sizeDelta = new Vector2(260f, 170f);
            var image = go.GetComponent<Image>();
            image.color = new Color(1f, 1f, 1f, .001f);
            image.raycastTarget = true;
            var card = go.GetComponent<PreparationCardInput>();
            card.ConfigureCard(cardId, level, shopOffer, price);
            slot.SetOccupant(card);
            card.AssignSlot(slot, true);
            card.Initialize(this, slot, visualCardPrefab, cardVisualLayer);
            return card;
        }

        public void CommitMoveOrSwap(PreparationCardInput movingCard, PreparationSlotUI target)
        {
            MoveOrSwap(movingCard, target);
        }

        public void RemoveCard(PreparationCardInput card)
        {
            if (!card)
                return;
            card.CurrentSlot?.SetOccupant(null);
            Destroy(card.gameObject);
        }

        private PreparationSlotUI FindDropTarget(Vector2 screenPosition)
        {
            PreparationSlotUI nearest = null;
            var nearestDistance = float.MaxValue;

            foreach (var slot in slots)
            {
                if (RectTransformUtility.RectangleContainsScreenPoint(slot.RectTransform, screenPosition, EventCamera))
                    return slot;

                var slotScreen = RectTransformUtility.WorldToScreenPoint(EventCamera, slot.CardAnchor.position);
                var distance = Vector2.Distance(screenPosition, slotScreen);
                if (distance < nearestDistance)
                {
                    nearestDistance = distance;
                    nearest = slot;
                }
            }

            return nearestDistance <= 150f * (rootCanvas ? rootCanvas.scaleFactor : 1f) ? nearest : null;
        }

        private static void MoveOrSwap(PreparationCardInput movingCard, PreparationSlotUI target)
        {
            var source = movingCard.CurrentSlot;
            var displaced = target.Occupant;

            source?.SetOccupant(displaced);
            target.SetOccupant(movingCard);

            movingCard.AssignSlot(target, false);
            if (displaced)
                displaced.AssignSlot(source, false);
        }
    }
}

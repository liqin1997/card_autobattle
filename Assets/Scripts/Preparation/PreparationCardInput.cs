using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using CardAutobattle.Prototype;

namespace CardAutobattle.Preparation
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform), typeof(CanvasGroup), typeof(Image))]
    public sealed class PreparationCardInput : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler,
        IPointerEnterHandler, IPointerExitHandler, IPointerDownHandler, IPointerUpHandler
    {
        [SerializeField] private float dragFollowSpeed = 3200f;
        [SerializeField] private PreparationSlotUI currentSlot;
        [SerializeField] private string cardId = "blade";
        [SerializeField, Range(1, 3)] private int level = 1;
        [SerializeField] private bool shopOffer;
        [SerializeField] private int purchasePrice;

        private PreparationBoardController controller;
        private RectTransform rectTransform;
        private CanvasGroup canvasGroup;
        private PreparationCardVisual visual;
        private Vector3 dragTargetWorld;
        private Vector3 pointerOffsetWorld;
        private bool initialized;
        private bool draggedSincePress;
        private Vector2 pointerDownPosition;

        public PreparationSlotUI CurrentSlot => currentSlot;
        public string CardId => cardId;
        public int Level => level;
        public bool IsShopOffer => shopOffer;
        public int PurchasePrice => purchasePrice;
        public CardDefinition Definition => PrototypeCardCatalog.Get(cardId);
        public bool IsDragging { get; private set; }
        public bool IsHovered { get; private set; }
        public bool IsPressed { get; private set; }
        public Vector2 PointerScreenPosition { get; private set; }

        private void Awake()
        {
            rectTransform = GetComponent<RectTransform>();
            canvasGroup = GetComponent<CanvasGroup>();
        }

        private void LateUpdate()
        {
            if (!initialized)
                return;

            if (IsDragging)
            {
                rectTransform.position = Vector3.MoveTowards(
                    rectTransform.position,
                    dragTargetWorld,
                    dragFollowSpeed * Time.unscaledDeltaTime);
            }
            else if (currentSlot)
            {
                rectTransform.position = currentSlot.CardAnchor.position;
            }
        }

        public void Initialize(PreparationBoardController board, PreparationSlotUI slot, GameObject visualPrefab, RectTransform visualParent)
        {
            if (initialized)
                return;

            controller = board;
            initialized = true;
            AssignSlot(slot, true);

            var visualObject = Instantiate(visualPrefab, visualParent);
            visualObject.name = "Visual_" + gameObject.name;
            visual = visualObject.GetComponent<PreparationCardVisual>();
            if (!visual)
                visual = visualObject.AddComponent<PreparationCardVisual>();
            visual.Initialize(this);
            visual.BindCardData();
        }

        public void ConfigureCard(string definitionId, int qualityLevel, bool isShopOffer, int price)
        {
            cardId = definitionId;
            level = Mathf.Clamp(qualityLevel, 1, 3);
            shopOffer = isShopOffer;
            purchasePrice = Mathf.Max(0, price);
            visual?.BindCardData();
        }

        public void MarkPurchased()
        {
            shopOffer = false;
            purchasePrice = 0;
            visual?.BindCardData();
            controller?.RefreshAllCardValues();
        }

        public void Upgrade()
        {
            level = Mathf.Min(3, level + 1);
            visual?.BindCardData();
            controller?.RefreshAllCardValues();
        }

        public void SetEffectValues(ResolvedCardValues values)
        {
            visual?.SetEffectValues(values);
        }

        public void AssignSlot(PreparationSlotUI slot, bool instant)
        {
            currentSlot = slot;
            if (instant && slot)
                rectTransform.position = slot.CardAnchor.position;
        }

        public void ReturnToSlot()
        {
            IsDragging = false;
        }

        public void OnBeginDrag(PointerEventData eventData)
        {
            draggedSincePress = true;
            controller?.CardHoverChanged(this, false);
            IsDragging = true;
            PointerScreenPosition = eventData.position;
            canvasGroup.blocksRaycasts = false;

            if (RectTransformUtility.ScreenPointToWorldPointInRectangle(
                    controller.CardInputLayer,
                    eventData.position,
                    controller.EventCamera,
                    out var pointerWorld))
            {
                pointerOffsetWorld = rectTransform.position - pointerWorld;
                dragTargetWorld = pointerWorld + pointerOffsetWorld;
            }

            visual?.BringToFront();
            controller.BeginDrag(this);
        }

        public void OnDrag(PointerEventData eventData)
        {
            PointerScreenPosition = eventData.position;
            if (RectTransformUtility.ScreenPointToWorldPointInRectangle(
                    controller.CardInputLayer,
                    eventData.position,
                    controller.EventCamera,
                    out var pointerWorld))
                dragTargetWorld = pointerWorld + pointerOffsetWorld;
        }

        public void OnEndDrag(PointerEventData eventData)
        {
            PointerScreenPosition = eventData.position;
            IsDragging = false;
            IsPressed = false;
            canvasGroup.blocksRaycasts = true;
            controller.EndDrag(this, eventData.position);
            visual?.ReleaseSorting();
        }

        public void OnPointerEnter(PointerEventData eventData)
        {
            IsHovered = true;
            PointerScreenPosition = eventData.position;
            controller?.CardHoverChanged(this, true);
        }

        public void OnPointerExit(PointerEventData eventData)
        {
            IsHovered = false;
            PointerScreenPosition = eventData.position;
            controller?.CardHoverChanged(this, false);
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            if (eventData.button != PointerEventData.InputButton.Left)
                return;
            IsPressed = true;
            draggedSincePress = false;
            pointerDownPosition = eventData.position;
            PointerScreenPosition = eventData.position;
            controller?.CardHoverChanged(this, false);
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            IsPressed = false;
            PointerScreenPosition = eventData.position;
            if (!draggedSincePress && Vector2.Distance(pointerDownPosition, eventData.position) < 18f)
                controller?.CardClicked(this);
        }

        private void OnDestroy()
        {
            if (visual)
                Destroy(visual.gameObject);
        }
    }
}

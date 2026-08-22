using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;
using CardAutobattle.Prototype;

namespace CardAutobattle.Preparation
{
    [DisallowMultipleComponent]
    public sealed class PreparationSlotUI : MonoBehaviour, IPointerClickHandler
    {
        [SerializeField] private PreparationZone zone;
        [SerializeField] private int index;
        [SerializeField] private RectTransform cardAnchor;
        [SerializeField] private Image background;
        [SerializeField] private Image highlight;
        [SerializeField] private SlotModifierView modifierView;
        [SerializeField] private SlotModifierType modifier;

        private PrototypeGameFlowController gameFlow;
        private PreparationBoardController boardController;

        public PreparationZone Zone => zone;
        public int Index => index;
        public RectTransform CardAnchor => cardAnchor ? cardAnchor : (RectTransform)transform;
        public RectTransform RectTransform => (RectTransform)transform;
        public PreparationCardInput Occupant { get; private set; }
        public SlotModifierType Modifier => modifier;

        private void Awake()
        {
            gameFlow = GetComponentInParent<PrototypeGameFlowController>();
            boardController = GetComponentInParent<PreparationBoardController>();
            if (!modifierView)
                modifierView = GetComponent<SlotModifierView>();
            modifierView?.SetModifier(modifier);
        }

        public void Configure(PreparationZone targetZone, int targetIndex, RectTransform anchor, Image slotBackground, Image slotHighlight)
        {
            zone = targetZone;
            index = targetIndex;
            cardAnchor = anchor;
            background = slotBackground;
            highlight = slotHighlight;
            SetHighlight(false, true);
        }

        public void SetOccupant(PreparationCardInput card)
        {
            Occupant = card;
            RefreshModifierCondition();
        }

        public void SetModifier(SlotModifierType value)
        {
            modifier = value;
            modifierView?.SetModifier(value);
            RefreshModifierCondition();
            boardController?.RefreshAllCardValues();
        }

        public void SetEnhancementTargetMode(bool visible, bool selected = false)
        {
            if (!highlight)
                return;
            highlight.gameObject.SetActive(visible);
            highlight.raycastTarget = visible;
            highlight.color = selected
                ? new Color(1f, .78f, .16f, .72f)
                : new Color(.22f, .92f, 1f, .46f);
        }

        public void OnPointerClick(PointerEventData eventData)
        {
            if (eventData.button == PointerEventData.InputButton.Left)
                gameFlow?.TryPreviewSlotEnhancement(this);
        }

        private void RefreshModifierCondition()
        {
            if (modifierView)
                modifierView.SetConditionActive(!Occupant || SlotModifierRules.SupportsCard(modifier, Occupant.Definition));
        }

        public void SetHighlight(bool visible, bool valid)
        {
            if (!highlight)
                return;

            highlight.gameObject.SetActive(visible);
            highlight.raycastTarget = false;
            highlight.color = valid
                ? new Color(0.26f, 1f, 0.65f, 0.38f)
                : new Color(1f, 0.25f, 0.28f, 0.42f);
        }
    }
}

using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Preparation
{
    [DisallowMultipleComponent]
    public sealed class PreparationSlotUI : MonoBehaviour
    {
        [SerializeField] private PreparationZone zone;
        [SerializeField] private int index;
        [SerializeField] private RectTransform cardAnchor;
        [SerializeField] private Image background;
        [SerializeField] private Image highlight;

        public PreparationZone Zone => zone;
        public int Index => index;
        public RectTransform CardAnchor => cardAnchor ? cardAnchor : (RectTransform)transform;
        public RectTransform RectTransform => (RectTransform)transform;
        public PreparationCardInput Occupant { get; private set; }

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
        }

        public void SetHighlight(bool visible, bool valid)
        {
            if (!highlight)
                return;

            highlight.gameObject.SetActive(visible);
            highlight.color = valid
                ? new Color(0.26f, 1f, 0.65f, 0.38f)
                : new Color(1f, 0.25f, 0.28f, 0.42f);
        }
    }
}

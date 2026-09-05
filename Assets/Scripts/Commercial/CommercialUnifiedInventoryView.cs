using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    public sealed class CommercialUnifiedInventoryView : MonoBehaviour
    {
        public RectTransform EquipmentContent;
        public RectTransform BackpackContent;
        public Button EquipmentTab;
        public Button BackpackTab;
        private bool bound;

        private void Start()
        {
            Bind();
            ShowMode(false);
        }

        private void Bind()
        {
            if (bound) return;
            bound = true;
            BackpackTab?.onClick.AddListener(() => ShowMode(false));
            EquipmentTab?.onClick.AddListener(() => ShowMode(true));
        }

        public void ShowMode(bool equipment)
        {
            Bind();
            if (EquipmentContent) EquipmentContent.gameObject.SetActive(equipment);
            if (BackpackContent) BackpackContent.gameObject.SetActive(!equipment);
            if (EquipmentTab) EquipmentTab.image.color = equipment ? Selected : Normal;
            if (BackpackTab) BackpackTab.image.color = equipment ? Normal : Selected;
            if (equipment) GetComponent<CommercialEquipmentView>()?.Refresh();
            else GetComponent<CommercialInventoryView>()?.Refresh();
        }

        private static readonly Color Normal = new(.055f, .12f, .22f, .96f);
        private static readonly Color Selected = new(.16f, .46f, .78f, 1f);
    }
}

using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    public sealed class CommercialEquipmentCell : MonoBehaviour
    {
        public Image Icon, Rim;
        public Outline RarityOutline;
        public Text Caption, Meta, Badge;
        public Button Button;
        public string ItemId { get; private set; }
        public void Bind(EquipmentItem item, Sprite icon, string caption, string meta, string badge)
        {
            ItemId = item?.Id;
            Icon.sprite = icon; Icon.enabled = icon;
            Icon.color = item == null ? new Color(.50f, .66f, .78f, .50f) : Color.white;
            Rim.color = Color.white;
            if (RarityOutline) RarityOutline.effectColor = item == null ? new Color(.17f, .31f, .43f) : EquipmentGenerator.RarityColor(item.Rarity);
            Caption.text = caption; Meta.text = meta; Badge.text = badge;
        }
        public void Pulse()
        {
            Icon.transform.DOKill(); Icon.transform.localScale = Vector3.one * .84f;
            Icon.transform.DOScale(1, .25f).SetEase(Ease.OutBack).SetUpdate(true);
        }
        public void BindContent(string id, Sprite icon, int quality, string caption, string meta, string badge)
        {
            ItemId = id; Icon.sprite = icon; Icon.enabled = icon; Icon.color = Color.white; Rim.color = Color.white;
            if (RarityOutline) RarityOutline.effectColor = EquipmentGenerator.RarityColor((EquipmentRarity)Mathf.Clamp(quality, 0, 3));
            Caption.text = caption; Meta.text = meta; Badge.text = badge;
        }
        private void OnDisable() { Icon.transform.DOKill(); Icon.transform.localScale = Vector3.one; }
    }
}

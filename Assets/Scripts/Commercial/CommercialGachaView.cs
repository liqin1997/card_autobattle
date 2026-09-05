using System;
using System.Collections.Generic;
using System.Linq;
using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    public sealed class CommercialGachaView : MonoBehaviour
    {
        public RectTransform PageBounds, RootUI, ModalRoot;
        private CommercialPrototypeController controller;
        private readonly Dictionary<string, Transform> widgets = new();
        private bool bound, wasVisible;
        private string selectedCardId;
        private CommercialGachaRarity selectedRarity;
        private int poolIndex;
        private float nextRefresh;
        private CommercialGameState State => controller.State;
        private Transform W(string name) => widgets.TryGetValue(name, out var value) ? value : null;
        private Text T(string name) => W(name)?.GetComponent<Text>();
        private Button B(string name) => W(name)?.GetComponent<Button>();
        private void SetText(string name, string value) { var text = T(name); if (text) text.text = value; }

        private void Start() { Bind(); Refresh(); }
        private void Bind()
        {
            if (bound || !RootUI || !ModalRoot) return;
            controller = GetComponent<CommercialPrototypeController>();
            foreach (var root in new[] { RootUI, ModalRoot })
                foreach (var child in root.GetComponentsInChildren<Transform>(true)) widgets.TryAdd(child.name, child);
            bound = true;
            B("GACHA_Draw1")?.onClick.AddListener(() => Draw(1));
            B("GACHA_Draw10")?.onClick.AddListener(() => Draw(10));
            B("GACHA_CloseResult")?.onClick.AddListener(CloseModals);
            B("GACHA_Upgrade")?.onClick.AddListener(UpgradeSelected);
            for (var i = 0; i < 3; i++)
            {
                var index = i;
                B("GACHA_Pool_" + i)?.onClick.AddListener(() => { poolIndex = index; Refresh(); Pulse(B("GACHA_Pool_" + index)?.transform); });
            }
            for (var i = 0; i < 6; i++)
            {
                var index = i;
                B("GACHA_Card_" + i)?.onClick.AddListener(() => ShowCard(FeaturedCards()[index].Id, CommercialGachaRarity.Rare, null));
            }
        }

        private void Update()
        {
            if (!bound || controller.State == null) return;
            var visible = PageBounds.gameObject.activeInHierarchy;
            if (wasVisible && !visible) CloseModals();
            if (visible && (!wasVisible || Time.unscaledTime >= nextRefresh)) { nextRefresh = Time.unscaledTime + .25f; Refresh(); FitLayout(); }
            wasVisible = visible;
        }

        public void Refresh()
        {
            Bind(); if (!bound || State == null || !PageBounds.gameObject.activeInHierarchy) return;
            SetText("GACHA_Currency", State.PremiumCurrency.ToString("N0"));
            SetText("GACHA_Pity", $"传说保底  {State.GachaPity} / {CommercialGachaService.LegendaryPity}");
            var fill = W("GACHA_PityFill") as RectTransform;
            if (fill) fill.anchorMax = new Vector2(Mathf.Clamp01(State.GachaPity / (float)CommercialGachaService.LegendaryPity), 1);
            SetText("GACHA_BannerTitle", new[] { "灰烬誓约", "荒野回响", "秘仪洪流" }[poolIndex]);
            SetText("GACHA_BannerBody", "召唤获得当前项目卡牌；重复卡牌转化为升级碎片。\n每 10 抽至少出现史诗结果，50 抽传说保底。数值提升从下一场战斗生效。");
            var cards = FeaturedCards();
            for (var i = 0; i < 6; i++)
            {
                var card = cards[i]; var progress = State.GetCardProgress(card.Id);
                SetText("GACHA_CardName_" + i, card.DisplayName);
                SetText("GACHA_CardLevel_" + i, $"Lv.{progress.Level}  碎片 {progress.Copies}/{CommercialGachaService.RequiredCopies(progress.Level)}");
                var image = W("GACHA_CardArt_" + i)?.GetComponent<Image>(); if (image) image.sprite = CardArt(card);
            }
            for (var i = 0; i < 3; i++) if (B("GACHA_Pool_" + i)) B("GACHA_Pool_" + i).image.color = i == poolIndex ? new Color(.22f,.54f,.91f,1) : new Color(.06f,.12f,.25f,.92f);
            FitLayout();
        }

        private CommercialCardDefinition[] FeaturedCards()
        {
            var all = CommercialCardCatalog.All.ToArray();
            return Enumerable.Range(0, 6).Select(i => all[(i + poolIndex * 5) % all.Length]).ToArray();
        }

        private void Draw(int count)
        {
            var error = CommercialGachaService.Draw(State, count, out var results);
            if (error != null) { ShowToast(error); return; }
            var best = results.OrderByDescending(result => result.Rarity).First();
            var summary = count == 1 ? null : string.Join("  ·  ", results.GroupBy(result => result.Rarity)
                .OrderByDescending(group => group.Key).Select(group => CommercialGachaService.RarityName(group.Key) + "×" + group.Count()));
            ShowCard(best.CardId, best.Rarity, summary);
            controller.NotifyCardProgressChanged();
        }

        private void ShowCard(string cardId, CommercialGachaRarity rarity, string summary)
        {
            selectedCardId = cardId; selectedRarity = rarity;
            var card = CommercialCardCatalog.Get(cardId); if (card == null) return;
            var progress = State.GetCardProgress(cardId);
            SetText("GACHA_ResultRarity", CommercialGachaService.RarityName(rarity));
            SetText("GACHA_ResultName", card.DisplayName);
            SetText("GACHA_ResultInfo", summary ?? $"{card.Type} · {card.Cooldown:0.0} 秒触发\n{card.Description}");
            SetText("GACHA_ResultProgress", $"Lv.{progress.Level}  ·  碎片 {progress.Copies}/{CommercialGachaService.RequiredCopies(progress.Level)}\n每级基础数值 +10%，当前 +{(progress.Level - 1) * 10}%");
            var art = W("GACHA_ResultArt")?.GetComponent<Image>(); if (art) art.sprite = CardArt(card);
            var upgrade = B("GACHA_Upgrade");
            if (upgrade)
            {
                upgrade.GetComponentInChildren<Text>().text = progress.Level >= CommercialGachaService.MaxCardLevel ? "已满级" : $"升级  {CommercialGachaService.UpgradeGold(progress.Level)} 金币";
                upgrade.interactable = progress.Level < CommercialGachaService.MaxCardLevel && progress.Copies >= CommercialGachaService.RequiredCopies(progress.Level) && State.Gold >= CommercialGachaService.UpgradeGold(progress.Level);
            }
            var modal = W("GACHA_ResultModal"); modal.gameObject.SetActive(true);
            var group = modal.GetComponent<CanvasGroup>(); group.DOKill(); group.alpha = 0; group.DOFade(1, .18f).SetUpdate(true);
            var panel = modal.Find("Panel"); panel.DOKill(); panel.localScale = Vector3.one * .82f; panel.DOScale(1, .28f).SetEase(Ease.OutBack).SetUpdate(true);
            var resultArt = W("GACHA_ResultArt"); resultArt.DOKill(); resultArt.localScale = Vector3.one * .72f; resultArt.DOScale(1, .38f).SetEase(Ease.OutBack).SetDelay(.06f).SetUpdate(true);
            FitLayout();
        }

        private void UpgradeSelected()
        {
            var error = CommercialGachaService.Upgrade(State, selectedCardId);
            if (error != null) { ShowToast(error); return; }
            Pulse(W("GACHA_ResultArt")); ShowToast("卡牌升级成功，基础数值已提升");
            controller.NotifyCardProgressChanged(); ShowCard(selectedCardId, selectedRarity, null);
        }

        public void CloseModals()
        {
            if (!bound) return; var modal = W("GACHA_ResultModal"); if (!modal) return;
            modal.DOKill(); modal.gameObject.SetActive(false);
        }

        private void ShowToast(string value)
        {
            SetText("GACHA_ToastText", value); var group = W("GACHA_Toast")?.GetComponent<CanvasGroup>(); if (!group) return;
            group.DOKill(); group.alpha = 1; group.DOFade(0, .3f).SetDelay(2.4f).SetUpdate(true);
        }

        private static void Pulse(Transform target) { if (!target) return; target.DOKill(); target.localScale = Vector3.one; target.DOPunchScale(Vector3.one * .08f, .22f, 7, .5f).SetUpdate(true); }
        private void FitLayout()
        {
            if (RootUI && PageBounds) RootUI.localScale = Vector3.one * Mathf.Min(PageBounds.rect.width / 1080f, PageBounds.rect.height / 1586f);
            var panel = W("GACHA_ResultModal")?.Find("Panel") as RectTransform;
            if (panel) panel.localScale = Vector3.one * Mathf.Min(1, (ModalRoot.rect.width - 40) / panel.rect.width, (ModalRoot.rect.height - 80) / panel.rect.height);
        }

        private static Sprite CardArt(CommercialCardDefinition card)
        {
            var key = card == null ? "summon_skull" : card.Id == "stone_guard" || card.Tags.HasFlag(CommercialCardTag.Defense) ? "defense_shield" :
                card.Id == "arc_battery" || card.Tags.HasFlag(CommercialCardTag.Magic) ? "thunder_cannon" :
                card.Id == "longbow" || card.Id == "quick_dagger" ? "gun_rifle" :
                card.Tags.HasFlag(CommercialCardTag.Weapon) ? "sword_relic" : card.Tags.HasFlag(CommercialCardTag.Summon) ? "summon_skull" : "thunder_cannon";
            return Resources.Load<Sprite>("Commercial/BattleUI/battle_card_art_" + key + "_544x336");
        }

        private void OnDestroy() { DOTween.Kill(RootUI); DOTween.Kill(ModalRoot); }
    }
}

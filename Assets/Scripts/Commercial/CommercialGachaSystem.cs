using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

namespace CardAutobattle.Commercial
{
    public enum CommercialGachaRarity { Rare, Epic, Legendary }

    public sealed class CommercialGachaResult
    {
        public string CardId;
        public CommercialGachaRarity Rarity;
        public int GrantedCopies;
        public bool FirstUnlock;
    }

    public static class CommercialGachaService
    {
        public const int SingleCost = 300;
        public const int TenCost = 2700;
        public const int LegendaryPity = 50;
        public const int MaxCardLevel = 20;

        public static string Draw(CommercialGameState state, int count, out List<CommercialGachaResult> results)
        {
            results = new List<CommercialGachaResult>();
            if (state == null || count != 1 && count != 10) return "抽取参数无效";
            state.EnsureCharacterData();
            var cost = count == 1 ? SingleCost : TenCost;
            if (state.PremiumCurrency < cost) return "召唤晶石不足";
            state.PremiumCurrency -= cost;
            for (var i = 0; i < count; i++) results.Add(Roll(state));
            CommercialSaveService.Save(state);
            return null;
        }

        private static CommercialGachaResult Roll(CommercialGameState state)
        {
            state.GachaSequence++;
            state.GachaPity++;
            var random = new System.Random(9173 + state.GachaSequence * 104729);
            CommercialGachaRarity rarity;
            if (state.GachaPity >= LegendaryPity) rarity = CommercialGachaRarity.Legendary;
            else if (state.GachaSequence % 10 == 0) rarity = CommercialGachaRarity.Epic;
            else
            {
                var roll = random.NextDouble();
                rarity = roll < .03 ? CommercialGachaRarity.Legendary : roll < .25 ? CommercialGachaRarity.Epic : CommercialGachaRarity.Rare;
            }
            if (rarity == CommercialGachaRarity.Legendary) state.GachaPity = 0;
            var pool = CommercialCardCatalog.All.Where(card => card.Id != CommercialGameState.HeroCardId).ToArray();
            var definition = pool[random.Next(pool.Length)];
            var first = !state.OwnedCardIds.Contains(definition.Id);
            if (first) state.OwnedCardIds.Add(definition.Id);
            var progress = state.GetCardProgress(definition.Id);
            var copies = first ? 0 : rarity == CommercialGachaRarity.Legendary ? 10 : rarity == CommercialGachaRarity.Epic ? 3 : 1;
            progress.Copies += copies;
            return new CommercialGachaResult { CardId = definition.Id, Rarity = rarity, GrantedCopies = copies, FirstUnlock = first };
        }

        public static int RequiredCopies(int level) => 2 + Mathf.Max(1, level) * 2;
        public static int UpgradeGold(int level) => 100 * Mathf.Max(1, level) * Mathf.Max(1, level);

        public static string Upgrade(CommercialGameState state, string cardId)
        {
            if (state == null || CommercialCardCatalog.Get(cardId) == null) return "卡牌不存在";
            var progress = state.GetCardProgress(cardId);
            if (progress.Level >= MaxCardLevel) return "卡牌已达到当前等级上限";
            var copies = RequiredCopies(progress.Level);
            var gold = UpgradeGold(progress.Level);
            if (progress.Copies < copies) return "卡牌碎片不足";
            if (state.Gold < gold) return "金币不足";
            progress.Copies -= copies;
            state.Gold -= gold;
            progress.Level++;
            CommercialSaveService.Save(state);
            return null;
        }

        public static string RarityName(CommercialGachaRarity rarity) => rarity switch
        {
            CommercialGachaRarity.Legendary => "传说",
            CommercialGachaRarity.Epic => "史诗",
            _ => "稀有"
        };
    }
}

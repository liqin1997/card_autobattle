using System;
using System.Linq;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEngine;

namespace CardAutobattle.EditorTools
{
    public static class CommercialGachaAcceptance
    {
        [MenuItem("Tools/Card Autobattle/Validate Integrated Inventory And Gacha")]
        public static void Validate()
        {
            const string saveKey = "CardAutobattle.CommercialSave.v1";
            var hadSave = PlayerPrefs.HasKey(saveKey);
            var previousSave = PlayerPrefs.GetString(saveKey, string.Empty);
            try
            {
                var state = CommercialGameState.CreateDefault();
                state.PremiumCurrency = 100000;
                state.Gold = 100000;
                var beforeCurrency = state.PremiumCurrency;
                var error = CommercialGachaService.Draw(state, 10, out var results);
            Require(error == null, error);
            Require(results.Count == 10, "Ten-pull did not produce ten cards.");
            Require(state.PremiumCurrency == beforeCurrency - CommercialGachaService.TenCost, "Ten-pull cost mismatch.");
            Require(results.All(result => CommercialCardCatalog.Get(result.CardId) != null), "Unknown card in gacha result.");
            Require(results.Any(result => result.Rarity >= CommercialGachaRarity.Epic), "Ten-pull guarantee failed.");

            var cardId = results[0].CardId;
            var progress = state.GetCardProgress(cardId);
            progress.Level = 1;
            progress.Copies = CommercialGachaService.RequiredCopies(progress.Level);
            var beforeMultiplier = state.CardLevelMultiplier(cardId);
            error = CommercialGachaService.Upgrade(state, cardId);
            Require(error == null, error);
            Require(progress.Level == 2, "Card level did not increase.");
            Require(Mathf.Approximately(state.CardLevelMultiplier(cardId), beforeMultiplier + .1f), "Card multiplier did not increase by 10%.");

            var blade = state.GetCardProgress("iron_blade");
            blade.Level = 1;
            var levelOne = new CommercialBattleSession(state, state.DraftFormation, 7123).GetCurrentResolvedPower(3);
            blade.Level = 2;
            var levelTwo = new CommercialBattleSession(state, state.DraftFormation, 7123).GetCurrentResolvedPower(3);
            Require(levelTwo > levelOne && Mathf.Abs(levelTwo / levelOne - 1.1f) < .001f, "Battle did not consume card level multiplier.");

            Require(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Resources/Commercial/Prefabs/PF_Screen_InventoryEquipment.prefab"), "Integrated inventory prefab missing.");
            Require(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Resources/Commercial/Prefabs/PF_Screen_Gacha.prefab"), "Gacha prefab missing.");
            Require(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/Resources/Commercial/Prefabs/PF_Popup_GachaResult.prefab"), "Gacha result prefab missing.");
                Debug.Log($"[CommercialGachaAcceptance] PASS · cards={results.Count} · L1={levelOne:0.00} · L2={levelTwo:0.00}");
            }
            finally
            {
                if (hadSave) PlayerPrefs.SetString(saveKey, previousSave);
                else PlayerPrefs.DeleteKey(saveKey);
                PlayerPrefs.Save();
            }
        }

        private static void Require(bool condition, string message)
        {
            if (!condition) throw new InvalidOperationException(message ?? "Acceptance failed.");
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text;
using CardAutobattle.Commercial;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class CommercialAshenForestAcceptance
    {
        private static int checks;
        private const BindingFlags Flags = BindingFlags.Instance | BindingFlags.NonPublic;
        private static void Check(bool ok, string label)
        { if (!ok) throw new InvalidOperationException("Forest acceptance failed: " + label); checks++; }
        private static CommercialBattleSession Fight(CommercialGameState s, string id, int seed, bool reward = true)
        {
            var encounter = CommercialWorldCatalog.CreateEncounter(s, id);
            Check(encounter != null, "encounter accessible: " + id);
            var b = new CommercialBattleSession(s, s.DraftFormation, seed, encounter); b.Advance(300);
            if (reward)
            { Check(b.Result == CommercialBattleResult.Victory, "earned victory: " + id); CommercialWorldCatalog.RecordVictory(s, encounter); }
            return b;
        }
        public static CommercialGameState EarnBossReady(int seed)
        {
            var s = CommercialGameState.CreateDefault(); CommercialWorldCatalog.RevealRegion(s, 1);
            Check(s.PlayerLevel == 1 && s.Equipped.Count == 0, "genuine level-one empty gear start");
            Check(s.World.RevealedNodes.Count == 3, "only three camp discoveries");
            Check(CommercialWorldCatalog.CreateEncounter(s, "boss_1") == null, "boss gated");
            Check(CommercialWorldCatalog.CreateEncounter(s, "main_2") == null, "next region gated");
            Check(CommercialAshenForest.Claim(s) != null, "cannot claim before accepting");
            Check(CommercialAshenForest.Accept(s) == null, "accept camp task");
            Fight(s, "main_1", seed); Fight(s, "main_1", seed + 1);
            Check(CommercialAshenForest.Ready(s), "two wins complete camp task");
            Check(CommercialAshenForest.Claim(s) == null, "camp reward");
            Check(s.PlayerLevel == 2, "reward grants level two");
            var weapon = s.Inventory.Last();
            Check(weapon.Slot == EquipmentSlot.MainWeapon && weapon.SetId == "iron_oath", "guaranteed weapon");
            Check(CommercialEquipmentService.Equip(s, weapon) == null, "weapon usable immediately");
            Check(CommercialAshenForest.Claim(s) != null, "reward cannot be double claimed");
            Check(CommercialAshenForest.Accept(s) == null, "accept scouting task");
            Check(CommercialWorldCatalog.CreateEncounter(s, "elite_1") == null, "scouting gate");
            Check(CommercialAshenForest.Interact(s, "af_scout") == null, "survey reveals elite");
            Fight(s, "elite_1", seed + 2); Check(CommercialAshenForest.Claim(s) == null, "elite quest reward");
            var armor = s.Inventory.Last();
            Check(s.PlayerLevel == 3 && armor.Slot == EquipmentSlot.Armor, "level three and guaranteed armor");
            Check(CommercialEquipmentService.Equip(s, armor) == null, "armor usable immediately");
            Check(CommercialEquipmentService.SetCount(s, "iron_oath") == 2, "two-piece set active");
            Check(CommercialAshenForest.Accept(s) == null, "accept bridge task");
            var wood = CommercialInventoryService.Count(s, "forest_wood");
            Check(CommercialAshenForest.Interact(s, "af_bridge") != null, "missing ore blocks bridge");
            Check(CommercialInventoryService.Count(s, "forest_wood") == wood, "failed bridge is atomic");
            Check(CommercialAshenForest.Interact(s, "af_orecache") == null, "ore collected into material storage");
            Check(CommercialAshenForest.Interact(s, "af_bridge") == null, "bridge consumes resources");
            Check(CommercialInventoryService.Count(s, "forest_wood") == wood - 8 && CommercialInventoryService.Count(s, "iron_ore") == 0, "exact material deduction");
            Check(CommercialAshenForest.Interact(s, "af_bridge") != null, "bridge cannot double spend");
            Check(CommercialAshenForest.Claim(s) == null && s.PlayerLevel == 4, "bridge reward reaches level four");
            Check(CommercialAshenForest.Accept(s) == null, "accept final task");
            Check(CommercialEquipmentService.Upgrade(s, EquipmentSlot.MainWeapon) == null, "earned gold and dust upgrade weapon");
            return s;
        }
        public static string RunDataChecks()
        {
            checks = 0; var s = EarnBossReady(2488); var log = new StringBuilder();
            var gearedWins = 0; var nakedWins = 0;
            for (var seed = 0; seed < 40; seed++)
            {
                var b = Fight(s, "boss_1", 2488 + seed * 91, false);
                if (b.Result == CommercialBattleResult.Victory) gearedWins++;
                var equipped = s.Equipped; s.Equipped = new();
                b = Fight(s, "boss_1", 2488 + seed * 91, false);
                if (b.Result == CommercialBattleResult.Victory) nakedWins++;
                s.Equipped = equipped;
            }
            Check(gearedWins == 40, "rewarded default formation consistently clears boss");
            Check(nakedWins <= 5, "same-level naked build has a meaningful equipment wall");
            Check(CommercialAshenForest.Interact(s, "af_relic") == null, "optional relic grants key");
            Check(CommercialAshenForest.Interact(s, "af_sealed") == null, "key unlocks optional chest");
            Check(CommercialInventoryService.Count(s, "ancient_key") == 0 && CommercialInventoryService.Count(s, "rare_equipment_chest") == 1, "key consumed and box stored");
            Check(CommercialInventoryService.Use(s, "rare_equipment_chest", 1, out _) == null, "box opens into equipment storage");
            Fight(s, "boss_1", 2488);
            Check(CommercialWorldCatalog.CreateEncounter(s, "main_2") == null, "boss kill alone does not bypass reward step");
            Check(CommercialAshenForest.Claim(s) == null, "final quest reward");
            Check(CommercialAshenForest.Finished(s) && CommercialWorldCatalog.Unlocked(s, CommercialWorldCatalog.Find("main_2")), "next region unlocked");
            Check(CommercialAshenForest.Claim(s) != null, "final reward receipt protected");
            CommercialWorldCatalog.RevealRegion(s, 2);
            Check(CommercialWorldCatalog.CreateEncounter(s, "main_2") != null, "next region enterable");
            var reload = JsonUtility.FromJson<CommercialGameState>(JsonUtility.ToJson(s)); reload.EnsureCharacterData();
            Check(CommercialAshenForest.Finished(reload) && CommercialAshenForest.Done(reload, "af_bridge"), "save round trip keeps quests and bridge");
            Check(reload.Equipped.Count == 2 && reload.Equipment.SlotUpgrades[5] == 1, "save keeps equipment strength");
            log.AppendLine($"PASS: {checks} data checks. Boss: geared {gearedWins}/40 wins; same-level no gear {nakedWins}/40 wins.");
            return log.ToString();
        }

        // UI acceptance uses the same button listeners as the player and the real battle simulation.
        // Only clock advancement is accelerated. No injected XP, equipment, wins or unlock flags.
        public static string RunRuntimeJourney()
        {
            if (!Application.isPlaying) throw new InvalidOperationException("Play Mode required");
            checks = 0;
            var c = UnityEngine.Object.FindObjectOfType<CommercialPrototypeController>();
            var map = c.GetComponent<CommercialWorldMapView>();
            c.enabled = false;
            typeof(CommercialPrototypeController).GetField("state", Flags).SetValue(c, CommercialGameState.CreateDefault());
            typeof(CommercialPrototypeController).GetField("battle", Flags).SetValue(c, null);
            typeof(CommercialPrototypeController).GetField("worldEncounter", Flags).SetValue(c, null);
            var s = c.State; CommercialWorldCatalog.RevealRegion(s, 1); map.Open(); map.ShowForestQuest();
            ClickAction(); Check(s.World.Forest.Accepted, "UI accepts initial task");
            ClickAction(); Check(map.SelectedNodeId == "main_1", "UI tracks camp");
            ClickAction(); Check(!map.IsOpen && c.Battle != null, "map combat returns to battle");
            Resolve(); c.RequestWorldEncounter("main_1"); Resolve();
            map.Open(); map.ShowForestQuest(); ClickAction(); Check(s.World.Forest.Step == 1, "UI claims first reward");
            EquipLast();
            map.Open(); map.ShowForestQuest(); ClickAction(); ClickAction();
            Check(map.SelectedNodeId == "af_scout", "UI tracks scout"); ClickAction();
            map.ShowForestQuest(); ClickAction(); Check(map.SelectedNodeId == "elite_1", "UI tracks elite after survey"); ClickAction(); Resolve();
            map.Open(); map.ShowForestQuest(); ClickAction(); Check(s.World.Forest.Step == 2, "UI claims armor"); EquipLast();
            map.Open(); map.ShowForestQuest(); ClickAction(); ClickAction();
            Check(map.SelectedNodeId == "af_orecache", "UI tracks missing material"); ClickAction();
            map.ShowForestQuest(); ClickAction(); Check(map.SelectedNodeId == "af_bridge", "UI tracks bridge"); ClickAction();
            map.ShowForestQuest(); ClickAction(); Check(s.World.Forest.Step == 3 && s.PlayerLevel == 4, "UI bridge reward and level-up");
            map.TrackButton.onClick.Invoke();
            var equipment = c.GetComponent<CommercialEquipmentView>(); equipment.ShowItem(s.GetEquipped(EquipmentSlot.MainWeapon));
            Button("EQ_Upgrade"); Button("EQ_ConfirmYes"); Check(s.Equipment.SlotUpgrades[5] == 1, "UI upgrade with earned resources");
            map.Open(); map.ShowForestQuest(); ClickAction(); ClickAction();
            Check(map.SelectedNodeId == "boss_1", "UI tracks boss"); ClickAction(); Resolve();
            map.Open(); map.ShowForestQuest(); ClickAction(); Check(CommercialAshenForest.Finished(s), "UI final reward unlock");
            ClickAction(); Check(map.SelectedNodeId == "af_exit", "UI tracks region exit"); ClickAction();
            Check(s.World.CurrentNodeId == "main_2" && c.Battle.Chapter == 2 && !map.IsOpen, "UI enters next region encounter");
            Check(CommercialSaveService.Load().World.Forest.Step == 4, "UI progression persisted");
            map.Open(); map.FocusNode("main_2");
            return $"PASS: {checks} runtime journey checks; Lv.{s.PlayerLevel}, {s.Equipped.Count} earned equipped pieces, weapon +{s.Equipment.SlotUpgrades[5]}, entered region 2. Temporary QA save; reset before delivery.";
            void ClickAction() { Check(map.ActionButton.interactable, "action enabled"); map.ActionButton.onClick.Invoke(); }
            void Resolve()
            {
                c.Battle.Advance(300); Check(c.Battle.Result == CommercialBattleResult.Victory, "real runtime battle victory");
                typeof(CommercialPrototypeController).GetMethod("ResolveBattle", Flags).Invoke(c, null);
            }
            void EquipLast()
            {
                var item = s.Inventory.Last(); var oldBattle = c.Battle;
                map.TrackButton.onClick.Invoke();
                var v = c.GetComponent<CommercialEquipmentView>(); v.ShowItem(item); Button("EQ_Equip");
                Check(s.GetEquipped(item.Slot) == item && ReferenceEquals(oldBattle, c.Battle), "equip UI preserves ongoing battle snapshot");
            }
            void Button(string name) => c.GetComponentsInChildren<Button>(true).First(b => b.name == name).onClick.Invoke();
        }
    }
}

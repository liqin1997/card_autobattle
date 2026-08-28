using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace CardAutobattle.EditorTools
{
    public static class CommercialInventoryAcceptance
    {
        private static int checks;
        private const string Key = "CardAutobattle.CommercialSave.v1";
        private const BindingFlags Flags = BindingFlags.NonPublic | BindingFlags.Instance;
        private static void Check(bool ok, string message) { if (!ok) throw new InvalidOperationException("Inventory acceptance: " + message); checks++; }
        private static bool Near(float a, float b) => Mathf.Abs(a - b) < .02f;
        private static string Json(CommercialGameState s) => JsonUtility.ToJson(s);
        private static void Set(object o, string field, object value) => o.GetType().GetField(field, Flags).SetValue(o, value);
        private static void Call(object o, string method) => o.GetType().GetMethod(method, Flags).Invoke(o, null);

        public static string RunDataChecks()
        {
            checks = 0;
            var config = CommercialInventoryCatalog.Balance;
            Check(config.Warehouses.Length == 4 && config.Items.Length == 15 && CommercialInventoryCatalog.Validate(config) == null, "warehouse and item configuration");
            var s = CommercialGameState.CreateDefault();
            var legacyGear = CommercialEquipmentService.Generate(1, 1, 104); s.Inventory.Add(legacyGear); s.Equip(legacyGear); s.Equipment.Dust = 17;
            s.Storage = null; s.SaveVersion = 4;
            var saved = Json(s); var restored = JsonUtility.FromJson<CommercialGameState>(saved); restored.EnsureCharacterData();
            CommercialEquipmentService.Migrate(restored); CommercialInventoryService.Migrate(restored);
            Check(restored.SaveVersion == 5 && restored.Inventory.Count == 1 && restored.Equipment.Dust == 17, "v4 migration preserves equipment and dust");
            Check(ReferenceEquals(restored.Inventory[0], restored.GetEquipped(legacyGear.Slot)), "canonical equipment rebind after load");
            var migrated = Json(restored); CommercialInventoryService.Migrate(restored); Check(migrated == Json(restored), "idempotent migration"); s = restored;
            var bundle = new InventoryRewardBundle { Gold = 60, Experience = 20 };
            foreach (var item in config.Items) bundle.Add(item.Id, 4);
            bundle.Equipment.Add(CommercialEquipmentService.Generate(1, 1, 219));
            Check(CommercialInventoryService.Grant(s, bundle, "验收", "reward:fixture") == null, "mixed reward grant");
            Check(s.Inventory.Count == 2 && CommercialInventoryService.Entries(s, "items").Count == 5 && CommercialInventoryService.Entries(s, "materials").Count == 7 && CommercialInventoryService.Entries(s, "special").Count == 3, "all warehouse routes");
            Check(s.Equipment.Dust == 21 && s.Storage.Stacks.All(x => x.ItemId != "forge_dust"), "single-source forging dust");
            var once = Json(s); Check(CommercialInventoryService.Grant(s, bundle, "验收", "reward:fixture") != null && once == Json(s), "receipt idempotency");
            var invalid = new InventoryRewardBundle { Gold = 100 }.Add("forest_wood", 9).Add("no_such_item", 1);
            Check(CommercialInventoryService.Grant(s, invalid, "无效奖励") != null && once == Json(s), "invalid mixed reward is atomic");
            Check(CommercialInventoryService.Grant(s, new InventoryRewardBundle().Add("forest_wood", -1), "无效数量") != null && once == Json(s), "negative quantity rejected");
            var duplicateGear = new InventoryRewardBundle(); duplicateGear.Equipment.Add(s.Inventory[0]);
            Check(CommercialInventoryService.Grant(s, duplicateGear, "重复装备") != null && once == Json(s), "duplicate gear rejected");
            Check(CommercialInventoryService.Grant(s, new InventoryRewardBundle().Add("forest_wood", int.MaxValue), "溢出") != null && once == Json(s), "quantity overflow rejected atomically");
            var purchase = new InventoryRewardBundle().Add("equipment_chest", 2);
            Check(CommercialInventoryService.GrantPurchase(s, purchase, "order-001") == null, "purchased box delivery");
            once = Json(s); Check(CommercialInventoryService.GrantPurchase(s, purchase, "order-001") != null && once == Json(s), "duplicate order blocked");
            Check(CommercialInventoryService.GrantPurchase(s, purchase, "") != null && once == Json(s), "purchase requires order id");
            Check(CommercialInventoryService.Count(s, "equipment_chest") == 6 && s.Storage.Stacks.Count(x => x.ItemId == "equipment_chest") == 1, "stack merging");
            var beforeGear = s.Inventory.Count;
            Check(CommercialInventoryService.Use(s, "equipment_chest", 3, out _) == null, "batch chest use");
            Check(s.Inventory.Count == beforeGear + 3 && s.Inventory.Skip(beforeGear).All(x => x.Rarity == EquipmentRarity.Blue) && CommercialInventoryService.Count(s, "equipment_chest") == 3, "three boxes produce three rare equipment items");
            Check(CommercialInventoryService.Use(s, "rare_equipment_chest", 1, out _) == null && s.Inventory.Last().Rarity == EquipmentRarity.Purple, "epic box quality");
            once = Json(s); Check(CommercialInventoryService.Use(s, "equipment_chest", 4, out _) != null && once == Json(s), "insufficient boxes cause no mutation");
            Check(CommercialInventoryService.Use(s, "ancient_key", 1, out _) != null && once == Json(s), "special item cannot be consumed directly");
            Check(CommercialInventoryService.Use(s, "supply_chest", 0, out _) != null && once == Json(s), "zero use rejected");
            var dust = s.Equipment.Dust;
            Check(CommercialInventoryService.Use(s, "material_pouch", 2, out _) == null && s.Equipment.Dust == dust + 10, "material box updates canonical forge dust");
            var level = s.PlayerLevel; Check(CommercialInventoryService.Use(s, "experience_scroll", 4, out _) == null && s.PlayerLevel > level, "experience item levels player");
            var wood = CommercialInventoryService.Count(s, "forest_wood");
            Check(CommercialInventoryService.ConsumeMaterials(s, new[] { new InventoryAmount("forest_wood", 1), new InventoryAmount("forge_dust", 2) }) == null && CommercialInventoryService.Count(s, "forest_wood") == wood - 1, "atomic material turn-in API");
            once = Json(s); Check(CommercialInventoryService.ConsumeMaterials(s, new[] { new InventoryAmount("forest_wood", 1), new InventoryAmount("ancient_key", 999) }) != null && once == Json(s), "failed turn-in does not consume partial materials");
            s.Storage.Stacks.Add(new InventoryStack { ItemId = "future_unknown", Count = 5 });
            var clone = JsonUtility.FromJson<CommercialGameState>(Json(s)); CommercialEquipmentService.Migrate(clone); CommercialInventoryService.Migrate(clone);
            Check(CommercialInventoryService.Entries(clone, "special").Any(x => x.ItemId == "future_unknown" && x.Count == 5), "unknown saved items preserved in special warehouse");
            Check(clone.Storage.ClaimedReceipts.Contains("order:order-001") && clone.Inventory.Count == s.Inventory.Count && clone.Equipment.Dust == s.Equipment.Dust, "inventory and receipts survive serialization");
            var def = CommercialInventoryCatalog.Get("ancient_key"); var oldWarehouse = def.WarehouseId; var warehouses = config.Warehouses;
            try
            {
                config.Warehouses = config.Warehouses.Concat(new[] { new WarehouseDefinition { Id = "season_archive", Name = "赛季仓库" } }).ToArray(); def.WarehouseId = "season_archive";
                Check(CommercialInventoryCatalog.Validate(config) == null && CommercialInventoryService.Entries(s, "season_archive").Any(x => x.ItemId == "ancient_key"), "config-only new warehouse routing");
            }
            finally { config.Warehouses = warehouses; def.WarehouseId = oldWarehouse; }
            var world = CommercialGameState.CreateDefault(); CommercialWorldCatalog.RevealRegion(world, 1);
            var idle = CommercialWorldCatalog.CreateEncounter(world, "main_1"); var idleDrops = new List<int>();
            for (var i = 0; i < 100; i++)
            {
                var oldWood = CommercialInventoryService.Count(world, "forest_wood");
                CommercialWorldCatalog.RecordVictory(world, idle);
                var delta = CommercialInventoryService.Count(world, "forest_wood") - oldWood;
                Check(delta >= 1 && delta <= 3, "idle regional material drop " + i); idleDrops.Add(delta);
            }
            Check(world.Inventory.Count > 0 && CommercialInventoryService.Count(world, "supply_chest") > 0, "idle gear and supply drops");
            Check(world.Stage == 1 && world.Chapter == 1 && world.Storage.Recent.Count == 20 && world.Storage.ClaimedReceipts.Count == 0, "no legacy stage advancement or unbounded idle receipts");
            // Generic reward routing is exercised in region 2. Region 1 now has the earned forest quest chain.
            world.World.RegionTasks[0].Claimed = true; world.World.Ensure(); CommercialWorldCatalog.RevealRegion(world, 2);
            Check(CommercialWorldCatalog.AcceptQuest(world, 2), "accept regional quest");
            CommercialWorldCatalog.RecordVictory(world, CommercialWorldCatalog.CreateEncounter(world, "elite_2"));
            var material = CommercialInventoryCatalog.RegionMaterial(2);
            var gearCount = world.Inventory.Count; var materialCount = CommercialInventoryService.Count(world, material);
            Check(CommercialWorldCatalog.ClaimQuest(world, "quest_2") && world.Inventory.Count == gearCount + 1 && CommercialInventoryService.Count(world, material) == materialCount + 4 && world.Equipment.Dust == 2, "quest awards gear and materials to correct warehouses");
            once = Json(world); Check(!CommercialWorldCatalog.ClaimQuest(world, "quest_2") && once == Json(world), "quest exactly once");
            Check(CommercialWorldCatalog.ClaimChest(world, "chest_2") && CommercialInventoryService.Count(world, "equipment_chest") == 1, "map chest delivers unopened equipment box");
            once = Json(world); Check(!CommercialWorldCatalog.ClaimChest(world, "chest_2") && once == Json(world), "map chest exactly once");
            for (var i = 0; i < 5; i++) CommercialWorldCatalog.RecordVictory(world, CommercialWorldCatalog.CreateEncounter(world, "main_2"));
            CommercialWorldCatalog.RecordVictory(world, CommercialWorldCatalog.CreateEncounter(world, "boss_2"));
            Check(CommercialInventoryService.Count(world, "boss_essence") == 1 && CommercialWorldCatalog.ClaimMainReward(world), "boss materials and main task claim");
            Check(CommercialInventoryService.Count(world, "rare_equipment_chest") == 1 && CommercialInventoryService.Count(world, "quest_seal") == 1, "main task item/special warehouse routes");
            return "PASS: " + checks + " inventory/reward/save-data checks. No persistent save writes.";
        }

        public static string RunRuntimeChecks()
        {
            if (!Application.isPlaying) throw new InvalidOperationException("Enter Play Mode first.");
            checks = 0; ShowFixture("items");
            var c = UnityEngine.Object.FindObjectOfType<CommercialPrototypeController>(); var s = c.State;
            var view = c.GetComponent<CommercialInventoryView>(); var equipment = c.GetComponent<CommercialEquipmentView>();
            Check(view.RootUI.gameObject.activeInHierarchy && view.TabContent.GetComponentsInChildren<Button>().Length == 4, "backpack navigation + four tabs");
            Check(view.Cells.Where(x => x.gameObject.activeSelf).All(x => x.Icon.sprite != null && x.Rim.raycastTarget), "item art and pointer targets");
            var firstFight = c.Battle; var firstAP = firstFight.CharacterSnapshot.AbilityPower;
            var item = CommercialEquipmentService.Generate(1, 1, 1985, EquipmentSlot.MainWeapon, EquipmentRarity.Gold, "arcanist", 25);
            item.BaseStats.Add(new EquipmentStatValue(EquipmentStat.AbilityPower, 35));
            item.BaseStats.Add(new EquipmentStatValue(EquipmentStat.Health, 100));
            var rewards = new InventoryRewardBundle(); rewards.Equipment.Add(item); Check(CommercialInventoryService.Grant(s, rewards, "战利品验收") == null, "gear enters canonical warehouse");
            view.SelectWarehouse("equipment"); view.Refresh(); view.Cells.First(x => x.ItemId == item.Id).Button.onClick.Invoke();
            Check(equipment.ModalRoot.Find("EQ_DetailModal").gameObject.activeSelf, "backpack gear opens shared comparison");
            Click(c, "EQ_Equip");
            Check(s.GetEquipped(item.Slot) == item && ReferenceEquals(firstFight, c.Battle) && Near(firstAP, c.Battle.CharacterSnapshot.AbilityPower), "equipping preserves active battle snapshot");
            Click(c, "Nav_2"); Check(!equipment.ModalRoot.Find("EQ_DetailModal").gameObject.activeSelf, "cross-page equipment popup closes");
            Click(c, "Nav_0"); var oldWood = CommercialInventoryService.Count(s, "forest_wood");
            firstFight.Advance(120); Check(firstFight.Result == CommercialBattleResult.Victory, "actual idle battle wins while backpack visible");
            Call(c, "ResolveBattle");
            Check(CommercialInventoryService.Count(s, "forest_wood") > oldWood && s.World.RegionTasks[0].IdleWins == 1, "idle settlement routes materials while viewing bag");
            var settled = Json(s); Call(c, "ResolveBattle"); Check(settled == Json(s), "completed battle settles once");
            Set(c, "nextBattleDelay", .000001f); Call(c, "Update");
            Check(!ReferenceEquals(c.Battle, firstFight) && view.RootUI.gameObject.activeInHierarchy, "automatic next battle starts without switching out of backpack");
            var expected = CommercialCharacterCalculator.BuildSnapshot(s); var actual = c.Battle.CharacterSnapshot;
            Check(!Near(actual.AbilityPower, firstAP) && Near(actual.AbilityPower, expected.AbilityPower) && Near(actual.MaxHealth, expected.MaxHealth) && Near(actual.Armor, expected.Armor) && Near(actual.CritChance, expected.CritChance) && Near(actual.HeroAttackInterval, expected.HeroAttackInterval), "automatic continuation adopts all equipment stats");
            c.Battle.Advance(120); Check(c.Battle.Result == CommercialBattleResult.Victory, "new equipment real idle battle wins"); Call(c, "ResolveBattle");
            view.SelectWarehouse("items"); view.ShowItem("equipment_chest"); Click(c, "BAG_Plus"); var n = s.Inventory.Count;
            Click(c, "BAG_Use"); Check(s.Inventory.Count == n + 2 && CommercialInventoryService.Count(s, "equipment_chest") == 10, "batch box UI grants two gear and consumes two boxes");
            view.ShowItem("experience_scroll"); Click(c, "BAG_Max"); Click(c, "BAG_Use");
            Check(CommercialInventoryService.Count(s, "experience_scroll") == 0 && !view.ModalRoot.Find("BAG_ItemModal").gameObject.activeSelf, "using final stack closes detail");
            view.SelectWarehouse("materials"); Check(view.Cells.Any(x => x.ItemId == "forge_dust"), "canonical forge dust shown in materials");
            view.Search.text = "灰烬"; Check(view.Cells.Count(x => x.gameObject.activeSelf) == 1 && view.Cells.First(x => x.gameObject.activeSelf).ItemId == "forest_wood", "name search");
            view.SelectWarehouse("equipment"); var firstId = view.Cells[0].ItemId; Click(c, "BAG_Next"); Check(view.Cells[0].ItemId != firstId, "gear warehouse pagination");
            view.SelectWarehouse("special"); view.ShowItem("ancient_key"); Check(!Find(c, "BAG_Use").gameObject.activeSelf, "special item cannot use from UI");
            Click(c, "Nav_3"); Check(!view.ModalRoot.Find("BAG_ItemModal").gameObject.activeSelf, "item popup closes on navigation");
            CommercialSaveService.Save(s); var reloaded = CommercialSaveService.Load();
            Check(reloaded.Inventory.Count == s.Inventory.Count && CommercialInventoryService.Count(reloaded, "equipment_chest") == 10 && reloaded.GetEquipped(item.Slot)?.Id == item.Id, "real PlayerPrefs reload keeps boxes/gear/equipment");
            view.SelectWarehouse("items"); Click(c, "Nav_0");
            CheckFit(view, 1080, 1586); CheckFit(view, 1080, 2006); CheckFit(view, 750, 1100); CheckFit(view, 1536, 1714);
            Canvas.ForceUpdateCanvases(); view.FitLayout();
            return "PASS: " + checks + " runtime UI/automatic-idle/equipment/save/layout checks. Temporary fixture; restore baseline after Play Mode.";
        }
        private static void CheckFit(CommercialInventoryView view, float width, float height)
        {
            var scale = Mathf.Min(width / 1080f, height / 1586f);
            Check(view.RootUI.rect.width * scale <= width + .1f && view.RootUI.rect.height * scale <= height + .1f, "reference layout fits " + width + "x" + height);
        }
        public static string ShowFixture(string warehouse = "items", string detailId = null)
        {
            CommercialEquipmentAcceptance.ShowFixture();
            var c = UnityEngine.Object.FindObjectOfType<CommercialPrototypeController>(); var s = c.State;
            var bundle = new InventoryRewardBundle(); foreach (var def in CommercialInventoryCatalog.Balance.Items) bundle.Add(def.Id, 12);
            var error = CommercialInventoryService.Grant(s, bundle, "验收样例"); if (error != null) throw new InvalidOperationException(error);
            c.NotifyEquipmentChanged(); Click(c, "Nav_0"); var view = c.GetComponent<CommercialInventoryView>(); view.SelectWarehouse(warehouse);
            if (detailId != null) view.ShowItem(detailId);
            return "Temporary inventory QA fixture; player baseline is backed up.";
        }
        public static string RunPointerCheck()
        {
            var view = UnityEngine.Object.FindObjectOfType<CommercialInventoryView>();
            var button = view.Cells.First(x => x.gameObject.activeInHierarchy).Button;
            var rect = (RectTransform)button.transform;
            var pointer = new PointerEventData(EventSystem.current) { position = RectTransformUtility.WorldToScreenPoint(null, rect.TransformPoint(rect.rect.center)) };
            var results = new List<RaycastResult>(); EventSystem.current.RaycastAll(pointer, results);
            Check(results.Count > 0 && results[0].gameObject.GetComponentInParent<Button>() == button, "actual rendered pointer target");
            ExecuteEvents.Execute(button.gameObject, pointer, ExecuteEvents.pointerClickHandler);
            Check(view.ModalRoot.Find("BAG_ItemModal").gameObject.activeSelf, "actual pointer opens detail");
            return "PASS: real raycast + pointer click opens item detail.";
        }
        public static string RestoreOriginalPlayerSave()
        {
            if (Application.isPlaying) throw new InvalidOperationException("Exit Play Mode first.");
            var original = SessionState.GetString("InventoryAcceptance.OriginalSave", "__missing__");
            if (original == "__missing__") throw new InvalidOperationException("No inventory baseline backup.");
            if (SessionState.GetBool("InventoryAcceptance.HadSave", false)) PlayerPrefs.SetString(Key, original); else PlayerPrefs.DeleteKey(Key);
            PlayerPrefs.Save(); return "Original player save restored; exact match=" + (PlayerPrefs.GetString(Key, "") == original);
        }
        private static Transform Find(CommercialPrototypeController c, string name) => CommercialPrototypeController.FindDeep(c.transform, name);
        private static void Click(CommercialPrototypeController c, string name) => Find(c, name).GetComponent<Button>().onClick.Invoke();
    }
}

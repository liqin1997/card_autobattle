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
    public static class CommercialEquipmentAcceptance
    {
        private static int checks;
        private const string SaveKey = "CardAutobattle.CommercialSave.v1";
        private const BindingFlags Flags = BindingFlags.Instance | BindingFlags.NonPublic;
        private static void Check(bool value, string message)
        { if (!value) throw new InvalidOperationException("Equipment acceptance: " + message); checks++; }
        private static bool Near(float a, float b) => Mathf.Abs(a - b) < .015f;

        public static string RunDataChecks()
        {
            checks = 0; CommercialEquipmentCatalog.Reload(); var config = CommercialEquipmentCatalog.Balance;
            Check(config.Slots.Length == 6 && config.Sets.Length == 5 && config.Affixes.Length == 21, "6 slots, 5 sets, 21 affix types");
            var legacy = CommercialGameState.CreateDefault();
            var old = new EquipmentItem { Id = "legacy_test", Slot = EquipmentSlot.MainWeapon, DisplayName = "旧武器", Attack = 35, Health = 90, Defense = 12, AttackSpeed = .1f };
            legacy.Inventory.Add(old); legacy.Equip(old); var before = CommercialCharacterCalculator.BuildSnapshot(legacy);
            var restored = JsonUtility.FromJson<CommercialGameState>(JsonUtility.ToJson(legacy)); CommercialEquipmentService.Migrate(restored);
            var after = CommercialCharacterCalculator.BuildSnapshot(restored);
            Check(ReferenceEquals(restored.Inventory[0], restored.GetEquipped(EquipmentSlot.MainWeapon)), "save rebinds item identity");
            Check(Near(before.AbilityPower, after.AbilityPower) && Near(before.MaxHealth, after.MaxHealth) && Near(before.HeroAttackInterval, after.HeroAttackInterval) && Near(before.Armor, after.Armor), "old gear retains exact attributes");
            var json = JsonUtility.ToJson(restored); CommercialEquipmentService.Migrate(restored);
            Check(json == JsonUtility.ToJson(restored), "migration idempotent");
            Check(restored.Inventory[0].RequiredLevel == 1 && restored.Inventory[0].Legacy, "old equipment remains wearable");

            foreach (var set in config.Sets)
            {
                var s = RichState();
                for (var i = 0; i < 6; i++)
                {
                    var item = CommercialEquipmentService.Generate(1, 1, 2000 + i, (EquipmentSlot)i, i % 2 == 0 ? EquipmentRarity.Blue : EquipmentRarity.Gold, set.Id, 15);
                    s.Inventory.Add(item); Check(CommercialEquipmentService.Equip(s, item) == null, "equip generated " + set.Id + i);
                    var raw = new EquipmentStatBlock(); foreach (var entry in s.Equipped) raw.Add(CommercialEquipmentService.ItemStats(entry.Item));
                    foreach (var bonus in set.Bonuses.Where(b => b.Pieces <= i + 1)) foreach (var stat in bonus.Stats) raw.Add(stat.Kind, stat.Value);
                    var actual = CommercialEquipmentService.Aggregate(s);
                    Check(Enum.GetValues(typeof(EquipmentStat)).Cast<EquipmentStat>().All(stat => Near(raw[stat], actual[stat])), set.Id + " exact " + (i + 1) + " piece threshold");
                }
                Check(CommercialEquipmentService.SetCount(s, set.Id) == 6, "mixed quality 6-piece set");
                var empty = CommercialEquipmentService.Aggregate(s, EquipmentSlot.Head, null);
                CommercialEquipmentService.Unequip(s, EquipmentSlot.Head); var unequipped = CommercialEquipmentService.Aggregate(s);
                Check(Enum.GetValues(typeof(EquipmentStat)).Cast<EquipmentStat>().All(stat => Near(empty[stat], unequipped[stat])), "preview matches real set break");
            }
            for (var quality = 0; quality < 4; quality++) for (var n = 0; n < 40; n++)
            {
                var item = CommercialEquipmentService.Generate(1 + n % 5, n % 20 + 1, n * 491 + quality, forcedRarity: (EquipmentRarity)quality);
                Check(item.Affixes.Count == config.Rarities[quality].AffixCount && item.Affixes.Select(a => a.Stat).Distinct().Count() == item.Affixes.Count &&
                    item.Affixes.All(a => a.Value >= a.Min && a.Value <= a.Max) && item.BaseStats.All(s => s.Value >= 0), "valid randomized roll " + quality + "/" + n);
            }
            Check(Enumerable.Range(1, 1000).Select(n => EquipmentGenerator.Generate(3, 10, n).Rarity).Distinct().Count() == 4, "all four qualities drop");

            var baseline = CommercialGameState.CreateDefault(); var naked = CommercialCharacterCalculator.BuildSnapshot(baseline);
            foreach (CommercialProfessionId profession in Enum.GetValues(typeof(CommercialProfessionId)))
            {
                baseline.SwitchProfession(profession); var p = CommercialCharacterCalculator.BuildSnapshot(baseline);
                for (var i = 0; i < 4; i++)
                {
                    var gear = new EquipmentStatBlock(); gear.Add((EquipmentStat)i, 10);
                    var stat = CommercialCharacterCalculator.BuildSnapshot(baseline, equipmentOverride: gear);
                    Check(stat.AbilityPower > p.AbilityPower, profession + " four-dimensional scaling " + i);
                }
            }
            var mods = new EquipmentStatBlock(); mods.Add(EquipmentStat.DamageBonus, .2f); mods.Add(EquipmentStat.HealingBonus, .3f); mods.Add(EquipmentStat.ShieldBonus, .4f);
            mods.Add(EquipmentStat.ProjectileBonus, .1f); mods.Add(EquipmentStat.MagicBonus, .15f); mods.Add(EquipmentStat.SummonDamageBonus, .25f); mods.Add(EquipmentStat.BasicAttackBonus, .2f);
            baseline.SwitchProfession(CommercialProfessionId.Warrior);
            var modified = CommercialCharacterCalculator.BuildSnapshot(baseline, equipmentOverride: mods);
            TestValue("iron_blade", 1.2f); TestValue("healing_potion", 1.3f); TestValue("oak_shield", 1.4f);
            TestValue("longbow", 1.3f); TestValue("fire_flask", 1.45f); TestValue("stone_guard", 1.45f); TestValue("vine_priest", 1.3f);
            TestValue("hourglass", 1); TestValue("war_drum", 1); TestValue("battle_banner", 1); TestValue("command_core", 1);
            foreach (var id in new[] { "frost_rune", "armor_break", "arc_battery" })
            {
                var a = CommercialCardValueCalculator.Resolve(CommercialCardCatalog.Get(id), naked, 0);
                var b = CommercialCardValueCalculator.Resolve(CommercialCardCatalog.Get(id), modified, 0);
                Check(Near(a.Secondary, b.Secondary), id + " debuff/CD secondary not damage-scaled");
            }
            Check(Near(CommercialCharacterCalculator.HeroBasicAttack(modified), CommercialCharacterCalculator.HeroBasicAttack(naked) * 1.4f), "hero basic damage multiplier");
            var hybrid = CommercialCardValueCalculator.Resolve(CommercialCardCatalog.Get("plate_armor"), modified, 0);
            var hybridBase = CommercialCardValueCalculator.Resolve(CommercialCardCatalog.Get("plate_armor"), naked, 0);
            Check(Near(hybrid.Primary, hybridBase.Primary * 1.4f) && Near(hybrid.Secondary, hybridBase.Secondary * 1.2f), "shield-damage hybrid typed multipliers");

            var state = RichState(); var gearItem = CommercialEquipmentService.Generate(1, 1, 8181, EquipmentSlot.MainWeapon, EquipmentRarity.Gold, "arcanist", 20);
            state.Inventory.Add(gearItem);
            var running = new CommercialBattleSession(state, state.DraftFormation, 17041); var oldPower = running.GetCurrentResolvedPower(3); var oldAp = running.CharacterSnapshot.AbilityPower;
            CommercialEquipmentService.Equip(state, gearItem);
            Check(Near(running.GetCurrentResolvedPower(3), oldPower) && Near(running.CharacterSnapshot.AbilityPower, oldAp), "equip does not mutate active fight");
            var next = new CommercialBattleSession(state, state.DraftFormation, 17041);
            Check(next.CharacterSnapshot.AbilityPower > oldAp, "next fight gets equipment snapshot");
            next.Advance(90); Check(next.Result == CommercialBattleResult.Victory && next.LivingEnemyCount == 0 && next.Hero.Health > 0, "actual equipment battle victory");
            Check(CommercialEquipmentService.ProtectedReason(state, gearItem) != null, "worn item protected");
            CommercialEquipmentService.SaveLoadout(state, 0); CommercialEquipmentService.Unequip(state, gearItem.Slot);
            Check(CommercialEquipmentService.Salvage(state, gearItem) != null, "saved loadout protected");
            Check(CommercialEquipmentService.ApplyLoadout(state, 0) == null && state.GetEquipped(gearItem.Slot) == gearItem, "atomic saved loadout application");
            state.Equipment.Loadouts[1].ItemIds[0] = "missing"; var equippedBefore = state.GetEquipped(gearItem.Slot);
            Check(CommercialEquipmentService.ApplyLoadout(state, 1) != null && state.GetEquipped(gearItem.Slot) == equippedBefore, "invalid loadout no partial changes");
            var upgradeBefore = CommercialEquipmentService.ItemStats(gearItem); var gold = state.Gold; var dust = state.Equipment.Dust;
            var upgradeCost = CommercialEquipmentService.UpgradeCost(state, gearItem.Slot);
            Check(CommercialEquipmentService.Upgrade(state, gearItem.Slot) == null && state.Gold == gold - upgradeCost.Gold && state.Equipment.Dust == dust - upgradeCost.Dust, "upgrade exact costs");
            var upgraded = CommercialEquipmentService.ItemStats(gearItem, 1);
            Check(upgraded[EquipmentStat.AbilityPower] > upgradeBefore[EquipmentStat.AbilityPower], "upgrade increases base attributes");
            var spare = CommercialEquipmentService.Generate(1, 1, 1911, gearItem.Slot, EquipmentRarity.Blue, "windrunner", 20); state.Inventory.Add(spare); CommercialEquipmentService.Equip(state, spare);
            Check(state.Equipment.SlotUpgrades[(int)spare.Slot] == 1, "upgrade survives replacement");
            var original = JsonUtility.ToJson(gearItem.Affixes[0]); var reforgeCost = CommercialEquipmentService.ReforgeCost(gearItem); gold = state.Gold; dust = state.Equipment.Dust;
            Check(CommercialEquipmentService.BeginReforge(state, gearItem, 0) == null && state.Gold == gold - reforgeCost.Gold && state.Equipment.Dust == dust - reforgeCost.Dust, "reforge exact costs");
            Check(JsonUtility.ToJson(gearItem.Affixes[0]) == original && state.Equipment.PendingRoll != null, "preview does not change existing affix");
            gold = state.Gold; Check(CommercialEquipmentService.BeginReforge(state, gearItem, 1) != null && state.Gold == gold, "pending prevents another charge");
            restored = JsonUtility.FromJson<CommercialGameState>(JsonUtility.ToJson(state)); CommercialEquipmentService.Migrate(restored);
            Check(restored.Equipment.PendingRoll != null, "pending reforge persisted");
            var candidate = JsonUtility.ToJson(restored.Equipment.PendingRoll.Candidate);
            Check(CommercialEquipmentService.FinishReforge(restored, true) == null && JsonUtility.ToJson(restored.Inventory.First(i => i.Id == gearItem.Id).Affixes[0]) == candidate, "accept pending affix after reload");
            Check(CommercialEquipmentService.FinishReforge(state, false) == null && JsonUtility.ToJson(gearItem.Affixes[0]) == original, "discard retains old affix");
            var craftCost = CommercialEquipmentService.CraftCost(state, EquipmentRarity.Purple); gold = state.Gold; dust = state.Equipment.Dust;
            Check(CommercialEquipmentService.Craft(state, "spiritbond", EquipmentSlot.Head, EquipmentRarity.Purple, out var crafted) == null && crafted.SetId == "spiritbond" && crafted.Slot == EquipmentSlot.Head && crafted.Affixes.Count == 2, "targeted set crafting");
            Check(state.Gold == gold - craftCost.Gold && state.Equipment.Dust == dust - craftCost.Dust, "craft exact costs");
            crafted.Locked = true; Check(CommercialEquipmentService.Salvage(state, crafted) != null, "locked item protected"); crafted.Locked = false;
            dust = state.Equipment.Dust; Check(CommercialEquipmentService.Salvage(state, crafted) == null && state.Equipment.Dust == dust + CommercialEquipmentService.SalvageValue(crafted), "salvage exact yield");
            Check(CommercialEquipmentService.Salvage(state, crafted) != null, "double salvage impossible");
            state.Gold = 0; dust = state.Equipment.Dust;
            Check(CommercialEquipmentService.Upgrade(state, EquipmentSlot.Head) != null && state.Equipment.Dust == dust, "insufficient funds no partial charge");
            Check(CommercialEquipmentService.Craft(state, "iron_oath", EquipmentSlot.Armor, EquipmentRarity.Gold, out _) != null && state.Equipment.Dust == dust, "insufficient craft resources no partial charge");

            TestActualSupport("oak_shield", EquipmentStat.ShieldBonus, .4f);
            TestActualSupport("healing_potion", EquipmentStat.HealingBonus, .3f);
            TestProjectile("quick_dagger", 2); TestProjectile("longbow", 3);
            var tank = RichState(); var tankItem = Plain(EquipmentSlot.Head, EquipmentStat.StartingShield, .2f);
            tankItem.BaseStats.Add(new EquipmentStatValue(EquipmentStat.SummonHealthBonus, .4f)); tank.Inventory.Add(tankItem); tank.Equip(tankItem);
            var tankFight = new CommercialBattleSession(tank, tank.DraftFormation, 15); var bare = RichState(); var bareFight = new CommercialBattleSession(bare, bare.DraftFormation, 15);
            Check(Near(tankFight.Hero.Shield, tankFight.Hero.MaxHealth * .2f), "starting shield actually applied");
            Check(Near(tankFight.Cards.First(c => c.Summon != null).Summon.MaxHealth, bareFight.Cards.First(c => c.Summon != null).Summon.MaxHealth * 1.4f), "summon HP modifier actually applied");
            return "PASS: " + checks + " equipment data/formula/combat checks. Persistent player save untouched.";

            void TestValue(string id, float factor)
            {
                var d = CommercialCardCatalog.Get(id); var a = CommercialCardValueCalculator.Resolve(d, naked, .2f); var b = CommercialCardValueCalculator.Resolve(d, modified, .2f);
                Check(Near(a.Primary * factor, b.Primary), id + " typed primary modifier");
            }
        }
        private static void TestActualSupport(string cardId, EquipmentStat stat, float amount)
        {
            var state = RichState(); state.DraftFormation.Slots = new string[9]; state.DraftFormation.Slots[4] = "hero"; state.DraftFormation.Slots[0] = cardId;
            var item = Plain(EquipmentSlot.Head, stat, amount); state.Inventory.Add(item); state.Equip(item);
            var fight = new CommercialBattleSession(state, state.DraftFormation, 101);
            foreach (var enemy in fight.Enemies) enemy.NextAction = 1000; fight.Hero.NextAction = 1000;
            fight.Hero.Health = fight.Hero.MaxHealth * .1f; var initial = fight.Hero.Health; var value = fight.GetCurrentResolvedPower(0);
            fight.Advance(5.6f);
            Check(stat == EquipmentStat.ShieldBonus ? Near(fight.Hero.Shield, value) : Near(fight.Hero.Health - initial, value), cardId + " actual combat amount matches displayed formula");
        }
        private static void TestProjectile(string cardId, int expected)
        {
            var state = RichState(); state.Stage = 10; state.DraftFormation.Slots = new string[9]; state.DraftFormation.Slots[4] = "hero"; state.DraftFormation.Slots[0] = cardId;
            var item = Plain(EquipmentSlot.Head, EquipmentStat.DamageBonus, .2f); state.Inventory.Add(item); state.Equip(item);
            var fight = new CommercialBattleSession(state, state.DraftFormation, 9211);
            foreach (var enemy in fight.Enemies) { enemy.NextAction = 1000; enemy.Health = enemy.MaxHealth = 10000; }
            fight.Hero.NextAction = 1000; fight.Advance(CommercialCardCatalog.Get(cardId).Cooldown + .8f);
            var events = new List<BattleVisualEvent>(); while (fight.TryDequeueVisualEvent(out var e)) events.Add(e);
            var shots = events.Where(e => e.Kind == BattleVisualEventKind.Projectile && e.SourceId == cardId).ToArray();
            Check(shots.Length == expected, cardId + " correct projectile count");
            Check(shots.Select(e => e.TargetId).Distinct().Count() == (cardId == "quick_dagger" ? 1 : 3), cardId + " correct projectile targets");
            Check(events.Any(e => e.Kind == BattleVisualEventKind.Damage || e.Kind == BattleVisualEventKind.CriticalDamage), cardId + " damage resolves after projectiles");
        }
        private static EquipmentItem Plain(EquipmentSlot slot, EquipmentStat stat, float value) => new()
        { Id = Guid.NewGuid().ToString("N"), DisplayName = "测试", Slot = slot, EquipmentVersion = 1, RequiredLevel = 1, BaseStats = new List<EquipmentStatValue> { new(stat, value) } };
        private static CommercialGameState RichState()
        { var state = CommercialGameState.CreateDefault(); state.PlayerLevel = 25; state.Gold = 200000; state.Equipment.Dust = 20000; return state; }

        public static string RunRuntimeChecks()
        {
            if (!Application.isPlaying) throw new InvalidOperationException("Enter Play Mode first.");
            checks = 0; var controller = UnityEngine.Object.FindObjectOfType<CommercialPrototypeController>(); var view = controller.GetComponent<CommercialEquipmentView>();
            var original = controller.State; var battle = controller.Battle; var encounter = Get(controller, "worldEncounter"); var wasEnabled = controller.enabled;
            var save = PlayerPrefs.GetString(SaveKey, ""); var hadSave = PlayerPrefs.HasKey(SaveKey);
            controller.enabled = false;
            try
            {
                var state = Fixture(); Set(controller, "state", state); Check(controller.RequestWorldEncounter("main_1"), "fixture starts explored idle encounter"); Click("Nav_4"); view.Refresh(); Canvas.ForceUpdateCanvases();
                Check(view.RootUI.gameObject.activeInHierarchy, "equipment navigation works");
                Check(view.Cells.Length == 20 && view.Cells.All(c => c.Icon.sprite != null), "20 pooled cells with imported art");
                Check(view.Slots.Length == 6 && view.Slots.All(c => c.Icon.sprite != null), "six slots with imported art");
                var visibleButton = view.Cells.First(c => c.gameObject.activeSelf).Button;
                Check(view.Cells.All(c => c.Rim.raycastTarget), "inventory cells have pointer targets");
                visibleButton.onClick.Invoke(); Check(view.ModalRoot.Find("EQ_DetailModal").gameObject.activeSelf, "inventory opens detail");
                view.CloseModals();
                var item = state.Inventory.Last(i => i.Slot == EquipmentSlot.MainWeapon);
                var oldBattle = controller.Battle; var ap = oldBattle.CharacterSnapshot.AbilityPower;
                view.ShowItem(item); Click("EQ_Equip");
                Check(state.GetEquipped(item.Slot) == item && ReferenceEquals(controller.Battle, oldBattle) && Near(ap, oldBattle.CharacterSnapshot.AbilityPower), "equip UI preserves active battle");
                Click("EQ_Upgrade"); Click("EQ_ConfirmYes"); Check(state.Equipment.SlotUpgrades[(int)item.Slot] == 1, "upgrade confirmation UI");
                var oldAffix = JsonUtility.ToJson(item.Affixes[0]); Click("EQ_Reforge"); Click("EQ_ConfirmYes");
                Check(state.Equipment.PendingRoll != null && JsonUtility.ToJson(item.Affixes[0]) == oldAffix, "reforge preview UI");
                Click("EQ_AcceptRoll"); Check(state.Equipment.PendingRoll == null, "reforge accept UI");
                Click("EQ_CompareMore"); Check(view.ModalRoot.Find("EQ_SetsModal").gameObject.activeSelf, "full attribute comparison UI"); Click("EQ_CloseSets");
                Check(view.ModalRoot.Find("EQ_DetailModal").gameObject.activeSelf, "comparison returns to detail");
                view.CloseModals(); Click("EQ_TabLoadouts"); Click("EQ_SaveLoadout_0"); Click("EQ_ConfirmYes"); Check(state.Equipment.Loadouts[0].ItemIds.Any(id => id == item.Id), "save loadout UI");
                view.CloseModals(); Click("EQ_TabForge"); var count = state.Inventory.Count; Click("EQ_Craft"); Click("EQ_ConfirmYes"); Check(state.Inventory.Count == count + 1, "craft confirmation UI");
                view.CloseModals(); Click("EQ_TabGear"); Click("EQ_Next"); Check(view.Cells[0].ItemId != state.Inventory.Last().Id, "inventory paging UI");
                Check(controller.RequestWorldEncounter("main_1"), "start replacement encounter"); Check(!Near(controller.Battle.CharacterSnapshot.AbilityPower, ap), "new encounter adopts new equipment");
                controller.Battle.Advance(90); Check(controller.Battle.Result == CommercialBattleResult.Victory, "actual equipped runtime battle wins");
                var persisted = CommercialSaveService.Load(); Check(persisted.Equipment.SlotUpgrades[(int)item.Slot] == 1 && persisted.GetEquipped(item.Slot)?.Id == item.Id, "save reload keeps gear/upgrade");
                return "PASS: " + checks + " equipment runtime interaction/raycast/save checks. Original state restored.";
            }
            finally
            {
                view.CloseModals(); Set(controller, "state", original); Set(controller, "battle", battle); Set(controller, "worldEncounter", encounter); controller.enabled = wasEnabled;
                if (hadSave) PlayerPrefs.SetString(SaveKey, save); else PlayerPrefs.DeleteKey(SaveKey); PlayerPrefs.Save();
                Click("Nav_4"); view.Refresh();
            }
            void Click(string name) => controller.GetComponentsInChildren<Button>(true).First(b => b.name == name).onClick.Invoke();
        }

        public static CommercialGameState Fixture()
        {
            var state = RichState(); var index = 0;
            CommercialWorldCatalog.RevealRegion(state, 1);
            foreach (var set in CommercialEquipmentCatalog.Balance.Sets) for (var slot = 0; slot < 6; slot++)
                state.Inventory.Add(CommercialEquipmentService.Generate(2, 10, 173 + index++ * 953, (EquipmentSlot)slot, EquipmentRarity.Gold, set.Id, 20));
            for (var i = 0; i < 6; i++) state.Equip(state.Inventory[i]);
            return state;
        }
        // UGUI absoluteDepth is finalized by the render loop. Call after ShowFixture has rendered a frame,
        // separately from synchronous tests which switch several pages in one editor callback.
        public static string RunPointerCheck()
        {
            var view = UnityEngine.Object.FindObjectOfType<CommercialEquipmentView>();
            var visibleButton = view.Cells.First(c => c.gameObject.activeInHierarchy).Button;
            var rect = (RectTransform)visibleButton.transform;
            var pointer = new PointerEventData(EventSystem.current) { position = RectTransformUtility.WorldToScreenPoint(null, rect.TransformPoint(rect.rect.center)) };
            var hits = new List<RaycastResult>(); EventSystem.current.RaycastAll(pointer, hits);
            Check(hits.Count > 0 && hits[0].gameObject.GetComponentInParent<Button>() == visibleButton, "rendered pointer raycast reaches inventory item");
            ExecuteEvents.Execute(visibleButton.gameObject, pointer, ExecuteEvents.pointerClickHandler);
            Check(view.ModalRoot.Find("EQ_DetailModal").gameObject.activeSelf, "pointer click opens equipment detail");
            view.CloseModals(); return "PASS: rendered inventory raycast and actual pointer click.";
        }
        public static string ShowFixture(string screen = "equipment")
        {
            var controller = UnityEngine.Object.FindObjectOfType<CommercialPrototypeController>(); controller.enabled = false;
            var state = Fixture(); Set(controller, "state", state); controller.RequestWorldEncounter("main_1");
            controller.GetComponentsInChildren<Button>(true).First(b => b.name == "Nav_4").onClick.Invoke();
            var view = controller.GetComponent<CommercialEquipmentView>(); view.CloseModals(); controller.NotifyEquipmentChanged(); view.Refresh();
            if (screen == "detail") view.ShowItem(state.Inventory[17]);
            else if (screen == "forge") controller.GetComponentsInChildren<Button>(true).First(b => b.name == "EQ_TabForge").onClick.Invoke();
            else if (screen == "sets") controller.GetComponentsInChildren<Button>(true).First(b => b.name == "EQ_TabSets").onClick.Invoke();
            return "Temporary equipment QA fixture. Restore original save after testing.";
        }
        public static string RestoreOriginalPlayerSave()
        {
            if (Application.isPlaying) throw new InvalidOperationException("Exit Play Mode before restoring the saved baseline.");
            if (SessionState.GetString("EquipmentAcceptance.OriginalSave", "__missing__") == "__missing__") throw new InvalidOperationException("No captured player baseline; restore aborted.");
            if (SessionState.GetBool("EquipmentAcceptance.HadSave", false)) PlayerPrefs.SetString(SaveKey, SessionState.GetString("EquipmentAcceptance.OriginalSave", ""));
            else PlayerPrefs.DeleteKey(SaveKey);
            PlayerPrefs.Save(); var state = CommercialSaveService.Load();
            return "Restored original player save: Level " + state.PlayerLevel + ", inventory " + state.Inventory.Count + ", equipped " + state.Equipped.Count;
        }
        private static object Get(object target, string name) => target.GetType().GetField(name, Flags).GetValue(target);
        private static void Set(object target, string name, object value) => target.GetType().GetField(name, Flags).SetValue(target, value);
    }
}

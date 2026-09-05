using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    // Scene-authored widgets. Reuses 20 inventory cells; no UI recreation on battle ticks.
    public sealed class CommercialEquipmentView : MonoBehaviour
    {
        public RectTransform PageBounds, RootUI, ModalRoot;
        public CommercialEquipmentCell[] Slots, Cells;
        private readonly Dictionary<string, Transform> widgets = new();
        private readonly Dictionary<string, Sprite> sprites = new();
        private readonly List<EquipmentItem> filtered = new();
        private CommercialPrototypeController controller;
        private CommercialGameState State => controller.State;
        private EquipmentItem selected;
        private int selectedAffix, page, slotFilter = -1, rarityFilter = -1, setFilter = -1, sort;
        private int craftSet, craftSlot, craftRarity = 1;
        private bool bound, wasVisible, workshop, comparisonMode;
        private float nextCheck;
        private string signature;
        private Action confirmed;
        private static readonly Color Muted = new(.58f, .73f, .85f);
        private static readonly Color Accent = new(.30f, .83f, 1f);
        private static readonly string[] EmptyIcons = { "btn_img_helmet", "btn_img_wristbands", "btn_img_clothes", "btn_img_trousers", "btn_img_shoes", "btn_img_weapons" };

        private Transform W(string name) => widgets.TryGetValue(name, out var value) ? value : null;
        private Text T(string name) => W(name)?.GetComponent<Text>();
        private Button B(string name) => W(name)?.GetComponent<Button>();
        private void Label(string name, string text) { var t = T(name); if (t) t.text = text; }
        private void ButtonLabel(string name, string text) { var b = B(name); if (b) b.GetComponentInChildren<Text>().text = text; }
        private void Active(string name, bool active) { var w = W(name); if (w) w.gameObject.SetActive(active); }
        private Sprite Art(string name)
        {
            if (!sprites.TryGetValue(name, out var value))
            {
                value = Resources.Load<Sprite>("Commercial/FeilongUI/Equipment/" + name);
                if (!value) value = Resources.Load<Sprite>("Commercial/Equipment/Art/" + name);
                sprites[name] = value;
            }
            return value;
        }
        public Sprite IconFor(EquipmentItem item) => item == null ? null : Art(CommercialEquipmentCatalog.IconKey(item));

        private void Start() { Bind(); Refresh(); }
        private void Bind()
        {
            if (bound || !RootUI || !ModalRoot) return;
            controller = GetComponent<CommercialPrototypeController>();
            foreach (var root in new[] { RootUI, ModalRoot })
                foreach (var child in root.GetComponentsInChildren<Transform>(true)) widgets.TryAdd(child.name, child);
            CommercialFeilongEquipmentSkin.Apply(this);
            bound = true;
            for (var i = 0; i < Slots.Length; i++)
            {
                var index = i;
                Slots[i].Button.onClick.AddListener(() =>
                {
                    var item = State.GetEquipped((EquipmentSlot)index);
                    if (item != null) ShowItem(item); else Toast("该部位未装备；在背包中选择装备，或前往锻造");
                });
            }
            for (var i = 0; i < Cells.Length; i++)
            {
                var index = i;
                Cells[i].Button.onClick.AddListener(() => { var n = page * Cells.Length + index; if (n < filtered.Count) ShowItem(filtered[n]); });
            }
            On("EQ_TabGear", () => { workshop = false; Refresh(); });
            On("EQ_TabForge", () => { workshop = true; Refresh(); });
            On("EQ_TabSets", ShowSets); On("EQ_SetInfo", ShowSets); On("EQ_TabLoadouts", ShowLoadouts);
            On("EQ_FilterSlot", () => { slotFilter = (slotFilter + 2) % 7 - 1; page = 0; Refresh(); });
            On("EQ_FilterRarity", () => { rarityFilter = (rarityFilter + 2) % 5 - 1; page = 0; Refresh(); });
            On("EQ_FilterSet", () => { setFilter = (setFilter + 2) % 6 - 1; page = 0; Refresh(); });
            On("EQ_Sort", () => { sort = (sort + 1) % 3; page = 0; Refresh(); });
            On("EQ_Previous", () => { page--; Refresh(); }); On("EQ_Next", () => { page++; Refresh(); });
            On("EQ_BulkSalvage", PreviewBulkSalvage);
            On("EQ_ResumeRoll", () => { var item = State.Inventory.FirstOrDefault(i => i.Id == State.Equipment.PendingRoll?.ItemId); if (item != null) ShowItem(item); });
            On("EQ_CloseDetail", CloseModals); On("EQ_CloseSets", () => { if (comparisonMode) { Active("EQ_SetsModal", false); comparisonMode = false; } else CloseModals(); }); On("EQ_CloseLoadouts", CloseModals);
            On("EQ_CompareMore", ShowFullComparison);
            On("EQ_Equip", ToggleEquip); On("EQ_Lock", ToggleLock); On("EQ_Salvage", PreviewSalvage);
            On("EQ_Upgrade", () =>
            {
                if (selected == null) return;
                var item = selected; var cost = CommercialEquipmentService.UpgradeCost(State, item.Slot);
                Confirm($"强化{CommercialEquipmentCatalog.SlotName(item.Slot)}槽位", $"消耗 {cost.Gold} 金币 + {cost.Dust} 锻造尘\n\n该部位装备基础属性 +5%\n强化跟随槽位，替换装备仍然保留。", () =>
                    Result(CommercialEquipmentService.Upgrade(State, item.Slot), "槽位强化成功，下一场战斗生效"));
            });
            On("EQ_Reforge", () =>
            {
                if (selected == null) return;
                var item = selected; var index = selectedAffix; var cost = CommercialEquipmentService.ReforgeCost(item);
                Confirm("重铸所选词条", $"消耗 {cost.Gold} 金币 + {cost.Dust} 锻造尘\n\n随机生成一条新词条，可选择保留新旧结果。\n放弃结果不会返还本次消耗。", () =>
                    Result(CommercialEquipmentService.BeginReforge(State, item, index), "新词条已生成，请选择保留或放弃"));
            });
            On("EQ_AcceptRoll", () => Result(CommercialEquipmentService.FinishReforge(State, true), "已保留新词条"));
            On("EQ_DiscardRoll", () => Result(CommercialEquipmentService.FinishReforge(State, false), "保留原词条"));
            for (var i = 0; i < 3; i++)
            {
                var index = i;
                On("EQ_Affix_" + i, () => { selectedAffix = index; RefreshDetail(); });
                On("EQ_SaveLoadout_" + i, () => Confirm("保存配装 " + (index + 1), "以当前六个部位覆盖这套方案。\n只保存装备选择，不复制装备或强化等级。", () =>
                { CommercialEquipmentService.SaveLoadout(State, index); Result(null, "配装已保存"); RefreshLoadouts(); }));
                On("EQ_ApplyLoadout_" + i, () => { Result(CommercialEquipmentService.ApplyLoadout(State, index), "配装已切换，下一场战斗生效"); RefreshLoadouts(); });
                On("EQ_ClearLoadout_" + i, () => Confirm("清空配装 " + (index + 1), "只删除方案记录，不删除任何装备。", () =>
                { State.Equipment.Loadouts[index].ItemIds = new string[6]; CommercialEquipmentService.Touch(State); Result(null, "已清空方案"); RefreshLoadouts(); }));
            }
            On("EQ_CraftSet", () => { craftSet = (craftSet + 1) % 5; RefreshForge(); });
            On("EQ_CraftSlot", () => { craftSlot = (craftSlot + 1) % 6; RefreshForge(); });
            On("EQ_CraftRarity", () => { craftRarity = craftRarity % 3 + 1; RefreshForge(); });
            On("EQ_Craft", PreviewCraft);
            On("EQ_ConfirmYes", () => { var action = confirmed; confirmed = null; Active("EQ_ConfirmModal", false); action?.Invoke(); });
            On("EQ_ConfirmNo", () => { confirmed = null; Active("EQ_ConfirmModal", false); });
        }
        private void On(string name, Action action) { var button = B(name); if (button) button.onClick.AddListener(() => action()); }

        private void Update()
        {
            if (!bound || controller.State == null) return;
            var visible = PageBounds.gameObject.activeInHierarchy;
            if (wasVisible && !visible) CloseModals();
            if (visible && (!wasVisible || Time.unscaledTime >= nextCheck))
            {
                nextCheck = Time.unscaledTime + .25f;
                var s = $"{State.Equipment.Revision}/{State.Inventory.Count}/{State.PlayerLevel}/{State.Gold}/{State.Equipment.Dust}/{State.Character.Profession}/{State.Character.AllocatedPoints}";
                if (!wasVisible || signature != s) { signature = s; Refresh(); }
                FitLayout();
            }
            wasVisible = visible;
        }
        public void FitLayout()
        {
            if (PageBounds && RootUI) RootUI.localScale = Vector3.one * Mathf.Min(PageBounds.rect.width / 1080f, PageBounds.rect.height / 1586f);
            if (!ModalRoot) return;
            foreach (Transform child in ModalRoot)
            {
                var panel = child.Find("Panel") as RectTransform;
                if (panel) panel.localScale = Vector3.one * Mathf.Min(1, (ModalRoot.rect.width - 40) / panel.rect.width, (ModalRoot.rect.height - 80) / panel.rect.height);
            }
        }
        public void Refresh()
        {
            Bind(); if (!bound || controller.State == null) return;
            Label("EQ_Wallet", $"金币 {State.Gold:N0}    锻造尘 {State.Equipment.Dust:N0}");
            var snapshot = CommercialCharacterCalculator.BuildSnapshot(State);
            Label("EQ_HeroName", CommercialProfessionCatalog.Get(snapshot.Profession).DisplayName + "  Lv." + State.PlayerLevel);
            Label("EQ_Power", $"综合评分  {State.CombatPower:0}");
            Label("EQ_FourAttributes", $"力量 {snapshot.Strength}    敏捷 {snapshot.Dexterity}\n智力 {snapshot.Intelligence}    体质 {snapshot.Vitality}");
            Label("EQ_CombatStats", $"生命 {snapshot.MaxHealth:0}   护甲 {snapshot.Armor:0.#}\n强度 {snapshot.AbilityPower:0.#}   暴击 {snapshot.CritChance:P0}");
            for (var i = 0; i < Slots.Length; i++)
            {
                var item = State.GetEquipped((EquipmentSlot)i); var grade = State.Equipment.SlotUpgrades[i];
                Slots[i].Bind(item, item == null ? Art(EmptyIcons[i]) : IconFor(item), CommercialEquipmentCatalog.SlotName((EquipmentSlot)i),
                    item == null ? "点击查看" : $"Lv.{item.ItemLevel}  +{grade}", item == null ? "空" : "+" + grade);
            }
            var activeSets = CommercialEquipmentCatalog.Balance.Sets.Select(s => (s, n: CommercialEquipmentService.SetCount(State, s.Id))).Where(x => x.n >= 2).ToArray();
            Label("EQ_ActiveSets", activeSets.Length == 0 ? "套装效果  ·  集齐 2 / 4 / 6 件激活" : string.Join("  ·  ", activeSets.Select(x => x.s.Name + " " + x.n + "/6")));
            Active("EQ_InventoryPanel", !workshop); Active("EQ_Showcase", !workshop); Active("EQ_SetBar", !workshop); Active("EQ_WorkshopPanel", workshop);
            B("EQ_TabGear").image.color = workshop ? new Color(.10f, .19f, .29f) : new Color(.15f, .40f, .61f);
            B("EQ_TabForge").image.color = workshop ? new Color(.15f, .40f, .61f) : new Color(.10f, .19f, .29f);
            Active("EQ_ResumeRoll", State.Equipment.PendingRoll != null);
            RefreshInventory(); RefreshForge();
            if (W("EQ_DetailModal").gameObject.activeSelf) RefreshDetail();
            FitLayout();
        }
        private void RefreshInventory()
        {
            var sets = CommercialEquipmentCatalog.Balance.Sets;
            ButtonLabel("EQ_FilterSlot", slotFilter < 0 ? "全部部位 ▾" : CommercialEquipmentCatalog.SlotName((EquipmentSlot)slotFilter) + " ▾");
            ButtonLabel("EQ_FilterRarity", rarityFilter < 0 ? "全部品质 ▾" : CommercialEquipmentCatalog.Balance.Rarities[rarityFilter].Name + " ▾");
            ButtonLabel("EQ_FilterSet", setFilter < 0 ? "全部套装 ▾" : sets[setFilter].Name + " ▾");
            ButtonLabel("EQ_Sort", new[] { "最新获得", "品质优先", "评分优先" }[sort] + " ↕");
            var query = State.Inventory.Where(i => (slotFilter < 0 || (int)i.Slot == slotFilter) &&
                (rarityFilter < 0 || (int)i.Rarity == rarityFilter) && (setFilter < 0 || i.SetId == sets[setFilter].Id));
            query = sort == 1 ? query.OrderByDescending(i => i.Rarity).ThenByDescending(i => i.ItemLevel) :
                sort == 2 ? query.OrderByDescending(i => i.Power) : query.Reverse();
            filtered.Clear(); filtered.AddRange(query);
            var pages = Mathf.Max(1, Mathf.CeilToInt(filtered.Count / (float)Cells.Length)); page = Mathf.Clamp(page, 0, pages - 1);
            Label("EQ_BagCount", $"装备背包  {filtered.Count} / {State.Inventory.Count}      ·      点击装备查看对比");
            Label("EQ_PageNumber", $"{page + 1} / {pages}");
            B("EQ_Previous").interactable = page > 0; B("EQ_Next").interactable = page < pages - 1;
            Active("EQ_EmptyBag", filtered.Count == 0);
            for (var i = 0; i < Cells.Length; i++)
            {
                var index = page * Cells.Length + i; var hasItem = index < filtered.Count;
                Cells[i].gameObject.SetActive(hasItem); if (!hasItem) continue;
                var item = filtered[index]; var worn = State.GetEquipped(item.Slot)?.Id == item.Id;
                var shortName = (CommercialEquipmentCatalog.Set(item.SetId)?.Name ?? (item.Legacy ? "传承" : "旅者")) + "·" + CommercialEquipmentCatalog.SlotName(item.Slot);
                Cells[i].Bind(item, IconFor(item), shortName, $"Lv.{item.ItemLevel} · {item.Power:0}", worn ? "已穿" : item.Locked ? "锁" : item.RequiredLevel > State.PlayerLevel ? "等级不足" : "");
            }
        }
        public void ShowItem(EquipmentItem item)
        {
            Bind(); if (item == null) return;
            selected = item; selectedAffix = State.Equipment.PendingRoll?.ItemId == item.Id ? State.Equipment.PendingRoll.Index : 0;
            CloseModals(); ShowModal("EQ_DetailModal"); RefreshDetail();
        }
        private void RefreshDetail()
        {
            if (selected == null || !State.Inventory.Contains(selected)) { Active("EQ_DetailModal", false); return; }
            var item = selected; var worn = State.GetEquipped(item.Slot)?.Id == item.Id; var grade = State.Equipment.SlotUpgrades[(int)item.Slot];
            Label("EQ_DetailTitle", item.DisplayName); T("EQ_DetailTitle").color = EquipmentGenerator.RarityColor(item.Rarity);
            W("EQ_DetailIcon").GetComponent<Image>().sprite = IconFor(item);
            Label("EQ_DetailMeta", $"{CommercialEquipmentCatalog.Balance.Rarities[(int)item.Rarity].Name} · {CommercialEquipmentCatalog.SlotName(item.Slot)} · Lv.{item.ItemLevel}\n需要角色 Lv.{item.RequiredLevel}  ·  槽位强化 +{grade}" + (item.Legacy ? "  ·  旧版传承" : ""));
            var current = CommercialCharacterCalculator.BuildSnapshot(State);
            var replacement = CommercialEquipmentService.Aggregate(State, item.Slot, worn ? null : item);
            var after = CommercialCharacterCalculator.BuildSnapshot(State, equipmentOverride: replacement);
            Label("EQ_Comparison", (worn ? "卸下后变化" : "替换后变化") + "  <color=#99B7CE>（包含套装得失）</color>\n" +
                $"力量 {Delta(after.Strength - current.Strength)}    敏捷 {Delta(after.Dexterity - current.Dexterity)}    智力 {Delta(after.Intelligence - current.Intelligence)}    体质 {Delta(after.Vitality - current.Vitality)}\n" +
                $"生命 {Delta(after.MaxHealth - current.MaxHealth)}    护甲 {Delta(after.Armor - current.Armor)}    强度 {Delta(after.AbilityPower - current.AbilityPower)}\n" +
                $"综合评分 {Delta(CommercialCharacterCalculator.PowerScore(after, State.PlayerLevel) - State.CombatPower)}   <color=#99B7CE>非伤害保证</color>");
            var baseText = new StringBuilder("基础属性  <color=#99B7CE>（含槽位强化）</color>\n");
            foreach (var stat in item.BaseStats.Where(v => v.Value != 0))
                baseText.AppendLine(CommercialEquipmentCatalog.Name(stat.Kind) + "  " + CommercialEquipmentCatalog.Format(stat.Kind, stat.Value * (1 + grade * CommercialEquipmentCatalog.Balance.UpgradeBaseStep)));
            Label("EQ_BaseStats", baseText.ToString());
            for (var i = 0; i < 3; i++)
            {
                var has = i < item.Affixes.Count; Active("EQ_Affix_" + i, has); if (!has) continue;
                var a = item.Affixes[i]; B("EQ_Affix_" + i).image.color = i == selectedAffix ? new Color(.13f, .34f, .49f) : new Color(.08f, .14f, .21f);
                ButtonLabel("EQ_Affix_" + i, (i == selectedAffix ? "● " : "○ ") + CommercialEquipmentCatalog.Name(a.Kind) + "  " + CommercialEquipmentCatalog.Format(a.Kind, a.Value) +
                    $"    <size=23><color=#A2B4C5>[{CommercialEquipmentCatalog.Format(a.Kind, a.Min, false)} ~ {CommercialEquipmentCatalog.Format(a.Kind, a.Max, false)}]</color></size>");
            }
            Label("EQ_AffixHeader", item.Affixes.Count == 0 ? "随机词条  ·  此装备无随机词条" : "随机词条  ·  点击选择要重铸的一条");
            var cost = CommercialEquipmentService.UpgradeCost(State, item.Slot); var reforge = CommercialEquipmentService.ReforgeCost(item);
            Label("EQ_UpgradeInfo", $"{CommercialEquipmentCatalog.SlotName(item.Slot)}强化 +{grade} → +{grade + 1}  ·  基础属性 +5%\n{cost.Gold} 金币 / {cost.Dust} 锻造尘  ·  换装备保留强化\n重铸：{reforge.Gold} 金币 / {reforge.Dust} 锻造尘");
            var set = CommercialEquipmentCatalog.Set(item.SetId);
            Label("EQ_DetailSet", set == null ? "无套装归属\n旧版装备完整保留原属性，不自动洗成新词条。" : SetDescription(set, false));
            ButtonLabel("EQ_Equip", worn ? "卸下装备" : "穿戴装备"); ButtonLabel("EQ_Lock", item.Locked ? "解除锁定" : "锁定装备");
            CommercialFeilongEquipmentSkin.SetButtonIcon(W("EQ_Lock"), Art(item.Locked ? "btn_unlock" : "btn_locked"));
            B("EQ_Equip").interactable = worn || item.RequiredLevel <= State.PlayerLevel;
            B("EQ_Salvage").interactable = CommercialEquipmentService.ProtectedReason(State, item) == null;
            B("EQ_Reforge").interactable = item.Affixes.Count > 0 && State.Equipment.PendingRoll == null;
            B("EQ_Upgrade").interactable = grade < Mathf.Min(CommercialEquipmentCatalog.Balance.MaxUpgradeLevel, State.PlayerLevel + 2);
            var pending = State.Equipment.PendingRoll; var showRoll = pending?.ItemId == item.Id;
            Active("EQ_DetailActions", !showRoll); Active("EQ_PendingRollPanel", showRoll);
            if (showRoll)
            {
                var old = item.Affixes[pending.Index]; var next = pending.Candidate;
                Label("EQ_PendingRollText", "重铸结果 · 已扣除材料\n原：" + CommercialEquipmentCatalog.Name(old.Kind) + " " + CommercialEquipmentCatalog.Format(old.Kind, old.Value) +
                    "\n新：<color=#73E5B4>" + CommercialEquipmentCatalog.Name(next.Kind) + " " + CommercialEquipmentCatalog.Format(next.Kind, next.Value) + "</color>\n关闭后结果仍会保存，确认前属性不变。");
            }
        }
        private static string Delta(float value) => $"<color={(value > .04f ? "#6DE4AF" : value < -.04f ? "#F68787" : "#A3B4C4")}>{value:+0.#;-0.#;0}</color>";
        private void ToggleEquip()
        {
            if (selected == null) return;
            if (State.GetEquipped(selected.Slot)?.Id == selected.Id) { CommercialEquipmentService.Unequip(State, selected.Slot); Result(null, "已卸下，下一场战斗生效"); }
            else { var error = CommercialEquipmentService.Equip(State, selected); Result(error, "已穿戴，下一场战斗生效"); if (error == null) Slots[(int)selected.Slot].Pulse(); }
        }
        private void ToggleLock()
        {
            if (selected == null) return; selected.Locked = !selected.Locked; CommercialEquipmentService.Touch(State);
            Result(null, selected.Locked ? "已锁定，防止误分解" : "已解除锁定");
        }
        private void PreviewSalvage()
        {
            var item = selected; var error = CommercialEquipmentService.ProtectedReason(State, item); if (error != null) { Toast(error); return; }
            Confirm("分解装备", $"{item.DisplayName}\n\n获得 {CommercialEquipmentService.SalvageValue(item)} 锻造尘\n分解后装备不可恢复。", () =>
            { var result = CommercialEquipmentService.Salvage(State, item); if (result == null) selected = null; Result(result, "分解完成"); });
        }
        private void PreviewBulkSalvage()
        {
            var items = filtered.Where(i => i.Rarity == EquipmentRarity.White && CommercialEquipmentService.ProtectedReason(State, i) == null).ToList();
            if (items.Count == 0) { Toast("当前筛选中没有可分解的普通装备"); return; }
            Confirm("批量分解普通装备", $"当前筛选中 {items.Count} 件普通装备\n预计获得 {items.Sum(CommercialEquipmentService.SalvageValue)} 锻造尘\n\n跳过已穿戴、锁定、配装和待重铸装备。\n分解不可恢复。", () =>
            {
                var count = 0; foreach (var item in items) if (CommercialEquipmentService.Salvage(State, item) == null) count++;
                Result(null, $"已分解 {count} 件普通装备");
            });
        }
        private void RefreshForge()
        {
            var set = CommercialEquipmentCatalog.Balance.Sets[craftSet]; var rarity = (EquipmentRarity)craftRarity;
            ButtonLabel("EQ_CraftSet", "套装  " + set.Name + " ▾"); ButtonLabel("EQ_CraftSlot", "部位  " + CommercialEquipmentCatalog.SlotName((EquipmentSlot)craftSlot) + " ▾");
            ButtonLabel("EQ_CraftRarity", "品质  " + CommercialEquipmentCatalog.Balance.Rarities[craftRarity].Name + " ▾");
            var cost = CommercialEquipmentService.CraftCost(State, rarity);
            Label("EQ_CraftCost", $"消耗 {cost.Gold} 金币 + {cost.Dust} 锻造尘\n拥有 {State.Gold} 金币 / {State.Equipment.Dust} 锻造尘");
            Label("EQ_CraftPreview", set.Name + " · " + CommercialEquipmentCatalog.SlotName((EquipmentSlot)craftSlot) +
                $"\n装备 Lv.{Mathf.Min(State.PlayerLevel, CommercialEquipmentCatalog.Balance.MaxItemLevel)}  ·  随机词条 {CommercialEquipmentCatalog.Balance.Rarities[craftRarity].AffixCount} 条\n" + set.Theme);
            var sample = new EquipmentItem { Slot = (EquipmentSlot)craftSlot, Rarity = rarity, SetId = set.Id };
            W("EQ_CraftIcon").GetComponent<Image>().sprite = IconFor(sample);
            Label("EQ_ForgeSetInfo", SetDescription(set, true));
            B("EQ_Craft").interactable = State.Gold >= cost.Gold && State.Equipment.Dust >= cost.Dust;
        }
        private void PreviewCraft()
        {
            var set = CommercialEquipmentCatalog.Balance.Sets[craftSet]; var slot = (EquipmentSlot)craftSlot; var rarity = (EquipmentRarity)craftRarity;
            var cost = CommercialEquipmentService.CraftCost(State, rarity);
            Confirm("确认定向锻造", $"{set.Name} · {CommercialEquipmentCatalog.SlotName(slot)} · {CommercialEquipmentCatalog.Balance.Rarities[(int)rarity].Name}\n\n消耗 {cost.Gold} 金币 + {cost.Dust} 锻造尘\n保底获得指定套装和部位，随机词条。", () =>
            {
                var error = CommercialEquipmentService.Craft(State, set.Id, slot, rarity, out var item);
                Result(error, "锻造成功"); if (error == null) ShowItem(item);
            });
        }
        private string SetDescription(EquipmentSetRule set, bool roomy)
        {
            var count = CommercialEquipmentService.SetCount(State, set.Id);
            var text = new StringBuilder(set.Name + "  " + count + "/6" + (roomy ? " · " + set.Theme : "") + "\n");
            foreach (var bonus in set.Bonuses)
                text.Append("<color=").Append(count >= bonus.Pieces ? "#6DE4AF" : "#98AEBE").Append('>').Append(bonus.Pieces).Append(" 件  ")
                    .Append(string.Join("  /  ", bonus.Stats.Select(s => CommercialEquipmentCatalog.Name(s.Kind) + CommercialEquipmentCatalog.Format(s.Kind, s.Value)))).AppendLine("</color>");
            return text.ToString();
        }
        private void ShowSets()
        {
            CloseModals(); comparisonMode = false; Label("EQ_SetsTitle", "套装图鉴");
            Label("EQ_SetsHint", "同套装不同部位累计件数，混合品质也可激活。\n2 / 4 / 6 件效果累加；每个部位最多计入 1 件。");
            Label("EQ_SetsBody", string.Join("\n", CommercialEquipmentCatalog.Balance.Sets.Select(s => SetDescription(s, true)))); ShowModal("EQ_SetsModal");
        }
        private void ShowFullComparison()
        {
            if (selected == null) return;
            var before = CommercialCharacterCalculator.BuildSnapshot(State);
            var worn = State.GetEquipped(selected.Slot)?.Id == selected.Id;
            var gear = CommercialEquipmentService.Aggregate(State, selected.Slot, worn ? null : selected);
            var after = CommercialCharacterCalculator.BuildSnapshot(State, equipmentOverride: gear);
            var text = new StringBuilder();
            Row("力量", before.Strength, after.Strength); Row("敏捷", before.Dexterity, after.Dexterity);
            Row("智力", before.Intelligence, after.Intelligence); Row("体质", before.Vitality, after.Vitality);
            Row("最大生命", before.MaxHealth, after.MaxHealth); Row("护甲", before.Armor, after.Armor);
            Row("效果强度", before.AbilityPower, after.AbilityPower); Row("暴击率", before.CritChance, after.CritChance, true);
            Row("暴击伤害", before.CritDamage, after.CritDamage, true);
            Row("主角攻击间隔（秒）", before.HeroAttackInterval, after.HeroAttackInterval);
            text.AppendLine("\n装备增益（含所有套装）");
            for (var i = (int)EquipmentStat.DamageBonus; i <= (int)EquipmentStat.StartingShield; i++)
                Row(CommercialEquipmentCatalog.Name((EquipmentStat)i), before.Equipment[(EquipmentStat)i], gear[(EquipmentStat)i], true);
            comparisonMode = true; Label("EQ_SetsTitle", worn ? "卸下后的属性变化" : "替换后的属性变化");
            Label("EQ_SetsHint", "以当前职业和完整六部位计算，已包含套装增减。\n左侧当前值 → 右侧替换后；下一场战斗生效。");
            Label("EQ_SetsBody", text.ToString()); ShowModal("EQ_SetsModal");
            void Row(string label, float a, float b, bool percent = false)
            { var scale = percent ? 100 : 1; var unit = percent ? "%" : ""; text.AppendLine($"{label}    {a * scale:0.#}{unit}  →  {b * scale:0.#}{unit}   ({Delta((b - a) * scale)}{unit})"); }
        }
        private void ShowLoadouts() { CloseModals(); RefreshLoadouts(); ShowModal("EQ_LoadoutsModal"); }
        private void RefreshLoadouts()
        {
            for (var i = 0; i < 3; i++)
            {
                var loadout = State.Equipment.Loadouts[i]; var items = loadout.ItemIds.Where(id => !string.IsNullOrEmpty(id)).Select(id => State.Inventory.FirstOrDefault(t => t.Id == id)).ToArray();
                Label("EQ_LoadoutText_" + i, loadout.Name + "  ·  " + items.Length + "/6\n" +
                    (items.Length == 0 ? "保存当前穿戴，随时一键切换" : string.Join(" / ", items.GroupBy(t => t?.SetId ?? "none").Select(g => (CommercialEquipmentCatalog.Set(g.Key)?.Name ?? "散件") + " " + g.Count() + "件"))));
            }
        }
        private void Result(string error, string success)
        {
            if (error != null) { Toast(error); return; }
            controller.NotifyEquipmentChanged(); Refresh(); Toast(success);
        }
        private void Confirm(string title, string body, Action action)
        {
            confirmed = action; Label("EQ_ConfirmTitle", title); Label("EQ_ConfirmBody", body); ShowModal("EQ_ConfirmModal");
        }
        private void ShowModal(string name)
        {
            Active(name, true); FitLayout(); var group = W(name).GetComponent<CanvasGroup>();
            group.DOKill(); group.alpha = 0; group.DOFade(1, .15f).SetUpdate(true);
        }
        public void CloseModals()
        {
            if (!bound) return; confirmed = null;
            foreach (var name in new[] { "EQ_DetailModal", "EQ_SetsModal", "EQ_LoadoutsModal", "EQ_ConfirmModal" })
            { var w = W(name); if (w) { w.GetComponent<CanvasGroup>().DOKill(); w.gameObject.SetActive(false); } }
        }
        private void Toast(string text)
        {
            Label("EQ_ToastText", text); var group = W("EQ_Toast").GetComponent<CanvasGroup>();
            group.DOKill(); group.alpha = 1; group.DOFade(0, .3f).SetDelay(2.5f).SetUpdate(true);
        }
        private void OnDestroy()
        {
            if (ModalRoot) foreach (var group in ModalRoot.GetComponentsInChildren<CanvasGroup>(true)) group.DOKill();
        }
    }
}

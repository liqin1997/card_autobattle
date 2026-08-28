using System;
using System.Collections.Generic;
using System.Linq;
using DG.Tweening;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    public sealed class CommercialInventoryView : MonoBehaviour
    {
        public RectTransform PageBounds, RootUI, ModalRoot, TabContent;
        public Button TabTemplate;
        public InputField Search;
        public CommercialEquipmentCell[] Cells;
        public string WarehouseId { get; private set; } = "items";
        private CommercialPrototypeController controller;
        private CommercialEquipmentView gearView;
        private CommercialGameState State => controller.State;
        private readonly Dictionary<string, Transform> widgets = new();
        private readonly Dictionary<string, Sprite> icons = new();
        private readonly List<Button> tabs = new();
        private readonly List<Row> rows = new();
        private string category = "", signature, selectedId;
        private int sort, page, quantity = 1;
        private bool bound, wasVisible;
        private float nextCheck;
        private sealed class Row { public string Id, Name, Category; public int Quality, Count, Sequence; public EquipmentItem Gear; }
        private Transform W(string name) => widgets.TryGetValue(name, out var t) ? t : null;
        private void Text(string name, string value) { var t = W(name)?.GetComponent<Text>(); if (t) t.text = value; }
        private Button B(string name) => W(name)?.GetComponent<Button>();
        private void On(string name, Action action) { var b = B(name); if (b) b.onClick.AddListener(() => action()); }
        private void ButtonText(string name, string value) => B(name).GetComponentInChildren<Text>().text = value;
        private void Active(string name, bool value) { var t = W(name); if (t) t.gameObject.SetActive(value); }
        public Sprite IconFor(string id)
        {
            var key = CommercialInventoryCatalog.Get(id)?.Icon ?? "icon_box";
            if (!icons.TryGetValue(key, out var sprite)) icons[key] = sprite = Resources.Load<Sprite>("Commercial/Inventory/Art/" + key);
            return sprite;
        }
        private void Start() { Bind(); Refresh(); }
        private void Bind()
        {
            if (bound || !RootUI || !ModalRoot) return;
            controller = GetComponent<CommercialPrototypeController>(); gearView = GetComponent<CommercialEquipmentView>();
            foreach (var root in new[] { RootUI, ModalRoot }) foreach (var t in root.GetComponentsInChildren<Transform>(true)) widgets.TryAdd(t.name, t);
            bound = true;
            var warehouses = CommercialInventoryCatalog.Balance.Warehouses;
            TabContent.sizeDelta = new Vector2(Mathf.Max(1032, warehouses.Length * 264 - 16), 74);
            for (var i = 0; i < warehouses.Length; i++)
            {
                var id = warehouses[i].Id;
                var tab = Instantiate(TabTemplate, TabContent); tab.name = "BAG_Warehouse_" + id;
                var rect = (RectTransform)tab.transform; rect.anchoredPosition = new Vector2(i * 264, 0);
                tab.gameObject.SetActive(true); tab.GetComponentInChildren<Text>().text = warehouses[i].Name;
                tab.onClick.AddListener(() => SelectWarehouse(id)); tabs.Add(tab);
            }
            for (var i = 0; i < Cells.Length; i++)
            {
                var index = i;
                Cells[i].Button.onClick.AddListener(() =>
                {
                    var n = page * Cells.Length + index;
                    if (n >= rows.Count) return;
                    var row = rows[n]; Cells[index].Pulse();
                    if (row.Gear != null) { CloseModals(); gearView.ShowItem(row.Gear); }
                    else ShowItem(row.Id);
                });
            }
            Search.onValueChanged.AddListener(_ => { page = 0; Refresh(); });
            On("BAG_Filter", () =>
            {
                var categories = AllRows().Select(x => x.Category).Distinct().OrderBy(x => x).Prepend("").ToList();
                category = categories[(Mathf.Max(0, categories.IndexOf(category)) + 1) % categories.Count]; page = 0; Refresh();
            });
            On("BAG_Sort", () => { sort = (sort + 1) % 3; page = 0; Refresh(); });
            On("BAG_Previous", () => { page--; Refresh(); }); On("BAG_Next", () => { page++; Refresh(); });
            On("BAG_Close", CloseModals);
            On("BAG_Minus", () => { quantity--; RefreshDetail(); }); On("BAG_Plus", () => { quantity++; RefreshDetail(); });
            On("BAG_Max", () => { quantity = Math.Min(99, CommercialInventoryService.Count(State, selectedId)); RefreshDetail(); });
            On("BAG_Use", UseSelected); On("BAG_Source", GoToSource);
            On("BAG_OpenEquipment", () => CommercialPrototypeController.FindDeep(transform, "Nav_4")?.GetComponent<Button>().onClick.Invoke());
            On("BAG_OpenMap", () => GetComponent<CommercialWorldMapView>()?.Open());
        }
        private void Update()
        {
            if (!bound || controller.State == null) return;
            var visible = PageBounds.gameObject.activeInHierarchy;
            if (wasVisible && !visible) CloseModals();
            if (visible && (!wasVisible || Time.unscaledTime >= nextCheck))
            {
                nextCheck = Time.unscaledTime + .25f;
                var s = $"{State.Storage.Revision}/{State.Inventory.Count}/{State.Equipment.Revision}/{State.Equipment.Dust}/{State.PlayerLevel}";
                if (!wasVisible || signature != s) { signature = s; Refresh(); }
                FitLayout();
            }
            wasVisible = visible;
        }
        public void SelectWarehouse(string id)
        {
            Bind(); if (!CommercialInventoryCatalog.Balance.Warehouses.Any(w => w.Id == id)) return;
            CloseModals(); gearView?.CloseModals(); WarehouseId = id; page = 0; category = "";
            Search.SetTextWithoutNotify(""); Refresh();
        }
        private IEnumerable<Row> AllRows()
        {
            if (WarehouseId == "equipment") return State.Inventory.Select((g, i) => new Row
            { Id = g.Id, Name = g.DisplayName, Category = CommercialEquipmentCatalog.SlotName(g.Slot), Quality = (int)g.Rarity, Count = 1, Gear = g, Sequence = i });
            return CommercialInventoryService.Entries(State, WarehouseId).Select(s => new Row { Id = s.ItemId, Name = CommercialInventoryCatalog.Name(s.ItemId),
                Category = CommercialInventoryCatalog.Get(s.ItemId)?.Category ?? "待识别", Quality = CommercialInventoryCatalog.Get(s.ItemId)?.Quality ?? 0, Count = s.Count, Sequence = s.Acquired });
        }
        public void Refresh()
        {
            Bind(); if (!bound || State == null || !PageBounds.gameObject.activeInHierarchy) return;
            var warehouses = CommercialInventoryCatalog.Balance.Warehouses;
            Text("BAG_Description", warehouses.First(w => w.Id == WarehouseId).Description);
            for (var i = 0; i < tabs.Count; i++) tabs[i].image.color = warehouses[i].Id == WarehouseId ? new Color(.18f, .49f, .71f) : new Color(.09f, .19f, .29f);
            var all = AllRows().ToList();
            if (!string.IsNullOrEmpty(category) && !all.Any(x => x.Category == category)) category = "";
            var query = all.Where(x => (category == "" || x.Category == category) && (string.IsNullOrWhiteSpace(Search.text) || x.Name.IndexOf(Search.text.Trim(), StringComparison.OrdinalIgnoreCase) >= 0));
            query = sort == 1 ? query.OrderByDescending(x => x.Quality).ThenByDescending(x => x.Sequence) : sort == 2 ? query.OrderBy(x => x.Name) : query.OrderByDescending(x => x.Sequence);
            rows.Clear(); rows.AddRange(query);
            var pages = Math.Max(1, (rows.Count + Cells.Length - 1) / Cells.Length); page = Mathf.Clamp(page, 0, pages - 1);
            Text("BAG_Count", $"{all.Count} {(WarehouseId == "equipment" ? "件装备" : "种物品")}  ·  自动分类入库");
            ButtonText("BAG_Filter", (category == "" ? "全部类型" : category) + " ↻");
            ButtonText("BAG_Sort", new[] { "最近获得 ↻", "品质优先 ↻", "名称排序 ↻" }[sort]);
            Text("BAG_Page", $"{page + 1} / {pages}"); B("BAG_Previous").interactable = page > 0; B("BAG_Next").interactable = page < pages - 1;
            Active("BAG_Empty", rows.Count == 0);
            Text("BAG_Empty", string.IsNullOrEmpty(Search.text) && category == "" ? "仓库暂时为空\n探索掉落或任务奖励会自动存入这里" : "没有符合筛选的物品");
            for (var i = 0; i < Cells.Length; i++)
            {
                var n = page * Cells.Length + i; var has = n < rows.Count; Cells[i].gameObject.SetActive(has); if (!has) continue;
                var row = rows[n]; var worn = row.Gear != null && State.GetEquipped(row.Gear.Slot)?.Id == row.Id;
                Cells[i].BindContent(row.Id, row.Gear == null ? IconFor(row.Id) : gearView.IconFor(row.Gear), row.Quality, row.Name,
                    row.Gear == null ? row.Category : $"Lv.{row.Gear.ItemLevel} · {row.Category}", row.Gear == null ? "×" + row.Count.ToString("N0") : worn ? "已穿戴" : row.Gear.Locked ? "已锁定" : "");
            }
            var latest = State.Storage.Recent.FirstOrDefault();
            var parts = latest?.Summary.Split(new[] { "  /  " }, StringSplitOptions.None);
            Text("BAG_Recent", latest == null ? "探索战利品与任务奖励将在这里显示。" : latest.Source + "\n" + string.Join(" / ", parts.Take(3)) + (parts.Length > 3 ? " 等" + parts.Length + "项" : ""));
            if (W("BAG_ItemModal").gameObject.activeSelf) RefreshDetail();
            FitLayout();
        }
        public void FitLayout()
        {
            if (RootUI && PageBounds) RootUI.localScale = Vector3.one * Mathf.Min(PageBounds.rect.width / 1080f, PageBounds.rect.height / 1586f);
            var p = W("BAG_ItemModal")?.Find("Panel") as RectTransform;
            if (p) p.localScale = Vector3.one * Mathf.Min(1, (ModalRoot.rect.width - 40) / p.rect.width, (ModalRoot.rect.height - 80) / p.rect.height);
        }
        public void ShowItem(string id)
        {
            Bind(); if (CommercialInventoryService.Count(State, id) <= 0) return;
            gearView?.CloseModals(); selectedId = id; quantity = 1;
            var modal = W("BAG_ItemModal"); modal.gameObject.SetActive(true);
            var group = modal.GetComponent<CanvasGroup>(); group.DOKill(); group.alpha = 0; group.DOFade(1, .16f).SetUpdate(true);
            RefreshDetail(); FitLayout();
        }
        private void RefreshDetail()
        {
            var count = CommercialInventoryService.Count(State, selectedId);
            if (count <= 0) { CloseModals(); return; }
            var item = CommercialInventoryCatalog.Get(selectedId);
            quantity = Mathf.Clamp(quantity, 1, Math.Min(count, 99));
            Text("BAG_DetailName", CommercialInventoryCatalog.Name(selectedId));
            Text("BAG_DetailMeta", (item?.Category ?? "待识别物品") + "  ·  持有 " + count.ToString("N0"));
            W("BAG_DetailIcon").GetComponent<Image>().sprite = IconFor(selectedId);
            Text("BAG_DetailBody", (item?.Description ?? "配置暂不可用，物品已保留。请勿删除存档。") + "\n\n获取途径：" + (item?.Source ?? "未知"));
            var usable = item?.CanUse == true;
            Text("BAG_RewardTitle", usable ? "本次使用可获得" : "用途说明");
            Text("BAG_RewardPreview", usable ? CommercialInventoryService.UsePreview(item, quantity) : selectedId == CommercialInventoryService.ForgeDust ? "前往装备页进行强化、重铸或锻造时，自动扣除锻造尘。" : "在对应的任务、制作或活动入口使用。\n此处用于查看与保管，不会自动消耗。" );
            Active("BAG_Quantity", usable); Active("BAG_Use", usable);
            Text("BAG_QuantityValue", quantity.ToString()); B("BAG_Minus").interactable = quantity > 1; B("BAG_Plus").interactable = quantity < Math.Min(99, count);
            ButtonText("BAG_Use", (item?.Category == "宝箱" ? "开启 " : "使用 ") + quantity + " 个");
            var node = CommercialWorldCatalog.Find(item?.SourceNode);
            B("BAG_Source").interactable = node != null && CommercialWorldCatalog.Unlocked(State, node);
            ButtonText("BAG_Source", node == null ? "来源见上方" : CommercialWorldCatalog.Unlocked(State, node) ? "查看地图来源" : "来源区域未解锁");
        }
        private void UseSelected()
        {
            var id = selectedId;
            var error = CommercialInventoryService.Use(State, id, quantity, out var result);
            if (error == null) { controller.NotifyEquipmentChanged(); Refresh(); }
            Toast(error ?? "奖励已分类入库：" + result);
        }
        private void GoToSource()
        {
            var node = CommercialWorldCatalog.Find(CommercialInventoryCatalog.Get(selectedId)?.SourceNode);
            if (node == null || !CommercialWorldCatalog.Unlocked(State, node)) return;
            CloseModals(); var map = GetComponent<CommercialWorldMapView>(); if (!map) return;
            map.Open(); map.FocusNode(node.Id);
        }
        public void CloseModals()
        {
            Bind(); var modal = W("BAG_ItemModal"); if (!modal) return;
            modal.GetComponent<CanvasGroup>().DOKill(); modal.gameObject.SetActive(false);
        }
        private void Toast(string message)
        {
            Text("BAG_ToastText", message); var group = W("BAG_Toast").GetComponent<CanvasGroup>();
            group.DOKill(); group.alpha = 1; group.DOFade(0, .3f).SetDelay(3).SetUpdate(true);
        }
        private void OnDestroy()
        {
            if (!ModalRoot) return;
            foreach (var group in ModalRoot.GetComponentsInChildren<CanvasGroup>(true)) group.DOKill();
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace CardAutobattle.Commercial
{
    [DefaultExecutionOrder(-100)]
    public sealed class CommercialWorldMapView : MonoBehaviour
    {
        public Camera MapCamera;
        public Transform MapRoot;
        public SpriteRenderer FogRenderer;
        public GameObject FullPage;
        public RawImage FullImage, PreviewImage;
        public RectTransform MarkerLayer;
        public Button MarkerTemplate;
        public Sprite[] EventIcons;
        public Slider ZoomSlider;
        public Text Header, Status, DetailTitle, DetailBody, ActionLabel, PreviewLocation, PreviewHint;
        public Button ActionButton, TrackButton;
        public GameObject DetailPanel;
        public Button[] QuestRows;
        public Button MainQuestRow;
        public Button OpenCityButton, OpenPreviewButton, BackButton, LocateButton, RevealButton, QuestButton;
        public Vector2 MapSize = new(54, 64);
        public bool IsOpen => FullPage && FullPage.activeSelf;
        public string SelectedNodeId { get; private set; }
        private CommercialPrototypeController controller;
        private RenderTexture mapTexture;
        private Texture2D fogTexture;
        private Sprite fogSprite;
        private readonly Dictionary<string, Button> markers = new();
        private readonly Dictionary<string, Text> markerLabels = new();
        private Vector2 center, velocity;
        private float zoom = 14f, refreshAt, renderAt;
        private int fogRevision = -1;
        private bool dragging, questMode;
        private int pinchTouches;
        private float pinchDistance;
        private string previewNode;
        private string toast;
        private float toastUntil;
        private string forestDetailRevision;
        private CommercialGameState State => controller.State;

        private void Start()
        {
            controller = GetComponent<CommercialPrototypeController>();
            mapTexture = new RenderTexture(1024, 1024, 16, RenderTextureFormat.ARGB32)
                { name = "WorldMap_SharedViewport_1024", antiAliasing = 1 };
            mapTexture.Create();
            FullImage.texture = PreviewImage.texture = mapTexture;
            MapCamera.targetTexture = mapTexture;
            MapCamera.enabled = false;
            OpenCityButton.onClick.AddListener(Open);
            OpenPreviewButton.onClick.AddListener(Open);
            BackButton.onClick.AddListener(() => controller.ReturnFromWorldMap());
            LocateButton.onClick.AddListener(FocusCurrent);
            RevealButton.onClick.AddListener(RevealNextRegion);
            QuestButton.onClick.AddListener(ShowQuestList);
            ZoomSlider.onValueChanged.AddListener(v => { zoom = Mathf.Lerp(5f, 26f, v); velocity = Vector2.zero; });
            ZoomSlider.SetValueWithoutNotify(Mathf.InverseLerp(5, 26, zoom));
            FullImage.gameObject.AddComponent<CommercialWorldMapInput>().View = this;
            MainQuestRow.onClick.AddListener(ShowMainQuest);
            for (var i = 0; i < QuestRows.Length; i++)
            {
                var index = i;
                QuestRows[i].onClick.AddListener(() => SelectNode("quest_" + (index + 1)));
            }
            foreach (var node in CommercialWorldCatalog.Nodes)
            {
                var marker = Instantiate(MarkerTemplate, MarkerLayer);
                marker.name = "Event_" + node.Id;
                var icon = node.Kind switch { WorldNodeKind.Survey => 1, WorldNodeKind.Gather => 4,
                    WorldNodeKind.Bridge => 0, WorldNodeKind.Exit => 0, _ => (int)node.Kind };
                marker.image.sprite = EventIcons[icon];
                marker.image.color = Color.white;
                marker.onClick.AddListener(() => SelectNode(node.Id));
                markers.Add(node.Id, marker);
                markerLabels.Add(node.Id, marker.GetComponentInChildren<Text>(true));
            }
            MarkerTemplate.gameObject.SetActive(false);
            var taskPanel = CommercialPrototypeController.FindDeep(transform, "MainQuestPanel");
            if (taskPanel)
            {
                var b = taskPanel.GetComponent<Button>() ?? taskPanel.gameObject.AddComponent<Button>();
                b.onClick.AddListener(() => { Open(); ShowQuestList(); });
            }
            State.EnsureCharacterData();
            CommercialWorldCatalog.RevealRegion(State, 1);
            var current = CommercialWorldCatalog.Find(State.World.CurrentNodeId);
            if (current != null) CommercialWorldCatalog.RevealRegion(State, current.Chapter);
            FullPage.SetActive(false);
            RefreshFog();
            FocusCurrent();
            if (controller.AwaitingFirstQuest) { Open(); FocusNode("quest_1"); }
        }

        public void Open()
        {
            if (!controller) return;
            controller.SetWorldMapMode(true);
            FullPage.SetActive(true);
            DetailPanel.SetActive(false);
            FocusCurrent();
            RefreshUI();
        }

        public void Hide()
        {
            if (FullPage) FullPage.SetActive(false);
            velocity = Vector2.zero; dragging = false; pinchTouches = 0;
            previewNode = null;
        }

        public void FocusCurrent()
        {
            if (!controller) return;
            var node = CommercialWorldCatalog.Find(State.World.CurrentNodeId) ?? CommercialWorldCatalog.Nodes[0];
            center = node.Position;
            velocity = Vector2.zero;
            SelectedNodeId = node.Id;
            previewNode = node.Id;
        }

        public void Pan(Vector2 pixelDelta, float viewportHeight, float deltaTime)
        {
            if (!IsOpen || viewportHeight <= 0) return;
            var movement = -pixelDelta * (zoom * 2 / viewportHeight);
            center += movement;
            velocity = Vector2.ClampMagnitude(movement / Mathf.Max(.008f, deltaTime), 60f);
        }
        public void BeginDrag() { dragging = true; velocity = Vector2.zero; }
        public void EndDrag() { dragging = false; }
        public void ZoomBy(float delta)
        {
            zoom = Mathf.Clamp(zoom + delta, 5, 26);
            ZoomSlider.SetValueWithoutNotify(Mathf.InverseLerp(5, 26, zoom));
            velocity = Vector2.zero;
        }

        private void LateUpdate()
        {
            if (!controller || !MapCamera) return;
            var visible = IsOpen || PreviewImage.gameObject.activeInHierarchy;
            if (!visible) { MapCamera.enabled = false; return; }
            if (!IsOpen && previewNode != State.World.CurrentNodeId) FocusCurrent();
            if (IsOpen && !dragging)
            {
                center += velocity * Time.unscaledDeltaTime;
                velocity *= Mathf.Exp(-9f * Time.unscaledDeltaTime);
            }
            if (IsOpen && Input.touchCount == 2)
            {
                var a = Input.GetTouch(0); var b = Input.GetTouch(1);
                if (RectTransformUtility.RectangleContainsScreenPoint(FullImage.rectTransform, a.position) &&
                    RectTransformUtility.RectangleContainsScreenPoint(FullImage.rectTransform, b.position))
                {
                    var distance = Vector2.Distance(a.position, b.position);
                    if (pinchTouches == 2) ZoomBy((pinchDistance - distance) * .035f);
                    pinchDistance = distance; pinchTouches = 2;
                }
            }
            else pinchTouches = 0;
            var target = IsOpen ? FullImage : PreviewImage;
            var aspect = Mathf.Max(.1f, target.rectTransform.rect.width / Mathf.Max(1, target.rectTransform.rect.height));
            var size = IsOpen ? zoom : 4.5f;
            var halfX = Mathf.Min(MapSize.x / 2, size * aspect);
            var halfY = Mathf.Min(MapSize.y / 2, size);
            center.x = Mathf.Clamp(center.x, -MapSize.x / 2 + halfX, MapSize.x / 2 - halfX);
            center.y = Mathf.Clamp(center.y, -MapSize.y / 2 + halfY, MapSize.y / 2 - halfY);
            MapCamera.orthographicSize = size;
            MapCamera.aspect = aspect;
            MapCamera.transform.position = MapRoot.position + new Vector3(center.x, center.y, -10);
            MapCamera.enabled = IsOpen || Time.unscaledTime >= renderAt;
            if (MapCamera.enabled) renderAt = Time.unscaledTime + .1f;
            if (IsOpen) UpdateMarkerPositions();
            if (Time.unscaledTime >= refreshAt)
            {
                refreshAt = Time.unscaledTime + .25f;
                RefreshFog(); RefreshUI();
            }
        }

        private void UpdateMarkerPositions()
        {
            var size = MarkerLayer.rect.size;
            foreach (var node in CommercialWorldCatalog.Nodes)
            {
                var p = MapCamera.WorldToViewportPoint(MapRoot.position + (Vector3)node.Position);
                var marker = markers[node.Id];
                var show = CommercialWorldCatalog.Unlocked(State, node) && CommercialWorldCatalog.Revealed(State, node) &&
                    p.x > .04f && p.x < .96f && p.y > .04f && p.y < .96f;
                marker.gameObject.SetActive(show);
                if (!show) continue;
                ((RectTransform)marker.transform).anchoredPosition = new Vector2((p.x - .5f) * size.x, (p.y - .5f) * size.y);
            }
        }

        public void SelectNode(string id)
        {
            var node = CommercialWorldCatalog.Find(id);
            if (!CommercialWorldCatalog.Unlocked(State, node)) { Toast(CommercialAshenForest.LockedReason(State, id)); return; }
            if (!CommercialWorldCatalog.Revealed(State, node)) { Toast("先探索该区域，驱散迷雾"); return; }
            SelectedNodeId = id; questMode = false;
            DetailPanel.SetActive(true);
            DetailTitle.text = node.Name + " · " + CommercialWorldCatalog.RegionNames[node.Chapter - 1];
            DetailBody.text = node.Description;
            ActionButton.onClick.RemoveAllListeners(); TrackButton.onClick.RemoveAllListeners();
            TrackButton.gameObject.SetActive(false);
            TrackButton.GetComponentInChildren<Text>().text = "追踪";
            ActionButton.interactable = true;
            if (id == "quest_1") { ShowForestQuest(); return; }
            if (CommercialAshenForest.IsForest(id) && node.Kind != WorldNodeKind.Idle && node.Kind != WorldNodeKind.Elite && node.Kind != WorldNodeKind.Boss)
            { ShowForestEvent(id); return; }
            if (node.Kind == WorldNodeKind.Quest)
            {
                var q = State.World.Quests.FirstOrDefault(x => x.Id == id);
                DetailBody.text += $"\n奖励：金币 {160 + node.Chapter * 80} · 经验 {40 + node.Chapter * 20}\n稀有装备 ×1 · 地区材料 ×4 · 锻造尘 ×2（自动分类入库）";
                ActionLabel.text = q == null ? "接取任务" : q.Claimed ? "已领取" : q.Completed ? "领取奖励" : "追踪并前往精英";
                ActionButton.interactable = q == null || !q.Claimed;
                ActionButton.onClick.AddListener(() =>
                {
                    if (q == null) { CommercialWorldCatalog.AcceptQuest(State, node.Chapter); Save(); SelectNode(id); }
                    else if (q.Completed) { CommercialWorldCatalog.ClaimQuest(State, id); Save(); SelectNode(id); }
                    else TrackQuest(id);
                });
                TrackButton.gameObject.SetActive(q != null && !q.Claimed);
                TrackButton.onClick.AddListener(() => TrackQuest(id));
            }
            else if (node.Kind == WorldNodeKind.Chest)
            {
                ActionLabel.text = State.World.CompletedNodes.Contains(id) ? "已开启" : "开启宝箱";
                ActionButton.interactable = !State.World.CompletedNodes.Contains(id);
                ActionButton.onClick.AddListener(() => { if (CommercialWorldCatalog.ClaimChest(State, id)) { Save(); Toast("宝箱奖励已放入背包"); } SelectNode(id); });
            }
            else
            {
                ActionLabel.text = node.Kind == WorldNodeKind.Idle ? "切换挂机区域" : "立即挑战";
                ActionButton.onClick.AddListener(() => controller.RequestWorldEncounter(id));
                if (State.World.CompletedNodes.Contains(id)) DetailBody.text += "\n首次奖励已领取；重复挑战仍有基础金币与经验。";
            }
        }

        public void FocusNode(string id)
        {
            var node = CommercialWorldCatalog.Find(id);
            if (node == null || !CommercialWorldCatalog.Unlocked(State, node)) return;
            // Locating a source never starts a fight or changes the idle encounter.
            center = node.Position; velocity = Vector2.zero; previewNode = node.Id;
            SelectNode(id);
        }

        private void TrackQuest(string id)
        {
            var q = State.World.Quests.FirstOrDefault(x => x.Id == id);
            if (q == null || q.Claimed) return;
            State.World.TrackedQuestId = id; Save();
            controller.RequestWorldEncounter("elite_" + CommercialWorldCatalog.Find(id).Chapter);
        }
        public void ShowQuestList()
        {
            if (!CommercialAshenForest.Finished(State) || CommercialWorldCatalog.Find(State.World.CurrentNodeId)?.Chapter == 1)
            { ShowForestQuest(); return; }
            questMode = true; DetailPanel.SetActive(false); RefreshUI();
            if (State.World.Quests.Count == 0) Toast("尚未接取支线，点击地图中的感叹号领取委托");
        }
        private void ShowMainQuest()
        {
            if (!CommercialAshenForest.Finished(State) || CommercialWorldCatalog.Find(State.World.CurrentNodeId)?.Chapter == 1)
            { ShowForestQuest(); return; }
            questMode = false; DetailPanel.SetActive(true); TrackButton.gameObject.SetActive(false);
            var target = CommercialWorldCatalog.MainRewardTarget(State);
            var task = CommercialWorldCatalog.CurrentMainQuest(State);
            DetailTitle.text = task == null ? "世界探索任务已全部完成" : "主线 · 探索" + CommercialWorldCatalog.RegionNames[task.Chapter - 1];
            DetailBody.text = task == null ? "可自由选择已探索地区挂机或挑战事件。" :
                $"区域挂机胜利 {task.IdleWins}/5\n击败区域首领 {(task.BossDefeated ? 1 : 0)}/1\n完成任务并领奖后解锁下一区域。\n金币 {200 + target * 100} · 经验 {60 + target * 30}\n史诗装备箱 ×1 · 锻造尘 ×4 · 探索徽记 ×1";
            ActionLabel.text = task?.Ready == true ? "领取奖励 / 解锁区域" : task?.IdleWins >= 5 ? "前往任务首领" : "前往任务挂机点";
            if (task == null) ActionLabel.text = "全部任务已完成";
            ActionButton.interactable = task != null; ActionButton.onClick.RemoveAllListeners();
            ActionButton.onClick.AddListener(() =>
            {
                if (CommercialWorldCatalog.ClaimMainReward(State)) { Save(); ShowMainQuest(); }
                else if (task != null)
                {
                    CommercialWorldCatalog.RevealRegion(State, task.Chapter);
                    controller.RequestWorldEncounter((task.IdleWins >= 5 ? "boss_" : "main_") + task.Chapter);
                }
            });
        }
        private void RevealNextRegion()
        {
            if (!CommercialAshenForest.Finished(State) || CommercialWorldCatalog.Find(State.World.CurrentNodeId)?.Chapter == 1)
            { FocusNode(CommercialAshenForest.Target(State)); return; }
            var chapter = Enumerable.Range(1, 5).FirstOrDefault(c => CommercialWorldCatalog.Unlocked(State, CommercialWorldCatalog.Find("main_" + c)) &&
                !CommercialWorldCatalog.Revealed(State, CommercialWorldCatalog.Find("main_" + c)));
            if (chapter == 0) { Toast("已探索所有可进入区域；完成主线任务并领奖可解锁新区域"); return; }
            CommercialWorldCatalog.RevealRegion(State, chapter); Save();
            center = CommercialWorldCatalog.RegionCenters[chapter - 1]; velocity = Vector2.zero;
            Toast("发现区域：" + CommercialWorldCatalog.RegionNames[chapter - 1]);
        }
        private void RefreshUI()
        {
            var revision = State.World.Forest.Step + ":" + State.World.Forest.Accepted + ":" + CommercialAshenForest.Progress(State);
            if (DetailPanel.activeSelf && SelectedNodeId == "quest_1" && revision != forestDetailRevision)
            { ShowForestQuest(); return; }
            var node = CommercialWorldCatalog.Find(State.World.CurrentNodeId) ?? CommercialWorldCatalog.Nodes[0];
            PreviewLocation.text = controller.CurrentWorldLocation;
            PreviewHint.text = "前往大地图  ›";
            Header.text = "世界探索  /  " + CommercialWorldCatalog.RegionNames[node.Chapter - 1];
            if (node.Chapter == 1) Header.text += $"  ·  发现 {CommercialAshenForest.Discovered(State)}/{CommercialAshenForest.Config.Nodes.Length}";
            RevealButton.GetComponentInChildren<Text>().text = node.Chapter == 1 ? "追踪目标" : "探索区域";
            Status.text = Time.unscaledTime < toastUntil ? toast :
                "拖动地图 · 双指 / 滑条缩放 · 后台战斗不中断";
            var main = CommercialWorldCatalog.CurrentMainQuest(State);
            MainQuestRow.GetComponentInChildren<Text>().text = main == null ? "世界探索任务已完成" :
                $"主线 · {CommercialWorldCatalog.RegionNames[main.Chapter - 1]}  挂机{main.IdleWins}/5 首领{(main.BossDefeated ? 1 : 0)}/1  ›";
            if (node.Chapter == 1 || !CommercialAshenForest.Finished(State))
                MainQuestRow.GetComponentInChildren<Text>().text = "主线 · " + CommercialAshenForest.Title(State) + "  ›";
            for (var i = 0; i < QuestRows.Length; i++)
            {
                var q = State.World.Quests.FirstOrDefault(x => x.Id == "quest_" + (i + 1));
                QuestRows[i].gameObject.SetActive(questMode && q != null && i != 0);
                QuestRows[i].GetComponentInChildren<Text>().text = CommercialWorldCatalog.RegionNames[i] + "委托  ·  " +
                    (q == null ? "未接取" : q.Claimed ? "已领取" : q.Completed ? "可领奖" : "击败精英 0/1") +
                    (State.World.TrackedQuestId == q?.Id ? "  [追踪]" : "");
            }
            foreach (var n in CommercialWorldCatalog.Nodes)
            {
                var q = State.World.Quests.FirstOrDefault(x => x.Id == n.Id);
                markerLabels[n.Id].text = (State.World.CurrentNodeId == n.Id ? "当前 · " : "") +
                    (q?.Claimed == true ? "委托已完成" : q?.Completed == true ? "委托可领奖" : n.Name) +
                    (n.Kind != WorldNodeKind.Idle && State.World.CompletedNodes.Contains(n.Id) ? " ✓" : "");
                if (n.Id == "quest_1") markerLabels[n.Id].text = CommercialAshenForest.Ready(State) ? "营地 · 可领奖！" : "灰烬营地 · 任务";
                var target = n.Id == CommercialAshenForest.Target(State);
                markers[n.Id].image.color = target ? new Color(1f, .82f, .3f) : Color.white;
            }
        }

        public void ShowForestQuest()
        {
            questMode = false; DetailPanel.SetActive(true); SelectedNodeId = "quest_1";
            forestDetailRevision = State.World.Forest.Step + ":" + State.World.Forest.Accepted + ":" + CommercialAshenForest.Progress(State);
            var finished = CommercialAshenForest.Finished(State);
            var q = CommercialAshenForest.Quest(State);
            DetailTitle.text = finished ? "灰烬森林 · 区域完成" : $"主线 {State.World.Forest.Step + 1}/4 · {q.Title}";
            DetailBody.text = finished ? "灰烬树王已被击败，通往鸦羽丘陵的道路已经开放。\n可继续探索森林支路，也可从鸦羽隘口前往新区域。" :
                q.Story + "\n\n" + CommercialAshenForest.Progress(State) + "\n\n奖励\n" + CommercialAshenForest.RewardDescription(State);
            var accepted = State.World.Forest.Accepted;
            var ready = CommercialAshenForest.Ready(State);
            ActionLabel.text = finished ? "前往鸦羽隘口" : !accepted ? "接取任务" : ready ? "领取任务奖励" : "追踪任务目标";
            ActionButton.interactable = true; ActionButton.onClick.RemoveAllListeners();
            ActionButton.onClick.AddListener(() =>
            {
                if (finished) { FocusNode("af_exit"); return; }
                if (!accepted)
                {
                    var error = CommercialAshenForest.Accept(State); Save();
                    Toast(error ?? "任务已接取 · 点击追踪目标开始探索"); ShowForestQuest();
                }
                else if (ready)
                {
                    var error = CommercialAshenForest.Claim(State); Save(); ShowForestQuest();
                    Toast(error ?? "奖励已入库 · 记得穿戴装备，再接取下一任务");
                }
                else FocusNode(CommercialAshenForest.Target(State));
            });
            TrackButton.onClick.RemoveAllListeners();
            TrackButton.gameObject.SetActive(State.World.Forest.Step > 0);
            TrackButton.GetComponentInChildren<Text>().text = "前往装备";
            TrackButton.onClick.AddListener(controller.OpenEquipmentFromMap);
            RefreshUI();
        }

        private void ShowForestEvent(string id)
        {
            var n = CommercialAshenForest.Node(id);
            if (n.Kind == "Exit")
            {
                ActionLabel.text = "前往鸦羽丘陵";
                ActionButton.onClick.AddListener(() =>
                { CommercialWorldCatalog.RevealRegion(State, 2); Save(); controller.RequestWorldEncounter("main_2"); });
                return;
            }
            var costs = n.Costs ?? Array.Empty<InventoryAmount>();
            var rewards = n.Rewards ?? Array.Empty<InventoryAmount>();
            if (costs.Length > 0) DetailBody.text += "\n\n交付：" + string.Join(" / ", costs.Select(i =>
                $"{CommercialInventoryCatalog.Name(i.Id)} {CommercialInventoryService.Count(State, i.Id)}/{i.Count}"));
            if (rewards.Length > 0) DetailBody.text += "\n\n获得：" + string.Join(" / ", rewards.Select(i => CommercialInventoryCatalog.Name(i.Id) + "×" + i.Count));
            var done = CommercialAshenForest.Done(State, id);
            ActionLabel.text = done ? "已完成" : n.Action;
            ActionButton.interactable = !done;
            ActionButton.onClick.AddListener(() =>
            {
                var error = CommercialAshenForest.Interact(State, id); Save(); SelectNode(id);
                Toast(error ?? (id == "af_bridge" ? "断桥已修复！打开任务领取奖励" : "探索完成 · 资源已自动分类入库"));
            });
        }

        private void RefreshFog()
        {
            if (fogRevision == State.World.RevealedNodes.Count) return;
            fogRevision = State.World.RevealedNodes.Count;
            if (!fogTexture)
            {
                fogTexture = new Texture2D(256, 256, TextureFormat.RGBA32, false) { name = "PersistentWorldFog", filterMode = FilterMode.Bilinear, wrapMode = TextureWrapMode.Clamp };
                fogSprite = Sprite.Create(fogTexture, new Rect(0, 0, 256, 256), new Vector2(.5f, .5f), 256);
                FogRenderer.sprite = fogSprite;
                FogRenderer.transform.localScale = new Vector3(MapSize.x, MapSize.y, 1);
            }
            var points = State.World.RevealedNodes.Select(CommercialWorldCatalog.Find).Where(n => n != null).Select(n => n.Position).ToArray();
            var pixels = new Color32[256 * 256];
            for (var y = 0; y < 256; y++) for (var x = 0; x < 256; x++)
            {
                var p = new Vector2((x / 255f - .5f) * MapSize.x, (y / 255f - .5f) * MapSize.y);
                var nearestSquared = 10000f;
                foreach (var point in points) nearestSquared = Mathf.Min(nearestSquared, (p - point).sqrMagnitude);
                var distance = Mathf.Sqrt(nearestSquared);
                var alpha = Mathf.SmoothStep(0, .94f, Mathf.InverseLerp(3.3f, 6.5f, distance));
                var shade = (byte)(22 + Mathf.PerlinNoise(x * .06f, y * .06f) * 18);
                pixels[y * 256 + x] = new Color32(shade, shade, (byte)(shade + 5), (byte)(alpha * 255));
            }
            fogTexture.SetPixels32(pixels); fogTexture.Apply();
        }
        private void Save() { CommercialSaveService.Save(State); RefreshFog(); RefreshUI(); }
        private void Toast(string message) { toast = message; toastUntil = Time.unscaledTime + 4; RefreshUI(); }
        private void OnDestroy()
        {
            if (MapCamera) { MapCamera.targetTexture = null; MapCamera.enabled = false; }
            if (FullImage) FullImage.texture = null;
            if (PreviewImage) PreviewImage.texture = null;
            if (mapTexture) { mapTexture.Release(); Destroy(mapTexture); }
            if (fogSprite) Destroy(fogSprite);
            if (fogTexture) Destroy(fogTexture);
        }
    }

    public sealed class CommercialWorldMapInput : MonoBehaviour, IBeginDragHandler, IDragHandler, IEndDragHandler, IScrollHandler
    {
        public CommercialWorldMapView View;
        public void OnBeginDrag(PointerEventData e) => View.BeginDrag();
        public void OnDrag(PointerEventData e)
        {
            if (Input.touchCount > 1) return;
            var canvas = GetComponentInParent<Canvas>();
            View.Pan(e.delta, ((RectTransform)transform).rect.height * canvas.scaleFactor, Time.unscaledDeltaTime);
        }
        public void OnEndDrag(PointerEventData e) => View.EndDrag();
        public void OnScroll(PointerEventData e) => View.ZoomBy(-e.scrollDelta.y * 1.2f);
    }
}

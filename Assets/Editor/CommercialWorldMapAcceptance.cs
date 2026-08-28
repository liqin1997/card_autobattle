using System;
using System.Linq;
using System.Reflection;
using CardAutobattle.Commercial;
using UnityEditor;
using UnityEngine;

namespace CardAutobattle.EditorTools
{
    /// <summary>Deterministic checks, isolated from the player's persistent save.</summary>
    public static class CommercialWorldMapAcceptance
    {
        private const BindingFlags Flags = BindingFlags.Instance | BindingFlags.NonPublic;
        private const string SaveKey = "CardAutobattle.CommercialSave.v1";
        private static int checks;
        private static void Check(bool condition, string label)
        { if (!condition) throw new InvalidOperationException("World map acceptance failed: " + label); checks++; }

        public static string RunDataChecks()
        {
            checks = 0;
            var state = CommercialEquipmentAcceptance.Fixture();
            state.World.RevealedNodes.Clear();
            state.PlayerLevel = 25;
            // Legacy-region regression fixture. Fresh forest progression is covered by CommercialAshenForestAcceptance.
            state.World.RegionTasks[0].Claimed = true; state.World.Ensure();
            Check(CommercialWorldCatalog.Nodes.Count == 34, "34 map nodes");
            Check(CommercialWorldCatalog.Nodes.Select(n => n.Id).Distinct().Count() == 34, "unique node ids");
            Check(!CommercialWorldCatalog.Unlocked(state, CommercialWorldCatalog.Find("main_3")), "next region locked");
            CommercialWorldCatalog.RevealRegion(state, 2);
            Check(state.World.RevealedNodes.Count == 5, "fog region reveal");
            Check(!CommercialWorldCatalog.RevealRegion(state, 2), "reveal idempotent");
            Check(CommercialWorldCatalog.AcceptQuest(state, 2), "accept side quest");
            Check(!CommercialWorldCatalog.AcceptQuest(state, 2), "accept idempotent");
            var elite = CommercialWorldCatalog.CreateEncounter(state, "elite_2");
            Fight(state, elite);
            Check(state.World.Quests[0].Completed, "real elite battle credits side quest");
            var gold = state.Gold;
            Check(CommercialWorldCatalog.ClaimQuest(state, "quest_2") && state.Gold > gold, "quest reward");
            gold = state.Gold;
            Check(!CommercialWorldCatalog.ClaimQuest(state, "quest_2") && state.Gold == gold, "quest reward exactly once");
            Check(CommercialWorldCatalog.ClaimChest(state, "chest_2"), "chest reward");
            gold = state.Gold;
            Check(!CommercialWorldCatalog.ClaimChest(state, "chest_2") && state.Gold == gold, "chest exactly once");
            Check(!CommercialWorldCatalog.ClaimChest(state, "chest_3"), "locked chest not lootable");
            var legacyStage = state.GlobalStage;
            for (var i = 0; i < 5; i++) Fight(state, CommercialWorldCatalog.CreateEncounter(state, "main_2"));
            Check(state.World.RegionTasks[1].IdleWins == 5, "idle objective counts 5 wins");
            Check(state.GlobalStage == legacyStage, "no linear stage auto-advance");
            Check(!CommercialWorldCatalog.ClaimMainReward(state), "boss objective still required");
            // This assertion covers generic regional quest settlement, not region-2 combat tuning.
            // Actual fresh-start boss combat is verified across 40 seeds in CommercialAshenForestAcceptance.
            CommercialWorldCatalog.RecordVictory(state, CommercialWorldCatalog.CreateEncounter(state, "boss_2"));
            Check(state.World.RegionTasks[1].Ready, "boss + idle complete main quest");
            Check(CommercialWorldCatalog.ClaimMainReward(state), "claim main quest");
            Check(!CommercialWorldCatalog.ClaimMainReward(state), "next task cannot be auto-claimed");
            Check(CommercialWorldCatalog.Unlocked(state, CommercialWorldCatalog.Find("main_3")), "quest reward unlocks new region");
            Check(CommercialWorldCatalog.CreateEncounter(state, "main_3") == null, "unrevealed region cannot be entered");
            CommercialWorldCatalog.RevealRegion(state, 3);
            Check(CommercialWorldCatalog.CreateEncounter(state, "main_3") != null, "explored region accessible");
            var loaded = JsonUtility.FromJson<CommercialGameState>(JsonUtility.ToJson(state)); loaded.EnsureCharacterData();
            Check(loaded.World.Quests[0].Claimed && loaded.World.RegionTasks[1].Claimed && loaded.World.RevealedNodes.Count == 10, "save round-trip");
            var oldSave = JsonUtility.FromJson<CommercialGameState>("{\"PlayerLevel\":3,\"Chapter\":1,\"Stage\":8}"); oldSave.EnsureCharacterData();
            Check(oldSave.World.RegionTasks.Count == 5 && oldSave.World.CurrentNodeId == "main_1", "old-save migration");
            foreach (CommercialProfessionId profession in Enum.GetValues(typeof(CommercialProfessionId)))
            {
                var test = CommercialGameState.CreateDefault(); test.PlayerLevel = 25; test.SwitchProfession(profession);
                var session = new CommercialBattleSession(test, test.DraftFormation, 17041);
                Check(session.TrySwapPlayerGridPositions(0, 3), profession + " live card swap");
                session.Advance(90);
                Check(session.Result == CommercialBattleResult.Victory, profession + " real battle victory");
                Check(session.Hero.Health > 0 && session.LivingEnemyCount == 0, profession + " valid result");
            }
            return "PASS: " + checks + " data/battle checks. No persistent save writes.";
        }

        private static void Fight(CommercialGameState state, CommercialWorldEncounter encounter)
        {
            Check(encounter != null, "valid encounter");
            var session = new CommercialBattleSession(state, state.DraftFormation, 17041, encounter);
            session.Advance(90);
            Check(session.Result == CommercialBattleResult.Victory, encounter.NodeId + " actual battle victory");
            CommercialWorldCatalog.RecordVictory(state, encounter);
        }

        public static string RunRuntimeChecks()
        {
            if (!Application.isPlaying) throw new InvalidOperationException("Run in Play Mode.");
            checks = 0;
            var controller = UnityEngine.Object.FindObjectOfType<CommercialPrototypeController>();
            var view = controller.GetComponent<CommercialWorldMapView>();
            var originalState = controller.State;
            var originalBattle = controller.Battle;
            var originalEncounter = Get(controller, "worldEncounter");
            var oldSettled = Get(controller, "battleSettled");
            var hadSave = PlayerPrefs.HasKey(SaveKey);
            var save = PlayerPrefs.GetString(SaveKey, "");
            controller.enabled = false;
            try
            {
                var state = CommercialEquipmentAcceptance.Fixture(); state.PlayerLevel = 25;
                state.World.RevealedNodes.Clear();
            // Legacy-region regression fixture. Fresh forest progression is covered by CommercialAshenForestAcceptance.
            state.World.RegionTasks[0].Claimed = true; state.World.Ensure();
                Set(controller, "state", state);
                CommercialWorldCatalog.RevealRegion(state, 2);
                controller.RequestWorldEncounter("main_2");
                var oldBattle = controller.Battle;
                oldBattle.Advance(.4f);
                var gold = state.Gold;
                view.Open();
                Check(view.IsOpen && !GameObject.Find("BattlePresentationRoot"), "full map hides battle presentation");
                controller.RequestWorldEncounter("boss_2");
                Check(!view.IsOpen && controller.Battle != oldBattle && controller.Battle.Elapsed == 0, "boss immediately interrupts old battle");
                Check(state.Gold == gold && state.World.RegionTasks[1].IdleWins == 0, "interrupted fight no rewards or progress");
                Check(controller.Battle.Enemies[0].DisplayName == "区域首领", "correct boss encounter");
                Check(!controller.RequestWorldEncounter("boss_5"), "locked destination rejected");
                Check(controller.CurrentWorldLocation.Contains("首领"), "center location shows actual encounter");
                CommercialWorldCatalog.AcceptQuest(state, 2);
                controller.RequestWorldEncounter("elite_2");
                controller.Battle.Advance(90); Call(controller, "ResolveBattle");
                Check(state.World.Quests[0].Completed, "runtime real elite victory updates quest");
                gold = state.Gold; Call(controller, "ResolveBattle");
                Check(state.Gold == gold, "battle settlement once");
                Call(controller, "StartNextBattle");
                Check(state.World.CurrentNodeId == state.World.IdleNodeId, "event ends resume previous idle location");
                view.Open();
                view.SelectNode("quest_2"); view.ActionButton.onClick.Invoke();
                Check(state.World.Quests[0].Claimed, "UI claims completed quest");
                view.SelectNode("chest_2"); view.ActionButton.onClick.Invoke();
                Check(state.World.CompletedNodes.Contains("chest_2"), "UI chest button works");
                var before = view.MapCamera.transform.position;
                view.BeginDrag(); view.Pan(new Vector2(180, 90), 1000, .1f); view.EndDrag();
                Check(((Vector2)Get(view, "center")) != CommercialWorldCatalog.RegionCenters[1], "pan changes camera center");
                view.ZoomBy(-999);
                Check((float)Get(view, "zoom") == 5, "minimum zoom clamped");
                view.ZoomBy(999);
                Check((float)Get(view, "zoom") == 26, "maximum zoom clamped");
                view.OpenCityButton.onClick.Invoke(); Check(view.IsOpen, "city map entry");
                view.BackButton.onClick.Invoke(); Check(!view.IsOpen, "back closes map");
                view.OpenPreviewButton.onClick.Invoke(); Check(view.IsOpen, "explore preview entry");
                return "PASS: " + checks + " runtime UI/interruption/settlement checks; player state/save restored in finally.";
            }
            finally
            {
                Set(controller, "state", originalState); Set(controller, "battle", originalBattle);
                Set(controller, "worldEncounter", originalEncounter); Set(controller, "battleSettled", oldSettled);
                controller.ReturnFromWorldMap(); Call(controller, "BindBattleViews", new object[] { null });
                controller.enabled = false; // Leave gameplay stopped for visual QA; caller explicitly resumes it.
                if (hadSave) PlayerPrefs.SetString(SaveKey, save); else PlayerPrefs.DeleteKey(SaveKey);
                PlayerPrefs.Save();
            }
        }
        private static object Get(object o, string field) => o.GetType().GetField(field, Flags).GetValue(o);
        private static void Set(object o, string field, object value) => o.GetType().GetField(field, Flags).SetValue(o, value);
        private static void Call(object o, string method, object[] args = null) => o.GetType().GetMethod(method, Flags).Invoke(o, args);
    }
}

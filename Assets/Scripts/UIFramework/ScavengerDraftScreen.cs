using System;
using CardAutobattle.Exploration;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class ScavengerDraftScreen : UIScreenBase
    {
        [SerializeField] private Button[] candidateButtons = new Button[3];
        [SerializeField] private Image[] candidateFrames = new Image[3];
        [SerializeField] private Text[] candidateNames = new Text[3];
        [SerializeField] private Text[] candidateStats = new Text[3];
        [SerializeField] private Text[] candidateTalents = new Text[3];
        [SerializeField] private Text selectionSummary;
        [SerializeField] private Button confirmButton;
        [SerializeField] private Button backButton;

        private ScavengerRecord[] candidates;
        private int selectedIndex = -1;

        public override UIScreenId ScreenId => UIScreenId.ScavengerDraft;

        protected override void OnInitialize()
        {
            for (var i = 0; i < candidateButtons.Length; i++)
            {
                var index = i;
                if (candidateButtons[i])
                    candidateButtons[i].onClick.AddListener(() => Select(index));
            }
            if (confirmButton)
                confirmButton.onClick.AddListener(Confirm);
            if (backButton)
                backButton.onClick.AddListener(() => UIRoot.Screens.Back());
        }

        protected override void OnOpen(object args)
        {
            candidates = ScavengerGenerator.GenerateCandidates(Environment.TickCount);
            selectedIndex = -1;
            if (confirmButton) confirmButton.interactable = false;
            if (selectionSummary)
                selectionSummary.text = "选择本次探索的卡组载体 · 槽位数量不会被平衡补偿";
            RefreshCandidates();
        }

        private void RefreshCandidates()
        {
            for (var i = 0; i < candidateButtons.Length; i++)
            {
                var available = candidates != null && i < candidates.Length && candidates[i] != null;
                candidateButtons[i].gameObject.SetActive(available);
                if (!available)
                    continue;
                var candidate = candidates[i];
                var stats = candidate.GetCurrentStats();
                candidateNames[i].text = $"{candidate.DisplayName}  ·  {candidate.Archetype}\n" +
                    $"Lv.1   天赋槽 {candidate.TalentSlots}";
                candidateStats[i].text =
                    $"武力 {stats.Might:0.#}  (+{candidate.Growth.Might:0.00}/级)\n" +
                    $"智力 {stats.Intellect:0.#}  (+{candidate.Growth.Intellect:0.00}/级)\n" +
                    $"防御 {stats.Defense:0.#}  (+{candidate.Growth.Defense:0.00}/级)\n" +
                    $"体力 {stats.Vitality:0.#}  (+{candidate.Growth.Vitality:0.00}/级)";
                candidateTalents[i].supportRichText = true;
                candidateTalents[i].text = BuildTalentText(candidate);
                candidateFrames[i].color = i == selectedIndex
                    ? new Color(.10f, .72f, .60f, 1f)
                    : candidate.TalentSlots >= 6
                        ? new Color(.28f, .16f, .08f, 1f)
                        : new Color(.055f, .095f, .115f, 1f);
            }
        }

        private static string BuildTalentText(ScavengerRecord candidate)
        {
            var lines = new System.Text.StringBuilder();
            foreach (var talent in candidate.Talents)
            {
                var color = ColorUtility.ToHtmlStringRGB(ScavengerTalentCatalog.RarityColor(talent.Rarity));
                lines.Append("<color=#").Append(color).Append(">").Append(talent.DisplayName)
                    .Append("</color>  ").Append(talent.Description).AppendLine();
            }
            return lines.ToString().TrimEnd();
        }

        private void Select(int index)
        {
            if (candidates == null || index < 0 || index >= candidates.Length)
                return;
            selectedIndex = index;
            var selected = candidates[index];
            if (selectionSummary)
                selectionSummary.text = $"已选择 {selected.DisplayName} · {selected.TalentSlots}槽 · " +
                    $"最大生命 {selected.GetMaxHealth():0}";
            if (confirmButton) confirmButton.interactable = true;
            RefreshCandidates();
        }

        private void Confirm()
        {
            if (selectedIndex < 0 || candidates == null)
                return;
            ExplorationRunContext.Select(candidates[selectedIndex]);
            UIRoot.Screens.Open(UIScreenId.Preparation, candidates[selectedIndex]);
        }

#if UNITY_EDITOR
        public void EditorConfigure(Button[] buttons, Image[] frames, Text[] names, Text[] stats,
            Text[] talents, Text summary, Button confirm, Button back)
        {
            candidateButtons = buttons;
            candidateFrames = frames;
            candidateNames = names;
            candidateStats = stats;
            candidateTalents = talents;
            selectionSummary = summary;
            confirmButton = confirm;
            backButton = back;
        }
#endif
    }
}

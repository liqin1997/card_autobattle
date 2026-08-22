using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class MainHubScreen : UIScreenBase
    {
        public enum MainTab
        {
            Gacha,
            Heroes,
            City,
            Explore,
            Codex
        }

        [SerializeField] private Button[] tabButtons = new Button[5];
        [SerializeField] private Image[] tabBackgrounds = new Image[5];
        [SerializeField] private Text[] tabLabels = new Text[5];
        [SerializeField] private GameObject[] pages = new GameObject[5];
        [SerializeField] private Button enterPreparationButton;
        [SerializeField] private MainTab defaultTab = MainTab.City;

        private static readonly Color SelectedColor = new(.10f, .72f, .60f, 1f);
        private static readonly Color NormalColor = new(.055f, .085f, .105f, .98f);
        private static readonly Color SelectedText = new(.94f, 1f, .97f, 1f);
        private static readonly Color NormalText = new(.55f, .65f, .70f, 1f);
        private MainTab currentTab;
        private bool hasSelection;

        public override UIScreenId ScreenId => UIScreenId.MainHub;

        protected override void OnInitialize()
        {
            for (var i = 0; i < tabButtons.Length; i++)
            {
                var index = i;
                if (tabButtons[i])
                    tabButtons[i].onClick.AddListener(() => SelectTab((MainTab)index));
            }

            if (enterPreparationButton)
                enterPreparationButton.onClick.AddListener(EnterPreparation);
        }

        protected override void OnOpen(object args)
        {
            if (!hasSelection)
                SelectTab(defaultTab);
        }

        public void SelectTab(MainTab tab)
        {
            currentTab = tab;
            hasSelection = true;
            for (var i = 0; i < pages.Length; i++)
            {
                var selected = i == (int)tab;
                if (pages[i])
                    pages[i].SetActive(selected);
                if (i < tabBackgrounds.Length && tabBackgrounds[i])
                    tabBackgrounds[i].color = selected ? SelectedColor : NormalColor;
                if (i < tabLabels.Length && tabLabels[i])
                    tabLabels[i].color = selected ? SelectedText : NormalText;
            }
            if (tab == MainTab.Heroes)
                GetComponentInChildren<ScavengerRosterView>(true)?.Refresh();
        }

        private void EnterPreparation()
        {
            UIRoot.Screens.Open(UIScreenId.ScavengerDraft);
        }

        public override bool HandleBack()
        {
            if (currentTab == MainTab.City)
                return false;
            SelectTab(MainTab.City);
            return true;
        }

#if UNITY_EDITOR
        public void EditorConfigure(Button[] buttons, Image[] backgrounds, Text[] labels,
            GameObject[] contentPages, Button preparationButton)
        {
            tabButtons = buttons;
            tabBackgrounds = backgrounds;
            tabLabels = labels;
            pages = contentPages;
            enterPreparationButton = preparationButton;
        }
#endif
    }
}

using System;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [Serializable]
    public sealed class ExplorationEventChoice
    {
        public string Title;
        public string Description;
        public string Footer;

        public ExplorationEventChoice(string title, string description, string footer = null)
        {
            Title = title;
            Description = description;
            Footer = footer;
        }
    }

    [DisallowMultipleComponent]
    public sealed class ExplorationChoiceEventView : MonoBehaviour
    {
        [SerializeField] private Image accentBar;
        [SerializeField] private Text title;
        [SerializeField] private Text description;
        [SerializeField] private Button[] choiceButtons = new Button[3];
        [SerializeField] private Text[] choiceTitles = new Text[3];
        [SerializeField] private Text[] choiceDescriptions = new Text[3];
        [SerializeField] private Text footer;

        private Action<int> selectCallback;
        private bool resolved;

        public void Open(string eventTitle, string eventDescription, Color accent,
            ExplorationEventChoice[] choices, Action<int> onSelect)
        {
            resolved = false;
            selectCallback = onSelect;
            if (title) title.text = eventTitle;
            if (description) description.text = eventDescription;
            if (accentBar) accentBar.color = accent;
            if (footer) footer.text = "选择后立即生效 · 本次事件不可撤销";

            for (var i = 0; i < choiceButtons.Length; i++)
            {
                var index = i;
                var available = choices != null && i < choices.Length && choices[i] != null;
                choiceButtons[i].gameObject.SetActive(available);
                choiceButtons[i].onClick.RemoveAllListeners();
                if (!available)
                    continue;
                if (choiceTitles[i]) choiceTitles[i].text = choices[i].Title;
                if (choiceDescriptions[i]) choiceDescriptions[i].text = choices[i].Description;
                choiceButtons[i].onClick.AddListener(() => Select(index));
            }
        }

        private void Select(int index)
        {
            if (resolved)
                return;
            resolved = true;
            foreach (var button in choiceButtons)
                if (button) button.interactable = false;
            selectCallback?.Invoke(index);
        }

#if UNITY_EDITOR
        public void EditorConfigure(Image accent, Text eventTitle, Text eventDescription,
            Button[] buttons, Text[] titles, Text[] descriptions, Text footerText)
        {
            accentBar = accent;
            title = eventTitle;
            description = eventDescription;
            choiceButtons = buttons;
            choiceTitles = titles;
            choiceDescriptions = descriptions;
            footer = footerText;
        }
#endif
    }
}

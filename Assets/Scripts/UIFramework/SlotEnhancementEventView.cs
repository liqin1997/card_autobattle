using System;
using CardAutobattle.Preparation;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class SlotEnhancementEventView : MonoBehaviour
    {
        [SerializeField] private GameObject choicePanel;
        [SerializeField] private Button[] choiceButtons = new Button[3];
        [SerializeField] private Text[] choiceTitles = new Text[3];
        [SerializeField] private Text[] choiceDescriptions = new Text[3];
        [SerializeField] private GameObject targetingPanel;
        [SerializeField] private Text targetingTitle;
        [SerializeField] private Text targetingHint;
        [SerializeField] private Button backButton;
        [SerializeField] private Button confirmButton;

        private SlotModifierType[] choices;
        private Action<SlotModifierType> choiceCallback;
        private Action backCallback;
        private Action confirmCallback;

        public void Open(SlotModifierType[] offeredChoices, Action<SlotModifierType> onChoice, Action onBack)
        {
            choices = offeredChoices;
            choiceCallback = onChoice;
            backCallback = onBack;
            for (var i = 0; i < choiceButtons.Length; i++)
            {
                var index = i;
                var available = choices != null && index < choices.Length;
                choiceButtons[i].gameObject.SetActive(available);
                choiceButtons[i].onClick.RemoveAllListeners();
                if (!available)
                    continue;
                choiceTitles[i].text = SlotModifierRules.DisplayName(choices[index]);
                choiceDescriptions[i].text = SlotModifierRules.Description(choices[index]);
                choiceButtons[i].onClick.AddListener(() => choiceCallback?.Invoke(choices[index]));
            }

            if (backButton)
            {
                backButton.onClick.RemoveAllListeners();
                backButton.onClick.AddListener(() => backCallback?.Invoke());
            }
            if (confirmButton)
                confirmButton.onClick.RemoveAllListeners();
            ShowChoices();
        }

        public void ShowChoices()
        {
            if (choicePanel) choicePanel.SetActive(true);
            if (targetingPanel) targetingPanel.SetActive(false);
        }

        public void BeginTargeting(SlotModifierType modifier)
        {
            if (choicePanel) choicePanel.SetActive(false);
            if (targetingPanel) targetingPanel.SetActive(true);
            if (targetingTitle) targetingTitle.text = SlotModifierRules.DisplayName(modifier);
            if (targetingHint) targetingHint.text = "请选择一个3×3棋盘槽位";
            if (confirmButton) confirmButton.interactable = false;
        }

        public void PreviewTarget(SlotModifierType modifier, int slotIndex, Action onConfirm)
        {
            confirmCallback = onConfirm;
            if (targetingTitle) targetingTitle.text = $"{SlotModifierRules.DisplayName(modifier)}  →  格子 {slotIndex + 1}";
            if (targetingHint) targetingHint.text = SlotModifierRules.Description(modifier);
            if (confirmButton)
            {
                confirmButton.interactable = true;
                confirmButton.onClick.RemoveAllListeners();
                confirmButton.onClick.AddListener(() => confirmCallback?.Invoke());
            }
        }
    }
}

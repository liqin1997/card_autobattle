using System;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class ExplorationCompleteView : MonoBehaviour
    {
        [SerializeField] private Text title;
        [SerializeField] private Text summary;
        [SerializeField] private Button returnButton;

        public void Open(string mapName, string scavengerName, int level, int experience, int coins, Action onReturn)
        {
            if (title) title.text = "探索完成";
            if (summary)
                summary.text = $"{mapName}\n\n拾荒者 {scavengerName}  Lv.{level}   经验 {experience}\n" +
                    $"持有金币 {coins}\n\n已暂存至英雄界面 · 卡组阵容已锁定";
            if (!returnButton)
                return;
            returnButton.onClick.RemoveAllListeners();
            if (onReturn != null)
                returnButton.onClick.AddListener(() => onReturn());
        }

#if UNITY_EDITOR
        public void EditorConfigure(Text titleText, Text summaryText, Button button)
        {
            title = titleText;
            summary = summaryText;
            returnButton = button;
        }
#endif
    }
}

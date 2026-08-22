using CardAutobattle.Exploration;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class ScavengerRosterView : MonoBehaviour
    {
        [SerializeField] private GameObject[] cards = new GameObject[6];
        [SerializeField] private Text[] names = new Text[6];
        [SerializeField] private Text[] details = new Text[6];

        private void OnEnable()
        {
            Refresh();
        }

        public void Refresh()
        {
            var records = ScavengerRosterRepository.Records;
            for (var i = 0; i < cards.Length; i++)
            {
                var hasRecord = i < records.Count;
                cards[i].SetActive(true);
                if (!hasRecord)
                {
                    names[i].text = i == 0 ? "暂无历练拾荒者" : "空位";
                    details[i].text = i == 0 ? "完成一次地图探索后，拾荒者会暂存在这里" : string.Empty;
                    continue;
                }

                var record = records[i];
                var stats = record.GetCurrentStats();
                names[i].text = $"{record.DisplayName}  Lv.{record.Level}\n{record.Archetype} · {record.TalentSlots}槽";
                details[i].text = $"武{stats.Might:0} 智{stats.Intellect:0} 防{stats.Defense:0} 体{stats.Vitality:0}\n" +
                    $"天赋 {record.TalentIds.Count}   锁定卡牌 {record.LockedDeck.Count}\n" +
                    (record.ExplorationCompleted ? "已完成 灰烬边境" : "探索中");
            }
        }

#if UNITY_EDITOR
        public void EditorConfigure(GameObject[] cardObjects, Text[] nameTexts, Text[] detailTexts)
        {
            cards = cardObjects;
            names = nameTexts;
            details = detailTexts;
        }
#endif
    }
}

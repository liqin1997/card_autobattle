using System;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Prototype
{
    [DisallowMultipleComponent]
    public sealed class BattleSceneView : MonoBehaviour
    {
        [SerializeField] private BattleActorView playerActor;
        [SerializeField] private BattleActorView enemyActor;
        [SerializeField] private RectTransform playerBoard;
        [SerializeField] private Text roundLabel;
        [SerializeField] private Text timerLabel;
        [SerializeField] private GameObject resultPanel;
        [SerializeField] private Text resultLabel;
        [SerializeField] private Button returnButton;

        private Color previousCameraColor;
        private Camera worldCamera;

        public void Initialize(int round, Action returnAction)
        {
            worldCamera = Camera.main;
            if (worldCamera)
            {
                previousCameraColor = worldCamera.backgroundColor;
                worldCamera.backgroundColor = new Color(.018f, .055f, .072f, 1f);
            }

            playerActor?.Initialize("我方");
            enemyActor?.Initialize($"敌方  R{round}");
            if (roundLabel)
                roundLabel.text = $"第 {round} 轮";
            if (resultPanel)
                resultPanel.SetActive(false);
            if (returnButton)
            {
                returnButton.gameObject.SetActive(false);
                returnButton.onClick.RemoveAllListeners();
                if (returnAction != null)
                    returnButton.onClick.AddListener(() => returnAction());
            }

            ClearPlayerBoard();
        }

        public Transform GetPlayerCell(int index)
        {
            if (!playerBoard || index < 0 || index >= playerBoard.childCount)
                return null;
            return playerBoard.GetChild(index);
        }

        public void SetHud(float playerHealth, float playerMaxHealth, float playerShield,
            float enemyHealth, float enemyMaxHealth, float enemyShield, float seconds, float speed)
        {
            playerActor?.SetHealth(playerHealth, playerMaxHealth, playerShield);
            enemyActor?.SetHealth(enemyHealth, enemyMaxHealth, enemyShield);
            if (timerLabel)
                timerLabel.text = $"自动战斗  {Mathf.Max(0f, seconds):0.0}s   ×{speed:0.##}";
        }

        public void PlayCardActivation(bool enemySource, CardEffectKind effect, float amount)
        {
            var offensive = IsOffensive(effect);
            var source = enemySource ? enemyActor : playerActor;
            var target = enemySource ? playerActor : enemyActor;
            source?.PlayAction(offensive, amount);
            if (offensive)
                target?.ReceiveHit(amount);
        }

        public void ShowResult(bool won, int reward)
        {
            if (resultPanel)
                resultPanel.SetActive(true);
            if (resultLabel)
            {
                resultLabel.text = won ? $"胜利\n+{reward} 金币" : $"战败\n+{reward} 金币";
                resultLabel.color = won ? new Color(.35f, 1f, .68f) : new Color(1f, .38f, .32f);
                resultLabel.gameObject.SetActive(true);
            }

            if (returnButton)
                returnButton.gameObject.SetActive(true);
            if (timerLabel)
                timerLabel.gameObject.SetActive(false);
            (won ? enemyActor : playerActor)?.PlayDefeat();
        }

        private void ClearPlayerBoard()
        {
            if (!playerBoard)
                return;
            foreach (var card in playerBoard.GetComponentsInChildren<BattleCardView>(true))
                Destroy(card.gameObject);
        }

        private static bool IsOffensive(CardEffectKind effect)
        {
            return effect is CardEffectKind.Damage or CardEffectKind.DamageAndBurn or
                CardEffectKind.DamageAndPoison or CardEffectKind.DamageAndSlow or
                CardEffectKind.DamageAndHaste or CardEffectKind.ShieldAndDamage or
                CardEffectKind.Drain or CardEffectKind.ChainDamage;
        }

        private void OnDestroy()
        {
            if (worldCamera)
                worldCamera.backgroundColor = previousCameraColor;
        }
    }
}

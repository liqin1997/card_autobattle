using System.Collections;
using Spine;
using Spine.Unity;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.Prototype
{
    [DisallowMultipleComponent]
    public sealed class BattleActorView : MonoBehaviour
    {
        [Header("Spine")]
        [SerializeField] private SkeletonAnimation skeletonAnimation;
        [SerializeField] private string skinName;
        [SerializeField] private string idleAnimation = "idle";
        [SerializeField] private string attackAnimation = "shoot";
        [SerializeField] private string skillAnimation = "ring";
        [SerializeField] private string hitAnimation = "hitted";

        [Header("World Health Bar")]
        [SerializeField] private Canvas healthCanvas;
        [SerializeField] private Image healthFill;
        [SerializeField] private Image shieldFill;
        [SerializeField] private Text healthLabel;
        [SerializeField] private Text nameLabel;

        private Color baseSkeletonColor = Color.white;
        private Coroutine feedbackRoutine;

        public void Initialize(string displayName)
        {
            if (!skeletonAnimation)
                skeletonAnimation = GetComponentInChildren<SkeletonAnimation>(true);

            if (skeletonAnimation)
            {
                skeletonAnimation.Initialize(true);
                if (!string.IsNullOrWhiteSpace(skinName) && skeletonAnimation.Skeleton.Data.FindSkin(skinName) != null)
                {
                    skeletonAnimation.Skeleton.SetSkin(skinName);
                    skeletonAnimation.Skeleton.SetSlotsToSetupPose();
                }

                baseSkeletonColor = new Color(skeletonAnimation.Skeleton.R, skeletonAnimation.Skeleton.G,
                    skeletonAnimation.Skeleton.B, skeletonAnimation.Skeleton.A);
                PlayLoop(idleAnimation);
            }

            if (nameLabel)
                nameLabel.text = displayName;
            SetHealth(1f, 1f, 0f);
        }

        public void SetHealth(float health, float maxHealth, float shield)
        {
            var safeMax = Mathf.Max(1f, maxHealth);
            if (healthFill)
                healthFill.fillAmount = Mathf.Clamp01(health / safeMax);
            if (shieldFill)
                shieldFill.fillAmount = Mathf.Clamp01(shield / safeMax);
            if (healthLabel)
                healthLabel.text = $"{Mathf.CeilToInt(health)}/{Mathf.CeilToInt(maxHealth)}   护盾 {Mathf.CeilToInt(shield)}";
        }

        public void PlayAction(bool offensive, float amount)
        {
            var animationName = offensive ? attackAnimation : skillAnimation;
            PlayOnceThenIdle(animationName);
            ShowFloatingValue(amount, offensive ? new Color(1f, .82f, .28f) : new Color(.35f, 1f, .72f), offensive ? "发动" : "+");
        }

        public void ReceiveHit(float amount)
        {
            if (HasAnimation(hitAnimation))
                PlayOnceThenIdle(hitAnimation);

            ShowFloatingValue(amount, new Color(1f, .28f, .22f), "-");
            if (feedbackRoutine != null)
                StopCoroutine(feedbackRoutine);
            feedbackRoutine = StartCoroutine(HitFeedback());
        }

        public void PlayDefeat()
        {
            var defeat = HasAnimation("die") ? "die" : HasAnimation("dying") ? "dying" : hitAnimation;
            if (HasAnimation(defeat))
                skeletonAnimation.AnimationState.SetAnimation(0, defeat, false);
        }

        private void PlayLoop(string animationName)
        {
            if (HasAnimation(animationName))
                skeletonAnimation.AnimationState.SetAnimation(0, animationName, true);
        }

        private void PlayOnceThenIdle(string animationName)
        {
            if (!HasAnimation(animationName))
                return;

            skeletonAnimation.AnimationState.SetAnimation(0, animationName, false);
            if (HasAnimation(idleAnimation))
                skeletonAnimation.AnimationState.AddAnimation(0, idleAnimation, true, 0f);
        }

        private bool HasAnimation(string animationName)
        {
            return skeletonAnimation && skeletonAnimation.Skeleton != null &&
                   !string.IsNullOrWhiteSpace(animationName) &&
                   skeletonAnimation.Skeleton.Data.FindAnimation(animationName) != null;
        }

        private IEnumerator HitFeedback()
        {
            if (!skeletonAnimation || skeletonAnimation.Skeleton == null)
                yield break;

            var start = transform.localPosition;
            for (var elapsed = 0f; elapsed < .22f; elapsed += Time.deltaTime)
            {
                var t = elapsed / .22f;
                SetSkeletonColor(Color.Lerp(new Color(1f, .28f, .22f, 1f), baseSkeletonColor, t));
                transform.localPosition = start + Vector3.right * (Mathf.Sin(t * Mathf.PI * 5f) * .07f * (1f - t));
                yield return null;
            }

            SetSkeletonColor(baseSkeletonColor);
            transform.localPosition = start;
            feedbackRoutine = null;
        }

        private void SetSkeletonColor(Color color)
        {
            var skeleton = skeletonAnimation.Skeleton;
            skeleton.R = color.r;
            skeleton.G = color.g;
            skeleton.B = color.b;
            skeleton.A = color.a;
        }

        private void ShowFloatingValue(float amount, Color color, string prefix)
        {
            if (!healthCanvas || amount <= .01f)
                return;

            var go = new GameObject("BattleFloatText", typeof(RectTransform), typeof(CanvasRenderer), typeof(Text));
            var rect = (RectTransform)go.transform;
            rect.SetParent(healthCanvas.transform, false);
            rect.anchorMin = rect.anchorMax = new Vector2(.5f, .5f);
            rect.sizeDelta = new Vector2(260f, 70f);
            rect.anchoredPosition = new Vector2(0f, -72f);
            var text = go.GetComponent<Text>();
            text.font = CardPresentationUtility.Font;
            text.fontSize = 32;
            text.fontStyle = FontStyle.Bold;
            text.alignment = TextAnchor.MiddleCenter;
            text.color = color;
            text.raycastTarget = false;
            text.text = $"{prefix}{Mathf.CeilToInt(amount)}";
            StartCoroutine(AnimateFloatingText(rect, text));
        }

        private static IEnumerator AnimateFloatingText(RectTransform rect, Text text)
        {
            var start = rect.anchoredPosition;
            var color = text.color;
            for (var elapsed = 0f; elapsed < .7f; elapsed += Time.deltaTime)
            {
                var t = elapsed / .7f;
                rect.anchoredPosition = start + Vector2.up * (75f * t);
                color.a = 1f - Mathf.SmoothStep(0f, 1f, t);
                text.color = color;
                yield return null;
            }
            Destroy(rect.gameObject);
        }
    }
}

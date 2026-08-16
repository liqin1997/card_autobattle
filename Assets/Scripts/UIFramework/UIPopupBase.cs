using System.Collections;
using UnityEngine;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform), typeof(CanvasGroup))]
    public abstract class UIPopupBase : MonoBehaviour
    {
        [SerializeField] private bool closeWhenMaskClicked = true;
        private CanvasGroup canvasGroup;

        public bool CloseWhenMaskClicked => closeWhenMaskClicked;
        protected GameUIRoot UIRoot { get; private set; }
        protected UIPopupService Service { get; private set; }

        internal void Initialize(GameUIRoot root, UIPopupService service)
        {
            UIRoot = root;
            Service = service;
            canvasGroup = GetComponent<CanvasGroup>();
            OnInitialize();
        }

        internal IEnumerator OpenRoutine(object args, float duration)
        {
            gameObject.SetActive(true);
            canvasGroup.alpha = 0f;
            canvasGroup.interactable = false;
            canvasGroup.blocksRaycasts = false;
            OnOpen(args);
            yield return Fade(1f, duration);
            canvasGroup.interactable = true;
            canvasGroup.blocksRaycasts = true;
        }

        internal IEnumerator CloseRoutine(float duration)
        {
            canvasGroup.interactable = false;
            canvasGroup.blocksRaycasts = false;
            OnClose();
            yield return Fade(0f, duration);
        }

        protected void CloseSelf() => Service.Close(this);

        private IEnumerator Fade(float target, float duration)
        {
            var start = canvasGroup.alpha;
            if (duration <= 0f)
            {
                canvasGroup.alpha = target;
                yield break;
            }

            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                canvasGroup.alpha = Mathf.Lerp(start, target, Mathf.Clamp01(elapsed / duration));
                yield return null;
            }
            canvasGroup.alpha = target;
        }

        protected virtual void OnInitialize() { }
        protected virtual void OnOpen(object args) { }
        protected virtual void OnClose() { }
    }
}

using System.Collections;
using UnityEngine;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    [RequireComponent(typeof(RectTransform), typeof(CanvasGroup))]
    public abstract class UIScreenBase : MonoBehaviour
    {
        [SerializeField] private bool fullScreen = true;

        private CanvasGroup canvasGroup;
        private bool initialized;

        public abstract UIScreenId ScreenId { get; }
        public UIWindowState State { get; private set; } = UIWindowState.Closed;
        public bool IsFullScreen => fullScreen;
        protected GameUIRoot UIRoot { get; private set; }

        internal void Initialize(GameUIRoot root)
        {
            if (initialized)
                return;

            UIRoot = root;
            canvasGroup = GetComponent<CanvasGroup>();
            initialized = true;
            OnInitialize();
        }

        internal IEnumerator OpenRoutine(object args, float duration)
        {
            gameObject.SetActive(true);
            State = UIWindowState.Opening;
            SetInteraction(false);
            OnOpen(args);

            yield return FadeTo(1f, duration);

            State = UIWindowState.Open;
            SetInteraction(true);
            OnOpenComplete();
        }

        internal IEnumerator CloseRoutine(float duration)
        {
            State = UIWindowState.Closing;
            SetInteraction(false);
            OnClose();

            yield return FadeTo(0f, duration);

            State = UIWindowState.Closed;
            gameObject.SetActive(false);
            OnCloseComplete();
        }

        internal void Refresh(object args)
        {
            OnRefresh(args);
        }

        private IEnumerator FadeTo(float target, float duration)
        {
            if (!canvasGroup)
                yield break;

            if (duration <= 0f)
            {
                canvasGroup.alpha = target;
                yield break;
            }

            var start = canvasGroup.alpha;
            var elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                canvasGroup.alpha = Mathf.Lerp(start, target, Mathf.Clamp01(elapsed / duration));
                yield return null;
            }
            canvasGroup.alpha = target;
        }

        protected void SetInteraction(bool enabled)
        {
            if (!canvasGroup)
                canvasGroup = GetComponent<CanvasGroup>();
            canvasGroup.interactable = enabled;
            canvasGroup.blocksRaycasts = enabled;
        }

        public virtual bool HandleBack() => false;
        protected virtual void OnInitialize() { }
        protected virtual void OnOpen(object args) { }
        protected virtual void OnRefresh(object args) { }
        protected virtual void OnOpenComplete() { }
        protected virtual void OnClose() { }
        protected virtual void OnCloseComplete() { }
    }
}

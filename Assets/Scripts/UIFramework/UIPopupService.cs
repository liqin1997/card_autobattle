using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class UIPopupService : MonoBehaviour
    {
        [SerializeField] private Image modalBlocker;
        [SerializeField, Min(0f)] private float fadeDuration = .14f;

        private readonly List<UIPopupBase> stack = new();
        private GameUIRoot root;
        private RectTransform modalLayer;
        private bool transitioning;

        internal void Initialize(GameUIRoot uiRoot, RectTransform layer)
        {
            root = uiRoot;
            modalLayer = layer;
            if (modalBlocker)
            {
                var button = modalBlocker.GetComponent<Button>();
                if (button)
                {
                    button.onClick.RemoveListener(OnMaskClicked);
                    button.onClick.AddListener(OnMaskClicked);
                }
                SetMaskVisible(false);
            }
        }

        public T Open<T>(T prefab, object args = null) where T : UIPopupBase
        {
            if (!prefab || transitioning)
                return null;

            var popup = Instantiate(prefab, modalLayer, false);
            popup.Initialize(root, this);
            stack.Add(popup);
            StartCoroutine(OpenRoutine(popup, args));
            return popup;
        }

        public void Close(UIPopupBase popup)
        {
            if (!popup || transitioning || !stack.Contains(popup))
                return;
            StartCoroutine(CloseRoutine(popup));
        }

        public bool CloseTop()
        {
            if (stack.Count == 0)
                return false;
            Close(stack[stack.Count - 1]);
            return true;
        }

        private IEnumerator OpenRoutine(UIPopupBase popup, object args)
        {
            transitioning = true;
            SetMaskVisible(true);
            modalBlocker.transform.SetSiblingIndex(Mathf.Max(0, popup.transform.GetSiblingIndex()));
            popup.transform.SetAsLastSibling();
            yield return popup.OpenRoutine(args, fadeDuration);
            transitioning = false;
        }

        private IEnumerator CloseRoutine(UIPopupBase popup)
        {
            transitioning = true;
            yield return popup.CloseRoutine(fadeDuration);
            stack.Remove(popup);
            Destroy(popup.gameObject);
            SetMaskVisible(stack.Count > 0);
            transitioning = false;
        }

        private void OnMaskClicked()
        {
            if (stack.Count == 0)
                return;
            var top = stack[stack.Count - 1];
            if (top.CloseWhenMaskClicked)
                Close(top);
        }

        private void SetMaskVisible(bool visible)
        {
            if (!modalBlocker)
                return;
            modalBlocker.gameObject.SetActive(visible);
            modalBlocker.raycastTarget = visible;
        }

#if UNITY_EDITOR
        public void EditorConfigure(Image blocker)
        {
            modalBlocker = blocker;
        }
#endif
    }
}

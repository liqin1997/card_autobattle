using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class UIScreenRouter : MonoBehaviour
    {
        [SerializeField] private RectTransform screenLayer;
        [SerializeField] private CanvasGroup inputBlocker;
        [SerializeField, Min(0f)] private float transitionDuration = .16f;
        [SerializeField] private UIScreenId initialScreen = UIScreenId.MainHub;
        [SerializeField] private List<UIScreenRegistration> screens = new();

        private readonly Dictionary<UIScreenId, UIScreenRegistration> registrationLookup = new();
        private readonly Dictionary<UIScreenId, UIScreenBase> instances = new();
        private readonly List<UIScreenId> history = new();
        private GameUIRoot root;
        private UIScreenBase current;
        private bool transitioning;

        public UIScreenBase Current => current;
        public UIScreenId CurrentId => current ? current.ScreenId : UIScreenId.None;
        public bool IsTransitioning => transitioning;

        internal void Initialize(GameUIRoot uiRoot)
        {
            root = uiRoot;
            registrationLookup.Clear();
            foreach (var registration in screens)
            {
                if (registration != null && registration.Id != UIScreenId.None && registration.Prefab)
                    registrationLookup[registration.Id] = registration;
            }
            SetInputBlocked(false);
        }

        internal IEnumerator OpenInitialRoutine()
        {
            yield return null;
            Open(initialScreen, null, false);
        }

        public bool Open(UIScreenId id, object args = null, bool pushHistory = true)
        {
            if (transitioning || id == UIScreenId.None)
                return false;

            if (current && current.ScreenId == id)
            {
                current.Refresh(args);
                return true;
            }

            if (!registrationLookup.ContainsKey(id))
            {
                Debug.LogError($"[UI] Screen is not registered: {id}");
                return false;
            }

            StartCoroutine(SwitchRoutine(id, args, pushHistory));
            return true;
        }

        public bool Back()
        {
            if (transitioning || !current)
                return false;

            if (current.HandleBack())
                return true;

            if (history.Count <= 1)
                return false;

            history.RemoveAt(history.Count - 1);
            var previous = history[history.Count - 1];
            StartCoroutine(SwitchRoutine(previous, null, false));
            return true;
        }

        private IEnumerator SwitchRoutine(UIScreenId id, object args, bool pushHistory)
        {
            transitioning = true;
            SetInputBlocked(true);

            var previous = current;
            if (previous)
                yield return previous.CloseRoutine(transitionDuration);

            var next = GetOrCreate(id);
            if (!next)
            {
                SetInputBlocked(false);
                transitioning = false;
                yield break;
            }

            current = next;
            UpdateHistory(id, pushHistory);
            yield return next.OpenRoutine(args, transitionDuration);

            if (previous && previous != next &&
                registrationLookup.TryGetValue(previous.ScreenId, out var previousRegistration) &&
                !previousRegistration.KeepAlive)
            {
                instances.Remove(previous.ScreenId);
                Destroy(previous.gameObject);
            }

            SetInputBlocked(false);
            transitioning = false;
        }

        private UIScreenBase GetOrCreate(UIScreenId id)
        {
            if (instances.TryGetValue(id, out var cached) && cached)
                return cached;

            var registration = registrationLookup[id];
            var instance = Instantiate(registration.Prefab, screenLayer, false);
            instance.name = registration.Prefab.name;
            if (instance.transform is RectTransform rect)
            {
                rect.anchorMin = Vector2.zero;
                rect.anchorMax = Vector2.one;
                rect.offsetMin = Vector2.zero;
                rect.offsetMax = Vector2.zero;
                rect.localScale = Vector3.one;
            }

            var screen = instance.GetComponent<UIScreenBase>();
            if (!screen)
            {
                Debug.LogError($"[UI] Prefab has no UIScreenBase: {registration.Prefab.name}");
                Destroy(instance);
                return null;
            }

            if (screen.ScreenId != id)
                Debug.LogWarning($"[UI] Registration {id} uses screen {screen.ScreenId}.");

            screen.Initialize(root);
            instance.SetActive(false);
            instances[id] = screen;
            return screen;
        }

        private void UpdateHistory(UIScreenId id, bool push)
        {
            if (history.Count == 0)
            {
                history.Add(id);
                return;
            }

            if (push)
            {
                if (history[history.Count - 1] != id)
                    history.Add(id);
            }
            else
            {
                history[history.Count - 1] = id;
            }
        }

        private void SetInputBlocked(bool blocked)
        {
            if (!inputBlocker)
                return;
            inputBlocker.gameObject.SetActive(blocked);
            inputBlocker.alpha = blocked ? 1f : 0f;
            inputBlocker.interactable = blocked;
            inputBlocker.blocksRaycasts = blocked;
        }

        private void Update()
        {
            if (Input.GetKeyDown(KeyCode.Escape))
                Back();
        }

#if UNITY_EDITOR
        public void EditorConfigure(RectTransform layer, CanvasGroup blocker,
            UIScreenId firstScreen, List<UIScreenRegistration> registrations)
        {
            screenLayer = layer;
            inputBlocker = blocker;
            initialScreen = firstScreen;
            screens = registrations;
        }
#endif
    }
}

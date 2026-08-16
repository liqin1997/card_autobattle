using System.Collections;
using UnityEngine;

namespace CardAutobattle.UI
{
    [DisallowMultipleComponent]
    public sealed class GameUIRoot : MonoBehaviour
    {
        [SerializeField] private UIScreenRouter screenRouter;
        [SerializeField] private UIPopupService popupService;
        [SerializeField] private RectTransform backgroundLayer;
        [SerializeField] private RectTransform screenLayer;
        [SerializeField] private RectTransform hudLayer;
        [SerializeField] private RectTransform dragLayer;
        [SerializeField] private RectTransform effectLayer;
        [SerializeField] private RectTransform modalLayer;
        [SerializeField] private RectTransform systemLayer;

        public static GameUIRoot Instance { get; private set; }
        public UIScreenRouter Screens => screenRouter;
        public UIPopupService Popups => popupService;
        public RectTransform DragLayer => dragLayer;
        public RectTransform EffectLayer => effectLayer;
        public RectTransform HudLayer => hudLayer;

        private void Awake()
        {
            if (Instance && Instance != this)
            {
                Destroy(gameObject);
                return;
            }

            Instance = this;
            DontDestroyOnLoad(gameObject);
            screenRouter.Initialize(this);
            popupService.Initialize(this, modalLayer);
        }

        private IEnumerator Start()
        {
            yield return screenRouter.OpenInitialRoutine();
        }

        private void OnDestroy()
        {
            if (Instance == this)
                Instance = null;
        }

#if UNITY_EDITOR
        public void EditorConfigure(UIScreenRouter router, UIPopupService popups,
            RectTransform background, RectTransform screen, RectTransform hud,
            RectTransform drag, RectTransform effect, RectTransform modal, RectTransform system)
        {
            screenRouter = router;
            popupService = popups;
            backgroundLayer = background;
            screenLayer = screen;
            hudLayer = hud;
            dragLayer = drag;
            effectLayer = effect;
            modalLayer = modal;
            systemLayer = system;
        }
#endif
    }
}

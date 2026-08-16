using UnityEngine;
using UnityEngine.EventSystems;

namespace CardAutobattle.UI
{
    public static class GameUIRuntimeBootstrap
    {
        private const string RootResourcePath = "UI/GameUIRoot";

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Bootstrap()
        {
            if (Object.FindFirstObjectByType<GameUIRoot>(FindObjectsInactive.Include))
                return;

            var legacy = GameObject.Find("GameCanvasRoot");
            if (legacy)
                legacy.SetActive(false);

            EnsureEventSystem();

            var prefab = Resources.Load<GameObject>(RootResourcePath);
            if (!prefab)
            {
                Debug.LogError($"[UI] Missing Resources/{RootResourcePath}.prefab. " +
                               "Run Tools/Card Autobattle/Build Lightweight UI Framework.");
                if (legacy)
                    legacy.SetActive(true);
                return;
            }

            var root = Object.Instantiate(prefab);
            root.name = "GameUIRoot";
        }

        private static void EnsureEventSystem()
        {
            if (Object.FindFirstObjectByType<EventSystem>(FindObjectsInactive.Include))
                return;

            new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));
        }
    }
}

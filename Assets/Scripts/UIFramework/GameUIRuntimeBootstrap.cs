using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.SceneManagement;

namespace CardAutobattle.UI
{
    public static class GameUIRuntimeBootstrap
    {
        private const string RootResourcePath = "UI/GameUIRoot";

        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void Bootstrap()
        {
            // FantasyMapCreator_2/Demo is a standalone map/fog presentation scene.
            // It intentionally has no game UI overlay so the Maplayer -> Foglayer
            // relationship can be inspected directly in Play Mode.
            var activeScene = SceneManager.GetActiveScene();
            if (activeScene.path == "Assets/FantasyMapCreator_2/Demo.unity")
                return;

            // The commercial vertical slice owns its complete UI hierarchy.  Do not
            // inject the legacy five-tab framework over that scene.
            if (Object.FindFirstObjectByType<CardAutobattle.Commercial.CommercialPrototypeController>(
                    FindObjectsInactive.Include))
                return;

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
